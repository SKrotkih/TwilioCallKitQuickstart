//
//  ViewController.swift
//  Twilio Voice Quickstart - Swift
//
//  Copyright © 2016 Twilio, Inc. All rights reserved.
//
//  Refactored by Serhii Krotkih in Jan 2023
//
import UIKit
import Combine
import TwilioVoice

class ViewController: UIViewController {
    @IBOutlet weak var qualityWarningsToaster: UILabel!
    @IBOutlet weak var placeCallButton: UIButton!
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var outgoingValue: UITextField!
    @IBOutlet weak var callControlView: UIView!
    @IBOutlet weak var muteSwitch: UISwitch!
    @IBOutlet weak var speakerSwitch: UISwitch!

    // Injected Dependencies
    var viewModel: CallsController!
    var sharedData: SharedData!

    var microphoneManager: MicrophoneManageable!
    var ringtoneManager: RingtoneManageable!
    var spinner: Spinner!
    var audioDevice: AudioDevice!

    var incomingAlertController: UIAlertController?

    /*
     Custom ringback will be played when this flag is enabled.
     When [answerOnBridge](https://www.twilio.com/docs/voice/twiml/dial#answeronbridge) is enabled in
     the <Dial> TwiML verb, the caller will not hear the ringback while the call is ringing and awaiting
     to be accepted on the callee's side. Configure this flag based on the TwiML application.
    */
    var playCustomRingback = false

    private var disposableBag = Set<AnyCancellable>()
    private var dependencies = Dependencies()

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        NSLog("Twilio Voice Version: %@", TwilioVoiceSDK.sdkVersion())

        spinner = Spinner(isSpinning: false, iconView: iconView)
        audioDevice = AudioDevice()
        dependencies.configure(for: self)
        onChangeCallStateSubscription()
        toggleUIState(isEnabled: true, showCallControl: false)
        outgoingValue.addTarget(self, action: #selector(ViewController.textFieldDidChange(_:)), for: .editingChanged)
        outgoingValue.delegate = self
    }

    private func onChangeCallStateSubscription() {
        store.$state
            .sink { [weak self] state in
                guard let self else { return }
                Task { @MainActor in
                    switch await state.callKit {
                    case .undefined, .begin, .reset, .timeout, .activateSession,
                            .deactivateSession, .endTwilioCall, .heldCall:
                        break
                    case .startTwilioCall:
                        self.toggleUIState(isEnabled: false, showCallControl: false)
                        self.spinner.startSpin()
                    case .answerCall:
                        // CallKitProvider should handle this event
                        break
                    }
                    switch await state.twilio {
                    case .undefined:
                        break
                    case .callDidStartRinging:
                        self.placeCallButton.setTitle("Ringing", for: .normal)
                        // When [answerOnBridge](https://www.twilio.com/docs/voice/twiml/dial#answeronbridge)
                        // is enabled in the
                        // <Dial> TwiML verb, the caller will not hear the ringback while the call is
                        // ringing and awaiting to be
                        // accepted on the callee's side. The application can use the `AVAudioPlayer`
                        // to play custom audio files
                        // between the `[TVOCallDelegate callDidStartRinging:]` and the
                        // `[TVOCallDelegate callDidConnect:]` callbacks.
                        if self.playCustomRingback {
                            do {
                                try self.ringtoneManager.playRingback(ringtone: "ringtone.wav")
                            } catch {
                                if case let .message(text) = error as? RingtoneError {
                                    print(text)
                                }
                            }
                        }
                    case .callDidStopRinging:
                        if self.playCustomRingback {
                            self.ringtoneManager.stopRingback()
                        }
                    case .callDidConnect:
                        self.placeCallButton.setTitle("Hang Up", for: .normal)
                        self.toggleUIState(isEnabled: true, showCallControl: true)
                        self.spinner.stopSpin()
                        self.audioDevice.toggleAudioRoute(toSpeaker: true)
                    case .isReconnectingWithError(let error):
                        print(error.localizedDescription)
                        self.placeCallButton.setTitle("Reconnecting", for: .normal)
                        self.toggleUIState(isEnabled: false, showCallControl: false)
                    case .callDidReconnect:
                        self.placeCallButton.setTitle("Hang Up", for: .normal)
                        self.toggleUIState(isEnabled: true, showCallControl: true)
                    case .callDidFailToConnect:
                        // CallKitProvider should handle this event
                        break
                    case .callDidDisconnect(let error):
                        print(error?.localizedDescription ?? "")
                        // CallKitProvider should handle this event
                    case .callDisconnected:
                        self.spinner.stopSpin()
                        self.toggleUIState(isEnabled: true, showCallControl: false)
                        self.placeCallButton.setTitle("Call", for: .normal)
                        self.sharedData.userInitiatedDisconnect = false
                    case .callDidReceiveQualityWarnings(let warnings, let isCleared):
                        self.qualityWarningsUpdatePopup(warnings, isCleared: isCleared)
                    }
                }
            }
            .store(in: &disposableBag)
    }

