//
//  TwilioInteractor.swift
//  TwilioCallKitQuickstart
//
import Foundation

protocol CallsController {
    func endCall(completion: @escaping (Bool) -> Void)
    func startCall(handle: String)
    func toggleMuteSwitch(to mute: Bool)
}

class TwilioInteractor: CallsController {
    func startCall(handle: String) {
        let uuid = UUID()
        store.stateDispatch(action: .performStartCallAction(uuid, handle))
    }

    func endCall(completion: @escaping (Bool) -> Void) {
        store.stateDispatch(action: .isCallInActiveState { isCallInActiveState in
            if isCallInActiveState {
                store.stateDispatch(action: .performEndCallAction)
                completion(true)
            } else {
                completion(false)
            }
        })
    }

    func toggleMuteSwitch(to mute: Bool) {
        // The sample app supports toggling mute from app UI only on the last connected call.
        store.stateDispatch(action: .setUpMuteForActiveCall(mute))
    }
}
