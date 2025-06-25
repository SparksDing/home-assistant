//
//  AddBlueToothDeviceView.swift
//  home-assistant
//
//  Created by admin on 6/25/25.
//

import SwiftUI

// 添加蓝牙设备的视图
struct AddBluetoothDeviceView: View {
    @Environment(\.presentationMode) var presentationMode // 用于关闭视图

    var body: some View {
        NavigationView {
            VStack {
                Text("添加蓝牙设备")
                    .font(.largeTitle)
                    .padding()

                // 这里可以放置你的添加设备的具体界面内容
                Text("在此处添加设备的详细内容...")
                    .padding()

                Button("关闭") {
                    presentationMode.wrappedValue.dismiss() // 关闭浮层
                }
                .padding()
            }
            .navigationBarItems(leading: Button("取消") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}
