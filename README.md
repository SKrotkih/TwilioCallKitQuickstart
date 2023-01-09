# Twilio Voice Quickstart for iOS

Here is refactoring of the [Twilio Voice Quickstart for iOS](https://github.com/twilio/voice-quickstart-swift) project.

## Requirements

- Xcode 13+
- Swift 5

## Introduction

Download or clone the repository
Open TwilioQuickstart.xcworkspace in Xcode
There are two projects:
- TwilioUiKitQuickstart - main view controller implemented with UIKit (storyboard)
- TwilioSwiftUiQuickstart - content view of main view controller implemented with SwiftUI
- [TwilioVoicePackage](https://github.com/SKrotkih/TwilioCallKitQuickstart/tree/master/TwilioVoicePackage) - local swift package (SPM) with refactored Twilio Voice Quickstart for iOS. 
It is used by TwilioUiKitQuickstart (UIKit) and TwilioSwiftUiQuickstart (SwiftUI) projects. 

To start using this code you should get an access token. Implement TwilioAccessTokenFetcher in the TwilioVoicePackage for that.
Study [README.md](https://github.com/SKrotkih/TwilioCallKitQuickstart/tree/master/TwilioVoicePackage) file from the Swift package TwilioVoicePackage and original [Twilio Voice Quickstart for iOS](https://github.com/twilio/voice-quickstart-swift) description

## Combine, SwiftUI, Concurrency

Were used [SwiftUI](https://developer.apple.com/documentation/SwiftUI), [Combine](https://developer.apple.com/documentation/Combine) frameworks and newest [Concurrency Swift](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html) approach.  

## The Redux pattern

The app uses Redux pattern.

## Changes history:

- 12-22-2022 - redesigned for the current Twilio code base 
- 01-07-2023 - added TwilioSwiftUiQuickstart project with SwiftUI implementation  
- 01-09-2023 - created TwilioVoicePackage. Extracted and connected to the TwilioUiKitQuickstart project
