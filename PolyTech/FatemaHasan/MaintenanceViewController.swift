import UIKit

class MaintenanceViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
  //View Buttons
    
    @IBAction func View1(_ sender: Any) {
        showAlert1(title: "Details", message: "Showing inventory details.")
    }
    
    @IBAction func View2(_ sender: UIButton) {
        showAlert1(title: "Details", message: "Showing inventory details.")
    }
    
    @IBAction func View3(_ sender: UIButton) {
        showAlert1(title: "Details", message: "Showing inventory details.")
    }
    
    @IBAction func View4(_ sender: UIButton) {
        showAlert1(title: "Details", message: "Showing inventory details.")
    }
    
    @IBAction func View5(_ sender: UIButton) {
        showAlert1(title: "Details", message: "Showing inventory details.")
    }
    //Edit Buttons
    @IBAction func Ed1(_ sender: UIButton) {
        performSegue(withIdentifier: "goToEdit", sender: self)   }
    
    @IBAction func ED2(_ sender: UIButton) { performSegue(withIdentifier: "goToEdit", sender: self)
    }

    @IBAction func ED3(_ sender: UIButton) { performSegue(withIdentifier: "goToEdit", sender: self)
    }
    @IBAction func Ed4(_ sender: UIButton) { performSegue(withIdentifier: "goToEdit", sender: self)
    }
    
    @IBAction func Ed5(_ sender: UIButton) { performSegue(withIdentifier: "goToEdit", sender: self)
    }
    //Delete
    @IBAction func D1(_ sender: UIButton) {
        showAlert1(
            title: "Success",
            message: "Request is removed successfully."
        )
    }
    
    @IBAction func D2(_ sender: UIButton) {
        showAlert1(
            title: "Success",
            message: "Request is removed successfully."
        )
    }
    
    @IBAction func D3(_ sender: UIButton) {
        showAlert1(
            title: "Success",
            message: "Request is removed successfully."
        )
    }
    
    @IBAction func D4(_ sender: UIButton) {
        showAlert1(
            title: "Success",
            message: "Request is removed successfully."
        )
    }
    
    @IBAction func D5(_ sender: UIButton) {
        showAlert1(
            title: "Success",
            message: "Request is removed successfully."
        )
    }
    func showAlert1(title: String, message: String) {
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
