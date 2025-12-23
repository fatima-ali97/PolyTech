import UIKit

class HistoryViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func ViewDetails(_ sender: UIButton) {
        showViewDetailsPopup()
    }
    /*
    @IBAction func Feedbackbtn(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let feedbackVC = storyboard.instantiateViewController(
            withIdentifier: "FeedbackViewController"
        ) as! FeedbackViewController
        
        // Push to Feedback page
        self.navigationController?.pushViewController(feedbackVC, animated: true)
    }
    */
    @IBOutlet weak var Search: UISearchBar!
    
    
    @IBAction func ViewDetails1(_ sender: Any) {
        showViewDetailsPopup()
    }

    @IBAction func ViewDetails2(_ sender: UIButton) {
        showViewDetailsPopup()
    }
    
    @IBAction func ViewDetails3(_ sender: Any) {
        showViewDetailsPopup()
    }
    
    @IBAction func ViewDetails4(_ sender: UIButton) {
        showViewDetailsPopup()
    }
    
    func showViewDetailsPopup() {
        let alert = UIAlertController(
            title: "Details",
            message: "The details:",
            preferredStyle: .alert
        )
        
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        
        self.present(alert, animated: true, completion: nil)
    }
}


