//
//  TechnicianCardCell.swift
//  PolyTech
//
//  Created by BP-36-212-02 on 21/12/2025.
//

import Foundation
import UIKit

final class TechnicianCardCell: UITableViewCell {
    
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
        
        statusLabel.layer.cornerRadius = 14
        statusLabel.clipsToBounds = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        dotView.layer.cornerRadius = dotView.bounds.height / 2
    }
}
