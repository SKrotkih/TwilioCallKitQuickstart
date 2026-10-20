//
//  TwilioVoiceQuickstartApp.swift
//  TwilioQuickstart
//
import SwiftUI
import TwilioVoiceAdapter

@main
struct TwilioVoiceQuickstartApp: App {
    @StateObject var viewModel = TwilioVoiceController()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
        }
    }
}
