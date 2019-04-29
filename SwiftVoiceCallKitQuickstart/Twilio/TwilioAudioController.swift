//
//  TwilioAudioController.swift
//  TwilioCallKitQuickstart
//

import Foundation
import TwilioVoice
import AVFoundation
import RxSwift

class TwilioAudioController: NSObject {
    
    var providerDelegate: CallKitProviderDelegate! {
        didSet {
            providerDelegate.state.subscribe() { value in
                if let state = value.element {
                    switch state {
                    case .reset:
                        TwilioVoice.isAudioEnabled = true
                    case .activateSession:
                        TwilioVoice.isAudioEnabled = true
                    case .deactivateSession:
                        TwilioVoice.isAudioEnabled = false
                    case .startTwilioCall:
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
    private let disposeBag = DisposeBag()
}
