//
//  HeaderView.swift
//  home-assistant
//
//  Created by admin on 6/25/25.
//

import SwiftUI


struct HeaderView: View {
    @Binding var currentView: ContentViewType
    @Binding var showMenu: Bool

    var body: some View {
        HStack {
            Button(action: {
                withAnimation {
                    showMenu.toggle() // 切换菜单状态
                }
            }) {
                Text("菜单")
                    .font(.headline)
            }
            .padding()
            Spacer(minLength: 0) // 使菜单和设备列表之间的空间可伸缩
                        
            Text(headerTitle)
                .font(.largeTitle)

            Spacer(minLength: currentView == .settings ? 125 : 95) // 动态调整
            
            // 添加一个空的按钮以保持右侧的空间
            Button(action: { }) {
                Text("") // 这里可以添加右侧按钮
                    .padding()
            }
        }
        .background(Color.gray.opacity(0.2)) // 头部背景色
    }
    
    private var headerTitle: String {
        switch currentView {
        case .deviceList:
            return "设备列表"
        case .settings:
            return "设置"
        }
    }
}



//#Preview {
//    HeaderView()
//}
