//
//  HelpPageViewController.swift
//  PolyTech
//
//  Created by BP-19-130-12 on 27/12/2025.
//

import UIKit

class HelpPageViewController: UIViewController {

    @IBOutlet weak var backbtn: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpBackBtn()

        // Do any additional setup after loading the view.
    }
    private func setUpBackBtn() {

        backbtn.isUserInteractionEnabled = true

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backbtnTapped))
        backbtn.addGestureRecognizer(tapGesture)
    }
    @objc func backbtnTapped() {

        let storyboard = UIStoryboard(name: "FAQ", bundle: nil)
        guard let vc = storyboard.instantiateViewController(withIdentifier: "FAQViewController") as? FAQViewController else {
            print("FAQViewController not found in storyboard")
            return
        }
        
        navigationController?.pushViewController(vc, animated: true)
    }
    

}
