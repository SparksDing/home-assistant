//
//  SwitchControl.swift
//  home-assistant
//
//  Created by admin on 6/25/25.
//

import SwiftUI

struct SwitchControl: View {
    var device: Device

    @State private var isOn: Bool = false // 开关状态

    var body: some View {
        Toggle(isOn: $isOn) {
            Text("开关状态: \(isOn ? "开" : "关")")
        }
        .padding()
    }
}
