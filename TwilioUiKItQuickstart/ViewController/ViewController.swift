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
import TwilioVoiceAdapter

class ViewController: UIViewController {
    @IBOutlet weak var qualityWarningsToaster: UILabel!
    @IBOutlet weak var placeCallButton: UIButton!
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var outgoingValue: UITextField!
    @IBOutlet weak var callControlView: UIView!
    @IBOutlet weak var muteSwitch: UISwitch!
    @IBOutlet weak var speakerSwitch: UISwitch!
    var spinner: Spinner!

    private var viewModel: TwilioVoiceController!
    private var disposableBag = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = buildTwilioVoiceController()
        spinner = Spinner(isSpinning: false, iconView: iconView)
        viewModel.viewDidLoad(viewController: self)
        outgoingValue.addTarget(self, action: #selector(Self.textFieldDidChange(_:)), for: .editingChanged)
        outgoingValue.delegate = self
    }
    
    private func buildTwilioVoiceController() -> TwilioVoiceController {
        TwilioVoiceController {
            CallButton()
                .onEnabled { [weak self] isEnabled in
                    self?.placeCallButton.isEnabled = isEnabled
                }
                .onTitle { [weak self] title in
                    self?.placeCallButton.setTitle(title, for: .normal)
                }
            CallControl()
                .onShow { [weak self] in
                    self?.callControlView.isHidden = false
                }
                .onHide { [weak self] in
                    self?.callControlView.isHidden = true
                }
            MuteControl()
                .onMute { [weak self] in
                    self?.muteSwitch.isOn = true
                }
                .offMute { [weak self] in
                    self?.muteSwitch.isOn = false
                }
            SpeackerControl()
                .onSpeacker { [weak self] in
                    self?.speakerSwitch.isOn = true
                }
                .offSpeacker { [weak self] in
                    self?.speakerSwitch.isOn = false
                }
            LongTermProcess()
                .onStart { [weak self] in
                    self?.spinner.startSpin()
                }
                .onEnd { [weak self] in
                    self?.spinner.stopSpin()
                }
            CallResult()
                .onWarning { [weak self] warningText in
                    self?.qualityWarningsToaster.alpha = 0.0
                    self?.qualityWarningsToaster.text = warningText
                    UIView.animate(withDuration: 1.0, animations: {
                        self?.qualityWarningsToaster.isHidden = false
                        self?.qualityWarningsToaster.alpha = 1.0
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
        }
    }

    @IBAction func makeCallButtonPressed(_ sender: Any) {
        viewModel.makeCallButtonPressed()
    }

    @IBAction func muteSwitchToggled(_ sender: UISwitch) {
        viewModel.toggleMuteSwitch(to: sender.isOn)
    }

    @IBAction func speakerSwitchToggled(_ sender: UISwitch) {
        viewModel.toggleSpeakerSwitch(to: sender.isOn)
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
