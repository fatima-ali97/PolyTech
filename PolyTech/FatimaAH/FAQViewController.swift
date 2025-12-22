//
//  FAQViewController.swift
//  PolyTech
//
//  Created by BP-19-130-12 on 21/12/2025.
//
import UIKit
import FirebaseFirestore
struct FAQItem {
    let question: String
    let answer: String
    var isExpanded: Bool
}

final class FAQViewController: UIViewController {

    @IBOutlet weak var searchBar: UISearchBar!

    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var getHelpTapped: UIButton!
    @IBAction func getHelpTapped(_ sender: UIButton) {
        let sb = UIStoryboard(name: "HelpPage", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "HelpPageVC")

    
        navigationController?.pushViewController(vc, animated: true)

    }
    private var faqs: [FAQItem] = [
        FAQItem(question: "Banner login",
                answer: "1) Go to the Bahrain Polytechnic website.\n2) Click Banner.\n3) Enter your student ID and password.",
                isExpanded: false),

        FAQItem(question: "Authenticator App setup",
                answer: "1) Install Google Authenticator.\n2) Scan the QR code.\n3) Enter the 6-digit code to confirm.",
                isExpanded: false),

        FAQItem(question: "VMware virtual machine Starting Error",
                answer: "1) Open VMware.\n2) Check the VM settings.\n3) Make sure the VM files path is correct.",
                isExpanded: false),

        FAQItem(question: "Password reset on computer",
                answer: "1) Open the reset page.\n2) Enter your student ID.\n3) Follow the steps to set a new password.",
                isExpanded: false),

        FAQItem(question: "Moodle login",
                answer: "1) Go to Moodle.\n2) Enter your credentials.\n3) If locked, reset your password.",
                isExpanded: false)
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "FAQs"

        tableView.dataSource = self
        tableView.delegate = self
        searchBar.delegate = self

        tableView.estimatedRowHeight = 60
        tableView.rowHeight = UITableView.automaticDimension
    }
}

extension FAQViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return faqs.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Use a Subtitle cell style OR add your own labels
        let cell = tableView.dequeueReusableCell(withIdentifier: "FAQCell", for: indexPath)

        let item = faqs[indexPath.row]
        cell.textLabel?.text = item.question
        cell.textLabel?.numberOfLines = 1

        // Show answer only when expanded
        cell.detailTextLabel?.text = item.isExpanded ? item.answer : nil
        cell.detailTextLabel?.numberOfLines = 0

        // Chevron
        let iconName = item.isExpanded ? "chevron.up" : "chevron.down"
        cell.accessoryView = UIImageView(image: UIImage(systemName: iconName))

        cell.selectionStyle = .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        faqs[indexPath.row].isExpanded.toggle()
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}

extension FAQViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // optional later (filtering)
    }
}
