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
}

@Spyable
public protocol BlueToothBridging {
    func can_identify(entityID: String) async throws -> Bool
    
    func provision(ssid: String, p: String, stateCallback: @escaping (String) -> Void) async throws
}

public final class BlueToothBridge: NSObject {
    
    private var readingContinuation: CheckedContinuation<Int, Error>?
    
    var centralManager: CBCentralManager!
    
    var peripherals: [CBPeripheral] = []
    
    let batteryLevelCharacteristicUUID = CBUUID(string: "AE41")
    
    override public init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func readCharacteristic(from peripheral: CBPeripheral, characteristicUUID: CBUUID) async throws -> Int {
        // 检查是否连接
        guard peripherals.contains(peripheral) else {
            throw ReadCharacteristicError.notConnected
        }
        
        // 查找特征
        guard let characteristic = peripheral.services?
                .compactMap({ $0.characteristics })
                .flatMap({ $0 }) // 展平特征数组
                .first(where: { $0.uuid == characteristicUUID }) else {
            throw ReadCharacteristicError.invalidCommand
        }

        // 读取特征的值
        peripheral.readValue(for: characteristic)

        // 用来恢复异步操作的 continuation
        return try await withCheckedThrowingContinuation { continuation in
            self.readingContinuation = continuation // 将 continuation 保存供之后使用
        }
    }
    
}

extension BlueToothBridge: CBPeripheralDelegate {
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        let currentDate = Date()
        if let services = peripheral.services {
            _ = services.map({ (service: CBService) in
                debugPrint("\(currentDate) - peripheral is \(peripheral) and service is \(service)")
                peripheral.discoverCharacteristics(nil, for: service)
            })
        } else if let error = error {
            debugPrint("\(currentDate) - error in didDiscoverServices Error:- \(error.localizedDescription)")
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            if characteristic.uuid == batteryLevelCharacteristicUUID {
                peripheral.setNotifyValue(true, for: characteristic)
                peripheral.readValue(for: characteristic)
            }
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.uuid == batteryLevelCharacteristicUUID {
            if let data = characteristic.value {
                let batteryLevel = data[0]
                print("Battery Level: \(batteryLevel)%")
            }
        } else if let continuation = readingContinuation {
            if let error = error {
                continuation.resume(throwing: error)
                readingContinuation = nil
                return
            }

            if let value = characteristic.value, characteristic.uuid == CHARACTERISTIC_UUID_CAPABILITIES {
                // 将特征的值转为 Int
                let capabilities = value.withUnsafeBytes {
                    $0.load(as: Int.self) // 根据实际数据格式进行转换
                }
                
                // 如果能读取的值不能转换为 Int，抛出错误
                continuation.resume(returning: capabilities)
                readingContinuation = nil // 清空 continuation
            }
        }
    }
}

extension BlueToothBridge: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        } else {
            // Handle Bluetooth not available or powered off
        }
    }
    

    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi: NSNumber) {
        if !peripherals.contains(peripheral) {
            peripherals.append(peripheral)
        }
    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    func connectPeripheral(peripheral: CBPeripheral) {
        centralManager.stopScan()
        centralManager.connect(peripheral)
    }
    
}

// MARK: Websocket Commands
extension BlueToothBridge: BlueToothBridging {
    public func provision(ssid: String, p: String, stateCallback: @escaping (String) -> Void) async throws {
        
    }
    
    
    public func can_identify(entityID: String) async throws -> Bool {
        // 调用 readCharacteristic 获取 capabilities
        guard let peripheral = peripherals.first(where: { $0.name == entityID }) else {
            throw ReadCharacteristicError.peripheralNotFound // 如果没有找到，抛出错误
        }
        
        let capabilities: Int = try await readCharacteristic(from: peripheral, characteristicUUID: CHARACTERISTIC_UUID_CAPABILITIES)
        
        // 检查 capabilities 中是否包含 IDENTIFY
        return (capabilities & Capabilities.IDENTIFY) != 0
    }
}
