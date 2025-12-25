//
//  ProfileViewController.swift
//  PolyTech
//
//  Created by BP-36-212-01 on 21/12/2025.
//

import UIKit

class ProfileViewController: UIViewController {

    @IBOutlet weak var actionButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupButtonUI()
    }
    
    func setupButtonUI() {
        let customColor = UIColor(red: 22/255, green: 42/255, blue: 68/255, alpha: 1.0)
        
        actionButton.layer.masksToBounds = true
        actionButton.backgroundColor = .clear
        actionButton.setTitleColor(.systemBlue, for: .normal)
    }
}
