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

        self.twilioAudioController = TwilioAudioController(providerDelegate: callKitProviderDelegate)

        let voIpNotificationsDelegate = VoIpNotificationsDelegate()

        let twilioInteractor = TwilioInteractor(notificationsDelegate: voIpNotificationsDelegate, callKitProviderDelegate: callKitProviderDelegate)
        
        let viewModel = ViewModel(interactor: twilioInteractor)
        viewController.viewModel = viewModel
        
        coolKitInteractor = CallKitInteractor(twilioInteractor: twilioInteractor, providerDelegate: callKitProviderDelegate)
        
        notificationsInteractor = VoIpNotificationsInteractor(notificationsDelegate: voIpNotificationsDelegate)
        
    }
}
