//
//  ContentViewModel.swift
//  TwilioVoiceQuickstart
//
//  Created by Sergey Krotkih on 30.06.2021.
//

import Foundation
import SwiftUI
import AVFoundation
import PushKit
import CallKit
import TwilioVoice
import RxSwift

@propertyWrapper
struct Published<Value> {
    var projectedValue: Observable<Value> { subject }
    var wrappedValue: Value { didSet { valueDidChange() } }

    private let subject = PublishSubject<Value>()

    init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }

    private func valueDidChange() {
        subject.on(.next(wrappedValue))
    }
}

let accessToken = "FAKE TOKEN" // <#PASTE YOUR ACCESS TOKEN HERE#>
let twimlParamTo = "to"

let kRegistrationTTLInDays = 365

let kCachedDeviceToken = "CachedDeviceToken"
let kCachedBindingDate = "CachedBindingDate"

class ContentViewModel: NSObject, ObservableObject, ContentPresentable  {
    @Published var outgoingValue: String = ""
    
    @Published var muteSwitchOn: Bool = false
    @Published var speackerSwitchOn: Bool = true
    
    var spinner: Spinner?
    var placeCallButton: PlaceCallButton?
    var toaster: QualityWarningsToaster?
    var callControls: CallControls?
    
    private let ringtoneManager = RingtoneWorker()

    let microphoneManager = MicrophoneManager()
    let audioManager = AudioWorker()
    
    private var disposeBag = DisposeBag()
    
    var incomingPushCompletionCallback: (() -> Void)?

    var incomingAlertController: UIAlertController?

    var callKitCompletionCallback: ((Bool) -> Void)? = nil
    var activeCallInvites: [String: CallInvite]! = [:]
    var activeCalls: [String: Call]! = [:]
    
    // activeCall represents the last connected call
    var activeCall: Call? = nil

    var callKitProvider: CXProvider?
    let callKitCallController = CXCallController()
    var userInitiatedDisconnect: Bool = false
    
    deinit {
        // CallKit has an odd API contract where the developer must call invalidate or the CXProvider is leaked.
        if let provider = callKitProvider {
            provider.invalidate()
        }
    }
    
    func viewDidAppear() {
        toggleUIState(isEnabled: true, showCallControl: false)
        
        /* Please note that the designated initializer `CXProviderConfiguration(localizedName: String)` has been deprecated on iOS 14. */
        let configuration = CXProviderConfiguration(localizedName: "Voice Quickstart")
        configuration.maximumCallGroups = 1
        configuration.maximumCallsPerCallGroup = 1
        callKitProvider = CXProvider(configuration: configuration)
        if let provider = callKitProvider {
            provider.setDelegate(self, queue: nil)
        }
        
        audioManager.configureTwilioVoiceSDK()

        $muteSwitchOn
                .subscribe(onNext: { [weak self] state in
                    self?.muteSwitchToggled(to: state)
                })
                .disposed(by: disposeBag)

        $speackerSwitchOn
                .subscribe(onNext: { [weak self] state in
                    self?.speakerSwitchToggled(to: state)
                })
                .disposed(by: disposeBag)
    }

    func mainButtonPressed() {
        guard activeCall == nil else {
            userInitiatedDisconnect = true
            performEndCallAction(uuid: activeCall!.uuid!)
            toggleUIState(isEnabled: false, showCallControl: false)
            
            return
        }
        
        microphoneManager.checkMicrophonePermissions(completion: {
            [weak self] idPermissionGranted in
                let uuid = UUID()
                let handle = "Voice Bot"
                
                if !idPermissionGranted {
                    self?.performStartCallAction(uuid: uuid, handle: handle)
                }
            }, cancelled: { [weak self] in
                self?.toggleUIState(isEnabled: true, showCallControl: false)
                self?.spinner?.state = .stop
            })
    }

    func muteSwitchToggled(to isMuted: Bool) {
        // The sample app supports toggling mute from app UI only on the last connected call.
        guard let activeCall = activeCall else { return }
        
        activeCall.isMuted = isMuted
    }
    
    func speakerSwitchToggled(to speackerSwitchOn: Bool) {
        audioManager.toggleAudioRoute(toSpeaker: speackerSwitchOn)
    }
}

// MARK: - TVOCallDelegate

extension ContentViewModel: CallDelegate {
    func callDidStartRinging(call: Call) {
        NSLog("callDidStartRinging:")
        
        placeCallButton?.title = "Ringing"
        
        ringtoneManager.playRingback()
    }
    
    func callDidConnect(call: Call) {
        NSLog("callDidConnect:")
        
        ringtoneManager.stopRingback()
        
        if let callKitCompletionCallback = callKitCompletionCallback {
            callKitCompletionCallback(true)
        }
        
        placeCallButton?.title = "Hang Up"
        
        toggleUIState(isEnabled: true, showCallControl: true)
        spinner?.state = .stop
        audioManager.toggleAudioRoute(toSpeaker: true)
    }
    
