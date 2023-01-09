//
//  RingtoneManager.swift
//  TwilioVoicePackage
//
import Foundation
import AVFoundation

protocol RingtoneManageable {
    func playRingback(ringtone: String) throws
    func stopRingback()
}

enum RingtoneError: Error {
    case message(String)
}

class RingtoneManager: NSObject, RingtoneManageable {
    private var ringtonePlayer: AVAudioPlayer?

    func playRingback(ringtone: String) throws {
        let resource = ringtone.components(separatedBy: ".")
        guard resource.count == 2,
              let url = Bundle.main.path(forResource: resource[0], ofType: resource[1]) else { return }

        let ringtonePath = URL(fileURLWithPath: url)

        do {
            ringtonePlayer = try AVAudioPlayer(contentsOf: ringtonePath)
            ringtonePlayer?.delegate = self
            ringtonePlayer?.numberOfLoops = -1

            ringtonePlayer?.volume = 1.0
            ringtonePlayer?.play()
        } catch {
            throw RingtoneError.message("Failed to initialize audio player")
        }
    }

    func stopRingback() {
        guard let ringtonePlayer = ringtonePlayer, ringtonePlayer.isPlaying else { return }

        ringtonePlayer.stop()
    }
}

// MARK: - AVAudioPlayerDelegate protocol implementation

extension RingtoneManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            NSLog("Audio player finished playing successfully")
        } else {
            NSLog("Audio player finished playing with some error")
        }
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let error = error {
            NSLog("Decode error occurred: \(error.localizedDescription)")
        }
    }
}
