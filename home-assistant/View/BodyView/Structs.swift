//
//  Device.swift
//  home-assistant
//
//  Created by admin on 6/25/25.
//

import Foundation


// 定义设备的类型
enum DeviceType {
    case switchControl
    case sliderControl
}

// 设备模型
struct Device: Identifiable {
    let id = UUID()
    let name: String
    let type: DeviceType
}


struct SettingItem: Identifiable {
    let id = UUID()
    let title: String
    let description: String
}


enum ContentViewType {
    case deviceList
    case settings
}
