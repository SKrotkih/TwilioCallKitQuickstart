//
//  CallKitProviderDelegate.swift
//  TwilioCallKitQuickstart
//

import Foundation
import CallKit
import AVFoundation
import RxSwift

class CallKitProviderDelegate: NSObject, CXProviderDelegate {
    
    public let state = PublishSubject<PhoneCallState>()
    
    func providerDidReset(_ provider: CXProvider) {
        print("\(#function)")
        state.onNext(.reset)
    }
    
    func providerDidBegin(_ provider: CXProvider) {
        print("\(#function)")
        state.onNext(.begin)
    }
    
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        print("\(#function) AVAudioSession")
        state.onNext(.activateSession)
    }
    
    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        print("\(#function) AVAudioSession")
        state.onNext(.deactivateSession)
    }
    
    func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {
        print("\(#function)")
        state.onNext(.timeout)
    }
    
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        print("\(#function) CXStartCallAction")
        state.onNext(.startTwilioCall)
        let uuid = action.callUUID
        provider.reportOutgoingCall(with: uuid, startedConnectingAt: Date())
        let completionHandler: (Bool) -> Void = { (success) in
            if (success) {
                provider.reportOutgoingCall(with: uuid, connectedAt: Date())
                action.fulfill()
            } else {
                action.fail()
            }
        }
        state.onNext(.outboundCall(uuid, completionHandler))
    }
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        print("\(#function) CXAnswerCallAction")
        let uuid = action.callUUID
        let completionHandler: (Bool) -> Void = { (success) in
            if (success) {
                action.fulfill()
            } else {
                action.fail()
            }
        }
        state.onNext(.answerCall(uuid, completionHandler))
        
        // RCP: Workaround from https://forums.developer.apple.com/message/169511 suggests configuring audio in the
        //      completion block of the `reportNewIncomingCallWithUUID:update:completion:` method instead of in
        //      `provider:performAnswerCallAction:` per the WWDC examples.
        // TwilioVoice.configureAudioSession()

        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        print("\(#function) CXEndCallAction")
        state.onNext(.endTwilioCall)
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        print("\(#function) CXSetHeldCallAction")
        let completionHandler: (Bool) -> Void = { success in
            if success {
                action.fulfill()
            } else {
                action.fail()
            }
        }
        state.onNext(.heldCall(action.isOnHold, completionHandler))
    }
}
