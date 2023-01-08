//
//  TwilioVoiceQuickstartApp.swift
//
//  TwilioVoiceQuickstart
//
//  Created by Serhii Krotkykh on 25.06.2021.
//

import SwiftUI

@main
struct TwilioVoiceQuickstartApp: App {
    @Environment(\.scenePhase) var scenePhase
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(ContentDependencies.configure())
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .active:
                print("Active")
            case .inactive:
                print("Inactive")
            case .background:
                print("Background")
            @unknown default:
                print("")
            }
        }
    }
}
