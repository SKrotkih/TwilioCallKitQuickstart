//
//  TwilioInteractor.swift
//  TwilioCallKitQuickstart
//

import Foundation
import TwilioVoice
import RxSwift
import CallKit
import PushKit

class TwilioInteractor: NSObject {

    public let state = PublishSubject<PhoneCallState>()
    private let accessTokenFetcher = TwilioAccessTokenFetcher()
    private var callInvite: TVOCallInvite?
    private var call: TVOCall?
    private var userInitiatedDisconnect: Bool = false
    private var callKitCompletionCallback: ((Bool)->Swift.Void?)? = nil
    private let disposeBag = DisposeBag()

    var outgoingPhoneNumber: String!
    
    var callKitProviderDelegate: CXProviderDelegate! {
        didSet {
            (callKitProviderDelegate as! CallKitProviderDelegate).state.subscribe() { value in
                if let state = value.element {
                    switch state {
                    case .answerCall(let uuid, let completionHandler):
                        self.performAnswerVoiceCall(uuid: uuid, completionHandler: completionHandler)
                    case .outboundCall(let uuid, let completionHandler):
                        self.performOutboundCall(uuid, completionHandler)
                    case .heldCall(let isOnHold, let completionHandler):
                        self.performHeldCall(isOnHold, completionHandler)
                    default:
                        break
                    }
                }
                }.disposed(by: disposeBag)
        }
    }
    var voIpNotificationsDelegate: PKPushRegistryDelegate! {
        didSet {
            (voIpNotificationsDelegate as! VoIpNotificationsDelegate).voIpNotifications.subscribe() { value in
                if let notification = value.element {
                    switch notification {
                    case .deviceTokenUpdated(let deviceToken):
                        self.registerDeviceToken(deviceToken)
                    case .deviceTokenInvalidated(let deviceToken):
                        self.unRegisterDeviceToken(deviceToken)
                    case .incomingCallReceived(let userInfo):
                        self.incomingCallReceived(with: userInfo)
                    }
                }
                }.disposed(by: disposeBag)
        }
    }
    var twilioNotificationDelegate: TVONotificationDelegate! {
        didSet {
            (twilioNotificationDelegate as! TwilioNotificationDelegate).state.subscribe() { value in
                if let state = value.element {
                    switch state {
                    case .pending(let callInvite):
                        self.didReceiveTwilioCallInvite(callInvite)
                    case .canceled(let callInvite):
                        self.didCancelTwilioCallInvite(callInvite)
                    case .error(let error):
                        self.didGetErrorTwilioCallInvite(error)
                    }
                }
                }.disposed(by: disposeBag)
        }
    }
    var twilioCallsDelegate: TVOCallDelegate! {
        didSet {
            (twilioCallsDelegate as! TwilioCallsDelegate).state.subscribe() { value in
                if let state = value.element {
                    switch state {
                    case .startTVOCall(let call):
                        self.startTwilioCall(call)
                    case .finishTVOCall(let call, let error):
                        self.finishTwilioCasll(call, error)
                    case .failToConnevtTVOCall(let call, let error):
                        self.failedTwillioCall(call, error)
                    }
                }
                }.disposed(by: disposeBag)
        }
    }
    
    override init() {
        super.init()
        self.twilioConfigure()
    }
    
    private func twilioConfigure() {
        TwilioVoice.logLevel = .verbose
    }
}

// MARK: - Handle notifications from the  VoIpNotifuicationsDelegate

extension TwilioInteractor {
    
    private func registerDeviceToken(_ deviceToken: String) {
        self.accessTokenFetcher.fetchAccessToken() { accessToken in
            guard let accessToken = accessToken else {
                return
            }
            TwilioVoice.register(withAccessToken: accessToken, deviceToken: deviceToken) { (error) in
                if let error = error {
                    print("An error occurred while registering: \(error.localizedDescription)")
                }
                else {
                    print("Successfully registered for VoIP push notifications.")
                }
            }
        }
    }
    private func unRegisterDeviceToken(_ deviceToken: String) {
        self.accessTokenFetcher.fetchAccessToken() { accessToken in
            guard let accessToken = accessToken else {
                return
            }
            TwilioVoice.unregister(withAccessToken: accessToken, deviceToken: deviceToken) { (error) in
                if let error = error {
                    print("An error occurred while unregistering: \(error.localizedDescription)")
                }
                else {
                    print("Successfully unregistered from VoIP push notifications.")
                }
            }
        }
    }
    private func incomingCallReceived(with userInfo: [AnyHashable: Any]) {
        TwilioVoice.handleNotification(userInfo, delegate: twilioNotificationDelegate)
    }
}

// MARK: - TVONotificationDelegate:
// Handle notifications from the Twilio Call Invite delegate

