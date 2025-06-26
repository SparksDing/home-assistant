// The Swift Programming Language
// https://docs.swift.org/swift-book


import Combine
import Factory
import Foundation
import OSLog
import Spyable
import CoreBluetooth

enum ReadCharacteristicError: Error {
    case notConnected
    case peripheralNotFound
    case invalidCommand
}


@Spyable
public protocol BlueToothBridging {
}


public final class BlueToothBridge: NSObject {
    
    private var readingContinuation: CheckedContinuation<Int, Never>?
    
    var centralManager: CBCentralManager!
    
    
    var peripherals: [CBPeripheral] = []
    
    let batteryLevelCharacteristicUUID = CBUUID(string: "AE41")
    
    override public init() {
        super.init()
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    
    // 假设状态的解析是返回一个 IntEnum 或 IntFlag，请根据具体类型定义
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

        // 这里的读取值将在 delegate 方法中处理
        return await withCheckedContinuation { continuation in
            // 在这里保存 continuation，以便在特征值更新时恢复
            self.readingContinuation = continuation
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
        peripheral.discoverServices(nil)
        peripheral.delegate = self
    }
    
    func connectPeripheral(peripheral: CBPeripheral) {
        centralManager.stopScan()
        centralManager.connect(peripheral)
    }
    
}

// MARK: Websocket Commands
extension BlueToothBridge: BlueToothBridging {
    
    
}
