//
//  CallState.swift
//  TwilioVoicePackage
//
import Foundation

enum CallKitCallState {
    case undefined
    case begin
    case reset
    case timeout
    case activateSession
    case deactivateSession
    case startTwilioCall
    case endTwilioCall
    case answerCall(UUID, (Bool) -> Void)
    case heldCall(Bool, (Bool) -> Void)
}

enum CallKitActionsState {
    case undefined
    case performVoiceCall
    case performAnswerVoiceCall
    case performStartCallAction
    case setUpMuteForActiveCall
    case performEndCallAction
    case reportIncomingCall
    case useActiveCallInvite
    case cancelledCallInviteReceived
    case callDidFailToConnect
    case callDidDisconnect
    case callDisconnected
    case isCallInActiveState
}

enum TwilioCallState {
    case undefined
    case callDidStartRinging
    case callDidStopRinging
    case callDidConnect
    case isReconnectingWithError(Error)
    case callDidReconnect
    case callDidFailToConnect
    case callDidDisconnect(Error?)
    case callDisconnected
    case callDidReceiveQualityWarnings(Set<NSNumber>, Bool)
}
///
/// State: Based on your state you render your UI or respond in any form.
/// So basically state refers to the source of truth.
///
actor CallState: Equatable {
    var callKit: CallKitCallState = .undefined
    var twilio: TwilioCallState = .undefined
    var callState: CallKitActionsState = .undefined
    var error: CallError?

    init(callKit: CallKitCallState = .undefined,
         twilio: TwilioCallState = .undefined,
         callState: CallKitActionsState = .undefined) {
        self.callKit = callKit
        self.twilio = twilio
        self.callState = callState
    }

    init(callKit: CallKitCallState) {
        self.callKit = callKit
        self.twilio = .undefined
        self.callState = .undefined
    }

    init(twilio: TwilioCallState) {
        self.twilio = twilio
        self.callKit = .undefined
        self.callState = .undefined
    }

    init(callState: CallKitActionsState) {
        self.callState = callState
        self.callKit = .undefined
        self.twilio = .undefined
    }

    func setUpError(_ error: CallError?) {
        self.error = error
    }

    static func == (lhs: CallState, rhs: CallState) -> Bool {
        // TODO: Need to research how to implement async equatable protocol
        true
    }
}
