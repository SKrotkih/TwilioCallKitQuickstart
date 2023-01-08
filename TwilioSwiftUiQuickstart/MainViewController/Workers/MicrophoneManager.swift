//
//  MicrophoneManager.swift
//  TwilioVoiceQuickstart
//
//  Created by Serhii Krotkykh on 09.07.2021.
//

import UIKit
import AVFoundation

class MicrophoneManager: NSObject {

    func checkMicrophonePermissions(completion: @escaping (_ permissionGranted: Bool) -> Void,
                                    cancelled: @escaping () -> Void) {
        checkRecordPermission { [weak self] permissionGranted in
            guard !permissionGranted else {
                completion(false)
                return
            }
            self?.showMicrophoneAccessRequest(completion: completion, cancelled: cancelled)
        }
    }

    private func checkRecordPermission(_ completion: @escaping (_ permissionGranted: Bool) -> Void) {
        let permissionStatus = AVAudioSession.sharedInstance().recordPermission

        switch permissionStatus {
        case .granted:
            // Record permission already granted.
            completion(true)
        case .denied:
            // Record permission denied.
            completion(false)
        case .undetermined:
            // Requesting record permission.
            // Optional: pop up app dialog to let the users know if they want to request.
            AVAudioSession.sharedInstance().requestRecordPermission { granted in completion(granted) }
        default:
            completion(false)
        }
    }

    private func showMicrophoneAccessRequest(completion: @escaping (_ permissionGranted: Bool) -> Void,
                                             cancelled: @escaping () -> Void) {
        let alertController = UIAlertController(title: "Voice Quick Start",
                                                message: "Microphone permission not granted",
                                                preferredStyle: .alert)
        let continueWithoutMic = UIAlertAction(title: "Continue without microphone", style: .default) {_ in
            completion(false)
        }
        let goToSettings = UIAlertAction(title: "Settings", style: .default) { _ in
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!,
                                      options: [UIApplication.OpenExternalURLOptionsKey.universalLinksOnly: false],
                                      completionHandler: nil)
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            cancelled()
        }
        [continueWithoutMic, goToSettings, cancel].forEach { alertController.addAction($0) }
        let viewController = UIApplication.shared.windows.first!.rootViewController!
        viewController.present(alertController, animated: true, completion: nil)
    }
}
