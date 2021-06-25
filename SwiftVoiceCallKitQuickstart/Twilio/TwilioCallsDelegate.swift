//
//  TwilioCallsDelegate.swift
//  TwilioCallKitQuickstart
//

import Foundation
import TwilioVoice
import RxSwift

// MARK: - CallDelegate - Twilio lifecycle events listener

enum TwilioCallLifeCycle {
    case startCall(Call)
    case finishCall(Call, Error?)
    case failToConnevtCall(Call, Error)
}

class TwilioCallsDelegate: NSObject, CallDelegate {
    
    var state = PublishSubject<TwilioCallLifeCycle>()
    
    func callDidConnect(_ call: Call) {
        print("\(#function)")
        state.onNext(.startCall(call))
    }
    
    func call(_ call: Call, didFailToConnectWithError error: Error) {
        print("\(#function): \(error.localizedDescription)")
        state.onNext(.failToConnevtCall(call, error))
    }
    
    func call(_ call: Call, didDisconnectWithError error: Error?) {
        print("\(#function): \(error?.localizedDescription ?? "Call disconnected")")
        state.onNext(.finishCall(call, error))
    }
}
