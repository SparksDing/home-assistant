//
//  home_assistantTests.swift
//  home-assistantTests
//
//  Created by admin on 6/12/25.
//

import XCTest
import EsphomeCommunication
import Factory
@testable import home_assistant

final class home_assistantTests: XCTestCase {
    
    var socketManager: SocketManager!
    
    @Injected(\.esphomeCommunication) private var esphomeBridge// 假设你有蓝牙桥的实例
    

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        socketManager = SocketManager()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    
    func testProtobuf() async {

        do {
            // 1. 建立连接（包含setupChannel的调用）
            try await esphomeBridge.connect(host: "192.168.1.42", port: 6053, password: "")
            
            print("Connection Established!")
            
            
            
            
            // 2. 获取设备信息
           let deviceInfo = try await esphomeBridge.fetchDeviceInfo()
//
//            // 3. 打印设备信息
            print("""
            设备信息:
            名称: \(deviceInfo.name)
            型号: \(deviceInfo.model)
            MAC地址: \(deviceInfo.macAddress)
            """)
            
//            if let features = deviceInfo.bluetoothProxyFeatures {
//                print("蓝牙代理功能: \(features)")
//            }
//            
//            // 4. 可选：获取实体列表
//            let entities = try await esphomeBridge.listEntities()
//            print("发现 \(entities.count) 个实体")
            
        } catch ESPHomeError.connectionFailed(let reason) {
            print("连接失败: \(reason)")
        } catch ESPHomeError.authenticationFailed {
            print("认证失败：密码错误")
        } catch {
            print("操作失败: \(error.localizedDescription)")
        }

        // 6. 阻塞主线程等待用户输入
        print("\n按回车键退出...")
        _ = readLine() // 等待用户输入
        
        // 5. 使用完毕后断开连接
        defer {
            Task {
                try? await esphomeBridge.disconnect()
            }
        }
    }
    
    
    func testSocketManager() {
        let expectation = self.expectation(description: "Data sent")

        // 发送数据并检查是否没有错误
        let testData = "Hello, Server!"
        socketManager.send(data: testData)
        
        // Simulate a short delay to wait for sending to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // 这里可以检查是否成功发送，具体检查方式取决于 socketManager 实现
            // 假设我们在 SocketManager 中实现了一个 dataSent 属性（需要在你的 SocketManager 代码中添加相关逻辑）
            // XCTAssertTrue(/* Check if data sent was successful */)
            expectation.fulfill()
        }

        // 等待操作完成
        waitForExpectations(timeout: 1.0) { error in
            if let error = error {
                XCTFail("Expectation failed with error: \(error)")
            }
        }
    }

}
