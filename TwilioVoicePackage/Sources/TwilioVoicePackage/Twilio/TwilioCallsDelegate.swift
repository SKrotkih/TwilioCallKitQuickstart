//
//  TwilioCallsDelegate.swift
//  TwilioVoicePackage
//
import Foundation
import TwilioVoice
import Combine
/**
 CallDelegate - Twilio lifecycle events listener
 @param
 @return
 */
class TwilioCallsDelegate: NSObject, CallDelegate {
    var callKitCompletionCallback: ((Bool) -> Void)?
    private let sharedData: SharedData

    init(sharedData: SharedData) {
        self.sharedData = sharedData
    }

    func callDidStartRinging(call: Call) {
        print("\(#function)")
        store.stateDispatch(action: .twilio(.callDidStartRinging))
    }

    func callDidConnect(call: Call) {
        print("\(#function)")
        store.stateDispatch(action: .twilio(.callDidStopRinging))
        if let completion = callKitCompletionCallback {
            completion(true)
        }

        store.stateDispatch(action: .twilio(.callDidConnect))
    }

    func call(call: Call, isReconnectingWithError error: Error) {
        print("\(#function)")
        store.stateDispatch(action: .twilio(.isReconnectingWithError(error)))
    }

    func callDidReconnect(call: Call) {
        print("\(#function)")
        store.stateDispatch(action: .twilio(.callDidReconnect))
    }

    func callDidFailToConnect(call: Call, error: Error) {
        NSLog("Call failed to connect: \(error.localizedDescription)")

        store.stateDispatch(action: .twilio(.callDidFailToConnect))

        if let completion = callKitCompletionCallback {
            completion(false)
        }

        store.stateDispatch(action: .callDidFailToConnect(call, error))

        callDisconnected(call: call)
    }

    func callDidDisconnect(call: Call, error: Error?) {
        if let error = error {
            NSLog("Call failed: \(error.localizedDescription)")
        } else {
            NSLog("Call disconnected")
        }

        store.stateDispatch(action: .twilio(.callDidDisconnect(error)))

        if sharedData.userInitiatedDisconnect {
            store.stateDispatch(action: .callDidDisconnect(call, error))
        }

        callDisconnected(call: call)
    }

    func callDisconnected(call: Call) {
        store.stateDispatch(action: .twilio(.callDisconnected))
        store.stateDispatch(action: .callDisconnected(call))
        store.stateDispatch(action: .twilio(.callDidStopRinging))
    }

    func callDidReceiveQualityWarnings(call: Call, currentWarnings: Set<NSNumber>, previousWarnings: Set<NSNumber>) {
        /**
        * currentWarnings: existing quality warnings that have not been cleared yet
        * previousWarnings: last set of warnings prior to receiving this callback
        *
        * Example:
        *   - currentWarnings: { A, B }
        *   - previousWarnings: { B, C }
        *   - intersection: { B }
        *
        * Newly raised warnings = currentWarnings - intersection = { A }
        * Newly cleared warnings = previousWarnings - intersection = { C }
        */
        var warningsIntersection: Set<NSNumber> = currentWarnings
        warningsIntersection = warningsIntersection.intersection(previousWarnings)

        var newWarnings: Set<NSNumber> = currentWarnings
        newWarnings.subtract(warningsIntersection)
        if newWarnings.count > 0 {
            store.stateDispatch(action: .twilio(.callDidReceiveQualityWarnings(newWarnings, false)))
        }

        var clearedWarnings: Set<NSNumber> = previousWarnings
        clearedWarnings.subtract(warningsIntersection)
        if clearedWarnings.count > 0 {
            store.stateDispatch(action: .twilio(.callDidReceiveQualityWarnings(clearedWarnings, true)))
        }
    }
}
