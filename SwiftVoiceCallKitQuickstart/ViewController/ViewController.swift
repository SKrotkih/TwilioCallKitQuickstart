//
//  ViewController.swift
//  Twilio Voice with CallKit Quickstart - Swift
//
//  Copyright © 2016 Twilio, Inc. All rights reserved.
//

import UIKit
import AVFoundation
import RxSwift

class ViewController: UIViewController {
    
    @IBOutlet weak var placeCallButton: UIButton!
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var outgoingValue: UITextField!
    @IBOutlet weak var callControlView: UIView!
    @IBOutlet weak var muteSwitch: UISwitch!
    @IBOutlet weak var speakerSwitch: UISwitch!
    
    private var configurator = Configurator()
    var twilioInteractor: TwilioInteractor!
    
    private let disposeBag = DisposeBag()
    
    private var isSpinning = false
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.configurator.configure(for: self)
        self.startCallKitEventsListening()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureView()
    }
    
    private func configureView() {
        outgoingValue.delegate = self
        didFinishCall()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func placeCall(_ sender: UIButton) {
        twilioInteractor.placeCall()
    }
    
    @IBAction func muteSwitchToggled(_ sender: UISwitch) {
        twilioInteractor.muteSwitchToggled(on: sender.isOn)
    }
    
    @IBAction func speakerSwitchToggled(_ sender: UISwitch) {
        toggleAudioRoute(toSpeaker: sender.isOn)
    }
    
    private func startCallKitEventsListening() {
        twilioInteractor.state.subscribe() { value in
            if let state = value.element {
                switch state {
                case .startCall:
                    self.didStartCall()
                case .endCall:
                    self.didFinishCall()
                default:
                    break
                }
            }
            }.disposed(by: disposeBag)
    }
    
    private func didStartCall() {
        self.placeCallButton.setTitle("Hang Up", for: .normal)
        self.toggleUIState(isEnabled: true, showCallControl: true)
        self.stopSpin()
        self.toggleAudioRoute(toSpeaker: true)
    }

    private func didFinishCall() {
        self.placeCallButton.setTitle("Call", for: .normal)
        self.toggleUIState(isEnabled: true, showCallControl: false)
        self.stopSpin()
    }
    
    // MARK: Icon spinning
    private func startSpin() {
        if !isSpinning {
            isSpinning = true
            spin(options: UIView.AnimationOptions.curveEaseIn)
        }
    }
    
    private func stopSpin() {
        isSpinning = false
    }
    
    private func spin(options: UIView.AnimationOptions) {
        UIView.animate(withDuration: 0.5,
                       delay: 0.0,
                       options: options,
                       animations: { [weak iconView] in
                        if let iconView = iconView {
                            iconView.transform = iconView.transform.rotated(by: CGFloat(Double.pi/2))
                        }
        }) { [weak self] (finished: Bool) in
            guard let strongSelf = self else {
                return
            }
            if (finished) {
                if (strongSelf.isSpinning) {
                    strongSelf.spin(options: UIView.AnimationOptions.curveLinear)
                } else if (options != UIView.AnimationOptions.curveEaseOut) {
                    strongSelf.spin(options: UIView.AnimationOptions.curveEaseOut)
                }
            }
        }
    }
    
    private func toggleUIState(isEnabled: Bool, showCallControl: Bool) {
        placeCallButton.isEnabled = isEnabled
        if (showCallControl) {
            callControlView.isHidden = false
            muteSwitch.isOn = false
            speakerSwitch.isOn = true
        } else {
            callControlView.isHidden = true
        }
    }
}

// MARK: - UITextFieldDelegate

extension ViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        outgoingValue.resignFirstResponder()
        return true
    }
}

// MARK: - AVAudioSession

extension ViewController {
    
    func toggleAudioRoute(toSpeaker: Bool) {
        // The mode set by the Voice SDK is "VoiceChat" so the default audio
        // route is the built-in receiver. Use port override to switch the route.
        do {
            if (toSpeaker) {
                try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
            } else {
                try AVAudioSession.sharedInstance().overrideOutputAudioPort(.none)
            }
        } catch {
            NSLog(error.localizedDescription)
        }
    }
}
