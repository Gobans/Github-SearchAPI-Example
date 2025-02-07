//
//  ToastView.swift
//  SearchRepository
//
//  Created by Lee Myeonghwan on 2/7/25.
//

import UIKit

class ToastView: UIView {

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        return label
    }()

    init(message: String) {
        super.init(frame: .zero)
        self.messageLabel.text = message
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        backgroundColor = UIColor.black.withAlphaComponent(0.8)
        layer.cornerRadius = 10
        layer.masksToBounds = true

        addSubview(messageLabel)
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            messageLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        ])
    }

    func show(in view: UIView, duration: TimeInterval = 2.0) {
        let screenWidth = view.frame.width
        let toastHeight: CGFloat = 50
        let bottomPadding: CGFloat = 50

        let tabBarHeight = view.safeAreaInsets.bottom
        self.frame = CGRect(x: 20, y: view.frame.height, width: screenWidth - 40, height: toastHeight)
        view.addSubview(self)

        UIView.animate(withDuration: 0.3, animations: {
            self.frame.origin.y = view.frame.height - toastHeight - bottomPadding - tabBarHeight
        }) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                self.dismiss()
            }
        }
    }

    private func dismiss() {
        UIView.animate(withDuration: 0.3, animations: {
            self.frame.origin.y += 60
            self.alpha = 0
        }) { _ in
            self.removeFromSuperview()
        }
    }
}
