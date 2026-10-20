//
//  TwilioVoiceQuickstartApp.swift
//  TwilioQuickstart
//
import SwiftUI
import TwilioVoiceAdapter

@main
struct TwilioVoiceQuickstartApp: App {
    @StateObject var viewModel = TwilioVoiceController(accessTokenConfiguration: .tokenServer)

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
        }
    }
}

extension TwilioAccessTokenConfiguration {
    // TODO: Replace with your Twilio access token server parameters
    static let tokenServer = TwilioAccessTokenConfiguration(
        baseURLString: "https://accesstoken.com",
        // If your token server is written in PHP, accessTokenEndpoint needs .php
        // extension at the end. For example : /accessToken.php
        accessTokenEndpoint: "/accessToken",
        identity: "alice"
    )
}