    func toggleUIState(isEnabled: Bool, showCallControl: Bool) {
        placeCallButton.isEnabled = isEnabled

        if showCallControl {
            callControlView.isHidden = false
            muteSwitch.isOn = false
            speakerSwitch.isOn = true
        } else {
            callControlView.isHidden = true
        }
    }

    @IBAction func mainButtonPressed(_ sender: Any) {
        viewModel.endCall { [weak self] callIsEnded in
            guard let self else { return }
            if callIsEnded {
                self.sharedData.userInitiatedDisconnect = true
                self.toggleUIState(isEnabled: false, showCallControl: false)
            }
        }

        microphoneManager.checkPermission(with: self)
            .sink { [weak self] result in
                guard let self else { return }
                switch result {
                case .permissionGranted, .continueWithoutMicrophone:
                    self.viewModel.startCall(handle: "Voice Bot")
                case .userCancelledGrantPermissions:
                    self.toggleUIState(isEnabled: true, showCallControl: false)
                    self.spinner.stopSpin()
                }
            }.store(in: &disposableBag)
    }

    @IBAction func muteSwitchToggled(_ sender: UISwitch) {
        viewModel.toggleMuteSwitch(to: sender.isOn)
    }

    @IBAction func speakerSwitchToggled(_ sender: UISwitch) {
        audioDevice.toggleAudioRoute(toSpeaker: sender.isOn)
    }
}

extension ViewController {
    func qualityWarningsUpdatePopup(_ warnings: Set<NSNumber>, isCleared: Bool) {
        var popupMessage: String = "Warnings detected: "
        if isCleared {
            popupMessage = "Warnings cleared: "
        }

        let mappedWarnings: [String] = warnings.map { number in
            warningString(Call.QualityWarning(rawValue: number.uintValue)!)
        }
        popupMessage += mappedWarnings.joined(separator: ", ")

        qualityWarningsToaster.alpha = 0.0
        qualityWarningsToaster.text = popupMessage
        UIView.animate(withDuration: 1.0, animations: {
            self.qualityWarningsToaster.isHidden = false
            self.qualityWarningsToaster.alpha = 1.0
        }, completion: { [weak self] _ in
            guard let self else { return }
            let deadlineTime = DispatchTime.now() + .seconds(5)
            DispatchQueue.main.asyncAfter(deadline: deadlineTime, execute: {
                UIView.animate(withDuration: 1.0, animations: {
                    self.qualityWarningsToaster.alpha = 0.0
                }, completion: { _ in
                    self.qualityWarningsToaster.isHidden = true
                })
            })
        })
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

// MARK: - UITextFieldDelegate

extension ViewController: UITextFieldDelegate {
    @objc func textFieldDidChange(_ textField: UITextField) {
        sharedData.outgoingValue = textField.text
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        outgoingValue.resignFirstResponder()
        return true
    }
}
