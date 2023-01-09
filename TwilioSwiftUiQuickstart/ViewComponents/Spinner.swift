//
//  Spinner.swift
//  TwilioVoiceQuickstart
//
//  Created by Serhii Krotkykh on 02.07.2021.
//

import SwiftUI

struct Spinner {
    enum State {
    case start
    case stop
    }

    @Binding var isSpinning: Bool

    var state: State = .stop {
        didSet {
            switch state {
            case .start:
                isSpinning = true
            case .stop:
                isSpinning = false
            }
        }
    }
}
