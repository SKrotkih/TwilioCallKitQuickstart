//
//  ViewModel.swift
//  TwilioCallKitQuickstart
//

import Foundation
import RxSwift
import AVFoundation

class ViewModel: NSObject {

    var twilioInteractor: TwilioInteractor!
    public let state = PublishSubject<PhoneCallState>()
    
    private let disposeBag = DisposeBag()
    
    override init() {
        super.init()
        self.startListeners()
    }
    
    private func startListeners() {
        twilioInteractor.state.bind(to: self.state).disposed(by: disposeBag)
    }
    
    func switchSpeaker(on isOn: Bool) {
        toggleAudioRoute(toSpeaker: isOn)
    }
    
    func muteSwith(on isOn: Bool) {
        twilioInteractor.muteSwitchToggled(on: isOn)
    }
    
    func makeCall(to handle: String?, phoneNumber: String?) {
        guard let handle = handle, let phoneNumber = phoneNumber else {
            return
        }
        twilioInteractor.outgoingPhoneNumber = phoneNumber
        // 'To' uses for CallKit to show on screen
        twilioInteractor.placeCall(to: handle)
    }
}

// MARK: - AVAudioSession

extension ViewModel {
    
    func toggleAudioRoute(toSpeaker: Bool) {
        // The mode set by the Voice SDK is "VoiceChat" so the default audio
        // route is the built-in receiver. Use port override to switch the route.
        do {
            if (toSpeaker) {
                try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
            } else {
                try AVAudioSession.sharedInstance().overrideOutputAudioPort(.none)
            }
        } catch {
            NSLog(error.localizedDescription)
        }
    }
}
