//
//  Environment.swift
//  TwilioCallKitQuickstart
//
import Foundation

struct NetworkService {
    var callKitActions: PhoneCallable

    init(with callKitActions: PhoneCallable) {
        self.callKitActions = callKitActions
    }
}
//
// Initiate all Twilio and CallKit dependencies
//
class Environment {
    let callKitActions: CallKitActions
    let sharedData: SharedData

    init() {
        sharedData = SharedData()
        let twilioNotificationsDelegate = TwilioNotificationDelegate()
        let callKitProviderDelegate = CallKitProviderDelegate(sharedData: sharedData)
        let pushNotificationsDelegate = PushNotificationsDelegate(
            callKitDelegate: callKitProviderDelegate,
            notificationDelegate: twilioNotificationsDelegate
        )
        let voIpNotificationsDelegate = VoIpNotificationsDelegate(delegate: pushNotificationsDelegate)
        // TODO: Find out where it is used
        let notificationsCenter = VoIpNotificationsCenter(notificationsDelegate: voIpNotificationsDelegate)

        let twilioCallDelegate = TwilioCallsDelegate(sharedData: sharedData)
        callKitActions = CallKitActions(twilioCallDelegate: twilioCallDelegate)
        callKitActions.pushKitEventDelegate = pushNotificationsDelegate
    }
}
