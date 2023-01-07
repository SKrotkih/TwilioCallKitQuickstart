//
//  CallWorker.swift
//  TwilioVoiceQuickstart
//
//  Created by Sergey Krotkih on 09.07.2021.
//

import UIKit
import TwilioVoice
import CallKit

class CallWorker: NSObject, CallDelegate {

    // MARK: - Public (TODO: inject from the viewmodel)
    private weak var presenterDelegate: CallPresentable!
    private var callKitDelegate: CallKitProviderCallable!
    private var callKitCallStorage: CallKitCallsStorageble!
    private var callKitCompletionHandler: CallKitCompletionHandlable!

    var audioManager: AudioWorker!

    // var callKitCompletionCallback: ((Bool) -> Void)? = nil
    var userInitiatedDisconnect: Bool = false
    
    // MARK: - Private
    private let ringtoneManager: RingtoneWorker!
    
    init(ringtoneManager: RingtoneWorker) {
        self.ringtoneManager = ringtoneManager
    }
    
    func configure(presenter: CallPresentable,
                   callKitDelegate: CallKitProviderCallable,
                   callKitCallStorage: CallKitCallsStorageble,
                   callKitCompletionHandler: CallKitCompletionHandlable) {
        self.presenterDelegate = presenter
        self.callKitDelegate = callKitDelegate
        self.callKitCallStorage = callKitCallStorage
        self.callKitCompletionHandler = callKitCompletionHandler
    }
    
    func callDidStartRinging(call: Call) {
        NSLog("callDidStartRinging:")
        
        presenterDelegate.setCallButtonTitle("Ringing")
        
        ringtoneManager.playRingback()
    }
    
    func callDidConnect(call: Call) {
        NSLog("callDidConnect:")
        
        ringtoneManager.stopRingback()

        callKitCompletionHandler.callDidConnect()

        presenterDelegate.setCallButtonTitle("Hang Up")
        
        presenterDelegate.toggleUIState(isEnabled: true, showCallControl: true)
        presenterDelegate.stopActivity()
        audioManager.toggleAudioRoute(toSpeaker: true)
    }
    
    func call(call: Call, isReconnectingWithError error: Error) {
        NSLog("call:isReconnectingWithError:")
        
        presenterDelegate.setCallButtonTitle("Reconnecting")
        
        presenterDelegate.toggleUIState(isEnabled: false, showCallControl: false)
    }
    
    func callDidReconnect(call: Call) {
        NSLog("callDidReconnect:")
        
        presenterDelegate.setCallButtonTitle("Hang Up")
        presenterDelegate.toggleUIState(isEnabled: true, showCallControl: true)
    }
    
    func callDidFailToConnect(call: Call, error: Error) {
        NSLog("Call failed to connect: \(error.localizedDescription)")
        
        callKitCompletionHandler.callDidFailToConnect()

        callKitDelegate.callFailed(call: call)

        callDisconnected(call: call)
    }
    
    func callDidDisconnect(call: Call, error: Error?) {
        if let error = error {
            NSLog("Call failed: \(error.localizedDescription)")
        } else {
            NSLog("Call disconnected")
        }
        
        if !userInitiatedDisconnect {
            let reason: CXCallEndedReason = error != nil ? .failed : .remoteEnded
            callKitDelegate.callDisconnected(call: call,
                                             reason: reason)
        }

        callDisconnected(call: call)
    }
    
    func callDisconnected(call: Call) {
        
        callKitCallStorage.disconnectCall(call: call)

        userInitiatedDisconnect = false
        
        ringtoneManager.stopRingback()
        
        presenterDelegate.stopActivity()
        presenterDelegate.toggleUIState(isEnabled: true, showCallControl: false)
        presenterDelegate.setCallButtonTitle("Call")
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
            presenterDelegate.qualityWarningsUpdatePopup(newWarnings, isCleared: false)
        }
        
        var clearedWarnings: Set<NSNumber> = previousWarnings
        clearedWarnings.subtract(warningsIntersection)
        if clearedWarnings.count > 0 {
            presenterDelegate.qualityWarningsUpdatePopup(clearedWarnings, isCleared: true)
        }
    }
}
