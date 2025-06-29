//
//  File.swift
//  
//
//  Created by admin on 6/25/25.
//


import Factory

extension Container {
    public var blueToothWifiConfiguration: Factory<BlueToothBridge> {
        Factory(self) { BlueToothBridge() }
            .singleton
    }
}
