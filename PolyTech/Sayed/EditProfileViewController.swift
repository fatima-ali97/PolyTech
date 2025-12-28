//
//  EditProfileViewController.swift
//  PolyTech
//
//  Created by BP-36-212-01 on 22/12/2025.
//

import UIKit

class EditProfileViewController: UIViewController {

    @IBOutlet weak var fullNameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var addressTextField: UITextField!
    @IBOutlet weak var changePasswordButton: UIButton!
    @IBOutlet weak var saveChangesButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTextFieldsUI()
    }
    
    func setupTextFieldsUI() {
        let allTextFields = [
            fullNameTextField,
            emailTextField,
            phoneTextField,
            usernameTextField,
            addressTextField
        ]
        
        for textField in allTextFields {
            guard let field = textField else { continue }
            
            field.layer.cornerRadius = 12.0
            
            field.layer.borderColor = UIColor.black.cgColor
            field.layer.borderWidth = 1.0
            
            field.layer.masksToBounds = true
            
            let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: field.frame.height))
            field.leftView = paddingView
            field.leftViewMode = .always
        }
    }
    
    func setupButtonUI() {
        changePasswordButton.layer.masksToBounds = true
        changePasswordButton.backgroundColor = .clear
        
        saveChangesButton.layer.masksToBounds = true
    }
}
