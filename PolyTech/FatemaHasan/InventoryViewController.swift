import UIKit

class InventoryViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
  //View Buttons
    @IBAction func View1(_ sender: UIButton) {
        showAlert(title: "Details", message: "Showing inventory details.")
    }
    
    @IBAction func V2(_ sender: UIButton) {
        showAlert(title: "Details", message: "Showing inventory details.")
    }
    
    @IBAction func V3(_ sender: UIButton) {
        showAlert(title: "Details", message: "Showing inventory details.")
    }
    
    @IBAction func V4(_ sender: UIButton) {
        showAlert(title: "Details", message: "Showing inventory details.")
    }
    
    @IBAction func V5(_ sender: UIButton) {
        showAlert(title: "Details", message: "Showing inventory details.")
    }
    //Edit Buttons

    @IBAction func Edit1(_ sender: UIButton) {
        performSegue(withIdentifier: "goToEdit", sender: self)
    }
    
    @IBAction func Edit2(_ sender: UIButton) {
        performSegue(withIdentifier: "goToEdit", sender: self)
    }
    
    @IBAction func Edit3(_ sender: UIButton) {
        performSegue(withIdentifier: "goToEdit", sender: self)
    }
    
    @IBAction func Edit4(_ sender: UIButton) {
        performSegue(withIdentifier: "goToEdit", sender: self)
    }
    
    
    @IBAction func Edit5(_ sender: UIButton) {
        performSegue(withIdentifier: "goToEdit", sender: self)
    }
    
    //Delete Buttons
    @IBAction func Delete1(_ sender: UIButton) {
        showAlert(
            title: "Success",
            message: "Request is removed successfully."
        )
    }
    
    @IBAction func Delete2(_ sender: UIButton) {
        showAlert(
            title: "Success",
            message: "Request is removed successfully."
        )
    }
    
    @IBAction func Delete3(_ sender: UIButton) {
        showAlert(
            title: "Success",
            message: "Request is removed successfully."
        )
    }
    
    @IBAction func Delete4(_ sender: UIButton) {
        showAlert(
            title: "Success",
            message: "Request is removed successfully."
        )
    }
    
    @IBAction func Delete5(_ sender: UIButton) {
        showAlert(
            title: "Success",
            message: "Request is removed successfully."
        )
    }
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )

        let ok = UIAlertAction(title: "OK", style: .default)
        alert.addAction(ok)

        present(alert, animated: true)
    }
}
