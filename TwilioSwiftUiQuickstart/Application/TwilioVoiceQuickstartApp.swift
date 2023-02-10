//
//  TwilioVoiceQuickstartApp.swift
//
//  TwilioSwiftUiQuickstart
//
//  Created by Serhii Krotkykh on 25.06.2021.
//
import SwiftUI
import TwilioVoiceAdapter

@main
struct TwilioVoiceQuickstartApp: App {
    @Environment(\.scenePhase) var scenePhase
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject var viewModel = TwilioVoiceController()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
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