    func call(call: Call, isReconnectingWithError error: Error) {
        NSLog("call:isReconnectingWithError:")
        
        placeCallButton?.title = "Reconnecting"
        
        toggleUIState(isEnabled: false, showCallControl: false)
    }
    
    func callDidReconnect(call: Call) {
        NSLog("callDidReconnect:")
        
        placeCallButton?.title = "Hang Up"
        
        toggleUIState(isEnabled: true, showCallControl: true)
    }
    
    func callDidFailToConnect(call: Call, error: Error) {
        NSLog("Call failed to connect: \(error.localizedDescription)")
        
        if let completion = callKitCompletionCallback {
            completion(false)
        }
        
        if let provider = callKitProvider {
            provider.reportCall(with: call.uuid!, endedAt: Date(), reason: CXCallEndedReason.failed)
        }

        callDisconnected(call: call)
    }
    
    func callDidDisconnect(call: Call, error: Error?) {
        if let error = error {
            NSLog("Call failed: \(error.localizedDescription)")
        } else {
            NSLog("Call disconnected")
        }
        
        if !userInitiatedDisconnect {
            var reason = CXCallEndedReason.remoteEnded
            
            if error != nil {
                reason = .failed
            }
            
            if let provider = callKitProvider {
                provider.reportCall(with: call.uuid!, endedAt: Date(), reason: reason)
            }
        }

        callDisconnected(call: call)
    }
    
    func callDisconnected(call: Call) {
        if call == activeCall {
            activeCall = nil
        }
        
        activeCalls.removeValue(forKey: call.uuid!.uuidString)
        
        userInitiatedDisconnect = false
        
        ringtoneManager.stopRingback()
        
        spinner?.state = .stop
        toggleUIState(isEnabled: true, showCallControl: false)
        placeCallButton?.title = "Call"
    }
    
    func call(call: Call, didReceiveQualityWarnings currentWarnings: Set<NSNumber>, previousWarnings: Set<NSNumber>) {
        /**
        * currentWarnings: existing quality warnings that have not been cleared yet
        * previousWarnings: last set of warnings prior to receiving this callback
        *
        * Example:
        *   - currentWarnings: { A, B }
        *   - previousWarnings: { B, C }
        *   - intersection: { B }
        *
        * Newly raised warnings = currentWarnings - intersection = { A }
        * Newly cleared warnings = previousWarnings - intersection = { C }
        */
        var warningsIntersection: Set<NSNumber> = currentWarnings
        warningsIntersection = warningsIntersection.intersection(previousWarnings)
        
        var newWarnings: Set<NSNumber> = currentWarnings
        newWarnings.subtract(warningsIntersection)
        if newWarnings.count > 0 {
            qualityWarningsUpdatePopup(newWarnings, isCleared: false)
        }
        
        var clearedWarnings: Set<NSNumber> = previousWarnings
        clearedWarnings.subtract(warningsIntersection)
        if clearedWarnings.count > 0 {
            qualityWarningsUpdatePopup(clearedWarnings, isCleared: true)
        }
    }
}

// MARK: - CXProviderDelegate

extension ContentViewModel: CXProviderDelegate {
    func providerDidReset(_ provider: CXProvider) {
        NSLog("providerDidReset:")
        audioManager.disableAudio()
    }

    func providerDidBegin(_ provider: CXProvider) {
        NSLog("providerDidBegin")
    }

    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        NSLog("provider:didActivateAudioSession:")
        audioManager.enableAudio()
    }

    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        NSLog("provider:didDeactivateAudioSession:")
        audioManager.disableAudio()
    }

    func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {
        NSLog("provider:timedOutPerformingAction:")
    }

    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        NSLog("provider:performStartCallAction:")
        
        toggleUIState(isEnabled: false, showCallControl: false)
        spinner?.state = .start
        
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
        
        let call = TwilioVoiceSDK.connect(options: connectOptions, delegate: self)
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
        
        let call = callInvite.accept(options: acceptOptions, delegate: self)
        activeCall = call
        activeCalls[call.uuid!.uuidString] = call
        callKitCompletionCallback = completionHandler
        
        activeCallInvites.removeValue(forKey: uuid.uuidString)
        
        guard #available(iOS 13, *) else {
            incomingPushHandled()
            return
        }
    }
}

// MARK: - PushKitEventDelegate

