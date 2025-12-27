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

    private func setupNotificationButton() {

        Notificationbtn.isUserInteractionEnabled = true

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(notificationTapped))
        Notificationbtn.addGestureRecognizer(tapGesture)
    }
    
    @objc func notificationTapped() {

        let storyboard = UIStoryboard(name: "NotificationStoryboard", bundle: nil)
        guard let vc = storyboard.instantiateViewController(withIdentifier: "NotificationsViewController") as? NotificationsViewController else {
            print("NotificationsViewController not found in storyboard")
            return
        }
        
        navigationController?.pushViewController(vc, animated: true)
    }
    
    
    @IBAction func faqButtonTapped(_ sender: UIButton) {
        print("FAQ button tapped!") // Debugging log
        
        let storyboard = UIStoryboard(name: "FAQ", bundle: nil) // Replace "FAQ" with your actual storyboard name
        
        guard let vc = storyboard.instantiateViewController(withIdentifier: "FAQViewController") as? FAQViewController else {
            print("FAQViewController not found in storyboard")
            return
        }
        
        // Confirm if the controller is correctly instantiated
        print("FAQViewController successfully instantiated")
        
        navigationController?.pushViewController(vc, animated: true)
    }
    }

