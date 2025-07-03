import Foundation
import Network
import Spyable
import SwiftProtobuf

@Spyable
public protocol ESPHomeBridging {
    func connect(host: String, port: Int, password: String) async throws
    func disconnect() async throws
    func fetchDeviceInfo() async throws -> ESPDeviceInfo
}

public final class EsphomeBridge: NSObject {
    private var connection: NWConnection?
    private var isConnected = false
    private var password: String?
    private var frameHelper: FrameHelperProtocol?
    private var handshakeComplete = false
    
    private enum ConnectionState {
        case disconnected
        case resolving
        case connecting
        case handshaking
        case connected
    }
    private var connectionState: ConnectionState = .disconnected
    
    override public init() {
        super.init()
        print("EsphomeBridge Init Success!")
    }
    
    deinit {
        Task { try? await disconnect() }
    }
}

// MARK: - 核心连接实现
extension EsphomeBridge: ESPHomeBridging {
    public func connect(host: String, port: Int = 6053, password: String = "") async throws {
        // 1. 创建TCP连接
        let endpoint = NWEndpoint.hostPort(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(rawValue: UInt16(port))!
        )
        connection = NWConnection(to: endpoint, using: .tcp)
        
        // 2. 建立连接
        try await establishSocketConnection()
        
        // 3. 发送Hello消息 (使用Protobuf)
        let helloRequest = HelloRequest.with {
            $0.clientInfo = "ESPHomeSwiftClient/1.0"
            $0.apiVersionMajor = 1
            $0.apiVersionMinor = 7
        }
        
        let helloResponse: HelloResponse = try await sendMessage(helloRequest)
        print("Connected to \(helloResponse.serverInfo), API v\(helloResponse.apiVersionMajor).\(helloResponse.apiVersionMinor)")
        
        // 4. 认证（如果需要）
        if !password.isEmpty {
            let connectRequest = ConnectRequest.with {
                $0.password = password
            }
            let connectResponse: ConnectResponse = try await sendMessage(connectRequest)
            if connectResponse.invalidPassword {
                throw ESPHomeError.authenticationFailed
            }
        }
        
        isConnected = true
        handshakeComplete = true
    }
    
    public func disconnect() async throws {
        connection?.cancel()
        isConnected = false
        handshakeComplete = false
        frameHelper = nil
        connectionState = .disconnected
    }
    
    
    public func fetchDeviceInfo() async throws -> ESPDeviceInfo {
        let request = DeviceInfoRequest()
        let response: DeviceInfoResponse = try await sendMessage(request)
        return ESPDeviceInfo(from: response)
    }
}

