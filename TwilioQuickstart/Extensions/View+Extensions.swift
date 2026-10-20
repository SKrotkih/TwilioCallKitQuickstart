//
//  View+Extensions.swift
//  TwilioQuickstart
//
import SwiftUI

extension View {
    func hidden(_ shouldHide: Bool) -> some View {
        opacity(shouldHide ? 0 : 1)
    }
}
