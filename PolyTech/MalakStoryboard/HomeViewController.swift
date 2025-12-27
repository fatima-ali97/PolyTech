import UIKit

class HomeViewController: UIViewController {
    
    @IBOutlet weak var Notificationbtn: UIImageView!
    @IBOutlet weak var FAQbtn: UIButton!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNotificationButton()
    }
    
    // MARK: - Setup Methods
    private func setupNotificationButton() {
        // Make sure user interaction is enabled
        Notificationbtn.isUserInteractionEnabled = true
        
        // Add tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(notificationTapped))
        Notificationbtn.addGestureRecognizer(tapGesture)
    }
    
    @objc func notificationTapped() {
        // Explicitly load the storyboard that contains NotificationsViewController
        let storyboard = UIStoryboard(name: "NotificationStoryboard", bundle: nil) // Replace "Main" with your storyboard name
        guard let vc = storyboard.instantiateViewController(withIdentifier: "NotificationsViewController") as? NotificationsViewController else {
            print("NotificationsViewController not found in storyboard")
            return
        }
        
        navigationController?.pushViewController(vc, animated: true)
    }
    
    
    @IBAction func faqButtonTapped(_ sender: UIButton) {
        //        print("FAQ button tapped!") // debug log
        //
        //        guard let vc = storyboard?.instantiateViewController(
        //            withIdentifier: "FAQViewController"
        //        ) as? FAQViewController else {
        //            print("Error: FAQViewController not found in storyboard!")
        //            return
        //        }
        //
        //        navigationController?.pushViewController(vc, animated: true)
        //    }
        
        let storyboard = UIStoryboard(name: "FAQ", bundle: nil) // Replace "Main" with your storyboard name
        guard let vc = storyboard.instantiateViewController(withIdentifier: "FAQViewController") as? NotificationsViewController else {
            print("FAQViewController not found in storyboard")
            return
        }
        
        navigationController?.pushViewController(vc, animated: true)
    }
}
