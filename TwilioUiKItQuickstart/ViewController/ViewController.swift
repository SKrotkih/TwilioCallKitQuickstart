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
import TwilioVoicePackage

class ViewController: UIViewController {
    @IBOutlet weak var qualityWarningsToaster: UILabel!
    @IBOutlet weak var placeCallButton: UIButton!
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var outgoingValue: UITextField!
    @IBOutlet weak var callControlView: UIView!
    @IBOutlet weak var muteSwitch: UISwitch!
    @IBOutlet weak var speakerSwitch: UISwitch!
    var spinner: Spinner!

    var viewModel = ViewModel()
    private var disposableBag = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        spinner = Spinner(isSpinning: false, iconView: iconView)
        viewModel.viewDidLoad(viewController: self)
        startListeningToStateChanges()
        outgoingValue.addTarget(self, action: #selector(ViewController.textFieldDidChange(_:)), for: .editingChanged)
        outgoingValue.delegate = self
    }

    private func startListeningToStateChanges() {
        viewModel.$enableMainButton
            .receive(on: RunLoop.main)
            .sink { [weak self] enable in
                self?.placeCallButton.isEnabled = enable
            }.store(in: &disposableBag)
        viewModel.$mainButtonTitle
            .receive(on: RunLoop.main)
            .sink { [weak self] title in
                self?.placeCallButton.setTitle(title, for: .normal)
            }.store(in: &disposableBag)
        viewModel.$showCallControl
            .receive(on: RunLoop.main)
            .sink { [weak self] show in
                self?.callControlView.isHidden = !show
            }.store(in: &disposableBag)
        viewModel.$onSpeaker
            .receive(on: RunLoop.main)
            .sink { [weak self] isOn in
                self?.speakerSwitch.isOn = isOn
            }.store(in: &disposableBag)
        viewModel.$onMute
            .receive(on: RunLoop.main)
            .sink { [weak self] isOn in
                self?.muteSwitch.isOn = isOn
            }.store(in: &disposableBag)
        viewModel.$startLongTermProcess
            .receive(on: RunLoop.main)
            .sink { [weak self] startLongTermProcess in
                if startLongTermProcess {
                    self?.spinner.startSpin()
                }
            }.store(in: &disposableBag)
        viewModel.$stopLongTermProcess
            .receive(on: RunLoop.main)
            .sink { [weak self] stopLongTermProcess in
                if stopLongTermProcess {
                    self?.spinner.stopSpin()
                }
            }.store(in: &disposableBag)
        viewModel.$warningText
            .receive(on: RunLoop.main)
            .sink { [weak self] text in
                self?.qualityWarningsToaster.alpha = 0.0
                self?.qualityWarningsToaster.text = text
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
            }.store(in: &disposableBag)
    }

    @IBAction func mainButtonPressed(_ sender: Any) {
        viewModel.mainButtonPressed()
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
