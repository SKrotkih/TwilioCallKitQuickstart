//
//  VoIpNotificationsCenter.swift
//  TwilioCallKitQuickstart
//
import Foundation
import PushKit

class VoIpNotificationsCenter: NSObject {
    private var voipRegistry: PKPushRegistry

    init(notificationsDelegate: VoIpNotificationsDelegate) {
        /*
          * Your app must initialize PKPushRegistry with PushKit push type
         VoIP at the launch time. As mentioned in the
         [PushKit guidelines](https://developer.apple.com/documentation/pushkit/supporting_pushkit_notifications_in_your_app),
         * the system can't deliver push notifications to your app until you create
         a PKPushRegistry object for
         * VoIP push type and set the delegate. If your app delays the initialization
         of PKPushRegistry, your app may receive outdated
         * PushKit push notifications, and if your app decides not to report
         the received outdated push notifications to CallKit, iOS may
         * terminate your app.
        */
        self.voipRegistry = PKPushRegistry.init(queue: DispatchQueue.main)
        self.voipRegistry.desiredPushTypes = Set([.voIP])
        self.voipRegistry.delegate = notificationsDelegate
    }
}
