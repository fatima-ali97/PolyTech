import UIKit
import FirebaseFirestore
import FirebaseAuth

class ReturnInventoryViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    var itemToEdit: Inventory?
    @IBOutlet weak var itemName: UITextField!
    @IBOutlet weak var category: UITextField!
    @IBOutlet weak var quantity: UITextField!
    @IBOutlet weak var reason: UITextField!
    @IBOutlet weak var condition: UITextField!
    @IBOutlet weak var returnbtn: UIButton!
    @IBOutlet weak var pageTitle: UILabel!
    @IBOutlet weak var backBtn: UIImageView!
    @IBOutlet weak var categoryDropDown: UIImageView!
    
    let database = Firestore.firestore()
    let categories = ["electronics", "laboratory", "classroom"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pageTitle.text = "New Return Inventory"
        returnbtn.setTitle("Save", for: .normal)

        // Set the delegate for the quantity text field
        quantity.delegate = self
        
        // Set the keyboard type for the quantity text field to number pad
        quantity.keyboardType = .numberPad
        
        setupBackBtnButton()
        setupCategoryPicker()
    }
    
    private func setupBackBtnButton() {
        backBtn.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backBtnTapped))
        backBtn.addGestureRecognizer(tapGesture)
    }
    
    @objc func backBtnTapped() {
        let storyboard = UIStoryboard(name: "HomePage", bundle: nil)
        guard let vc = storyboard.instantiateViewController(withIdentifier: "HomeViewController") as? HomeViewController else {
            print("HomeViewController not found in storyboard")
            return
        }
        
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func setupCategoryPicker() {
        let categoryPicker = UIPickerView()
        categoryPicker.delegate = self
        categoryPicker.dataSource = self
        category.inputView = categoryPicker

        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(donePickingCategory))
        toolbar.setItems([doneButton], animated: true)
        category.inputAccessoryView = toolbar
    }
    
    @objc func donePickingCategory() {
        view.endEditing(true)
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return categories.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return categories[row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        category.text = categories[row]
    }

    @IBAction func Returnbtn(_ sender: UIButton) {
        guard
            let itemNameText = itemName.text, !itemNameText.isEmpty,
            let categoryText = category.text, !categoryText.isEmpty,
            let quantityText = quantity.text, let quantityValue = Int(quantityText),
            let reasonText = reason.text, !reasonText.isEmpty,
            let conditionText = condition.text, !conditionText.isEmpty
        else {
            let alert = UIAlertController(
                title: "Error",
                message: "Please fill in all fields correctly",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        let data: [String: Any] = [
            "itemName": itemNameText,
            "category": categoryText,
            "quantity": quantityValue,
            "reason": reasonText,
            "condition": conditionText,
            "createdAt": Timestamp()
        ]
        
        database.collection("returnInventoryRequest").addDocument(data: data) { [weak self] error in
            self?.handleResult(error: error, successMessage: "Return inventory saved successfully")
        }
    }
    
    func handleResult(error: Error?, successMessage: String) {
        if let error = error {
            let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        } else {
            let alert = UIAlertController(title: "Success", message: successMessage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                self.navigationController?.popViewController(animated: true)
            })
            present(alert, animated: true)
        }
    }
    
    // UITextFieldDelegate method to restrict input to numbers only
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Allow only digits, backspace, and other control characters
        let allowedCharacters = CharacterSet(charactersIn: "0123456789")
        let characterSet = CharacterSet(charactersIn: string)
        return allowedCharacters.isSuperset(of: characterSet) || string.isEmpty
    }
}
