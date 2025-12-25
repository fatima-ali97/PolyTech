//
//  EditProfileViewController.swift
//  PolyTech
//
//  Created by BP-36-212-01 on 22/12/2025.
//

import UIKit

class EditProfileViewController: UIViewController {

    // 1. ربط الحقول الخمسة من الـ Storyboard
    @IBOutlet weak var fullNameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var addressTextField: UITextField!
    @IBOutlet weak var changePasswordButton: UIButton!
    @IBOutlet weak var saveChangesButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 2. استدعاء دالة التنسيق
        setupTextFieldsUI()
    }
    
    func setupTextFieldsUI() {
        // نضع جميع الحقول في مصفوفة (Array) لنطبق التنسيق عليها جميعاً مرة واحدة بدل تكرار الكود
        let allTextFields = [
            fullNameTextField,
            emailTextField,
            phoneTextField,
            usernameTextField,
            addressTextField
        ]
        
        for textField in allTextFields {
            // التأكد أن الحقل مربوط وليس nil لتجنب الـ Fatal Error
            guard let field = textField else { continue }
            
            // ضبط الانحناء (Radius)
            field.layer.cornerRadius = 12.0
            
            // ضبط لون الحدود (أسود) وعرضها
            field.layer.borderColor = UIColor.black.cgColor
            field.layer.borderWidth = 1.0
            
            // تفعيل القص لضمان ظهور الانحناء
            field.layer.masksToBounds = true
            
            // إضافة مسافة بادئة صغيرة (Padding) لكي لا يلتصق النص بالحافة اليسرى
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
