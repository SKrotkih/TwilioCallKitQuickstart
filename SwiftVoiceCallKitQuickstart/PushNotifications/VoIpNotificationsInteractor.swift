//
//  VoIpNotificationsInteractor.swift
//  TwilioCallKitQuickstart
//

import Foundation
import PushKit

class VoIpNotificationsInteractor: NSObject {

    var notificationsDelegate: VoIpNotificationsDelegate! {
        didSet {
            voipRegistry = PKPushRegistry.init(queue: DispatchQueue.main)
            voipRegistry.desiredPushTypes = Set([.voIP])
            voipRegistry.delegate = notificationsDelegate
        }
    }
    private var voipRegistry: PKPushRegistry!
    
    override init() {
        super.init()
    }
}
