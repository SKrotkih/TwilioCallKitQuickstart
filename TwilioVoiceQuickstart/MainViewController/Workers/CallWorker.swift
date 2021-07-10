//
//  CallWorker.swift
//  TwilioVoiceQuickstart
//
//  Created by Sergey Krotkih on 09.07.2021.
//

import UIKit
import TwilioVoice
import CallKit

protocol CallPresentable {
    func setCallButtonTitle(_ title: String)
    func startActivity()
    func stopActivity()
    func toggleUIState(isEnabled: Bool, showCallControl: Bool)
    func qualityWarningsUpdatePopup(_ warnings: Set<NSNumber>, isCleared: Bool)
}

class CallWorker: NSObject, CallDelegate {

    // MARK: - Public (TODO: inject from the viewmodel)
    var callKitProvider: CXProvider?
    var callKitCompletionCallback: ((Bool) -> Void)? = nil
    var userInitiatedDisconnect: Bool = false
    var callKitWorker: CallKitWorker!
    var audioManager: AudioWorker!
    var presenter: CallPresentable!
    
    // MARK: - Private
    private let ringtoneManager = RingtoneWorker()
    
    func callDidStartRinging(call: Call) {
        NSLog("callDidStartRinging:")
        
        presenter.setCallButtonTitle("Ringing")
        
        ringtoneManager.playRingback()
    }
    
    func callDidConnect(call: Call) {
        NSLog("callDidConnect:")
        
        ringtoneManager.stopRingback()

        if let callKitCompletionCallback = callKitCompletionCallback {
            callKitCompletionCallback(true)
        }
        
        presenter.setCallButtonTitle("Hang Up")
        
        presenter.toggleUIState(isEnabled: true, showCallControl: true)
        presenter.stopActivity()
        audioManager.toggleAudioRoute(toSpeaker: true)
    }
    
    func call(call: Call, isReconnectingWithError error: Error) {
        NSLog("call:isReconnectingWithError:")
        
        presenter.setCallButtonTitle("Reconnecting")
        
        presenter.toggleUIState(isEnabled: false, showCallControl: false)
    }
    
    func callDidReconnect(call: Call) {
        NSLog("callDidReconnect:")
        
        presenter.setCallButtonTitle("Hang Up")
        presenter.toggleUIState(isEnabled: true, showCallControl: true)
    }
    
    func callDidFailToConnect(call: Call, error: Error) {
        NSLog("Call failed to connect: \(error.localizedDescription)")
        
        if let completion = callKitCompletionCallback {
            completion(false)
        }
        
        if let provider = callKitProvider {
            provider.reportCall(with: call.uuid!, endedAt: Date(), reason: CXCallEndedReason.failed)
        }

        callDisconnected(call: call)
    }
    
    func callDidDisconnect(call: Call, error: Error?) {
        if let error = error {
            NSLog("Call failed: \(error.localizedDescription)")
        } else {
            NSLog("Call disconnected")
        }
        
        if !userInitiatedDisconnect {
            var reason = CXCallEndedReason.remoteEnded
            
            if error != nil {
                reason = .failed
            }
            
            if let provider = callKitProvider {
                provider.reportCall(with: call.uuid!, endedAt: Date(), reason: reason)
            }
        }

        callDisconnected(call: call)
    }
    
    func callDisconnected(call: Call) {
        if call == callKitWorker.activeCall {
            callKitWorker.activeCall = nil
        }
        
        callKitWorker.activeCalls.removeValue(forKey: call.uuid!.uuidString)
        
        userInitiatedDisconnect = false
        
        ringtoneManager.stopRingback()
        
        presenter.stopActivity()
        presenter.toggleUIState(isEnabled: true, showCallControl: false)
        presenter.setCallButtonTitle("Call")
    }
    
    func call(call: Call, didReceiveQualityWarnings currentWarnings: Set<NSNumber>, previousWarnings: Set<NSNumber>) {
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
            presenter.qualityWarningsUpdatePopup(newWarnings, isCleared: false)
        }
        
        var clearedWarnings: Set<NSNumber> = previousWarnings
        clearedWarnings.subtract(warningsIntersection)
        if clearedWarnings.count > 0 {
            presenter.qualityWarningsUpdatePopup(clearedWarnings, isCleared: true)
        }
    }
}