extension TwilioInteractor {
    private func didReceiveTwilioCallInvite(_ callInvite: TVOCallInvite) {
        print("\(#function)")
        if (self.callInvite != nil && self.callInvite?.state == .pending) {
            print("Already a pending incoming call invite.");
            print("  >> Ignoring call from %@", callInvite.from);
            (self.voIpNotificationsDelegate as! VoIpNotificationsDelegate).incomingPushHandled()
            return
        } else if (self.call != nil) {
            print("Already an active call.");
            print("  >> Ignoring call from %@", callInvite.from);
            (self.voIpNotificationsDelegate as! VoIpNotificationsDelegate).incomingPushHandled()
            return
        }
        self.callInvite = callInvite
        self.state.onNext(.twilioReceivedCallInvite(callInvite.uuid, "Voice Bot"))
    }
    private func didCancelTwilioCallInvite(_ callInvite: TVOCallInvite) {
        print("\(#function)")
        self.state.onNext(.endCallAction(callInvite.uuid))
        self.callInvite = nil
        (self.voIpNotificationsDelegate as! VoIpNotificationsDelegate).incomingPushHandled()
    }
    private func didGetErrorTwilioCallInvite(_ error: Error) {
        print("\(#function): \(error.localizedDescription)")
    }
}

// MARK: - twilioCallsDelegate: TwilioCallsDelegate
// Handle notifications from the Twilio Call Life Cycle delegate (after callInvite)

extension TwilioInteractor {
    private func startTwilioCall(_ call: TVOCall) {
        self.call = call
        if let callKitCompletionCallback = self.callKitCompletionCallback {
            callKitCompletionCallback(true)
            self.callKitCompletionCallback = nil
        }
        self.state.onNext(.startTwilioCall)
    }
    private func finishTwilioCasll(_ call: TVOCall, _ error: Error?) {
        if !self.userInitiatedDisconnect {
            self.userInitiatedDisconnect = false
            self.state.onNext(.cancelledCallAction(call.uuid, error))
        }
        self.call = nil
        self.state.onNext(.endTwilioCall)
    }
    private func failedTwillioCall(_ call: TVOCall, _ error: Error) {
        if let callKitCompletionCallback = self.callKitCompletionCallback {
            callKitCompletionCallback(false)
            self.callKitCompletionCallback = nil
        }
        self.state.onNext(.endCallAction(call.uuid))
        self.call = nil
        self.userInitiatedDisconnect = false
        self.state.onNext(.endTwilioCall)
    }
}

// MARK: - Handle notifications from the CallKitProviderDelegate

extension TwilioInteractor {
    
    private func performAnswerVoiceCall(uuid: UUID, completionHandler: @escaping (Bool) -> Swift.Void) {
        if let callInvite = self.callInvite {
            if callInvite.state == .pending {
                callInvite.reject()
            } else {
                call = callInvite.accept(with: twilioCallsDelegate)
            }
            self.callInvite = nil
        } else if let call = self.call {
            call.disconnect()
        }
        self.callKitCompletionCallback = completionHandler
        (self.voIpNotificationsDelegate as! VoIpNotificationsDelegate).incomingPushHandled()
    }
    private func performOutboundCall(_ uuid: UUID, _ completionHandler: @escaping (Bool) -> Void) {
        self.accessTokenFetcher.fetchAccessToken() { accessToken in
            guard let accessToken = accessToken else {
                completionHandler(false)
                return
            }
            self.call = TwilioVoice.call(accessToken, params: ["To": self.outgoingPhoneNumber], uuid: uuid, delegate: twilioCallsDelegate)
            self.callKitCompletionCallback = completionHandler
        }
    }
    private func performHeldCall(_ isOnHold: Bool, _ completionHandler: @escaping (Bool) -> Void) {
        if (self.call?.state == .connected) {
            self.call?.isOnHold = isOnHold
            completionHandler(true)
        } else {
            completionHandler(false)
        }
    }
}

// MARK: - Public

extension TwilioInteractor {
    
    func testIncomingCall() {
        self.state.onNext(.twilioReceivedCallInvite(UUID(), "Voice Bot"))
    }

    // Make a call action
    func placeCall(to handle: String, video: Bool = false) {
        if (self.call != nil && self.call?.state == .connected) {
            self.userInitiatedDisconnect = true
            self.state.onNext(.endCallAction(self.call!.uuid))
            self.state.onNext(.endTwilioCall)
        } else {
            let uuid = UUID()
            self.state.onNext(.makeCallAction(uuid, handle, video))
        }
    }
    
    func muteSwitchToggled(on: Bool) {
        if let call = call {
            call.isMuted = on
        } else {
            print("No active call to be muted")
        }
    }
}
