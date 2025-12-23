import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth
class HistoryViewController: UIViewController {
    let db = Firestore.firestore()
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchDataFromFirestore()
    }
    
    @IBAction func ViewDetails(_ sender: UIButton) {
        showViewDetailsPopup()
        fetchDataFromFirestore()    }
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
        fetchDataFromFirestore()
    }
    
    @IBAction func ViewDetails2(_ sender: UIButton) {
        showViewDetailsPopup()
        fetchDataFromFirestore()
    }
    
    @IBAction func ViewDetails3(_ sender: Any) {
        showViewDetailsPopup()
        fetchDataFromFirestore()
    }
    
    @IBAction func ViewDetails4(_ sender: UIButton) {
        showViewDetailsPopup()
        fetchDataFromFirestore()
    }
    
    func fetchDataFromFirestore() {
        db.collection("history").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error.localizedDescription)")
            } else {
                for document in querySnapshot!.documents {
                    // Print document data to the console
                    print("\(document.documentID) => \(document.data())")
                }
            }
        }
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
    

