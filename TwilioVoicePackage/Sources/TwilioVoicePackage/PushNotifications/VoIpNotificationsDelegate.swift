//
//  VoIpNotificationsDelegate.swift
//  TwilioVoicePackage
//
import Foundation
import PushKit

/**
 PKPushRegistryDelegate
 @param
 @return
 */
class VoIpNotificationsDelegate: NSObject, PKPushRegistryDelegate {
    private weak var pushKitEventDelegate: PushKitEventDelegate?

    init(delegate: PushKitEventDelegate) {
        self.pushKitEventDelegate = delegate
    }

    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        print("\(#function)")

        if let delegate = self.pushKitEventDelegate {
            delegate.credentialsUpdated(credentials: credentials)
        }
    }

    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        print("\(#function)")

        if let delegate = self.pushKitEventDelegate {
            delegate.credentialsInvalidated()
        }
    }

    /**
     * Try using the `pushRegistry:didReceiveIncomingPushWithPayload:forType:withCompletionHandler:` method if
     * your application is targeting iOS 11. According to the docs, this delegate method is deprecated by Apple.
     */
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload,
                      for type: PKPushType) {
        print("\(#function)")

        if let delegate = self.pushKitEventDelegate {
            delegate.incomingPushReceived(payload: payload)
        }
    }

    /**
     * This delegate method is available on iOS 11 and above. Call the completion handler once the
     * notification payload is passed to the `TwilioVoiceSDK.handleNotification()` method.
     */
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload,
                      for type: PKPushType, completion: @escaping () -> Void) {
        print("\(#function)")
        print("Incoming push with payload: \(payload.dictionaryPayload)")

        if let delegate = self.pushKitEventDelegate {
            delegate.incomingPushReceived(payload: payload, completion: completion)
        }
        /**
         * The Voice SDK processes the call notification and returns the call invite synchronously.
         * Report the incoming call to
         * CallKit and fulfill the completion before exiting this callback method.
         */
        completion()
    }
}
