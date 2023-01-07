//
//  RingtoneWorker.swift
//  TwilioVoiceQuickstart
//
//  Created by Sergey Krotkih on 09.07.2021.
//

import AVFoundation

class RingtoneWorker: NSObject {
    
    /*
     Custom ringback will be played when this flag is enabled.
     When [answerOnBridge](https://www.twilio.com/docs/voice/twiml/dial#answeronbridge) is enabled in
     the <Dial> TwiML verb, the caller will not hear the ringback while the call is ringing and awaiting
     to be accepted on the callee's side. Configure this flag based on the TwiML application.
    */
    private var playCustomRingback: Bool
    private var ringtonePlayer: AVAudioPlayer?
    
    init(customRingback: String? = nil,
         numberOfLoops: Int = -1,
         volume: Float = 1.0
    ) {
        self.playCustomRingback = false
        super.init()
        if let ringtone = customRingback,
           let ringtonePath = Bundle.main.path(forResource: ringtone, ofType: nil) {
            let ringtoneUrl = URL(fileURLWithPath: ringtonePath)
            do {
                ringtonePlayer = try AVAudioPlayer(contentsOf: ringtoneUrl)
                ringtonePlayer?.delegate = self
                ringtonePlayer?.numberOfLoops = numberOfLoops
                ringtonePlayer?.volume = volume
                self.playCustomRingback = true
            } catch {
                NSLog("Failed to initialize audio player")
            }
        }
    }
    
    /*
     When [answerOnBridge](https://www.twilio.com/docs/voice/twiml/dial#answeronbridge) is enabled in the
     <Dial> TwiML verb, the caller will not hear the ringback while the call is ringing and awaiting to be
     accepted on the callee's side. The application can use the `AVAudioPlayer` to play custom audio files
     between the `[TVOCallDelegate callDidStartRinging:]` and the `[TVOCallDelegate callDidConnect:]` callbacks.
    */
    func playRingback() {
        guard playCustomRingback  else { return }
        guard let ringtonePlayer = ringtonePlayer, ringtonePlayer.isPlaying else { return }
        ringtonePlayer.play()
    }
    
    func stopRingback() {
        guard playCustomRingback  else { return }
        guard let ringtonePlayer = ringtonePlayer, ringtonePlayer.isPlaying else { return }
        ringtonePlayer.stop()
    }
}

extension RingtoneWorker: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            NSLog("Audio player finished playing successfully");
        } else {
            NSLog("Audio player finished playing with some error");
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let error = error {
            NSLog("Decode error occurred: \(error.localizedDescription)")
        }
    }
}
