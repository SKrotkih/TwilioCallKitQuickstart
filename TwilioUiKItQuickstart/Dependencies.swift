//
//  Dependencies.swift
//  TwilioCallKitQuickstart
//
import Foundation
import TwilioVoicePackage
///
/// Dependency Injection
///
struct Dependencies {
    mutating func configure(for viewModel: ViewModel) {
        viewModel.microphoneManager = MicrophoneManager()
        viewModel.ringtoneManager = RingtoneManager()
        viewModel.audioDevice = AudioDeviceManager()
    }
}
