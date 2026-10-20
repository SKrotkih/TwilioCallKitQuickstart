<img alt="Twilio logo" align="right" src="/TwilioQuickstart/Resources/TwilioLogo.png">

# Twilio Voice Quickstart

Twilio Voice Quickstart is a refactored codebase from the [Twilio Voice Quickstart for iOS](https://github.com/twilio/voice-quickstart-swift) project.

## Requirements

- Xcode 16+ (iOS 18.6 or later)
- Swift 5

## Installation
Download or clone the repository.
Open *TwilioQuickstart.xcodeproj* in Xcode.

The project uses [twilio-voice-ios-adapter](https://github.com/SKrotkih/twilio-voice-ios-adapter) - an SPM package with the refactored Twilio Voice Quickstart for iOS project.

To start using this code you should get an access token. Implement *TwilioAccessTokenFetcher* in twilio-voice-ios-adapter for that.

Read the [twilio-voice-ios-adapter README](https://github.com/SKrotkih/twilio-voice-ios-adapter#readme).

Study the original description of [Twilio Voice Quickstart for iOS](https://github.com/twilio/voice-quickstart-swift).

## Combine, SwiftUI, Concurrency

The project uses [SwiftUI](https://developer.apple.com/documentation/SwiftUI), [Combine](https://developer.apple.com/documentation/Combine) and [Concurrency Swift](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html).  

## The Redux pattern

The app uses the **Redux** pattern.

## Change history

- 12-22-2022 - redesigned for the current Twilio code base 
- 01-07-2023 - added TwilioSwiftUiQuickstart project with SwiftUI implementation  
- 01-09-2023 - created SPM package twilio-voice-ios-adapter
- 10-20-2026 - renamed TwilioSwiftUiQuickstart to TwilioQuickstart
