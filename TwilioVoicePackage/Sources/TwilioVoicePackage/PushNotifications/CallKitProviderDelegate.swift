//
//  CallKitProviderDelegate.swift
//  TwilioVoicePackage
//
import Foundation
import TwilioVoice
import CallKit
import Combine

let twimlParamTo = "to"

/// CallKit framework CXProviderDelegate implementation
class CallKitProviderDelegate: NSObject, CXProviderDelegate {
    private let sharedData: SharedData

    var activeCallInvites: [String: CallInvite]! = [:]
    var activeCalls: [String: Call]! = [:]
    // activeCall represents the last connected call
    var activeCall: Call?
    let callKitCallController = CXCallController()

    init(sharedData: SharedData) {
        self.sharedData = sharedData
    }

    var audioDevice = DefaultAudioDevice()

    func providerDidReset(_ provider: CXProvider) {
        print("\(#function)")
        audioDevice.isEnabled = false
        store.stateDispatch(action: .callKit(.reset))
    }

    func providerDidBegin(_ provider: CXProvider) {
        print("\(#function)")
        store.stateDispatch(action: .callKit(.begin))
    }

    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        print("\(#function)")
        audioDevice.isEnabled = true
        store.stateDispatch(action: .callKit(.activateSession))
    }

    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        print("\(#function)")
        audioDevice.isEnabled = false
        store.stateDispatch(action: .callKit(.deactivateSession))
    }

    func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {
        print("\(#function)")
        store.stateDispatch(action: .callKit(.timeout))
    }

    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        print("\(#function)")
        store.stateDispatch(action: .callKit(.startTwilioCall))

        provider.reportOutgoingCall(with: action.callUUID, startedConnectingAt: Date())

        store.stateDispatch(action: .performVoiceCall(action.callUUID, "", sharedData.outgoingValue) { success in
            if success {
                NSLog("performVoiceCall() successful")
                provider.reportOutgoingCall(with: action.callUUID, connectedAt: Date())
            } else {
                NSLog("performVoiceCall() failed")
            }
        })

        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        print("\(#function)")

        store.stateDispatch(action: .performAnswerVoiceCall(action.callUUID) { success in
            if success {
                NSLog("performAnswerVoiceCall() successful")
            } else {
                NSLog("performAnswerVoiceCall() failed")
            }
        })
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        print("\(#function)")

        if let invite = activeCallInvites[action.callUUID.uuidString] {
            invite.reject()
            activeCallInvites.removeValue(forKey: action.callUUID.uuidString)
        } else if let call = activeCalls[action.callUUID.uuidString] {
            call.disconnect()
        } else {
            NSLog("Unknown UUID to perform end-call action with")
        }
        store.stateDispatch(action: .callKit(.endTwilioCall))
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        print("\(#function)")

        if let call = activeCalls[action.callUUID.uuidString] {
            call.isOnHold = action.isOnHold
            action.fulfill()
        } else {
            action.fail()
        }
    }

    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        print("\(#function)")

        if let call = activeCalls[action.callUUID.uuidString] {
            call.isMuted = action.isMuted
            action.fulfill()
        } else {
            action.fail()
        }
    }
}
