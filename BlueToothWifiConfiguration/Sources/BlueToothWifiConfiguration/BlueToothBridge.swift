// The Swift Programming Language
// https://docs.swift.org/swift-book


import ApplicationConfiguration
import Combine
import Factory
import Foundation
import OSLog
import Spyable


@Spyable
public protocol BlueToothBridging {
    func turnLight(on: Bool, entityID: String) async throws -> Int
    var entityPublisher: PassthroughSubject<EntityState, Never> { get }
    var entityInitialStatePublisher: PassthroughSubject<[EntityState], Never> { get }
    var octopusPublisher: PassthroughSubject<[OctopusRate], Never> { get }
    var responsePublisher: PassthroughSubject<HAMessage, Never> { get }
}
