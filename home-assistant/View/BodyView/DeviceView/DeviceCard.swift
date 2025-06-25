//
//  DeviceCard.swift
//  home-assistant
//
//  Created by admin on 6/25/25.
//

import SwiftUI

struct DeviceCard: View {
    var device: Device

    var body: some View {
        VStack {
            Text(device.name)
                .font(.headline)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)

            if device.type == .switchControl {
                SwitchControl(device: device) // 如果是开关控制，显示 SwitchControl
            } else if device.type == .sliderControl {
                SliderControl(device: device) // 如果是滑块控制，显示 SliderControl
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2) // 添加阴影
    }
}
