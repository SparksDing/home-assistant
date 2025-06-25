//
//  home_assistantTests.swift
//  home-assistantTests
//
//  Created by admin on 6/12/25.
//

import XCTest
@testable import home_assistant

final class home_assistantTests: XCTestCase {
    
    var socketManager: SocketManager!

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
