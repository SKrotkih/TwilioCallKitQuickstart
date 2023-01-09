# Twilio Voice Quickstart for iOS

Refactoring of the actual original project [SwiftVoiceQuickstart](https://github.com/twilio/voice-quickstart-swift).

## Requirements

- Xcode 13+
- Swift 5

## Introduction

Download or clone the repository
Open TwilioQuickstart.xcworkspace file in root directory
There are two projects:
- TwilioUiKitQuickstart - xcode project where main view controller implemented with UIKit (storyboard)
- TwilioSwiftUiQuickstart - xcode project where content view of main view controller implemented with SwiftUI 
- TwilioVoicePackage - local swift package (SPM) with refactored Twilio Voice Quickstart project codebase. Used by previous (UIKit and SwiftUI) projects. 

To start using this code you should get an access token. Implement TwilioAccessTokenFetcher for that.

Study the original description here: [Twilio Voice Quickstart for iOS](https://github.com/twilio/voice-quickstart-swift) 

## Package Dependencies

Twilio Voice is now distributed via Swift Package Manager, so add the https://github.com/twilio/twilio-voice-ios repository as a Swift Package.

## Combine, SwiftUI

Were used [Combine](https://developer.apple.com/documentation/Combine) framework and newest [Concurrency Swift](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html) approach.  

## The Redux pattern

The app uses Redux pattern.

## Changes history:

- 22-12-2022 - redesigned for the current Twilio code base 
- 07-01-2023 - added TwilioSwiftUiQuickstart project with SwiftUI implementation  
- 09-0102023 - created TwilioVoicePackage. Extracted and connected to the TwilioUiKitQuickstart project
