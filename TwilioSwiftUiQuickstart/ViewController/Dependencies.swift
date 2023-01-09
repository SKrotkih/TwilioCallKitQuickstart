//
//  Dependencies.swift
//  TwilioVoiceQuickstart
//
//  Created by Serhii Krotkykh on 12.07.2021.
//

import Foundation
import TwilioVoice

struct ContentDependencies {

    static func configure() -> ContentViewModel {
        let ringbackPlayer = RingtoneWorker(customRingback: "ringtone.wav")
        let callWorker = CallWorker(ringtoneManager: ringbackPlayer)

        let callKitWorker = CallKitWorker(callDelegate: callWorker)

        let audioManager = AudioWorker()

        let microphoneManager = MicrophoneManager()
        let viewModel = ContentViewModel(callKitWorker: callKitWorker,
                                         audioManager: audioManager,
                                         microphoneManager: microphoneManager)
        callKitWorker.configure(presenter: viewModel)
        callWorker.configure(presenter: viewModel,
                             callKitDelegate: callKitWorker,
                             callKitCallStorage: callKitWorker,
                             callKitCompletionHandler: callKitWorker)

        return viewModel
    }
}
