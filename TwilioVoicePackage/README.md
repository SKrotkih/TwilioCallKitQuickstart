# TwilioVoicePackage

Refactoring of the actual original project [SwiftVoiceQuickstart](https://github.com/twilio/voice-quickstart-swift).

## Requirements

- Xcode 13+
- Swift 5

## Package Dependencies

Twilio Voice is now distributed via Swift Package Manager, 
so add the https://github.com/twilio/twilio-voice-ios repository as an external Swift Package to your project (read [here]((https://github.com/twilio/voice-quickstart-swift))).

## Get started with TwilioVoicePackage 

First of all you should implement TwilioAccessTokenFetcher class in this package or use your own in your app

## Use case

import TwilioVoicePackage

let viewModel = ViewModel()

and then update your UI with listening of the viewModel's publishers. See examples TwilioSwiftUiQuickstart and TwilioUiKitQuickstart 

## Changes history:

- 01-10-2023 - created the package 
