//
//  DeviceOverview.swift
//  home-assistant
//
//  Created by admin on 6/25/25.
//

import SwiftUI

struct DeviceView: View {
    var devices: [Device]

    var body: some View {
        NavigationView {
            List(devices) { device in
                NavigationLink(destination: DeviceDetailView(device: device)) {
                    DeviceCard(device: device)
                }
            }
            .listStyle(PlainListStyle())
        }
    }
}


//#Preview {
//    DeviceOverView()
//}
