//
//  CallKitWorker.swift
//  TwilioVoiceQuickstart
//
//  Created by Serhii Krotkykh on 09.07.2021.
//

import UIKit
import CallKit
import TwilioVoice

protocol CallKitProviderCallable {
    func callFailed(call: Call)
    func callDisconnected(call: Call, reason: CXCallEndedReason)
}

protocol CallKitCallsStorageble {
    func disconnectCall(call: Call)
}

protocol CallKitCompletionHandlable {
    func callDidConnect()
    func callDidFailToConnect()
}

protocol CallKitCallsInviteble {
    func callInviteReceived(callInvite: CallInvite)
    func callInviteCancelled(callInvite: CallInvite)
    func getCallInvite(callSid: String) -> CallInvite?
}

class CallKitWorker: NSObject {
    // MARK: - Public
    var outgoingValue: String = ""

    // MARK: - Private
    private let callKitCallController = CXCallController()
    private var callKitProvider: CXProvider?
    private var audioDevice = DefaultAudioDevice()
    private weak var callDelegate: CallWorker!
    private weak var presenterDelegate: CallKitPresentable!
    private var callKitCompletionCallback: ((Bool) -> Void)?

    private var activeCalls: [String: Call]! = [:]
    private var activeCallInvites: [String: CallInvite]! = [:]

    // activeCall represents the last connected call
    private var activeCall: Call?

    init(callDelegate: CallWorker,
         maximumCallGroups: Int = 1,
         maximumCallsPerCallGroup: Int = 1
    ) {
        self.callDelegate = callDelegate

        super.init()

        self.configueProvider(maximumCallGroups: maximumCallGroups,
                              maximumCallsPerCallGroup: maximumCallsPerCallGroup)
    }

    func configure(presenter: CallKitPresentable) {
        self.presenterDelegate = presenter
    }

    private func configueProvider(maximumCallGroups: Int,
                                  maximumCallsPerCallGroup: Int) {
        /* Please note that the designated initializer `CXProviderConfiguration(localizedName: String)`
         has been deprecated on iOS 14.
         */
        let configuration = CXProviderConfiguration(localizedName: "Voice Quickstart")
        configuration.maximumCallGroups = maximumCallGroups
        configuration.maximumCallsPerCallGroup = maximumCallsPerCallGroup
        callKitProvider = CXProvider(configuration: configuration)
        if let provider = callKitProvider {
            provider.setDelegate(self, queue: nil)
        }
    }

    deinit {
        // CallKit has an odd API contract where the developer must call invalidate or the CXProvider is leaked.
        if let provider = callKitProvider {
            provider.invalidate()
        }
    }
}

extension CallKitWorker: CallKitCallsStorageble {
    func disconnectCall(call: Call) {
        if call == activeCall {
            activeCall = nil
        }
        activeCalls.removeValue(forKey: call.uuid!.uuidString)
    }
}

extension CallKitWorker: CallKitProviderCallable {
    func callFailed(call: Call) {
        if let provider = callKitProvider {
            provider.reportCall(with: call.uuid!, endedAt: Date(), reason: CXCallEndedReason.failed)
        }
    }

    func callDisconnected(call: Call, reason: CXCallEndedReason) {
        if let provider = callKitProvider {
            provider.reportCall(with: call.uuid!, endedAt: Date(), reason: reason)
        }
    }

}

extension CallKitWorker: CallKitCompletionHandlable {
    func callDidConnect() {
        if let callKitCompletionCallback = callKitCompletionCallback {
            callKitCompletionCallback(true)
        }
    }

    func callDidFailToConnect() {
        if let completion = callKitCompletionCallback {
            completion(false)
        }
    }
}

extension CallKitWorker: CallKitCallsInviteble {

    func getCallInvite(callSid: String) -> CallInvite? {
        guard let activeCallInvites = activeCallInvites, !activeCallInvites.isEmpty else {
            NSLog("No pending call invite")
            return nil
        }
        return activeCallInvites.values.first { invite in invite.callSid == callSid }
    }

