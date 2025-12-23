import UIKit

class HomeViewController: UIViewController {
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Hide the navigation bar on the this view controller
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    @IBOutlet weak var Notificationbtn: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
//
//        Notificationbtn.isUserInteractionEnabled = true
//        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(notificationTapped))
//        Notificationbtn.addGestureRecognizer(tapGesture)
    }
    
// change the name of the controller
//    @objc func notificationTapped() {
//          let vc = storyboard?.instantiateViewController(withIdentifier: "NotificationViewController") as! NotificationViewController
//          navigationController?.pushViewController(vc, animated: true)
//      }
    
    
    
    @IBOutlet weak var FAQbtn: UIButton!

    
    
}
