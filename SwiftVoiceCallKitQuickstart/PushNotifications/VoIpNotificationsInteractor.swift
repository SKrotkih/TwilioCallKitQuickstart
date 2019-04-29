//
//  VoIpNotificationsInteractor.swift
//  TwilioCallKitQuickstart
//

import Foundation
import PushKit

class VoIpNotificationsInteractor: NSObject {

    var notificationsDelegate: VoIpNotificationsDelegate!
    private var voipRegistry: PKPushRegistry!
    
    override init() {
        voipRegistry = PKPushRegistry.init(queue: DispatchQueue.main)
        super.init()
        voipRegistry.delegate = notificationsDelegate
        voipRegistry.desiredPushTypes = Set([.voIP])
    }
}
