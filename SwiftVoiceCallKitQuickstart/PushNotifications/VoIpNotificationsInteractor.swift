//
//  VoIpNotificationsInteractor.swift
//  TwilioCallKitQuickstart
//

import Foundation
import PushKit

class VoIpNotificationsInteractor: NSObject {

    private var voipRegistry: PKPushRegistry!
    
    required init(notificationsDelegate: VoIpNotificationsDelegate) {
        voipRegistry = PKPushRegistry.init(queue: DispatchQueue.main)
        super.init()
        voipRegistry.delegate = notificationsDelegate
        voipRegistry.desiredPushTypes = Set([.voIP])
    }
}
