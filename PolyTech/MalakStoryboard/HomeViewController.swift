import UIKit

class HomeViewController: UIViewController {
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    @IBOutlet weak var Notificationbtn: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Notificationbtn.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(notificationTapped))
        Notificationbtn.addGestureRecognizer(tapGesture)
    }
    
    @objc func notificationTapped() {
        let vc = storyboard?.instantiateViewController(withIdentifier: "NotificationsViewController") as! NotificationsViewController
        navigationController?.pushViewController(vc, animated: true)
    }
    
    
    @IBAction func faqButtonTapped(_ sender: UIButton) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "FAQViewController") as! FAQViewController
        navigationController?.pushViewController(vc, animated: true)
    }
    
}
