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
    
    private let notificationsDelegate: VoIpNotificationsDelegate
    private let disposeBag = DisposeBag()
    private let accessTokenFetcher = TwilioAccessTokenFetcher()
    
    private var callInvite: TVOCallInvite?
    private var call: TVOCall?
    private var userInitiatedDisconnect: Bool = false
    
    private var callKitCompletionCallback: ((Bool)->Swift.Void?)? = nil
    
    required init(notificationsDelegate: VoIpNotificationsDelegate,
                  callKitProviderDelegate: CallKitProviderDelegate) {
        self.notificationsDelegate = notificationsDelegate
        self.callKitProviderDelegate = callKitProviderDelegate
        super.init()
        self.twilioConfigure()
        self.addObservers()
    }
    
    private func twilioConfigure() {
        TwilioVoice.logLevel = .verbose
    }
    
    private func addObservers() {
        notificationsDelegate.voIpNotifications.subscribe() { value in
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
                    self.accessTokenFetcher.fetchAccessToken() { accessToken in
                        guard let accessToken = accessToken else {
                            completionHandler(false)
                            return
                        }

                        let to = "+1234555555" // self.outgoingValue.text!
                        
                        self.call = TwilioVoice.call(accessToken, params: ["To": to], uuid: uuid, delegate: self)
                        self.callKitCompletionCallback = completionHandler
                    }
                case .heldCall(let isOnHold, let completionHandler):
                    if (self.call?.state == .connected) {
                        self.call?.isOnHold = isOnHold
                        completionHandler(true)
                    } else {
                        completionHandler(false)
                    }
                default:
                    break
                }
            }
            }.disposed(by: disposeBag)
    }

    func performAnswerVoiceCall(uuid: UUID, completionHandler: @escaping (Bool) -> Swift.Void) {

        self.didAnswerCall()
        
        call = self.callInvite?.accept(with: self)
        self.callInvite = nil
        self.callKitCompletionCallback = completionHandler
        self.notificationsDelegate.incomingPushHandled()
    }
    
    
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
        TwilioVoice.handleNotification(userInfo, delegate: self)
    }
}

// MARK: - Public

extension TwilioInteractor {

    // Make a call action
    func placeCall() {
        if (self.call != nil && self.call?.state == .connected) {
            self.userInitiatedDisconnect = true
            self.state.onNext(.endCallAction(self.call!.uuid))
            self.state.onNext(.endCall)
        } else {
            let uuid = UUID()
            let handle = "Voice Bot"
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

// MARK: - TVONotificaitonDelegate

extension TwilioInteractor: TVONotificationDelegate {

    func callInviteReceived(_ callInvite: TVOCallInvite) {
        if (callInvite.state == .pending) {
            handleCallInviteReceived(callInvite)
        } else if (callInvite.state == .canceled) {
            handleCallInviteCanceled(callInvite)
        }
    }
    
    func handleCallInviteReceived(_ callInvite: TVOCallInvite) {
        print("\(#function)")
        if (self.callInvite != nil && self.callInvite?.state == .pending) {
            print("Already a pending incoming call invite.");
            print("  >> Ignoring call from %@", callInvite.from);
            self.notificationsDelegate.incomingPushHandled()
            return
        } else if (self.call != nil) {
            print("Already an active call.");
            print("  >> Ignoring call from %@", callInvite.from);
            self.notificationsDelegate.incomingPushHandled()
            return
        }
        self.callInvite = callInvite
        self.state.onNext(.callInviteReceived(callInvite.uuid, "Voice Bot"))
    }
    
    func handleCallInviteCanceled(_ callInvite: TVOCallInvite) {
        print("\(#function)")
        self.state.onNext(.endCallAction(callInvite.uuid))
        self.callInvite = nil
        self.notificationsDelegate.incomingPushHandled()
    }
    
    func notificationError(_ error: Error) {
        print("\(#function): \(error.localizedDescription)")
    }
    
    private func didAnswerCall() {
        if (self.callInvite != nil && self.callInvite?.state == .pending) {
            self.callInvite?.reject()
            self.callInvite = nil
        } else if (self.call != nil) {
            self.call?.disconnect()
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
