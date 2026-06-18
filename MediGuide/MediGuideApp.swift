//
//  MediGuideApp.swift
//  MediGuide
//
//  Created by Ashmita Appineni on 2/17/26.
//

import SwiftUI

@main
struct MediGuideApp: App {
    init() {
        NotificationManager.requestPermission()
        _ = NetworkReachabilityMonitor.shared  // warm up monitor before first API call
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
