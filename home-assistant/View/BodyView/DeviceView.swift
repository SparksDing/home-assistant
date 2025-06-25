//
//  DeviceOverview.swift
//  home-assistant
//
//  Created by admin on 6/25/25.
//

import SwiftUI

struct DeviceView: View {
    var devices: [Device]

    var body: some View {
        List(devices) { device in
            DeviceCard(device: device)
        }
        .padding(0) // 移除默认的内边距
        .listStyle(PlainListStyle()) // 使用Plain样式，使List的样式更简单
    }
}


//#Preview {
//    DeviceOverView()
//}
