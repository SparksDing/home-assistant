//
//  SocketManager.swift
//  home-assistant
//
//  Created by admin on 6/12/25.
//

import Foundation
import Network

class SocketManager: ObservableObject {
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "SocketQueue")
    
    init() {
        // 创建 socket
        setupConnection()
    }
    
    // 设置连接
    private func setupConnection() {
        let host = NWEndpoint.Host("127.0.0.1") // 目标主机
        let port = NWEndpoint.Port(integerLiteral: 6053) // 目标端口
        
        connection = NWConnection(host: host, port: port, using: .tcp)
        
        connection?.stateUpdateHandler = { state in
            switch state {
            case .ready:
                print("Connected to \(host) on port \(port)")
            case .failed(let error):
                print("Failed to connect: \(error)")
            default:
                break
            }
        }
        
        connection?.start(queue: queue)
    }
    
    // 发送数据
    func send(data: String) {
        guard let connection = connection else { return }
        let dataToSend = data.data(using: .utf8) ?? Data()
        connection.send(content: dataToSend, completion: .contentProcessed { error in
            if let error = error {
                print("Failed to send data: \(error)")
            } else {
                print("Data sent: \(data)")
            }
        })
    }
}
