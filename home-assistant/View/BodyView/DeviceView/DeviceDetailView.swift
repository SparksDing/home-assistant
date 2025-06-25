//
//  DeviceDetailView.swift
//  home-assistant
//
//  Created by admin on 6/25/25.
//

import SwiftUI

struct DeviceDetailView: View {
    var device: Device
    
    @Environment(\.presentationMode) var presentationMode // 用于管理当前视图的展示模式
    
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    // 返回上一页
                    presentationMode.wrappedValue.dismiss() // 返回上一页
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title)
                        .foregroundColor(.blue)
                }
                Spacer()
            }
            .padding() // 返回按钮的布局
            
            Text(device.name)
                .font(.largeTitle)
                .padding()
            
            // 在这里替换为你的3D模型视图
            Text("设备的 3D 模型展示区")
                .font(.title2)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white.opacity(0.2)) // 模拟 3D 模型的位置
                .cornerRadius(10)
                .padding()
            
            Spacer() // 用来调整内容的排版
        }
        .navigationBarHidden(true) // 隐藏默认的导航
    }
}

