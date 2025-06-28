//
//  AddBlueToothDeviceView.swift
//  home-assistant
//
//  Created by admin on 6/25/25.
//

import AppConfiguration
import BlueToothWifiConfiguration
import SwiftUI
import Combine
import Factory
import RealmSwift


@MainActor
class AddBluetoothViewModel: ObservableObject {
    @Published var isShowingWiFiAlert = false
    @Published var ssid: String = ""
    @Published var password: String = ""
    @Published var isWiFiSupported = false
    @Published var configurationResultMessage: String = ""
    @Published var isShowingResultAlert = false

    @Injected(\.blueToothWifiConfiguration) private var blueToothBridge// 假设你有蓝牙桥的实例

    // 使用 @MainActor 确保在主线程上执行
    func checkWiFiSupport() async {
        do {
            let state = try await blueToothBridge.can_identify()

            if state == 1 {
                isWiFiSupported = true
            }
        } catch {
            print("检查设备支持错误: \(error)")
        }
    }

    // 使用 @MainActor 确保在主线程上执行
    func configureWiFi() async {
        do {
            let redirectURL = try await blueToothBridge.provision(ssid: ssid, p: password, stateCallback: { state in
                // 处理状态更新
                print("当前状态: \(state)")
            })

            // 配置成功，设置弹框消息
            configurationResultMessage = "配置完成，重定向 URL: \(redirectURL ?? "无")"
        } catch {
            // 配置失败，设置弹框消息
            configurationResultMessage = "配置 Wi-Fi 失败: \(error.localizedDescription)"
        }

        // 清空输入
        ssid = ""
        password = ""

        // 显示结果弹框
        isShowingResultAlert = true
    }
}

// 添加蓝牙设备的视图
struct AddBluetoothDeviceView: View {
    @Environment(\.presentationMode) var presentationMode // 用于关闭视图

    @ObservedObject var viewModel = AddBluetoothViewModel() // 使用 ViewModel

    var body: some View {
        VStack {
            if viewModel.isWiFiSupported {
                Button("配置 Wi-Fi") {
                    viewModel.isShowingWiFiAlert = true // 弹出输入框
                }
            } else {
                Text("蓝牙设备不支持配置 Wi-Fi")
            }
        }
        .alert(isPresented: $viewModel.isShowingWiFiAlert) {
            Alert(
                title: Text("输入 Wi-Fi 名称和密码"),
                message: Text("请提供您的 Wi-Fi 名称及密码"),
                primaryButton: .default(Text("提交")) {
                    // 使用 async 调用 configureWiFi
                    Task {
                        await viewModel.configureWiFi()
                    }
                },
                secondaryButton: .cancel()
            )
        }
        // 显示配置结果的弹框
        .alert(isPresented: $viewModel.isShowingResultAlert) {
            Alert(
                title: Text("配置结果"),
                message: Text(viewModel.configurationResultMessage),
                dismissButton: .default(Text("确定"))
            )
        }
        .onAppear {
                // 在视图出现时检查 Wi-Fi 支持
                Task {
                    await viewModel.checkWiFiSupport()
                }
            }
        }
}
