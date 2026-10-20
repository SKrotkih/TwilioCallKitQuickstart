//
//  Extensions.swift
//  TwilioVoiceQuickstart
//
import SwiftUI

// Hide keyboard method for iOS 13 or iOS 14.
// Use @FocusState for iOS 15 instead
#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif

extension View {
    func hidden(_ shouldHide: Bool) -> some View {
        opacity(shouldHide ? 0 : 1)
    }
}
