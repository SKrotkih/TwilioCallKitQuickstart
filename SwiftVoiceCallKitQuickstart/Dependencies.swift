//
//  Dependencies.swift
//  TwilioCallKitQuickstart
//

import Foundation

enum PhoneCallState {
    case undefined
    case reset
    case begin
    case activateSession
    case deactivateSession
    case timeout
    case answerCall(UUID, (Bool) -> Void)
    case endTwilioCall
    case startTwilioCall
    case heldCall(Bool, (Bool) -> Void)
    case makeCallAction(UUID, String)
    case endCallAction(UUID)
    case cancelledCallAction(UUID, Error?)
    case twilioReceivedCallInvite(UUID, String)
    case outboundCall(UUID, (Bool) -> Void)
}

struct Dependencies {
    
    private var twilioAudioController: TwilioAudioController!
    private var coolKitInteractor: CallKitInteractor!
    private var notificationsInteractor: VoIpNotificationsInteractor!
    
    mutating func configure(for viewController: ViewController) {

        self.coolKitInteractor = CallKitInteractor()
        self.notificationsInteractor = VoIpNotificationsInteractor()
        self.twilioAudioController = TwilioAudioController()

        let callKitProviderDelegate = CallKitProviderDelegate()
        let voIpNotificationsDelegate = VoIpNotificationsDelegate()
        let twilioNotificationDelegate = TwilioNotificationDelegate()
        let twilioCallsDelegate = TwilioCallsDelegate()
        let twilioInteractor = TwilioInteractor()
        let viewModel = ViewModel()
        
        twilioInteractor.callKitProviderDelegate = callKitProviderDelegate
        twilioInteractor.voIpNotificationsDelegate = voIpNotificationsDelegate
        twilioInteractor.twilioNotificationDelegate = twilioNotificationDelegate
        twilioInteractor.twilioCallsDelegate = twilioCallsDelegate
        
        viewModel.twilioInteractor = twilioInteractor

        viewController.viewModel = viewModel
        
        self.coolKitInteractor.twilioInteractor = twilioInteractor
        self.coolKitInteractor.callKitProviderDelegate = callKitProviderDelegate
        
        self.notificationsInteractor.notificationsDelegate = voIpNotificationsDelegate

        self.twilioAudioController.providerDelegate = callKitProviderDelegate
        
    }
}
