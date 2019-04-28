//
//  TwilioAudioController.swift
//  SwiftVoiceCallKitQuickstart
//

import Foundation
import TwilioVoice
import AVFoundation
import RxSwift

class TwilioAudioController: NSObject {
    
    private let providerDelegate: CallKitProviderDelegate
    
    private let disposeBag = DisposeBag()
    
    required init(providerDelegate: CallKitProviderDelegate) {
        self.providerDelegate = providerDelegate
        super.init()
        
        addObservers()
    }

    private func addObservers() {
        providerDelegate.state.subscribe() { value in
            if let state = value.element {
                switch state {
                case .reset:
                    TwilioVoice.isAudioEnabled = true
                case .activateSession:
                    TwilioVoice.isAudioEnabled = true
                case .deactivateSession:
                    TwilioVoice.isAudioEnabled = false
                case .startCall:
                    TwilioVoice.configureAudioSession()
                    TwilioVoice.isAudioEnabled = false
                case .answerCall:
                    TwilioVoice.isAudioEnabled = false
                default:
                    break
                }
            }
        }.disposed(by: disposeBag)
    }
}
