//
//  ContentViewModel.swift
//  TwilioVoiceQuickstart
//
//  Created by Serhii Krotkykh on 30.06.2021.
//
import SwiftUI
import Combine
import TwilioVoice
import TwilioVoicePackage

protocol CallPresentable: AnyObject {
    func setCallButtonTitle(_ title: String)
    func startActivity()
    func stopActivity()
    func toggleUIState(isEnabled: Bool, showCallControl: Bool)
    func qualityWarningsUpdatePopup(_ warnings: Set<NSNumber>, isCleared: Bool)
}

protocol CallKitPresentable: AnyObject {
    func startActivity()
    func toggleUIState(isEnabled: Bool, showCallControl: Bool)
}

protocol ContentPresentable: ObservableObject {
    var spinner: Spinner? { get set }
    var placeCallButton: PlaceCallButton? { get set }
    var toaster: QualityWarningsToaster? { get set }
    var callControls: CallControls? { get set }

    var muteSwitchOn: Bool { get set }
    var speackerSwitchOn: Bool { get set }
    var outgoingValue: String { get set }

    var muteButtonTitle: String { get }
    var spakerButtonTitle: String { get }
    var textFieldPlaceholder: String { get }
    var hintText: String { get }

    func viewDidAppear()
    func mainButtonPressed()
}

class ContentViewModel: NSObject, ObservableObject, ContentPresentable {
    // static localized texts
    @Published var muteButtonTitle = "Mute"
    @Published var spakerButtonTitle = "Speaker"
    @Published var textFieldPlaceholder = "Client name or phone number"
    @Published var hintText = """
    Dial a client name or phone number. Leaving the
    field empty results in an automated response.
"""

    @Published var outgoingValue: String = ""
    @Published var muteSwitchOn: Bool = false
    @Published var speackerSwitchOn: Bool = true

    // injected view components refs
    var spinner: Spinner?
    var placeCallButton: PlaceCallButton?
    var toaster: QualityWarningsToaster?
    var callControls: CallControls?

    private var outgoingPhoneNumber: String?

    private let callKitWorker: CallKitWorker!
    private let audioManager: AudioWorker!
    private let microphoneManager: MicrophoneManager!

//    var microphoneManager: MicrophoneManageable!
    var ringtoneManager: RingtoneManageable!
    var audioDevice: AudioDevice!
    

    // activeCall represents the last connected call
    var activeCall: Call?

    var userInitiatedDisconnect: Bool = false

    private var cancellable = Set<AnyCancellable>()

    init(callKitWorker: CallKitWorker,
         audioManager: AudioWorker,
         microphoneManager: MicrophoneManager) {
        self.callKitWorker = callKitWorker
        self.audioManager = audioManager
        self.microphoneManager = microphoneManager

        super.init()

        $muteSwitchOn
            .sink(receiveValue: { [weak self] state in
                self?.muteSwitchToggled(to: state)
            }).store(in: &cancellable)

        $speackerSwitchOn
            .sink(receiveValue: { [weak self] state in
                self?.speakerSwitchToggled(to: state)
            }).store(in: &cancellable)

        $outgoingValue
            .sink(receiveValue: { [weak self] value in
            self?.outgoingPhoneNumber = value
        }).store(in: &cancellable)

    }

    func viewDidAppear() {
        toggleUIState(isEnabled: true, showCallControl: false)
    }

    func mainButtonPressed() {
        guard activeCall == nil else {
            userInitiatedDisconnect = true
            callKitWorker.performEndCallAction(uuid: activeCall!.uuid!)
            toggleUIState(isEnabled: false, showCallControl: false)

            return
        }

        microphoneManager.checkMicrophonePermissions(completion: { [weak self] idPermissionGranted in
            let uuid = UUID()
            let handle = "Voice Bot"

            if !idPermissionGranted {
                self?.callKitWorker.performStartCallAction(uuid: uuid, handle: handle)
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

extension ContentViewModel: CallPresentable, CallKitPresentable {
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
