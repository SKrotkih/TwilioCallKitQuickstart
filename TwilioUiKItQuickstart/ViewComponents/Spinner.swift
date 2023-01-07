//
//  Spinner.swift
//  TwilioCallKitQuickstart
//
import UIKit

// MARK: - Icon spinning

class Spinner {
    private var isSpinning: Bool
    private let iconView: UIImageView

    init(isSpinning: Bool, iconView: UIImageView) {
        self.isSpinning = isSpinning
        self.iconView = iconView
    }

    func startSpin() {
        guard !isSpinning else { return }

        isSpinning = true
        spin(options: UIView.AnimationOptions.curveEaseIn)
    }

    func stopSpin() {
        isSpinning = false
    }

    private func spin(options: UIView.AnimationOptions) {
        UIView.animate(withDuration: 0.5, delay: 0.0, options: options, animations: { [weak iconView] in
            if let iconView = iconView {
                iconView.transform = iconView.transform.rotated(by: CGFloat(Double.pi/2))
            }
        }, completion: { [weak self] finished in
            guard let self else { return }
            if finished {
                if self.isSpinning {
                    self.spin(options: UIView.AnimationOptions.curveLinear)
                } else if options != UIView.AnimationOptions.curveEaseOut {
                    self.spin(options: UIView.AnimationOptions.curveEaseOut)
                }
            }
        })
    }
}
