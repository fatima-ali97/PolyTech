//
//  NotificationLayout.swift
//  PolyTech
//
//  Created by BP-19-130-15 on 24/12/2025.
//

import UIKit

class NotificationLayout: UIView {

    override init(frame: CGRect) {
            super.init(frame: frame)
            // Create a notification layout with a title, subtitle, and body
            let titleLabel = UILabel()
            titleLabel.text = "Custom Notification"
            titleLabel.font = .systemFont(ofSize: 24)
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview(titleLabel)

            let subtitleLabel = UILabel()
            subtitleLabel.text = "This is a custom notification"
            subtitleLabel.font = .systemFont(ofSize: 18)
            subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview(subtitleLabel)

            let bodyLabel = UILabel()
            bodyLabel.text = "This is a brief description of the notification"
            bodyLabel.font = .systemFont(ofSize: 16)
            bodyLabel.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview(bodyLabel)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
}