// MARK: - 私有方法实现
private extension EsphomeBridge {
    private func establishSocketConnection() async throws {
        guard let connection = connection else {
            throw ESPHomeError.connectionFailed("Connection not initialized")
        }
        
        // 使用AsyncStream处理状态更新
        let stateStream = AsyncStream<NWConnection.State> { continuation in
            connection.stateUpdateHandler = { state in
                continuation.yield(state)
                if case .cancelled = state {
                    continuation.finish()
                }
            }
            connection.start(queue: .main)
        }
        
        // 处理状态流
        for await state in stateStream {
            switch state {
            case .ready:
                configureSocketOptions()
                return // 成功连接，直接返回
                
            case .failed(let error):
                throw ESPHomeError.connectionFailed(error.localizedDescription)
                
            case .cancelled:
                throw ESPHomeError.connectionFailed("Connection cancelled")
                
            default:
                break
            }
        }
        
        // 添加超时控制
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                for await _ in stateStream {
                    // 等待状态更新
                }
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: 10_000_000_000) // 10秒超时
                connection.cancel()
                throw ESPHomeError.timeout
            }
            
            try await group.next()!
            group.cancelAll()
        }
    }
    
    func configureSocketOptions() {
        // 可在此配置TCP选项
    }
    
    
    
    func makeHelloRequest() throws -> HelloRequest {
            var request = HelloRequest()
            request.clientInfo = "ESPHomeSwiftClient/1.0"
            request.apiVersionMajor = 1
            request.apiVersionMinor = 7
            return request
        }
        
    func makeConnectRequest(password: String) -> ConnectRequest {
        var request = ConnectRequest()
        request.password = password
        return request
    }
    
    func sendMessage<T: SwiftProtobuf.Message, U: SwiftProtobuf.Message>(_ request: T) async throws -> U {
        guard let connection = connection else {
            throw ESPHomeError.notConnected
        }
        
        // 1. 编码消息类型和内容
        let messageType = try getMessageType(for: T.self)
        let payload = try request.serializedData()
        
        // 2. 构建协议帧
        var frame = Data()
        frame.append(0x00) // 起始字节
        frame.append(contentsOf: encodeVarUInt(UInt(payload.count)))
        frame.append(contentsOf: encodeVarUInt(UInt(messageType)))
        frame.append(payload)
        
        // 3. 发送数据
        try await connection.send(content: frame)
        
        // 4. 接收响应
        let responseData = try await connection.receive(minimumIncompleteLength: 1, maximumLength: 4096)
        return try parseResponse(responseData)
    }
    
    func parseResponse<T: SwiftProtobuf.Message>(_ data: Data) throws -> T {
        // 发送方的头部布局是：填充 + 0x00标志 + 长度varint + 类型varint + 实际数据
        // 我们需要找到0x00标志的位置
        
        // 1. 查找0x00标志字节
        guard let zeroIndex = data.firstIndex(of: 0x00) else {
            throw ESPHomeError.invalidResponse
        }
        
        // 2. 从0x00标志后开始解析
        let headerStart = zeroIndex + 1
        guard headerStart < data.count else {
            throw ESPHomeError.invalidResponse
        }
        
        // 3. 解析长度和类型
        let remainingData = data.suffix(from: headerStart)
        let (payloadSize, offset1) = try decodeVarUInt(remainingData)
        let (messageType, offset2) = try decodeVarUInt(remainingData.dropFirst(offset1))
        
        // 4. 提取payload
        let payloadStart = headerStart + offset1 + offset2
        let payloadEnd = payloadStart + Int(payloadSize)
        guard payloadEnd <= data.count else {
            throw ESPHomeError.invalidResponse
        }
        let payload = data[payloadStart..<payloadEnd]
        
        // 5. 根据消息类型解码
        return try decodeMessage(type: Int(messageType), data: payload)
    }

    private func decodeVarUInt(_ data: Data) throws -> (value: UInt32, bytesRead: Int) {
        var value: UInt32 = 0
        var shift: UInt32 = 0
        var bytesRead = 0
        
        for byte in data {
            bytesRead += 1
            value |= UInt32(byte & 0x7F) << shift
            if (byte & 0x80) == 0 {
                return (value, bytesRead)
            }
            shift += 7
            if shift >= 32 {
                throw ESPHomeError.invalidResponse
            }
        }
        
        throw ESPHomeError.invalidResponse
    }
    
    
    func getMessageType<T: SwiftProtobuf.Message>(for messageType: T.Type) throws -> Int {
        // 这里应该根据.proto文件中的option (id)返回正确的消息类型ID
        // 简化实现，实际应该建立完整的消息类型映射
        switch messageType {
            case is HelloRequest.Type: return 1
            case is HelloResponse.Type: return 2
            case is ConnectRequest.Type: return 3
            case is ConnectResponse.Type: return 4
            case is DeviceInfoRequest.Type: return 9
            case is DeviceInfoResponse.Type: return 10
            default:
                throw ESPHomeError.unsupportedMessageType
        }
    }
    
    func decodeMessage<T: Message>(type: Int, data: Data) throws -> T {
        switch type {
        case 2: return try HelloResponse(serializedBytes: data) as! T
        case 4: return try ConnectResponse(serializedBytes: data) as! T
        case 10: return try DeviceInfoResponse(serializedBytes: data) as! T
        default:
            throw ESPHomeError.unsupportedMessageType
        }
    }
    
    func encodeVarUInt(_ value: UInt) -> Data {
        var data = Data()
        var v = value
        repeat {
            var byte = UInt8(v & 0x7F)
            v >>= 7
            if v != 0 { byte |= 0x80 }
            data.append(byte)
        } while v != 0
        return data
    }

    
    func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask { try await operation() }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw ESPHomeError.timeout
            }
            
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
}

// MARK: - FrameHelper协议
private protocol FrameHelperProtocol {
    var connection: NWConnection { get }
    init(connection: NWConnection)
    func performHandshake() async throws
}

private struct PlaintextFrameHelper: FrameHelperProtocol {
    let connection: NWConnection
    
    func performHandshake() async throws {
        // 明文协议不需要实际握手
    }
}

// MARK: - 错误类型
public enum ESPHomeError: Error {
    case notConnected
    case connectionFailed(String)
    case disconnectionFailed(String)
    case invalidResponse
    case requestFailed(String, String)
    case timeout
    case handshakeFailed
    case authenticationFailed
    case invalidVarUInt
    case incompleteVarUInt
    case unsupportedMessageType
}

// MARK: - 数据模型
public struct ESPHomeEntity {
    public let id: String
    public let name: String
    public let type: EntityType
    public let state: String?
    
    public enum EntityType {
        case light
        case `switch`
        case sensor
        case binarySensor
        case fan
        case cover
        case climate
        case other(String)
    }
}

public struct ESPDeviceInfo {
    public let name: String
    public let macAddress: String
    public let version: String
    public let model: String
    
    init(from response: DeviceInfoResponse) {
        self.name = response.name
        self.macAddress = response.macAddress
        self.version = response.esphomeVersion
        self.model = response.model
    }
}


// MARK: - NWConnection 异步扩展
extension NWConnection {
    func send(content: Data) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.send(
                content: content,
                completion: .contentProcessed { error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            )
        }
    }
    
    func receive(minimumIncompleteLength: Int, maximumLength: Int) async throws -> Data {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data, Error>) in
            self.receive(
                minimumIncompleteLength: minimumIncompleteLength,
                maximumLength: maximumLength
            ) { data, _, isComplete, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let data = data {
                    continuation.resume(returning: data)
                } else if isComplete {
                    continuation.resume(returning: Data())
                }
            }
        }
    }
}
