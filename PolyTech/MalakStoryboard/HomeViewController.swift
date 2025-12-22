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
    
    
       

        
    @IBOutlet weak var FAQbtn: UIButton!
    
            @IBAction func FAQbtn(_ sender: UIButton) {

                let sb = UIStoryboard(name: "FAQ", bundle: nil)
                let faqNav = sb.instantiateViewController(withIdentifier: "FAQNavController")

                self.navigationController?.pushViewController(faqNav, animated: true)
            }

        
    
}
