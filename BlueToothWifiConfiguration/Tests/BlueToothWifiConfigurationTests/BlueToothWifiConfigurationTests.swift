import XCTest
import CoreBluetooth
@testable import BlueToothWifiConfiguration


final class BlueToothWifiConfigurationTests: XCTestCase {
    var centralManager: CBCentralManager!
    var centralManagerDelegate: CentralManagerDelegateMock!
    
    override func setUp() {
        super.setUp()
        centralManagerDelegate = CentralManagerDelegateMock()
        centralManager = CBCentralManager(delegate: centralManagerDelegate, queue: nil)
    }
    
    override func tearDown() {
        centralManager = nil
        centralManagerDelegate = nil
        super.tearDown()
    }
    
    func testCentralManagerInitialization() {
        XCTAssertNotNil(centralManager)
        XCTAssertNotNil(centralManager.delegate)
    }
    
    func testBluetoothState() {
        // Since Bluetooth state updates are asynchronous, we need to use expectations
        let expectation = XCTestExpectation(description: "Wait for Bluetooth state update")
        
        // Simulate the state update (in a real test, this would happen automatically)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.centralManagerDelegate.stateUpdated?(self.centralManager)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
        
        // Verify the delegate was called
        XCTAssertTrue(centralManagerDelegate.didUpdateStateCalled)
    }
}

// Mock delegate to track CBCentralManager callbacks
class CentralManagerDelegateMock: NSObject, CBCentralManagerDelegate {
    var didUpdateStateCalled = false
    var stateUpdated: ((CBCentralManager) -> Void)?
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        didUpdateStateCalled = true
        stateUpdated?(central)
    }
}
