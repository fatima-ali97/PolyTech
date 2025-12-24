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
     /* func openFeedbackPage() {
        let storyboard = UIStoryboard(name: "Feedback", bundle: nil)

        let feedbackVC = storyboard.instantiateViewController(
            withIdentifier: "FeedbackViewController"
        ) as! FeedbackViewController

        self.navigationController?.pushViewController(feedbackVC, animated: true)
    }
    @IBAction func feedbackButtonTapped(_ sender: UIButton) {
        openFeedbackPage()
    }

    func openFeedbackPage() {
        let storyboard = UIStoryboard(name: "Feedback", bundle: nil)
        let feedbackVC = storyboard.instantiateViewController(withIdentifier: "FeedbackViewController") as! FeedbackViewController
        self.navigationController?.pushViewController(feedbackVC, animated: true)
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
    
    @IBOutlet weak var Search: UISearchBar!
    
    
    @IBAction func ViewDetails1(_ sender: Any) {
       
        fetchDataFromFirestore()
    }
    
    @IBAction func ViewDetails2(_ sender: UIButton) {
   
        fetchDataFromFirestore()
    }
    
    @IBAction func ViewDetails3(_ sender: Any) {
      
        fetchDataFromFirestore()
    }
    
    @IBAction func ViewDetails4(_ sender: UIButton) {
       
        fetchDataFromFirestore()
    }
    
    func fetchDataFromFirestore() {
           db.collection("history").getDocuments { (querySnapshot, error) in
               if let error = error {
                   print("Error getting documents: \(error.localizedDescription)")
                   return
               }

               guard let documents = querySnapshot?.documents,
                     let firstDocument = documents.first else {
                   print("No history data found")
                   return
               }

               let data = firstDocument.data()
               self.showViewDetailsPopup(data: data)
           }
       }
    func showViewDetailsPopup(data: [String: Any]){
            
            let requestName = data["requestName"] as? String ?? "N/A"
            let itemName = data["itemName"] as? String ?? "N/A"
            let category = data["category"] as? String ?? "N/A"
            let location = data["location"] as? String ?? "N/A"
            let reason = data["reason"] as? String ?? "N/A"

            let message = """
            Request Name: \(requestName)
            Item Name: \(itemName)
            Category: \(category)
            Location: \(location)
            Reason: \(reason)
            """

            let alert = UIAlertController(
                title: "Details",
                message: message,
                preferredStyle: .alert
            )

            let okAction = UIAlertAction(title: "OK", style: .default)
            alert.addAction(okAction)

            self.present(alert, animated: true)
        }
    }
    

