//
//  ProfileViewController.swift
//  PolyTech
//
//  Created by BP-36-212-01 on 21/12/2025.
//

import UIKit

class ProfileViewController: UIViewController {

    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupButtonUI()
        setupScrollViewUI()
    }
    
    func setupButtonUI() {
        let customColor = UIColor(red: 22/255, green: 42/255, blue: 68/255, alpha: 1.0)
        
        actionButton.layer.masksToBounds = true
        actionButton.backgroundColor = .clear
        actionButton.setTitleColor(.systemBlue, for: .normal)
    }
    
    func setupScrollViewUI() {
            scrollView.contentInsetAdjustmentBehavior = .never
            scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 1050, right: 0)
        }
    
}
