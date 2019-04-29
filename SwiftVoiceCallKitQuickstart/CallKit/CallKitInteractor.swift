//
//  CallKitInteractor.swift
//  TwilioCallKitQuickstart
//

import Foundation
import CallKit
import RxSwift

// TODO: Remove
import TwilioVoice

class CallKitInteractor: NSObject {
    
    private var callKitProvider: CXProvider!
    private let callKitCallController: CXCallController
    private let disposeBag = DisposeBag()

    var twilioInteractor: TwilioInteractor! {
        didSet {
            twilioInteractor.state.subscribe() { value in
                if let state = value.element {
                    switch state {
                    case .twilioReceivedCallInvite(let uuid, let handle):
                        // Incoming call
                        self.reportIncomingCall(from: handle, uuid: uuid)
                    case .makeCallAction(let uuid, let handle, let video):
                        // Outbound call
                        self.performStartCallAction(uuid: uuid, handle: handle, video: video)
                    case .endCallAction(let uuid):
                        // Close CallKit screen
                        self.performEndCallAction(uuid: uuid)
                    case .cancelledCallAction(let uuid, let error):
                        self.failedCall(uuid: uuid, error: error)
                    default:
                        break
                    }
                }
                }.disposed(by: disposeBag)
        }
    }
    var callKitProviderDelegate: CXProviderDelegate! {
        didSet {
            callKitProvider = CXProvider(configuration: type(of: self).providerConfiguration)
            callKitProvider.setDelegate(callKitProviderDelegate, queue: nil)
        }
    }
    
    override init() {
        callKitCallController = CXCallController()

        super.init()
    }
    
    /// The app's provider configuration, representing its CallKit capabilities
    static var providerConfiguration: CXProviderConfiguration {
        let localizedName = NSLocalizedString("TwilioCallKitQuickstart", comment: "Name of application")
        let configuration = CXProviderConfiguration(localizedName: localizedName)
        configuration.supportsVideo = false
        configuration.maximumCallsPerCallGroup = 1
        configuration.supportedHandleTypes = [.phoneNumber]
        configuration.iconTemplateImageData = #imageLiteral(resourceName: "TwilioLogo.png").pngData()
        configuration.ringtoneSound = "Ringtone.caf"
        return configuration
    }
    
    deinit {
        // CallKit has an odd API contract where the developer must call invalidate or the CXProvider is leaked.
        callKitProvider.invalidate()
    }
    
    private func failedCall(uuid: UUID, error: Error?) {
        var reason = CXCallEndedReason.remoteEnded
        if error != nil {
            reason = .failed
        }
        callKitProvider.reportCall(with: uuid, endedAt: Date(), reason: reason)
    }
    
    // MARK: Incoming call action
    /// Report the incoming call to the system
    private func reportIncomingCall(from: String, uuid: UUID) {
        let callHandle = CXHandle(type: .generic, value: from)
        
        let callUpdate = CXCallUpdate()
        callUpdate.remoteHandle = callHandle
        callUpdate.supportsDTMF = true
        callUpdate.supportsHolding = true
        callUpdate.supportsGrouping = false
        callUpdate.supportsUngrouping = false
        callUpdate.hasVideo = false
        
        // display incoming call UI when receiving incoming voip notification
        let backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
        
        // TODO: Remove after test. It's delay for have ability to test in background mode
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.callKitProvider.reportNewIncomingCall(with: uuid, update: callUpdate) { error in
                if let error = error {
                    print("Failed to report incoming call successfully: \(error.localizedDescription).")
                } else {
                    print("Incoming call successfully reported.")
                    // RCP: Workaround per https://forums.developer.apple.com/message/169511
                    TwilioVoice.configureAudioSession()
                }
                UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
            }
        }
        
    }
    
    // MARK: Outbound Call Kit Actions
    private func performStartCallAction(uuid: UUID, handle: String, video: Bool = false) {
        let callHandle = CXHandle(type: .generic, value: handle)
        let startCallAction = CXStartCallAction(call: uuid, handle: callHandle)
        startCallAction.isVideo = video
        let transaction = CXTransaction(action: startCallAction)
        
        callKitCallController.request(transaction)  { error in
            if let error = error {
                print("StartCallAction transaction request failed: \(error.localizedDescription)")
                return
            }
            
            print("StartCallAction transaction request successful")
            
            let callUpdate = CXCallUpdate()
            callUpdate.remoteHandle = callHandle
            callUpdate.supportsDTMF = true
            callUpdate.supportsHolding = true
            callUpdate.supportsGrouping = false
            callUpdate.supportsUngrouping = false
            callUpdate.hasVideo = false
            
            self.callKitProvider.reportCall(with: uuid, updated: callUpdate)
        }
    }

    private func performEndCallAction(uuid: UUID) {
        
        let endCallAction = CXEndCallAction(call: uuid)
        let transaction = CXTransaction(action: endCallAction)
        
        callKitCallController.request(transaction) { error in
            if let error = error {
                print("EndCallAction transaction request failed: \(error.localizedDescription).")
                return
            }
            print("EndCallAction transaction request successful")
        }
    }
}
