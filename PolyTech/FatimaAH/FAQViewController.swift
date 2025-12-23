//
//  FAQViewController.swift
//  PolyTech
//
//  Created by BP-19-130-12 on 21/12/2025.
//

import UIKit
import FirebaseFirestore
struct FAQItem {
    let id: String
    let title: String
    let desc: String
    var isExpanded: Bool = false
}

final class FAQViewController: UIViewController {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var getHelpTapped: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func getHelpTapped(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "HelpPage", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "HelpPageVC")
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private let db = Firestore.firestore()

    private var allFAQs: [FAQItem] = []
    private var shownFAQs: [FAQItem] = []
    private var isSearching = false

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "FAQs"

        tableView.dataSource = self
        tableView.delegate = self
        searchBar.delegate = self

        // Dynamic height
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60

        fetchFAQs()
    }

    private func fetchFAQs() {
        db.collection("FAQ").getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }

            if let error = error {
                print("🔥 Firestore error:", error.localizedDescription)
                return
            }

            guard let docs = snapshot?.documents else { return }

            var temp: [FAQItem] = docs.compactMap { doc in
                let data = doc.data()
                let title = data["Title"] as? String ?? ""
                let desc  = data["Description"] as? String ?? ""
                return FAQItem(id: doc.documentID, title: title, desc: desc, isExpanded: false)
            }

           
            temp.sort {
                (Int($0.id) ?? 999999) < (Int($1.id) ?? 999999)
            }

            self.allFAQs = temp
            self.shownFAQs = temp
            self.tableView.reloadData()
        }
    }

    private func updateChevron(for cell: UITableViewCell, expanded: Bool) {
        let iconName = expanded ? "chevron.up" : "chevron.down"
        let imageView = UIImageView(image: UIImage(systemName: iconName))
        imageView.tintColor = .systemGray
        cell.accessoryView = imageView
    }
}

extension FAQViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return shownFAQs.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "FAQCell", for: indexPath)

        let item = shownFAQs[indexPath.row]
        cell.textLabel?.text = item.title
        cell.textLabel?.numberOfLines = 0

        if item.isExpanded {
            cell.detailTextLabel?.text = item.desc
            cell.detailTextLabel?.numberOfLines = 0
        } else {
            cell.detailTextLabel?.text = nil
        }

        cell.selectionStyle = .none
        updateChevron(for: cell, expanded: item.isExpanded)

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        shownFAQs[indexPath.row].isExpanded.toggle()


        if let originalIndex = allFAQs.firstIndex(where: { $0.id == shownFAQs[indexPath.row].id }) {
            allFAQs[originalIndex].isExpanded = shownFAQs[indexPath.row].isExpanded
        }

        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}

extension FAQViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let text = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        if text.isEmpty {
            isSearching = false
            shownFAQs = allFAQs
        } else {
            isSearching = true
            shownFAQs = allFAQs.filter {
                $0.title.localizedCaseInsensitiveContains(text) ||
                $0.desc.localizedCaseInsensitiveContains(text)
            }
        }

        tableView.reloadData()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
