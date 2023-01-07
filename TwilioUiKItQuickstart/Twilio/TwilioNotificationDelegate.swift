//
//  TwilioNotificationDelegate.swift
//  TwilioCallKitQuickstart
//
import Foundation
import TwilioVoice

enum TwilioNotifications {
    case pending(CallInvite)
    case canceled(CallInvite)
    case error(Error)
}

/**
 Twilio NotificationDelegate
 @param
 @return
 */
class TwilioNotificationDelegate: NSObject, NotificationDelegate {
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
        store.stateDispatch(action: .reportIncomingCall(from, callInvite.uuid))
        store.stateDispatch(action: .useActiveCallInvite(callInvite))
    }

    func cancelledCallInviteReceived(cancelledCallInvite: CancelledCallInvite, error: Error) {
        store.stateDispatch(action: .cancelledCallInviteReceived(cancelledCallInvite, error))
    }
}
