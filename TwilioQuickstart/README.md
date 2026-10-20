<img alt="Twilio logo" align="right" src="/TwilioQuickstart/Resources/TwilioLogo.png">

# Twilio Voice Quickstart

Twilio Voice Quickstart is a SwiftUI iOS app for making and receiving voice calls with Twilio and CallKit. It is a refactored version of the [Twilio Voice Quickstart for iOS](https://github.com/twilio/voice-quickstart-swift) project.

The app contains only the UI. All Twilio Voice, CallKit and PushKit logic lives in the SPM package [twilio-voice-ios-adapter](https://github.com/SKrotkih/twilio-voice-ios-adapter).

## Requirements

- Xcode 16+
- iOS 18.6+
- Swift 5
- A Twilio access token server

## Installation

1. Clone this repository and [twilio-voice-ios-adapter](https://github.com/SKrotkih/twilio-voice-ios-adapter) side by side, because the project references the adapter as a local package at `../twilio-voice-ios-adapter`:

   ```
   git clone https://github.com/SKrotkih/TwilioCallKitQuickstart.git
   git clone https://github.com/SKrotkih/twilio-voice-ios-adapter.git
   ```

2. Open *TwilioQuickstart.xcodeproj* in Xcode. Swift Package Manager resolves the Twilio Voice SDK through the adapter.
3. Set your development team and bundle identifier. Push credentials (VoIP certificate) in the Twilio Console must match that bundle identifier.

## Access token

The app passes its token server parameters to the adapter as a `TwilioAccessTokenConfiguration`. Replace the placeholder values in *TwilioQuickstart/Application/TwilioVoiceQuickstartApp.swift*:

```swift
extension TwilioAccessTokenConfiguration {
    static let tokenServer = TwilioAccessTokenConfiguration(
        baseURLString: "https://accesstoken.com",
        accessTokenEndpoint: "/accessToken",
        identity: "alice"
    )
}
```

```swift
@StateObject var viewModel = TwilioVoiceController(accessTokenConfiguration: .tokenServer)
```

How to set up the token server, the required capabilities (microphone, Background Modes, Push Notifications) and how the call flow works are described in the [twilio-voice-ios-adapter README](https://github.com/SKrotkih/twilio-voice-ios-adapter#readme).

## Project structure

| Folder | Contents |
|---|---|
| `Application/` | App entry point and the access token configuration |
| `Views/` | `ContentView`, the call screen |
| `Extensions/` | Keyboard and view helpers |
| `Resources/` | Assets, logo and ringtone |

## Change history

- 12-22-2022 - redesigned for the current Twilio code base
- 01-07-2023 - added TwilioSwiftUiQuickstart project with SwiftUI implementation
- 01-09-2023 - created SPM package twilio-voice-ios-adapter
- 10-20-2026 - renamed TwilioSwiftUiQuickstart to TwilioQuickstart, removed the UIKit example and the empty test targets, token server parameters are now passed to the adapter via `TwilioAccessTokenConfiguration`, iOS 18.6+

## License

See [LICENSE](../LICENSE).
