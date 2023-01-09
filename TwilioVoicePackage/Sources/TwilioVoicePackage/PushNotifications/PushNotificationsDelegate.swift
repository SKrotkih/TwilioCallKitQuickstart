//
//  PushNotificationsDelegate.swift
//  TwilioVoicePackage
//
import UIKit
import PushKit
import CallKit
import TwilioVoice

protocol PushKitEventDelegate: AnyObject {
    func credentialsUpdated(credentials: PKPushCredentials)
    func credentialsInvalidated()
    func incomingPushReceived(payload: PKPushPayload)
    func incomingPushReceived(payload: PKPushPayload, completion: @escaping () -> Void)
    func incomingPushHandled()
}

let kRegistrationTTLInDays = 365

let kCachedDeviceToken = "CachedDeviceToken"
let kCachedBindingDate = "CachedBindingDate"

class PushNotificationsDelegate: NSObject, PushKitEventDelegate {

    var activeCallInvites: [String: CallInvite]! = [:]
    var incomingPushCompletionCallback: (() -> Void)?
    var callKitProvider: CXProvider?

    weak var callKitDelegate: CallKitProviderDelegate?
    let notificationDelegate: NotificationDelegate

    init(callKitDelegate: CallKitProviderDelegate,
         notificationDelegate: NotificationDelegate) {
        self.callKitDelegate = callKitDelegate
        self.notificationDelegate = notificationDelegate
        super.init()
        self.configureCallKitProvider()
    }

    deinit {
        // CallKit has an odd API contract where the developer must call invalidate or the CXProvider is leaked.
        if let provider = callKitProvider {
            provider.invalidate()
        }
    }

    func configureCallKitProvider() {
       /* Please note that the designated initializer `CXProviderConfiguration(localizedName: String)`
        has been deprecated on iOS 14. */
        let configuration = CXProviderConfiguration(localizedName: appName)
        configuration.maximumCallGroups = 1
        configuration.maximumCallsPerCallGroup = 1
        callKitProvider = CXProvider(configuration: configuration)
        if let provider = callKitProvider {
            provider.setDelegate(callKitDelegate, queue: nil)
        }
    }

    func credentialsUpdated(credentials: PKPushCredentials) {
        guard registrationRequired() ||
                UserDefaults.standard.data(forKey: kCachedDeviceToken) != credentials.token else { return }

        let cachedDeviceToken = credentials.token
        /*
         * Perform registration if a new device token is detected.
         */
        let accessToken = TwilioAccessTokenFetcher.fetchAccessToken()
        TwilioVoiceSDK.register(accessToken: accessToken, deviceToken: cachedDeviceToken) { error in
            if let error = error {
                NSLog("An error occurred while registering: \(error.localizedDescription)")
            } else {
                NSLog("Successfully registered for VoIP push notifications.")

                // Save the device token after successfully registered.
                UserDefaults.standard.set(cachedDeviceToken, forKey: kCachedDeviceToken)

                /**
                 * The TTL of a registration is 1 year. The TTL for registration for this device/identity
                 * pair is reset to 1 year whenever a new registration occurs or a push notification is
                 * sent to this device/identity pair.
                 */
                UserDefaults.standard.set(Date(), forKey: kCachedBindingDate)
            }
        }
    }

    /**
     * The TTL of a registration is 1 year. The TTL for registration for this device/identity pair is reset to
     * 1 year whenever a new registration occurs or a push notification is sent to this device/identity pair.
     * This method checks if binding exists in UserDefaults, and if half of TTL has been passed then the method
     * will return true, else false.
     */
    func registrationRequired() -> Bool {
        guard
            let lastBindingCreated = UserDefaults.standard.object(forKey: kCachedBindingDate) as? Date
        else { return true }

        let date = Date()
        var components = DateComponents()
        components.setValue(kRegistrationTTLInDays/2, for: .day)

        if let expirationDate = Calendar.current.date(byAdding: components, to: lastBindingCreated) {
            return  expirationDate.compare(date) == ComparisonResult.orderedDescending
        }

        return true
    }

    func credentialsInvalidated() {
        guard let deviceToken = UserDefaults.standard.data(forKey: kCachedDeviceToken) else { return }
        let accessToken = TwilioAccessTokenFetcher.fetchAccessToken()
        TwilioVoiceSDK.unregister(accessToken: accessToken, deviceToken: deviceToken) { error in
            if let error = error {
                NSLog("An error occurred while unregistering: \(error.localizedDescription)")
            } else {
                NSLog("Successfully unregistered from VoIP push notifications.")
            }
        }

        UserDefaults.standard.removeObject(forKey: kCachedDeviceToken)

        // Remove the cached binding as credentials are invalidated
        UserDefaults.standard.removeObject(forKey: kCachedBindingDate)
    }

    func incomingPushReceived(payload: PKPushPayload) {
        // The Voice SDK will use main queue to invoke `cancelledCallInviteReceived:error:`
        // when delegate queue is not passed
        TwilioVoiceSDK.handleNotification(payload.dictionaryPayload, delegate: notificationDelegate, delegateQueue: nil)
    }

    func incomingPushReceived(payload: PKPushPayload, completion: @escaping () -> Void) {
        //        The Voice SDK will use main queue to invoke `cancelledCallInviteReceived:error:`
        //        when delegate queue is not passed
        TwilioVoiceSDK.handleNotification(payload.dictionaryPayload, delegate: notificationDelegate, delegateQueue: nil)

        if let version = Float(UIDevice.current.systemVersion), version < 13.0 {
            // Save for later when the notification is properly handled.
            incomingPushCompletionCallback = completion
        }
    }

    func incomingPushHandled() {
        guard let completion = incomingPushCompletionCallback else { return }

        incomingPushCompletionCallback = nil
        completion()
    }

    private var appName: String {
        guard let dictionary = Bundle.main.infoDictionary else { return "" }
        if let version: String = dictionary["CFBundleDisplayName"] as? String {
           return version
        } else {
           return ""
        }
    }
}
