//
//  TechnicianCardCell.swift
//  PolyTech
//
//  Created by BP-36-212-02 on 21/12/2025.
//

import Foundation
import UIKit

final class TechnicianCardCell: UITableViewCell {
    
    @IBOutlet weak var hoursViewCard: UIView!
    @IBOutlet weak var tasksViewCard: UIView!
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var hoursValueLabel: UILabel!
    @IBOutlet weak var tasksValueLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dotView: UIView!
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        
        dotView.layer.cornerRadius = dotView.bounds.height / 2
        dotView.clipsToBounds = true
        
        statusLabel.layer.cornerRadius = 5
        statusLabel.clipsToBounds = true
        
        cardView.layer.cornerRadius = 16
        cardView.layer.masksToBounds = false
        cardView.layer.shadowOpacity = 0.12
        cardView.layer.shadowRadius = 10
        cardView.layer.shadowOffset = CGSize(width: 0, height: 6)
        
        tasksViewCard.layer.cornerRadius = 14
        tasksViewCard.layer.masksToBounds = true
        tasksViewCard.layer.borderWidth = 1
        tasksViewCard.layer.borderColor = UIColor.systemGray5.cgColor
        
        hoursViewCard.layer.cornerRadius = 14
        hoursViewCard.layer.masksToBounds = true
        hoursViewCard.layer.borderWidth = 1
        hoursViewCard.layer.borderColor = UIColor.systemGray5.cgColor
        
        contentView.clipsToBounds = false
        clipsToBounds = false
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        dotView.layer.cornerRadius = dotView.bounds.height / 2
    }
}
