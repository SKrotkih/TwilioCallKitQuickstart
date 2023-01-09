//
//  CallKitActions.swift
//  TwilioCallKitQuickstart
//
import Foundation
import CallKit
import TwilioVoice

public protocol PhoneCallable {
    func performVoiceCall(uuid: UUID, client: String?, to: String?, completionHandler: @escaping (Bool) -> Void)
    func performAnswerVoiceCall(uuid: UUID, completionHandler: @escaping (Bool) -> Void)
    func performStartCallAction(uuid: UUID, handle: String)
    func setUpMuteForActiveCall(_ isMuted: Bool)
    func performEndCallAction()
    func reportIncomingCall(from: String, uuid: UUID)
    func useActiveCallInvite(_ callInvite: CallInvite)
    func cancelledCallInviteReceived(cancelledCallInvite: CancelledCallInvite, error: Error)
    func callDidFailToConnect(call: Call, error: Error)
    func callDidDisconnect(call: Call, error: Error?)
    func callDisconnected(call: Call)
    func performEndCallAction(uuid: UUID)
    func isCallInActiveState(completionHandler: @escaping (Bool) -> Void)
}

public final class CallKitActions: NSObject, PhoneCallable {
    let callKitCallController = CXCallController()
    var callKitCompletionCallback: ((Bool) -> Void)?
    var callKitProvider: CXProvider?
    var activeCalls: [String: Call] = [:]
    var activeCallInvites: [String: CallInvite] = [:]
    // activeCall represents the last connected call
    private var activeCall: Call?
    private let twilioCallDelegate: CallDelegate
    weak var pushKitEventDelegate: PushKitEventDelegate?

    public init(twilioCallDelegate: CallDelegate) {
        self.twilioCallDelegate = twilioCallDelegate
    }

    public func performVoiceCall(uuid: UUID, client: String?, to: String?, completionHandler: @escaping (Bool) -> Void) {
        let connectOptions = ConnectOptions(accessToken: accessToken) { builder in
            builder.params = [twimlParamTo: to ?? ""]
            builder.uuid = uuid
        }
        let call = TwilioVoiceSDK.connect(options: connectOptions, delegate: twilioCallDelegate)
        activeCall = call
        activeCalls[call.uuid!.uuidString] = call
        callKitCompletionCallback = completionHandler
    }

    public func performAnswerVoiceCall(uuid: UUID, completionHandler: @escaping (Bool) -> Void) {
        guard let callInvite = activeCallInvites[uuid.uuidString] else {
            NSLog("No CallInvite matches the UUID")
            return
        }

        let acceptOptions = AcceptOptions(callInvite: callInvite) { builder in
            builder.uuid = callInvite.uuid
        }

        let call = callInvite.accept(options: acceptOptions, delegate: twilioCallDelegate)
        activeCall = call
        activeCalls[call.uuid!.uuidString] = call
        callKitCompletionCallback = completionHandler

        activeCallInvites.removeValue(forKey: uuid.uuidString)

        pushKitEventDelegate?.incomingPushHandled()
    }

    public func performStartCallAction(uuid: UUID, handle: String) {
        guard let provider = callKitProvider else {
            NSLog("CallKit provider not available")
            return
        }

        let callHandle = CXHandle(type: .generic, value: handle)
        let startCallAction = CXStartCallAction(call: uuid, handle: callHandle)
        let transaction = CXTransaction(action: startCallAction)

        callKitCallController.request(transaction) { error in
            if let error = error {
                NSLog("StartCallAction transaction request failed: \(error.localizedDescription)")
                return
            }

            NSLog("StartCallAction transaction request successful")

            let callUpdate = CXCallUpdate()

            callUpdate.remoteHandle = callHandle
            callUpdate.supportsDTMF = true
            callUpdate.supportsHolding = true
            callUpdate.supportsGrouping = false
            callUpdate.supportsUngrouping = false
            callUpdate.hasVideo = false

            provider.reportCall(with: uuid, updated: callUpdate)
        }
    }

    public func reportIncomingCall(from: String, uuid: UUID) {
        guard let provider = callKitProvider else {
            NSLog("CallKit provider not available")
            return
        }

        let callHandle = CXHandle(type: .generic, value: from)
        let callUpdate = CXCallUpdate()

        callUpdate.remoteHandle = callHandle
        callUpdate.supportsDTMF = true
        callUpdate.supportsHolding = true
        callUpdate.supportsGrouping = false
        callUpdate.supportsUngrouping = false
        callUpdate.hasVideo = false

        provider.reportNewIncomingCall(with: uuid, update: callUpdate) { error in
            if let error = error {
                NSLog("Failed to report incoming call successfully: \(error.localizedDescription).")
            } else {
                NSLog("Incoming call successfully reported.")
            }
        }
    }

    public func callDisconnected(call: Call) {
        if call == activeCall {
            activeCall = nil
        }
        activeCalls.removeValue(forKey: call.uuid!.uuidString)
    }

    public func callDidDisconnect(call: Call, error: Error?) {
        var reason = CXCallEndedReason.remoteEnded

        if error != nil {
            reason = .failed
        }

        if let provider = callKitProvider {
            provider.reportCall(with: call.uuid!, endedAt: Date(), reason: reason)
        }
    }

    public func callDidFailToConnect(call: Call, error: Error) {
        if let provider = callKitProvider {
            provider.reportCall(with: call.uuid!, endedAt: Date(), reason: CXCallEndedReason.failed)
        }
    }

    public func useActiveCallInvite(_ callInvite: CallInvite) {
        activeCallInvites[callInvite.uuid.uuidString] = callInvite
    }

    public func isCallInActiveState(completionHandler: (Bool) -> Void ) {
        completionHandler(activeCall != nil)
    }

    public func setUpMuteForActiveCall(_ isMuted: Bool) {
        if let call = activeCall {
            call.isMuted = isMuted
        }
    }

    public func performEndCallAction() {
        if let call = activeCall, let uuid = call.uuid {
            performEndCallAction(uuid: uuid)
        }
    }

    public func performEndCallAction(uuid: UUID) {

        let endCallAction = CXEndCallAction(call: uuid)
        let transaction = CXTransaction(action: endCallAction)

        callKitCallController.request(transaction) { error in
            if let error = error {
                NSLog("EndCallAction transaction request failed: \(error.localizedDescription).")
            } else {
                NSLog("EndCallAction transaction request successful")
            }
        }
    }

    public func cancelledCallInviteReceived(cancelledCallInvite: CancelledCallInvite, error: Error) {
        NSLog("cancelledCallInviteCanceled:error:, error: \(error.localizedDescription)")

        guard activeCallInvites.isEmpty == false else {
            NSLog("No pending call invite")
            return
        }

        let callInvite = activeCallInvites.values.first { invite in invite.callSid == cancelledCallInvite.callSid }

        if let callInvite = callInvite {
            performEndCallAction(uuid: callInvite.uuid)
            self.activeCallInvites.removeValue(forKey: callInvite.uuid.uuidString)
        }
    }
}
