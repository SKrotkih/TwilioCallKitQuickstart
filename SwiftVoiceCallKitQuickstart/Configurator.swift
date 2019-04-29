//
//  Configurator.swift
//  TwilioCallKitQuickstart
//

import Foundation

struct Configurator {
    
    private var twilioAudioController: TwilioAudioController!
    private var coolKitInteractor: CallKitInteractor!
    private var notificationsInteractor: VoIpNotificationsInteractor!
    
    mutating func configure(for viewController: ViewController) {

        let callKitProviderDelegate = CallKitProviderDelegate()
        let voIpNotificationsDelegate = VoIpNotificationsDelegate()
        let twilioNotificationDelegate = TwilioNotificationDelegate()
        let twilioInteractor = TwilioInteractor()
        let viewModel = ViewModel()
        self.coolKitInteractor = CallKitInteractor()
        self.notificationsInteractor = VoIpNotificationsInteractor()

        twilioInteractor.callKitProviderDelegate = callKitProviderDelegate
        twilioInteractor.voIpNotificationsDelegate = voIpNotificationsDelegate
        twilioInteractor.twilioNotificationDelegate = twilioNotificationDelegate
        
        self.twilioAudioController = TwilioAudioController()
        self.twilioAudioController.providerDelegate = callKitProviderDelegate
        
        viewModel.twilioInteractor = twilioInteractor

        viewController.viewModel = viewModel
        
        self.coolKitInteractor.twilioInteractor = twilioInteractor
        self.coolKitInteractor.callKitProviderDelegate = callKitProviderDelegate
        
        self.notificationsInteractor.notificationsDelegate = voIpNotificationsDelegate
        
    }
}
