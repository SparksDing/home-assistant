//
//  MenuView.swift
//  home-assistant
//
//  Created by admin on 6/25/25.
//

import SwiftUI

struct MenuView: View {
    @Binding var showMenu: Bool
    @Binding var currentView: ContentViewType

    var body: some View {
        GeometryReader { geometry in
            VStack {
                HStack {
                    Text("功能选项")
                        .font(.headline)
                    Spacer()
                    Button(action: {
                        withAnimation {
                            showMenu.toggle() // 关闭菜单
                        }
                    }) {
                        Image(systemName: "xmark")
                    }
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)

                List {
                    Button(action: {
                        withAnimation {
                            currentView = .deviceList
                            showMenu = false
                        }
                    }) {
                        Text("设备列表")
                    }
                    Button(action: {
                        withAnimation {
                            currentView = .settings
                            showMenu = false
                        }
                    }) {
                        Text("设置")
                    }
                }
                .frame(maxWidth: .infinity) // List 充满横向
            }
            .frame(width: geometry.size.width * 0.7) // 菜单宽度占屏幕宽度的70%
            .background(Color.white)
            .cornerRadius(10) // 圆角效果
            .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 2) // 添加阴影
            .offset(x: showMenu ? 0 : -geometry.size.width) // 根据状态调整菜单的X偏移
            .animation(.easeInOut) // 添加动画效果
            .padding(.top, (UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0) + 20) // 适配灵动岛
        }
        .edgesIgnoringSafeArea(.all) // 让菜单充满全屏
    }
}


//#Preview {
//    MenuView()
//}

