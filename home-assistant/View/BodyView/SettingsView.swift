//
//  SettingsView.swift
//  home-assistant
//
//  Created by admin on 6/25/25.
//

import SwiftUI

struct SettingsView: View {
    var settings: [SettingItem]
    @Binding var isAddBluetoothDevicePresented: Bool // 绑定添加设备的状态

    var body: some View {
        List {
            ForEach(settings) { item in
                // 每个设置项使用 HStack
                HStack(spacing: 10) { // 适当设置 Item 之间的间隔
                    Image(systemName: "gear") // 示例图标
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.blue)

                    // 左侧的文本信息
                    VStack(alignment: .leading) {
                        Text(item.title)
                            .font(.headline)
                        Text(item.description)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer() // 确保 Image 在最左侧
                }
                .frame(maxWidth: .infinity) // 设置项充满宽度
                .padding(.vertical, 10) // 设置项的上下内边距
                .onTapGesture {
                    if item.title == "蓝牙" {
                        isAddBluetoothDevicePresented = true // 点击蓝牙时，显示添加设备的浮层
                    }
                }
            }
            .background(Color.clear) // Optional：使背景透明以显示分割线
            Divider() // 在每项的底部添加分割线
                .padding(.horizontal, 0) // 去掉分割线两侧的额外间距
        }
        .listStyle(PlainListStyle()) // 使用Plain样式，使List的样式更简单
    }}
