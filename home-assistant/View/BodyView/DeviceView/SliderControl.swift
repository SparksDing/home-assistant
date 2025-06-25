//
//  SliderControl.swift
//  home-assistant
//
//  Created by admin on 6/25/25.
//

import SwiftUI

struct SliderControl: View {
    var device: Device

    @State private var value: Double = 50.0 // 滑块初始值

    var body: some View {
        VStack {
            Slider(value: $value, in: 0...100, step: 1)
            Text("滑块值: \(Int(value))")
        }
        .padding()
    }
}
