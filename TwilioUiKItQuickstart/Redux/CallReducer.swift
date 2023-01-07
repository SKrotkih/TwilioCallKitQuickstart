//
//  AuthReducer.swift
//  Twilio Voice Quickstart - Swift
//
import Foundation
///
/// Reducer: A Reducer is a function that takes the current state from the store, and the action.
/// It combines the action and current state together and returns the new state
///
func callReducer(state: CallState,
                 action: CallAction,
                 environment: NetworkService) async throws -> CallState {
    let newState = await Task {
        let state = {
            switch action {
            case .twilio(let callState):
                return CallState(twilio: callState)
            case .callKit(let callState):
                return CallState(callKit: callState)
            case .performVoiceCall(let uuid, let client, let twimlParamTo, let completion):
                environment.callKitActions.performVoiceCall(uuid: uuid,
                                                            client: client,
                                                            to: twimlParamTo,
                                                            completionHandler: completion)
                return CallState(callState: .performVoiceCall)
            case .performAnswerVoiceCall(let uuid, let completion):
                environment.callKitActions.performAnswerVoiceCall(uuid: uuid, completionHandler: completion)
                return CallState(callState: .performAnswerVoiceCall)
            case .performStartCallAction(let uuid, let handle):
                environment.callKitActions.performStartCallAction(uuid: uuid, handle: handle)
                return CallState(callState: .performStartCallAction)
            case .setUpMuteForActiveCall(let muted):
                environment.callKitActions.setUpMuteForActiveCall(muted)
                return CallState(callState: .setUpMuteForActiveCall)
            case .performEndCallAction:
                environment.callKitActions.performEndCallAction()
                return CallState(callState: .performEndCallAction)
            case .reportIncomingCall(let from, let uuid):
                environment.callKitActions.reportIncomingCall(from: from, uuid: uuid)
                return CallState(callState: .reportIncomingCall)
            case .useActiveCallInvite(let callInvite):
                environment.callKitActions.useActiveCallInvite(callInvite)
                return CallState(callState: .useActiveCallInvite)
            case .cancelledCallInviteReceived(let cancelledCallInvite, let error):
                environment.callKitActions.cancelledCallInviteReceived(
                    cancelledCallInvite: cancelledCallInvite, error: error)
                return CallState(callState: .cancelledCallInviteReceived)
            case .callDidFailToConnect(let call, let error):
                environment.callKitActions.callDidFailToConnect(call: call, error: error)
                return CallState(callState: .callDidFailToConnect)
            case .callDidDisconnect(let call, let error):
                environment.callKitActions.callDidDisconnect(call: call, error: error)
                return CallState(callState: .callDidDisconnect)
            case .callDisconnected(let call):
                environment.callKitActions.callDisconnected(call: call)
                return CallState(callState: .callDisconnected)
            case .isCallInActiveState(let completionHandler):
                environment.callKitActions.isCallInActiveState(completionHandler: completionHandler)
                return CallState(callState: .isCallInActiveState)
            }
        }()
        return state
    }.value

    return newState
}
