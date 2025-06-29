// The Swift Programming Language
// https://docs.swift.org/swift-book


import Combine
import Factory
import Foundation
import OSLog
import Spyable
import CoreBluetooth

let SERVICE_UUID = CBUUID(string: "00467768-6228-2272-4663-277478268000")
let SERVICE_DATA_UUID = CBUUID(string: "00004677-0000-1000-8000-00805f9b34fb")
let CHARACTERISTIC_UUID_CAPABILITIES = CBUUID(string: "00467768-6228-2272-4663-277478268005")
let CHARACTERISTIC_UUID_STATE = CBUUID(string: "00467768-6228-2272-4663-277478268001")
let CHARACTERISTIC_UUID_ERROR = CBUUID(string: "00467768-6228-2272-4663-277478268002")
let CHARACTERISTIC_UUID_RPC_COMMAND = CBUUID(string: "00467768-6228-2272-4663-277478268003")
let CHARACTERISTIC_UUID_RPC_RESULT = CBUUID(string: "00467768-6228-2272-4663-277478268004")

// 定义一个字符数组来存储特征
let IMPROV_CHARACTERISTICS: [CBUUID] = [
    CHARACTERISTIC_UUID_CAPABILITIES,
    CHARACTERISTIC_UUID_ERROR,
    CHARACTERISTIC_UUID_RPC_COMMAND,
    CHARACTERISTIC_UUID_RPC_RESULT,
    CHARACTERISTIC_UUID_STATE,
]

// 定义能力的枚举，假设 IDENTIFY 是 0x01
struct Capabilities {
    static let IDENTIFY: Int = 0x01 // 可以根据实际情况替换为相应的能力值
}


enum ReadCharacteristicError: Error {
    case notConnected
    case peripheralNotFound
    case invalidCommand
    case serviceDiscoveryFailed
    case characteristicDiscoveryFailed
    case readFailed
}

@Spyable
public protocol BlueToothBridging {
    func can_identify(entityID: String) async throws -> Bool
    
    func provision(ssid: String, p: String, stateCallback: @escaping (String) -> Void) async throws
}

public final class BlueToothBridge: NSObject {
    
    private var readingContinuation: CheckedContinuation<Int, Error>?
    private var connectionContinuation: CheckedContinuation<Void, Error>?
    private var serviceDiscoveryContinuation: CheckedContinuation<Void, Error>?
    private var characteristicDiscoveryContinuation: CheckedContinuation<Void, Error>?
    
    var centralManager: CBCentralManager!
    
    var peripherals: [CBPeripheral] = []
    
    let batteryLevelCharacteristicUUID = CBUUID(string: "AE41")
    