extension ContentViewModel: PushKitEventDelegate {
    func credentialsUpdated(credentials: PKPushCredentials) {
        guard
            (registrationRequired() || UserDefaults.standard.data(forKey: kCachedDeviceToken) != credentials.token)
        else {
            return
        }

        let cachedDeviceToken = credentials.token
        /*
         * Perform registration if a new device token is detected.
         */
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
            let lastBindingCreated = UserDefaults.standard.object(forKey: kCachedBindingDate)
        else { return true }
        
        let date = Date()
        var components = DateComponents()
        components.setValue(kRegistrationTTLInDays/2, for: .day)
        let expirationDate = Calendar.current.date(byAdding: components, to: lastBindingCreated as! Date)!

        if expirationDate.compare(date) == ComparisonResult.orderedDescending {
            return false
        }
        return true;
    }
    
    func credentialsInvalidated() {
        guard let deviceToken = UserDefaults.standard.data(forKey: kCachedDeviceToken) else { return }
        
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
        // The Voice SDK will use main queue to invoke `cancelledCallInviteReceived:error:` when delegate queue is not passed
        TwilioVoiceSDK.handleNotification(payload.dictionaryPayload, delegate: self, delegateQueue: nil)
    }
    
    func incomingPushReceived(payload: PKPushPayload, completion: @escaping () -> Void) {
        // The Voice SDK will use main queue to invoke `cancelledCallInviteReceived:error:` when delegate queue is not passed
        TwilioVoiceSDK.handleNotification(payload.dictionaryPayload, delegate: self, delegateQueue: nil)
        
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
}


// MARK: - TVONotificaitonDelegate

extension ContentViewModel: NotificationDelegate {
    func callInviteReceived(callInvite: CallInvite) {
        NSLog("callInviteReceived:")
        
        /**
         * The TTL of a registration is 1 year. The TTL for registration for this device/identity
         * pair is reset to 1 year whenever a new registration occurs or a push notification is
         * sent to this device/identity pair.
         */
        UserDefaults.standard.set(Date(), forKey: kCachedBindingDate)
        
        let callerInfo: TVOCallerInfo = callInvite.callerInfo
        if let verified: NSNumber = callerInfo.verified {
            if verified.boolValue {
                NSLog("Call invite received from verified caller number!")
            }
        }
        
        let from = (callInvite.from ?? "Voice Bot").replacingOccurrences(of: "client:", with: "")

        // Always report to CallKit
        reportIncomingCall(from: from, uuid: callInvite.uuid)
        activeCallInvites[callInvite.uuid.uuidString] = callInvite
    }
    
    func cancelledCallInviteReceived(cancelledCallInvite: CancelledCallInvite, error: Error) {
        NSLog("cancelledCallInviteCanceled:error:, error: \(error.localizedDescription)")

        guard let activeCallInvites = activeCallInvites, !activeCallInvites.isEmpty else {
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


extension ContentViewModel: CallPresentable, CallKitPresentable, CallMakerPresentable {
    func setCallButtonTitle(_ text: String) {
        placeCallButton?.title = text
    }
    
    func startActivity() {
        spinner?.state = .start
    }
    
    func stopActivity() {
        spinner?.state = .stop
    }
    
    func toggleUIState(isEnabled: Bool, showCallControl: Bool) {
        placeCallButton?.isEnabled = isEnabled
        
        if showCallControl {
            callControls?.isHidden = false
            muteSwitchOn = false
            speackerSwitchOn = true
        } else {
            callControls?.isHidden = true
        }
    }

    func qualityWarningsUpdatePopup(_ warnings: Set<NSNumber>, isCleared: Bool) {
        var popupMessage: String = "Warnings detected: "
        if isCleared {
            popupMessage = "Warnings cleared: "
        }
        
        let mappedWarnings: [String] = warnings.map { number in warningString(Call.QualityWarning(rawValue: number.uintValue)!)}
        popupMessage += mappedWarnings.joined(separator: ", ")
        
        toaster?.isHidden = true
        toaster?.text = popupMessage
        UIView.animate(withDuration: 1.0, animations: {
            self.toaster?.isHidden = false
        }) { [weak self] finish in
            guard let strongSelf = self else { return }
            let deadlineTime = DispatchTime.now() + .seconds(5)
            DispatchQueue.main.asyncAfter(deadline: deadlineTime, execute: {
                UIView.animate(withDuration: 1.0, animations: {
                    strongSelf.toaster?.isHidden = true
                }) { (finished) in
                    strongSelf.toaster?.isHidden = true
                }
            })
        }
    }
    
    func warningString(_ warning: Call.QualityWarning) -> String {
        switch warning {
        case .highRtt: return "high-rtt"
        case .highJitter: return "high-jitter"
        case .highPacketsLostFraction: return "high-packets-lost-fraction"
        case .lowMos: return "low-mos"
        case .constantAudioInputLevel: return "constant-audio-input-level"
        default: return "Unknown warning"
        }
    }
}
