//
//  Dependencies.swift
//  TwilioCallKitQuickstart
//

import Foundation

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
