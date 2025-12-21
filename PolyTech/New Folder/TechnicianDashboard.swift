//
//  TechnicianDashboard.swift
//  PolyTech
//
//  Created by BP-19-130-11 on 15/12/2025.
//

import UIKit

class TechnicianDashboard: UIViewController {

    @IBOutlet weak var totalRequestsCard: UIView!
    @IBOutlet weak var pendingCard: UIView!
    @IBOutlet weak var inProgressCard: UIView!
    @IBOutlet weak var completedCard: UIView!
    @IBOutlet weak var StatusCard: UIView!
    @IBOutlet weak var taskListButton: UIButton!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUIElements()
    }
    
    func setupUIElements() {
        
        let cornerRadius: CGFloat = 12.0
                
        applyCardStyling(to: totalRequestsCard, cornerRadius: cornerRadius)
        applyCardStyling(to: pendingCard, cornerRadius: cornerRadius)
        applyCardStyling(to: inProgressCard, cornerRadius: cornerRadius)
        applyCardStyling(to: completedCard, cornerRadius: cornerRadius)
        applyCardStyling(to: StatusCard, cornerRadius: cornerRadius)
        
        taskListButton.layer.cornerRadius = 15.0
        
        taskListButton.backgroundColor = UIColor(named: "PrimaryDarkBlue") ?? .systemBlue
        taskListButton.setTitleColor(.white, for: .normal)

    }
    
    
    func applyCardStyling(to view: UIView, cornerRadius: CGFloat) {
        view.layer.cornerRadius = cornerRadius
        
        view.layer.masksToBounds = false
        view.layer.shadowColor = UIColor.gray.cgColor
        view.layer.shadowOpacity = 0.2
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4.0
        
        view.backgroundColor = .white
    }



    @IBAction func taskListButtonTapped(_ sender: UIButton) {
        print("Task List button tapped. Proceeding to tasks view.")
    }
}
