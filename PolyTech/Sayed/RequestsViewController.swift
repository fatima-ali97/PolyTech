//
//  RequestsViewController.swift
//  PolyTech
//
//  Created by BP-36-212-01 on 31/12/2025.
//

import UIKit
import FirebaseFirestore

class RequestsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.separatorStyle = .none
        
        tableView.dataSource = self
        tableView.delegate = self
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RequestCell", for: indexPath)
        
        if let cardView = cell.viewWithTag(200) {
            cardView.layer.borderColor = UIColor.systemGray4.cgColor
            cardView.layer.borderWidth = 1.0
            cardView.layer.cornerRadius = 12
            
            cardView.layer.shadowColor = UIColor.black.cgColor
            cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
            cardView.layer.shadowRadius = 4
            cardView.layer.shadowOpacity = 0.1
            cardView.layer.masksToBounds = false
        }

        if let titleLabel = cell.viewWithTag(101) as? UILabel {
            titleLabel.text = "Computer maintenance request"
        }
        
        cell.selectionStyle = .none
        
        return cell
    }
}
