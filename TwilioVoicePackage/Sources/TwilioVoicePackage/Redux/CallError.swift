//
//  CallError.swift
//  TwilioVoicePackage
//
import Foundation

enum CallError: Error, Equatable {
    case message(String)
}

func == (left: CallError, right: CallError) -> Bool {
    switch (left, right) {
    case (.message(let left), .message(let right)) where left == right: return true
    default: return false
    }
}
