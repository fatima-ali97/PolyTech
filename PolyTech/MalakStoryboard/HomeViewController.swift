import UIKit

class HomeViewController: UIViewController {

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
//          let vc = storyboard?.instantiateViewController(withIdentifier: "NotificationVC") as! NotificationViewController
//          navigationController?.pushViewController(vc, animated: true)
//      }
    
    @IBAction func FAQbtn(_ sender: UIButton) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "FAQVC") as! FAQViewController
        navigationController?.pushViewController(vc, animated: true)
    }
    
}
