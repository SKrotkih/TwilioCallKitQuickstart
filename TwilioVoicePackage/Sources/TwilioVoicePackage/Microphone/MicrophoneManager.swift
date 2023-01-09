//
//  MicrophoneManager.swift
//  TwilioVoicePackage
//
import UIKit
import AVFoundation
import Combine

enum MicrophoneUsing {
    case permissionGranted
    case continueWithoutMicrophone
    case userCancelledGrantPermissions
}

protocol MicrophoneManageable {
    func checkPermission(with viewController: UIViewController) -> AnyPublisher<MicrophoneUsing, Never>
}

class MicrophoneManager: MicrophoneManageable {
    private var viewController: UIViewController?

    init() { }
    
    @MainActor
    func checkPermission(with viewController: UIViewController) -> AnyPublisher<MicrophoneUsing, Never> {
        self.viewController = viewController
        return Future<MicrophoneUsing, Never> { promise in
            self.checkRecordPermission { [weak self] permissionGranted in
                guard let self else { return }
                guard !permissionGranted else {
                    promise(.success(.permissionGranted))
                    return
                }
                let uuid = UUID()
                let handle = "Voice Bot"
                self.showMicrophoneAccessRequest(uuid, handle) { result in
                    promise(result)
                }
            }
        }.eraseToAnyPublisher()
    }

    private func checkRecordPermission(completion: @escaping (_ permissionGranted: Bool) -> Void) {
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

    @MainActor
    private func showMicrophoneAccessRequest(_ uuid: UUID, _ handle: String,
                                             completion: @escaping (Result<MicrophoneUsing, Never>) -> Void) {
        let alertController = UIAlertController(title: "Voice Quick Start",
                                                message: "Microphone permission not granted",
                                                preferredStyle: .alert)
        let continueWithoutMic = UIAlertAction(title: "Continue without microphone", style: .default) { _ in
            completion(.success(.continueWithoutMicrophone))
        }
        let goToSettings = UIAlertAction(title: "Settings", style: .default) { _ in
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!,
                                      options: [UIApplication.OpenExternalURLOptionsKey.universalLinksOnly: false],
                                      completionHandler: nil)
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completion(.success(.userCancelledGrantPermissions))
        }
        [continueWithoutMic, goToSettings, cancel].forEach { alertController.addAction($0) }
        viewController?.present(alertController, animated: true, completion: nil)
    }
}