    override public init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        print("BlueToothBridge Init Success!")
    }
    
    func readCharacteristic(from peripheral: CBPeripheral, characteristicUUID: CBUUID) async throws -> Int {
        // 1. 检查是否已连接，如果没有则连接
        if peripheral.state != .connected {
            try await connectPeripheral(peripheral)
            guard peripheral.state == .connected else {
                throw ReadCharacteristicError.notConnected
            }
        }
        
        // 2. 如果 services 为空，则发现服务
        if peripheral.services == nil {
            try await discoverServices(for: peripheral)
        }
        
        peripheral.services?.forEach { print(" - \($0.uuid) \($0.isPrimary ? "(主服务)" : "")") }
        
        // 3. 获取目标服务（安全解包）
        guard let service = peripheral.services?.first(where: { $0.uuid == CBUUID(string: "0000180A-0000-1000-8000-00805F9B34FB") }) else {
            throw ReadCharacteristicError.serviceDiscoveryFailed
        }

        
        // 4. 发现特征（如果需要）
        if service.characteristics == nil {
            do {
                try await discoverCharacteristics(for: service)
            } catch {
                throw ReadCharacteristicError.characteristicDiscoveryFailed
            }
        }
        
        guard let characteristics = service.characteristics else {
            print("⚠️ No characteristics found for service: \(service.uuid)")
            throw ReadCharacteristicError.characteristicDiscoveryFailed
        }
        
        print("\n✅ Discovered \(characteristics.count) characteristics for service \(service.uuid):")
        for characteristic in characteristics {
            let properties = characteristic.properties
            print("""
            UUID: \(characteristic.uuid)
            Properties: \(properties)
            Value: \(String(describing: characteristic.value ?? nil))
            """)
        }
        
        // 5. 获取目标特征（安全解包）
        guard let characteristic = service.characteristics?.first(where: { $0.uuid == characteristicUUID }) else {
            throw ReadCharacteristicError.invalidCommand
        }
        
        // 6. 读取特征值
        return try await readValue(for: characteristic, on: peripheral)
    }
    
    // MARK: - 异步连接设备
    private func connectPeripheral(_ peripheral: CBPeripheral) async throws {
        guard peripheral.state != .connected else { return }
        
        centralManager.connect(peripheral)
        
        return try await withCheckedThrowingContinuation { continuation in
            self.connectionContinuation = continuation
        }
    }
    
    // MARK: - 异步发现服务
    private func discoverServices(for peripheral: CBPeripheral) async throws {
        peripheral.discoverServices(nil)
        
        return try await withCheckedThrowingContinuation { continuation in
            self.serviceDiscoveryContinuation = continuation
        }
    }
    
    // MARK: - 异步发现特征
    private func discoverCharacteristics(for service: CBService) async throws {
        service.peripheral?.discoverCharacteristics(IMPROV_CHARACTERISTICS, for: service)
        
        return try await withCheckedThrowingContinuation { continuation in
            self.characteristicDiscoveryContinuation = continuation
        }
    }
    
    // MARK: - 异步读取特征值
    private func readValue(for characteristic: CBCharacteristic, on peripheral: CBPeripheral) async throws -> Int {
        peripheral.readValue(for: characteristic)
        
        return try await withCheckedThrowingContinuation { continuation in
            self.readingContinuation = continuation
        }
    }
    
}

extension BlueToothBridge: CBPeripheralDelegate {
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            serviceDiscoveryContinuation?.resume(throwing: error)
        } else {
            serviceDiscoveryContinuation?.resume(returning: ())
        }
        serviceDiscoveryContinuation = nil
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            characteristicDiscoveryContinuation?.resume(throwing: error)
        } else {
            characteristicDiscoveryContinuation?.resume(returning: ())
        }
        characteristicDiscoveryContinuation = nil
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            readingContinuation?.resume(throwing: error)
        } else if let value = characteristic.value {
            let capabilities = value.withUnsafeBytes { $0.load(as: Int.self) }
            readingContinuation?.resume(returning: capabilities)
        } else {
            readingContinuation?.resume(throwing: ReadCharacteristicError.readFailed)
        }
        readingContinuation = nil
    }
}

extension BlueToothBridge: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            print("开始扫描蓝牙设备")
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        } else {
            // Handle Bluetooth not available or powered off
        }
    }
    

    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi: NSNumber) {
        // print("发现蓝牙设备 名称: \(peripheral.name ?? "未知")")
        if !peripherals.contains(peripheral) {
            peripherals.append(peripheral)
        }
    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectionContinuation?.resume(returning: ())
        connectionContinuation = nil
        peripheral.delegate = self
    }
    
}

// MARK: Websocket Commands
extension BlueToothBridge: BlueToothBridging {
    public func provision(ssid: String, p: String, stateCallback: @escaping (String) -> Void) async throws {
        
    }
    
    
    public func can_identify(entityID: String) async throws -> Bool {
//        peripherals.forEach { peripheral in
//            print("""
//                发现设备：
//                名称: \(peripheral.name ?? "未知")
//                UUID: \(peripheral.identifier)
//            """)
//        }
        
        for _ in 0..<10 {
            if let peripheral = peripherals.first(where: { $0.name == entityID }) {
                let capabilities = try await readCharacteristic(from: peripheral, characteristicUUID: CHARACTERISTIC_UUID_CAPABILITIES)
                return (capabilities & Capabilities.IDENTIFY) != 0
            }
            try await Task.sleep(nanoseconds: UInt64(1 * 1_000_000_000))
        }
        throw ReadCharacteristicError.peripheralNotFound
    }
}
