<img alt="Twilio logo" align="right" src="/TwilioSwiftUiQuickstart/Resources/TwilioLogo.png">

# Twilio Voice Quickstart for iOS

Here you can find a refactored code from [Twilio Voice Quickstart for iOS](https://github.com/twilio/voice-quickstart-swift) project.

## Requirements

- Xcode 13+
- Swift 5

## Introduction

## Instalation
Download or clone the repository.
Open *TwilioQuickstart.xcworkspace* in Xcode.
There are two projects:
- **TwilioUiKitQuickstart** - main view controller implemented with UIKit (storyboard)
- **TwilioSwiftUiQuickstart** - same functionality as previous one but content view of main view controller implemented with SwiftUI
And project with Swift package:
- [TwilioVoicePackage](https://github.com/SKrotkih/TwilioCallKitQuickstart/tree/master/TwilioVoicePackage) - local SPM package with refactored Twilio Voice Quickstart for iOS project. 
The package is used by TwilioUiKitQuickstart (UIKit). Other hand TwilioSwiftUiQuickstart (SwiftUI) project uses [TwilioVoiceAdapter](https://github.com/SKrotkih/twilio-voice-ios-adapter). 
- [TwilioVoiceAdapter](https://github.com/SKrotkih/twilio-voice-ios-adapter) - remote SPM package. The same as local package TwilioVoicePackage codebase.  

To start using this code you should get an access token. Implement *TwilioAccessTokenFetcher* in TwilioVoicePackage for that.
Read [README.md](https://github.com/SKrotkih/TwilioCallKitQuickstart/tree/master/TwilioVoicePackage) from TwilioVoicePackage. 
Study original description [Twilio Voice Quickstart for iOS](https://github.com/twilio/voice-quickstart-swift).

## Combine, SwiftUI, Concurrency

In the project developemnt were used [SwiftUI](https://developer.apple.com/documentation/SwiftUI), [Combine](https://developer.apple.com/documentation/Combine) and [Concurrency Swift](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html).  

## The Redux pattern

The app uses **Redux** pattern.

## Changes history:

- 12-22-2022 - redesigned for the current Twilio code base 
- 01-07-2023 - added TwilioSwiftUiQuickstart project with SwiftUI implementation  
- 01-09-2023 - created TwilioVoicePackage. Extracted and connected to the TwilioUiKitQuickstart project
