//
//  AudioWorker.swift
//  TwilioVoiceQuickstart
//
//  Created by Sergey Krotkih on 09.07.2021.
//

import Foundation
import TwilioVoice

class AudioWorker {
    private let audioDevice: DefaultAudioDevice!

    init(audioDevice: DefaultAudioDevice = DefaultAudioDevice()) {
        self.audioDevice = audioDevice
        /*
         * The important thing to remember when providing a TVOAudioDevice is that the device must be set
         * before performing any other actions with the SDK (such as connecting a Call, or accepting an incoming Call).
         * In this case we've already initialized our own `TVODefaultAudioDevice` instance which we will now set.
         */
        TwilioVoiceSDK.audioDevice = audioDevice
    }

    func toggleAudioRoute(toSpeaker: Bool) {
        // The mode set by the Voice SDK is "VoiceChat" so the default audio route is the built-in receiver. Use port override to switch the route.
        audioDevice.block = {
            DefaultAudioDevice.DefaultAVAudioSessionConfigurationBlock()
            
            do {
                try AVAudioSession.sharedInstance().overrideOutputAudioPort(toSpeaker ? .speaker : .none)
            } catch {
                NSLog(error.localizedDescription)
            }
        }
        audioDevice.block()
    }
    
    func enableAudio() {
        audioDevice.isEnabled = true
    }

    func disableAudio() {
        audioDevice.isEnabled = true
    }
}
