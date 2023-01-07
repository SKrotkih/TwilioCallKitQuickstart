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

    var spinner: Spinner!

    // Injected Dependencies
    var viewModel: ViewModel!
    var microphoneManager: MicrophoneManageable!
    var ringtoneManager: RingtoneManageable!
    var audioDevice: AudioDevice!

    /*
     Custom ringback will be played when this flag is enabled.
     When [answerOnBridge](https://www.twilio.com/docs/voice/twiml/dial#answeronbridge) is enabled in
     the <Dial> TwiML verb, the caller will not hear the ringback while the call is ringing and awaiting
     to be accepted on the callee's side. Configure this flag based on the TwiML application.
    */
    private let playCustomRingback = false

    private var disposableBag = Set<AnyCancellable>()
    private var dependencies = Dependencies()

    override func viewDidLoad() {
        super.viewDidLoad()
        spinner = Spinner(isSpinning: false, iconView: iconView)
        dependencies.configure(for: self)
        startListeningToStateChanges()
        viewModel.viewDidLoad()
        outgoingValue.addTarget(self, action: #selector(ViewController.textFieldDidChange(_:)), for: .editingChanged)
        outgoingValue.delegate = self
    }
    //
    // Update View according the phone call phase changes
    //
    private func startListeningToStateChanges() {
        viewModel.event
            .receive(on: RunLoop.main)
            .sink { [weak self] state  in
                guard let self else { return }
                switch state {
                case .nothing:
                    break
                case .viewDidLoad:
                    self.toggleUIState(isEnabled: true, showCallControl: false)
                case .startCall:
                    self.toggleUIState(isEnabled: false, showCallControl: false)
                    self.spinner.startSpin()
                case .startRinging:
                    self.placeCallButton.setTitle("Ringing", for: .normal)
                    if self.playCustomRingback {
                        do {
                            try self.ringtoneManager.playRingback(ringtone: "ringtone.wav")
                        } catch {
                            if case let .message(text) = error as? RingtoneError {
                                print(text) // should be shown with toaster?
                            }
                        }
                    }
                case .stopRinging:
                    if self.playCustomRingback {
                        self.ringtoneManager.stopRingback()
                    }
                case .connected:
                    self.placeCallButton.setTitle("Hang Up", for: .normal)
                    self.toggleUIState(isEnabled: true, showCallControl: true)
                    self.audioDevice.toggleAudioRoute(toSpeaker: true)
                    self.spinner.stopSpin()
                case .reconnectWithError:
                    self.placeCallButton.setTitle("Reconnecting", for: .normal)
                    self.toggleUIState(isEnabled: false, showCallControl: false)
                case .reconnect:
                    self.placeCallButton.setTitle("Hang Up", for: .normal)
                    self.toggleUIState(isEnabled: true, showCallControl: true)
                case .disconnected:
                    self.placeCallButton.setTitle("Call", for: .normal)
                    self.toggleUIState(isEnabled: true, showCallControl: false)
                    self.viewModel.callDisconnected()
                    self.spinner.stopSpin()
                case .qualityWarnings(warnings: let warnings, isCleared: let isCleared):
                    self.qualityWarningsUpdatePopup(warnings, isCleared: isCleared)
                }
        }.store(in: &disposableBag)
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
                self.toggleUIState(isEnabled: false, showCallControl: false)
            }
        }

        microphoneManager.checkPermission(with: self)
            .sink { [weak self] result in
                guard let self else { return }
                switch result {
                case .permissionGranted, .continueWithoutMicrophone:
                    self.viewModel.startCall()
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
        viewModel.saveOutgoingValue(textField.text)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        outgoingValue.resignFirstResponder()
        return true
    }
}
