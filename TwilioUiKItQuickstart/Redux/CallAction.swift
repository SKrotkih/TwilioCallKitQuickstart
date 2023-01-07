//
//  CallAction.swift
//  Twilio Voice Quickstart - Swift
//
import UIKit
import CallKit
import TwilioVoice

///
/// Action: Actions are payloads or simply objects of information,
/// that captures from the application via any kind of events such as
/// touch events, network API responses etc,.
///
enum CallAction {
    case twilio(TwilioCallState)
    case callKit(CallKitCallState)

    case performVoiceCall(UUID, String?, String?, (Bool) -> Void)
    case performAnswerVoiceCall(UUID, completionHandler: (Bool) -> Void)
    case performStartCallAction(UUID, String)
    case setUpMuteForActiveCall(Bool)
    case performEndCallAction
    case reportIncomingCall(String, UUID)
    case useActiveCallInvite(CallInvite)
    case cancelledCallInviteReceived(CancelledCallInvite, Error)
    case callDidFailToConnect(Call, Error)
    case callDidDisconnect(Call, Error?)
    case callDisconnected(Call)
    case isCallInActiveState(completionHandler: (Bool) -> Void)
}
