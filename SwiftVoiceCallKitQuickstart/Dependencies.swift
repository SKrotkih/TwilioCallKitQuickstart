//
//  Dependencies.swift
//  TwilioCallKitQuickstart
//
import Foundation
///
/// Dependency Injection
///
struct Dependencies {
    mutating func configure(for viewController: ViewController) {
        viewController.viewModel = TwilioInteractor()
        viewController.microphoneManager = MicrophoneManager()
        viewController.ringtoneManager = RingtoneManager()
        viewController.sharedData = ReduxStore.shared.environment.sharedData
    }
}
