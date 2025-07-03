//
//  Container.swift
//  EsphomeCommunication
//
//  Created by 盈蒙高 on 2025/6/29.
//


import Factory

extension Container {
    public var esphomeCommunication: Factory<EsphomeBridge> {
        Factory(self) { EsphomeBridge() }
            .singleton
    }
}

