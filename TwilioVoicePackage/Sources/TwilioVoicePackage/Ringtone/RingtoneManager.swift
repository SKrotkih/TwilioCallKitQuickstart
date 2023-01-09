//
//  RingtoneManager.swift
//  TwilioCallKitQuickstart
//
import Foundation
import AVFoundation

public protocol RingtoneManageable {
    func playRingback(ringtone: String) throws
    func stopRingback()
}

public enum RingtoneError: Error {
    case message(String)
}

public class RingtoneManager: NSObject, RingtoneManageable {
    private var ringtonePlayer: AVAudioPlayer?

    public func playRingback(ringtone: String) throws {
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

    public func stopRingback() {
        guard let ringtonePlayer = ringtonePlayer, ringtonePlayer.isPlaying else { return }

        ringtonePlayer.stop()
    }
}

// MARK: - AVAudioPlayerDelegate protocol implementation

extension RingtoneManager: AVAudioPlayerDelegate {
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            NSLog("Audio player finished playing successfully")
        } else {
            NSLog("Audio player finished playing with some error")
        }
    }

    public func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let error = error {
            NSLog("Decode error occurred: \(error.localizedDescription)")
        }
    }
}
