//
//  ViewModel.swift
//  TwilioUiKitQuickstart
//
import UIKit
import Combine
import TwilioVoicePackage

class ViewModel: ObservableObject {
    
    var twilioVoice = TwilioInteractor(sharedData: ReduxStore.shared.environment.sharedData)
    private var disposableBag = Set<AnyCancellable>()
    /*
     Custom ringback will be played when this flag is enabled.
     When [answerOnBridge](https://www.twilio.com/docs/voice/twiml/dial#answeronbridge) is enabled in
     the <Dial> TwiML verb, the caller will not hear the ringback while the call is ringing and awaiting
     to be accepted on the callee's side. Configure this flag based on the TwiML application.
    */
    private let playCustomRingback = false

    var ringtoneManager: RingtoneManageable!
    var audioDevice: AudioDeviceManager!
    var microphoneManager: MicrophoneManageable!
    
    private var dependencies = Dependencies()
    private var viewController: UIViewController?

    func viewDidLoad(viewController: UIViewController) {
         dependencies.configure(for: self)
    }
    
    @Published var enableMainButton = false
    @Published var mainButtonTitle = ""
    @Published var showCallControl = false
    @Published var onMute = false
    @Published var onSpeaker = true
    @Published var startLongTermProcess = false
    @Published var stopLongTermProcess = false
    @Published var warningText = ""

    private func startListeningToStateChanges() {
        twilioVoice.event
            .receive(on: RunLoop.main)
            .sink { [weak self] state  in
                guard let self else { return }
                switch state {
                case .nothing:
                    break
                case .viewDidLoad:
                    self.enableMainButton = true
                    self.showCallControl = false
                case .startCall:
                    self.enableMainButton = false
                    self.showCallControl = false
                    self.startLongTermProcess = true
                case .startRinging:
                    self.mainButtonTitle = "Ringing"
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
                    self.mainButtonTitle = "Hang Up"
                    self.enableMainButton = true
                    self.showCallControl = true
                    self.onMute = false
                    self.onSpeaker = true
                    self.audioDevice.toggleAudioRoute(toSpeaker: true)
                    self.stopLongTermProcess = true
                case .reconnectWithError:
                    self.mainButtonTitle = "Reconnecting"
                    self.enableMainButton = true
                    self.showCallControl = false
                case .reconnect:
                    self.mainButtonTitle = "Hang Up"
                    self.enableMainButton = true
                    self.showCallControl = true
                    self.onMute = false
                    self.onSpeaker = true
                case .disconnected:
                    self.mainButtonTitle = "Call"
                    self.enableMainButton = true
                    self.showCallControl = false
                    self.twilioVoice.callDisconnected()
                    self.stopLongTermProcess = true
                case .qualityWarnings(warnings: let warnings, isCleared: let isCleared):
                    self.qualityWarningsUpdatePopup(warnings, isCleared: isCleared)
                }
        }.store(in: &disposableBag)
    }

    func mainButtonPressed() {
        twilioVoice.endCall { [weak self] callIsEnded in
            guard let self else { return }
            if callIsEnded {
                self.enableMainButton = false
                self.showCallControl = false
            }
        }
        guard let viewController = self.viewController else { return }
        microphoneManager.checkPermission(with: viewController)
            .sink { [weak self] result in
                guard let self else { return }
                switch result {
                case .permissionGranted, .continueWithoutMicrophone:
                    self.twilioVoice.startCall()
                case .userCancelledGrantPermissions:
                    self.enableMainButton = true
                    self.showCallControl = false
                    self.stopLongTermProcess = true
                }
            }.store(in: &disposableBag)
    }
    
    func toggleMuteSwitch(to isOn: Bool) {
        twilioVoice.toggleMuteSwitch(to: isOn)
    }
    
    func toggleSpeakerSwitch(to isOn: Bool) {
        audioDevice.toggleAudioRoute(toSpeaker: isOn)
    }
    
    func saveOutgoingValue(_ value: String?) {
        twilioVoice.saveOutgoingValue(value)
    }
}

extension ViewModel {
    func qualityWarningsUpdatePopup(_ warnings: Set<NSNumber>, isCleared: Bool) {
        var popupMessage: String = "Warnings detected: "
        if isCleared {
            popupMessage = "Warnings cleared: "
        }
        let mappedWarnings: [String] = warnings.map { number in
            twilioVoice.callQualityWarning(for: number.uintValue)
        }
        popupMessage += mappedWarnings.joined(separator: ", ")
        warningText = popupMessage
    }
}
