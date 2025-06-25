// The Swift Programming Language
// https://docs.swift.org/swift-book


import Combine
import Factory
import Foundation
import OSLog
import Spyable


@Spyable
public protocol BlueToothBridging {
    func turnLight(on: Bool, entityID: String) async throws -> Int
    var entityPublisher: PassthroughSubject<Int, Never> { get }
    var entityInitialStatePublisher: PassthroughSubject<[Int], Never> { get }
    var octopusPublisher: PassthroughSubject<[Int], Never> { get }
    var responsePublisher: PassthroughSubject<Int, Never> { get }
}


public final class BlueToothBridge: NSObject {
}


extension BlueToothBridge: URLSessionTaskDelegate {
    
}

// MARK: Websocket Commands
extension BlueToothBridge: BlueToothBridging {
    public func turnLight(on: Bool, entityID: String) async throws -> Int {
        <#code#>
    }
    
    public var entityPublisher: PassthroughSubject<Int, Never> {
        <#code#>
    }
    
    public var entityInitialStatePublisher: PassthroughSubject<[Int], Never> {
        <#code#>
    }
    
    public var octopusPublisher: PassthroughSubject<[Int], Never> {
        <#code#>
    }
    
    public var responsePublisher: PassthroughSubject<Int, Never> {
        <#code#>
    }
    
    
}
