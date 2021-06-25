//
//  TwilioVoiceQuickstartApp.swift
//  TwilioVoiceQuickstart
//
//  Created by Sergey Krotkih on 25.06.2021.
//

import SwiftUI

@main
struct TwilioVoiceQuickstartApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(muteIsOn: false, speackerIsOn: true, outgoingNumber: "", call: {})
        }
    }
}