    func callInviteReceived(callInvite: CallInvite) {
        activeCallInvites[callInvite.uuid.uuidString] = callInvite
    }

    func callInviteCancelled(callInvite: CallInvite) {
        activeCallInvites.removeValue(forKey: callInvite.uuid.uuidString)
    }
}

// MARK: - CXProviderDelegate protocol implementation

extension CallKitWorker: CXProviderDelegate {
    func providerDidReset(_ provider: CXProvider) {
        NSLog("providerDidReset:")
        audioDevice.isEnabled = false
    }

    func providerDidBegin(_ provider: CXProvider) {
        NSLog("providerDidBegin")
    }

    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        NSLog("provider:didActivateAudioSession:")
        audioDevice.isEnabled = true
    }

    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        NSLog("provider:didDeactivateAudioSession:")
        audioDevice.isEnabled = false
    }

    func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {
        NSLog("provider:timedOutPerformingAction:")
    }

    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        NSLog("provider:performStartCallAction:")

        presenterDelegate.toggleUIState(isEnabled: false, showCallControl: false)
        presenterDelegate.startActivity()

        provider.reportOutgoingCall(with: action.callUUID, startedConnectingAt: Date())

        performVoiceCall(uuid: action.callUUID, client: "") { success in
            if success {
                NSLog("performVoiceCall() successful")
                provider.reportOutgoingCall(with: action.callUUID, connectedAt: Date())
            } else {
                NSLog("performVoiceCall() failed")
            }
        }

        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        NSLog("provider:performAnswerCallAction:")

        performAnswerVoiceCall(uuid: action.callUUID) { success in
            if success {
                NSLog("performAnswerVoiceCall() successful")
            } else {
                NSLog("performAnswerVoiceCall() failed")
            }
        }

        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        NSLog("provider:performEndCallAction:")

        if let invite = activeCallInvites[action.callUUID.uuidString] {
            invite.reject()
            activeCallInvites.removeValue(forKey: action.callUUID.uuidString)
        } else if let call = activeCalls[action.callUUID.uuidString] {
            call.disconnect()
        } else {
            NSLog("Unknown UUID to perform end-call action with")
        }

        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        NSLog("provider:performSetHeldAction:")

        if let call = activeCalls[action.callUUID.uuidString] {
            call.isOnHold = action.isOnHold
            action.fulfill()
        } else {
            action.fail()
        }
    }

    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        NSLog("provider:performSetMutedAction:")

        if let call = activeCalls[action.callUUID.uuidString] {
            call.isMuted = action.isMuted
            action.fulfill()
        } else {
            action.fail()
        }
    }

    // MARK: Call Kit Actions
    func performStartCallAction(uuid: UUID, handle: String) {
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

    func reportIncomingCall(from: String, uuid: UUID) {
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

    func performEndCallAction(uuid: UUID) {

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

    func performVoiceCall(uuid: UUID, client: String?, completionHandler: @escaping (Bool) -> Void) {
        let connectOptions = ConnectOptions(accessToken: accessToken) { builder in
            builder.params = [twimlParamTo: self.outgoingValue]
            builder.uuid = uuid
        }

        let call = TwilioVoiceSDK.connect(options: connectOptions, delegate: callDelegate)
        activeCall = call
        activeCalls[call.uuid!.uuidString] = call
        callKitCompletionCallback = completionHandler
    }

    func performAnswerVoiceCall(uuid: UUID, completionHandler: @escaping (Bool) -> Void) {
        guard let callInvite = activeCallInvites[uuid.uuidString] else {
            NSLog("No CallInvite matches the UUID")
            return
        }

        let acceptOptions = AcceptOptions(callInvite: callInvite) { builder in
            builder.uuid = callInvite.uuid
        }

        let call = callInvite.accept(options: acceptOptions, delegate: callDelegate)
        activeCall = call
        activeCalls[call.uuid!.uuidString] = call
        callKitCompletionCallback = completionHandler

        activeCallInvites.removeValue(forKey: uuid.uuidString)

        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.incomingPushHandled()
        }
    }
}
