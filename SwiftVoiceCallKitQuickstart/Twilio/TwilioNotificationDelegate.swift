//
//  TwilioNotificationDelegate.swift
//  TwilioCallKitQuickstart
//

import Foundation
import TwilioVoice
import RxSwift

// MARK: - TVONotificaitonDelegate

enum TwilioNotifications {
    case pending(TVOCallInvite)
    case canceled(TVOCallInvite)
    case error(Error)
}

class TwilioNotificationDelegate: NSObject, TVONotificationDelegate {
    
    var state = PublishSubject<TwilioNotifications>()
    
    func callInviteReceived(_ callInvite: TVOCallInvite) {
        if (callInvite.state == .pending) {
            self.state.onNext(.pending(callInvite))
        } else if (callInvite.state == .canceled) {
            self.state.onNext(.canceled(callInvite))
        }
    }

    func notificationError(_ error: Error) {
        self.state.onNext(.error(error))
    }
}
