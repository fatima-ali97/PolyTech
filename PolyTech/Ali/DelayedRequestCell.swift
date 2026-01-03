//
//  DelayedRequestCell.swift
//  PolyTech
//
//  Created by BP-36-212-04 on 31/12/2025.
//

import Foundation
import UIKit

final class DelayedRequestCell: UITableViewCell {
    
    @IBOutlet weak var reassignButton: UIButton!
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        
        cardView.layer.cornerRadius = 16
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = UIColor.systemGray5.cgColor
        cardView.layer.masksToBounds = true
        

        reassignButton.clipsToBounds = true
        
        var config = UIButton.Configuration.filled()
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
        config.cornerStyle = .capsule
        config.baseBackgroundColor = .accent

        reassignButton.configuration = config

    }
}
