//
//  ViewController.swift
//  Twilio Voice with CallKit Quickstart - Swift
//
//  Copyright © 2016 Twilio, Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ViewController: UIViewController {
    
    @IBOutlet weak var placeCallButton: UIButton!
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var outgoingValue: UITextField!
    
    @IBOutlet weak var outgoingPhoneNumberTextField: UITextField!
    @IBOutlet weak var callControlView: UIView!
    @IBOutlet weak var muteSwitch: UISwitch!
    @IBOutlet weak var speakerSwitch: UISwitch!
    
    public var viewModel: ViewModel!
    
    private var configurator = Dependencies()
    private let disposeBag = DisposeBag()
    private var isSpinning = false
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.configurator.configure(for: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        startListeners()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.outgoingValue.text = "Test"
        self.outgoingPhoneNumberTextField.text = "+123456789"
    }
    
    private func configureView() {
        outgoingValue.delegate = self
        didFinishCall()
    }
    
    private func startListeners() {
        
        speakerSwitch.rx.isOn.asObservable()
            .subscribe(onNext:{ isOn in
                self.viewModel.switchSpeaker(on: isOn)
            })
            .disposed(by:disposeBag)
        muteSwitch.rx.isOn.asObservable()
            .subscribe(onNext:{ isOn in
                self.viewModel.muteSwith(on: isOn)
            })
            .disposed(by:disposeBag)
        placeCallButton.rx.tap.asObservable()
            .subscribe(onNext:{ _ in
                self.viewModel.makeCall(to: self.outgoingValue.text, phoneNumber: self.outgoingPhoneNumberTextField.text)
            })
            .disposed(by:disposeBag)
        viewModel.state.subscribe() { value in
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
        self.viewModel.switchSpeaker(on: true)
    }

    private func didFinishCall() {
        self.placeCallButton.setTitle("Call", for: .normal)
        self.toggleUIState(isEnabled: true, showCallControl: false)
        self.stopSpin()
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

// MARK: Spinner

extension ViewController {
    
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
}


// MARK: - UITextFieldDelegate

extension ViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        outgoingValue.resignFirstResponder()
        return true
    }
}
