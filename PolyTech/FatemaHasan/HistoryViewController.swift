import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth

class HistoryViewController: UIViewController {

    let db = Firestore.firestore()

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBOutlet weak var Search: UISearchBar!

    @IBAction func viewDetailsButtonTapped(_ sender: UIButton) {
        fetchHistoryForUserIDs()
    }
    /*
         // Reusable function to open Feedback page
         func openFeedbackPage() {
             let storyboard = UIStoryboard(name: "Feedback", bundle: nil)
             guard let feedbackVC = storyboard.instantiateViewController(
                 withIdentifier: "FeedbackViewController"
             ) as? FeedbackViewController else {
                 print("FeedbackViewController not found")
                 return
             }
             if let navController = self.navigationController {
                 navController.pushViewController(feedbackVC, animated: true)
             } else {
                 present(feedbackVC, animated: true)
             }
         }

         // MARK: - Actions for buttons
         @IBAction func feedbackButtonTapped(_ sender: UIButton) {
             openFeedbackPage()
         }

         @IBAction func Feedback1(_ sender: UIButton) {
             openFeedbackPage()
         }

         @IBAction func Feedback2(_ sender: UIButton) {
             openFeedbackPage()
         }

         @IBAction func Feedback3(_ sender: UIButton) {
             openFeedbackPage()
         }

         @IBAction func Feedback4(_ sender: UIButton) {
             openFeedbackPage()
         }

         @IBAction func Feedback5(_ sender: UIButton) {
             openFeedbackPage()
         }
     
 */

    func fetchHistoryForUserIDs() {
        let userIDs = [
            "7fg0EVpMQUPHR9kgBPEv7mFRgLt1",
            "njeKzS3LdubCZC8tAgrPmGlQtgh1v",
            "uHdeNxV47CZUp6SwM3s1X1GAP3t1",
            "zvyu1FR9kfabqzzb4uHRop3hbgb2"
        ]

        // Fetch documents for all user IDs
        db.collection("history")
            .whereField("userId", in: userIDs)
            .getDocuments { snapshot, error in
                if let error = error {
                    self.showAlert(title: "Error", message: error.localizedDescription)
                    return
                }

                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    self.showAlert(title: "No Data", message: "No history found for the specified users.")
                    return
                }

                // For simplicity, show the first document
                let data = documents[0].data()
                self.showHistoryDetailsPopup(data: data)
            }
    }

    func showHistoryDetailsPopup(data: [String: Any]) {
        let requestName = data["requestName"] as? String ?? "N/A"
        let itemName = data["itemName"] as? String ?? "N/A"
        let category = data["category"] as? String ?? "N/A"
        let location = data["location"] as? String ?? "N/A"

        let message = """
        Request Name: \(requestName)
        Item Name: \(itemName)
        Category: \(category)
        Location: \(location)
        """

        let alert = UIAlertController(title: "History Details", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
    }

    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
    }
}
