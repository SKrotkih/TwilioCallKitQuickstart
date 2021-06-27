//
//  TwilioCallsDelegate.swift
//  TwilioCallKitQuickstart
//

import Foundation
import TwilioVoice
import RxSwift

// MARK: - TVOCallDelegate - Twilio lifecycle events listener

enum TwilioCallLifeCycle {
    case startTVOCall(TVOCall)
    case finishTVOCall(TVOCall, Error?)
    case failToConnevtTVOCall(TVOCall, Error)
}

class TwilioCallsDelegate: NSObject, TVOCallDelegate {
    
    var state = PublishSubject<TwilioCallLifeCycle>()
    
    func callDidConnect(_ call: TVOCall) {
        print("\(#function)")
        state.onNext(.startTVOCall(call))
    }
    
    func call(_ call: TVOCall, didFailToConnectWithError error: Error) {
        print("\(#function): \(error.localizedDescription)")
        state.onNext(.failToConnevtTVOCall(call, error))
    }
    
    func call(_ call: TVOCall, didDisconnectWithError error: Error?) {
        print("\(#function): \(error?.localizedDescription ?? "Call disconnected")")
        state.onNext(.finishTVOCall(call, error))
    }
}
