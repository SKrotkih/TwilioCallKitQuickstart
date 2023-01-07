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
        let viewModel = TwilioInteractor(sharedData: ReduxStore.shared.environment.sharedData)
        viewController.viewModel = viewModel
        viewController.microphoneManager = MicrophoneManager()
        viewController.ringtoneManager = RingtoneManager()
        viewController.audioDevice = AudioDevice()
    }
}
