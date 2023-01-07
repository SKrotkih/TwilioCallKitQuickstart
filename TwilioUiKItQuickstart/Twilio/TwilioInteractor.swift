//
//  TwilioInteractor.swift
//  TwilioCallKitQuickstart
//
import Foundation
import TwilioVoice
import Combine

protocol CallsController {
    func startCall()
    func endCall(completion: @escaping (Bool) -> Void)
    func callDisconnected()
    func toggleMuteSwitch(to mute: Bool)
    func saveOutgoingValue(_ text: String?)
}

enum CallEvents {
    case nothing
    case viewDidLoad
    case startCall
    case startRinging
    case stopRinging
    case connected
    case reconnectWithError(Error)
    case reconnect
    case disconnected
    case qualityWarnings(warnings: Set<NSNumber>, isCleared: Bool)
}

protocol LifeCycleEventsHandler {
    init(sharedData: SharedData)
    var event: Published<CallEvents>.Publisher { get }
    func viewDidLoad()
}

typealias ViewModel = CallsController & LifeCycleEventsHandler

class TwilioInteractor: ObservableObject, ViewModel {
    @Published var state: CallEvents = .nothing
    var event: Published<CallEvents>.Publisher { $state }

    let sharedData: SharedData
    private var disposableBag = Set<AnyCancellable>()
    /**
     Init TwilioInteractor
     @param
     sharedData - structure we use to share data with Twilio framework
     @return
     */
    required init(sharedData: SharedData) {
        NSLog("Twilio Voice Version: %@", TwilioVoiceSDK.sdkVersion())
        self.sharedData = sharedData
    }
    /**
     @param
     @return
     */
    func viewDidLoad() {
        state = .viewDidLoad
        store.$state
            .sink { [weak self] state in
                guard let self else { return }
                Task { @MainActor in
                    switch await state.callKit {
                    case .undefined, .begin, .reset, .timeout, .activateSession,
                            .deactivateSession, .endTwilioCall, .heldCall:
                        break
                    case .answerCall:
                        break
                    case .startTwilioCall:
                        self.state = .startCall
                    }
                    switch await state.twilio {
                    case .undefined:
                        break
                    case .callDidStartRinging:
                        // When [answerOnBridge](https://www.twilio.com/docs/voice/twiml/dial#answeronbridge)
                        // is enabled in the
                        // <Dial> TwiML verb, the caller will not hear the ringback while the call is
                        // ringing and awaiting to be
                        // accepted on the callee's side. The application can use the `AVAudioPlayer`
                        // to play custom audio files
                        // between the `[TVOCallDelegate callDidStartRinging:]` and the
                        // `[TVOCallDelegate callDidConnect:]` callbacks.
                        self.state = .startRinging
                    case .callDidStopRinging:
                        self.state = .stopRinging
                    case .callDidConnect:
                        self.state = .connected
                    case .isReconnectingWithError(let error):
                        self.state = .reconnectWithError(error)
                    case .callDidReconnect:
                        self.state = .reconnect
                    case .callDidFailToConnect:
                        // CallKitProvider should handle this event
                        break
                    case .callDidDisconnect(let error):
                        print(error?.localizedDescription ?? "")
                        // CallKitProvider should handle this event
                    case .callDisconnected:
                        self.state = .disconnected
                    case .callDidReceiveQualityWarnings(let warnings, let isCleared):
                        self.state = .qualityWarnings(warnings: warnings, isCleared: isCleared)
                    }
                }
            }
            .store(in: &disposableBag)
    }
    /**
     @param
     @return
     */
    func startCall() {
        let uuid = UUID()
        let handle = "Voice Bot"
        self.sharedData.userInitiatedDisconnect = false
        store.stateDispatch(action: .performStartCallAction(uuid, handle))
    }
    /**
     @param
     @return
     */
    func endCall(completion: @escaping (Bool) -> Void) {
        store.stateDispatch(action: .isCallInActiveState { isCallInActiveState in
            if isCallInActiveState {
                self.sharedData.userInitiatedDisconnect = true
                store.stateDispatch(action: .performEndCallAction)
                completion(true)
            } else {
                completion(false)
            }
        })
    }
    /**
     @param
     @return
     */
    func callDisconnected() {
        self.sharedData.userInitiatedDisconnect = false
    }
    /**
     @param
     @return
     */
    func toggleMuteSwitch(to mute: Bool) {
        // The sample app supports toggling mute from app UI only on the last connected call.
        store.stateDispatch(action: .setUpMuteForActiveCall(mute))
    }
    /**
     @param
     @return
     */
    func saveOutgoingValue(_ text: String?) {
        sharedData.outgoingValue = text
    }
}
