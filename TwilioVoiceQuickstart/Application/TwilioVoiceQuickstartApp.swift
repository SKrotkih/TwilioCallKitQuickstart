//
//  TwilioVoiceQuickstartApp.swift
//
//  TwilioVoiceQuickstart
//
//  Created by Sergey Krotkih on 25.06.2021.
//

import SwiftUI

@main
struct TwilioVoiceQuickstartApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(ContentViewModel())
        }
    }
}
