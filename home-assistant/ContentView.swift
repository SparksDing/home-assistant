//
//  ContentView.swift
//  home-assistant
//
//  Created by admin on 6/12/25.
//

import SwiftUI

struct ContentView: View {
    @State private var showMenu = false
    @State private var currentView: ContentViewType = .deviceList
    
    @State private var devices = [
        Device(name: "灯光", type: .switchControl),
        Device(name: "空调", type: .sliderControl),
        Device(name: "风扇", type: .switchControl),
        Device(name: "音响", type: .sliderControl)
    ] // 假设有一些设备
    
    // 示例设置项
    @State private var settings = [
        SettingItem(title: "Wi-Fi", description: "管理网络连接"),
        SettingItem(title: "蓝牙", description: "管理蓝牙设备"),
        SettingItem(title: "通知", description: "管理应用通知设置"),
        SettingItem(title: "隐私", description: "管理隐私选项"),
    ]
    
    // 用于管理蓝牙设备添加的状态
    @State private var isAddBluetoothDevicePresented = false

    var body: some View {
        ZStack {
            NavigationView {
                VStack(spacing: 0) {
                    HeaderView(currentView: $currentView, showMenu: $showMenu)
                    if currentView == .deviceList {
                        DeviceView(devices: devices)
                    } else {
                        SettingsView(settings: settings, isAddBluetoothDevicePresented: $isAddBluetoothDevicePresented)
                    }
                }
                .navigationBarHidden(true) // 隐藏默认的导航条
            }

            // 左侧抽屉菜单
            if showMenu {
                MenuView(showMenu: $showMenu, currentView: $currentView)
                    .transition(.move(edge: .leading)) // 从左侧滑入的过渡效果
                    .zIndex(1) // 确保菜单在上层
            }
        }.sheet(isPresented: $isAddBluetoothDevicePresented) {
            AddBluetoothDeviceView() // 显示添加蓝牙设备的视图
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
