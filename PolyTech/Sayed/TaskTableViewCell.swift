//
//  TaskTableViewCell.swift
//  PolyTech
//
//  Created by BP-36-212-02 on 14/12/2025.
//

import UIKit

class TaskTableViewCell: UITableViewCell {
    
    weak var delegate: TaskCellDelegate?
    
    @IBOutlet weak var taskIdLabel: UILabel!
    @IBOutlet weak var clientLabel: UILabel!
    @IBOutlet weak var dueDateLabel: UILabel!
    @IBOutlet weak var statusBtn: UIButton!
    

    @IBAction func viewDetailsButtonTapped(_ sender: UIButton) {
        delegate?.didTapViewDetails(on: self)
    }
    
    @IBAction func statusButtonTapped(_ sender: UIButton) {
        delegate?.didTapStatusButton(on: self)
    }
}
