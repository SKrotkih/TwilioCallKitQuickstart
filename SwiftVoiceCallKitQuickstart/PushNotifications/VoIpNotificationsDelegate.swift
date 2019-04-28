//
//  VoIpNotificationsDelegate.swift
//  TwilioCallKitQuickstart
//

import Foundation
import PushKit
import RxSwift

// MARK: PKPushRegistryDelegate

enum VoIpNitifications {
    case deviceTokenUpdated(String)
    case deviceTokenInvalidated(String)
    case incomingCallReceived([AnyHashable: Any])
}

class VoIpNotificationsDelegate: NSObject, PKPushRegistryDelegate {

    public let voIpNotifications = PublishSubject<VoIpNitifications>()
    
    private var incomingPushCompletionCallback: (()->Swift.Void?)? = nil
    private var deviceToken: String?
    
    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        print("\(#function)")
        if (type != .voIP) {
            return
        }
        let deviceToken = (credentials.token as NSData).description
        self.deviceToken = deviceToken
        self.voIpNotifications.onNext(.deviceTokenUpdated(deviceToken))
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        print("\(#function)")
        if (type != .voIP) {
            return
        }
        guard let deviceToken = self.deviceToken else {
            return
        }
        self.voIpNotifications.onNext(.deviceTokenInvalidated(deviceToken))
        self.deviceToken = nil
    }
    
    /**
     * Try using the `pushRegistry:didReceiveIncomingPushWithPayload:forType:withCompletionHandler:` method if
     * your application is targeting iOS 11. According to the docs, this delegate method is deprecated by Apple.
     */
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType) {
        print("\(#function)")
        if (type != .voIP) {
            return
        }
        self.voIpNotifications.onNext(.incomingCallReceived(payload.dictionaryPayload))
    }
    
    /**
     * This delegate method is available on iOS 11 and above. Call the completion handler once the
     * notification payload is passed to the `TwilioVoice.handleNotification()` method.
     */
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        print("\(#function)")
        if (type != .voIP) {
            return
        }
        // Save for later when the notification is properly handled.
        self.incomingPushCompletionCallback = completion
        self.voIpNotifications.onNext(.incomingCallReceived(payload.dictionaryPayload))
    }
    
    func incomingPushHandled() {
        if let completion = self.incomingPushCompletionCallback {
            completion()
            self.incomingPushCompletionCallback = nil
        }
    }
}
