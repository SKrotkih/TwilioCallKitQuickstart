//
//  CallNotificationsHandler.swift
//  TwilioVoiceQuickstart
//
//  Created by Sergey Krotkih on 09.07.2021.
//

import Foundation
import TwilioVoice
import CallKit

class CallNotificationsHandler: NSObject, NotificationDelegate {
    
    // MARK: - Public
    // TODO: Injection Dependency for two vars:
    var callKitWorker: CallKitWorker!
    var callInviteStorage: CallKitCallsInviteble!
    
    func callInviteReceived(callInvite: CallInvite) {
        NSLog("callInviteReceived:")
        
        /**
         * The TTL of a registration is 1 year. The TTL for registration for this device/identity
         * pair is reset to 1 year whenever a new registration occurs or a push notification is
         * sent to this device/identity pair.
         */
        UserDefaults.standard.set(Date(), forKey: kCachedBindingDate)
        
        let callerInfo: TVOCallerInfo = callInvite.callerInfo
        if let verified: NSNumber = callerInfo.verified {
            if verified.boolValue {
                NSLog("Call invite received from verified caller number!")
            }
        }
        
        let from = (callInvite.from ?? "Voice Bot").replacingOccurrences(of: "client:", with: "")

        // Always report to CallKit
        callKitWorker.reportIncomingCall(from: from, uuid: callInvite.uuid)
        callInviteStorage.callInviteReceived(callInvite: callInvite)
    }
    
    func cancelledCallInviteReceived(cancelledCallInvite: CancelledCallInvite, error: Error) {
        NSLog("cancelledCallInviteCanceled:error:, error: \(error.localizedDescription)")

        if let callInvite = callInviteStorage.getCallInvite(callSid: cancelledCallInvite.callSid) {
            callKitWorker.performEndCallAction(uuid: callInvite.uuid)
            callInviteStorage.callInviteCancelled(callInvite: callInvite)
        }
    }
}
