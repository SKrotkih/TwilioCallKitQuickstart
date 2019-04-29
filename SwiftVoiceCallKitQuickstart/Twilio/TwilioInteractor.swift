//
//  TwilioInteractor.swift
//  TwilioCallKitQuickstart
//

import Foundation
import TwilioVoice
import RxSwift

class TwilioInteractor: NSObject {

    public let state = PublishSubject<PhoneCallState>()
    
    var callKitProviderDelegate: CallKitProviderDelegate!
    var voIpNotificationsDelegate: VoIpNotificationsDelegate!
    var twilioNotificationDelegate: TwilioNotificationDelegate!
    
    private let disposeBag = DisposeBag()
    private let accessTokenFetcher = TwilioAccessTokenFetcher()
    
    private var callInvite: TVOCallInvite?
    private var call: TVOCall?
    private var userInitiatedDisconnect: Bool = false
    
    private var callKitCompletionCallback: ((Bool)->Swift.Void?)? = nil

    var outgoingPhoneNumber: String!
    
    override init() {
        super.init()
        self.twilioConfigure()
        self.listenDelegates()
    }
    
    private func twilioConfigure() {
        TwilioVoice.logLevel = .verbose
    }
    
    private func listenDelegates() {
        voIpNotificationsDelegate.voIpNotifications.subscribe() { value in
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
        
        callKitProviderDelegate.state.subscribe() { value in
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
        twilioNotificationDelegate.state.subscribe() { value in
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

// MARK: - Twilio Call Invite Handler

extension TwilioInteractor {
    private func didReceiveTwilioCallInvite(_ callInvite: TVOCallInvite) {
        print("\(#function)")
        if (self.callInvite != nil && self.callInvite?.state == .pending) {
            print("Already a pending incoming call invite.");
            print("  >> Ignoring call from %@", callInvite.from);
            self.voIpNotificationsDelegate.incomingPushHandled()
            return
        } else if (self.call != nil) {
            print("Already an active call.");
            print("  >> Ignoring call from %@", callInvite.from);
            self.voIpNotificationsDelegate.incomingPushHandled()
            return
        }
        self.callInvite = callInvite
        self.state.onNext(.callInviteReceived(callInvite.uuid, "Voice Bot"))
    }
    private func didCancelTwilioCallInvite(_ callInvite: TVOCallInvite) {
        print("\(#function)")
        self.state.onNext(.endCallAction(callInvite.uuid))
        self.callInvite = nil
        self.voIpNotificationsDelegate.incomingPushHandled()
    }
    private func didGetErrorTwilioCallInvite(_ error: Error) {
        print("\(#function): \(error.localizedDescription)")
    }
}

// MARK: - From VoIpNotifuicationsDelegate notiofications handle

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

// MARK: - From CallKitProviderDelegate notiofications handle

extension TwilioInteractor {
    
    private func performAnswerVoiceCall(uuid: UUID, completionHandler: @escaping (Bool) -> Swift.Void) {
        if let callInvite = self.callInvite {
            if callInvite.state == .pending {
                callInvite.reject()
            } else {
                call = callInvite.accept(with: self)
            }
            self.callInvite = nil
        } else if let call = self.call {
            call.disconnect()
        }
        self.callKitCompletionCallback = completionHandler
        self.voIpNotificationsDelegate.incomingPushHandled()
    }
    private func performOutboundCall(_ uuid: UUID, _ completionHandler: @escaping (Bool) -> Void) {
        self.accessTokenFetcher.fetchAccessToken() { accessToken in
            guard let accessToken = accessToken else {
                completionHandler(false)
                return
            }
            self.call = TwilioVoice.call(accessToken, params: ["To": self.outgoingPhoneNumber], uuid: uuid, delegate: self)
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

    // Make a call action
    func placeCall(to handle: String) {
        if (self.call != nil && self.call?.state == .connected) {
            self.userInitiatedDisconnect = true
            self.state.onNext(.endCallAction(self.call!.uuid))
            self.state.onNext(.endCall)
        } else {
            let uuid = UUID()
            self.state.onNext(.makeCallAction(uuid, handle))
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


// MARK: - TVOCallDelegate

extension TwilioInteractor: TVOCallDelegate  {
    
    func callDidConnect(_ call: TVOCall) {
        print("\(#function)")
        self.call = call
        if let callKitCompletionCallback = self.callKitCompletionCallback {
            callKitCompletionCallback(true)
            self.callKitCompletionCallback = nil
        }
        self.state.onNext(.startCall)
    }
    
    func call(_ call: TVOCall, didFailToConnectWithError error: Error) {
        print("\(#function): \(error.localizedDescription)")
        if let callKitCompletionCallback = self.callKitCompletionCallback {
            callKitCompletionCallback(false)
            self.callKitCompletionCallback = nil
        }
        self.state.onNext(.endCallAction(call.uuid))
        self.call = nil
        self.userInitiatedDisconnect = false
        self.state.onNext(.endCall)
    }
    
    func call(_ call: TVOCall, didDisconnectWithError error: Error?) {
        print("\(#function): \(error?.localizedDescription ?? "Call disconnected")")
        if !self.userInitiatedDisconnect {
            self.userInitiatedDisconnect = false
            self.state.onNext(.cancelledCallAction(call.uuid, error))
        }
        self.call = nil
        self.state.onNext(.endCall)
    }
}
