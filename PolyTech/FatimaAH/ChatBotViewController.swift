//
//  ChatBotViewController.swift
//  PolyTech
//
//  Created by zahra ismaeel on 22/12/2025.
//

import UIKit

struct Message {
    let text: String
    let isUser: Bool
}

final class ChatBotViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextField: UITextField!

    private var messages: [Message] = [
        Message(text: "Hi 👋 How can I help you?", isUser: false)
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Chat Bot"

        tableView.dataSource = self
        tableView.delegate = self

        tableView.keyboardDismissMode = .interactive
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableView.automaticDimension

        messageTextField.delegate = self

        reloadAndScrollToBottom()
    }

    @IBAction func sendButtonTapped(_ sender: UIButton) {
        sendMessage()
    }

    private func sendMessage() {
        let text = (messageTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        // Add user message
        messages.append(Message(text: text, isUser: true))
        messageTextField.text = ""
        reloadAndScrollToBottom()

        let reply = botReply(for: text)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.messages.append(Message(text: reply, isUser: false))
            self.reloadAndScrollToBottom()
        }
    }

    private func botReply(for text: String) -> String {
        let lower = text.lowercased()

        if lower.contains("hello") || lower.contains("hi") {
            return "Hello! 😊 Ask me anything."
        } else if lower.contains("faq") {
            return "You can check FAQs for common problems. What topic do you need?"
        } else if lower.contains("banner") {
            return "For Banner login: Go to Bahrain Polytechnic website → Banner → enter your ID and password."
        } else if lower.contains("help") {
            return "If you need help, tap the Help page from your app (or tell me what you need)."
        } else {
            return "I got you. Can you explain a bit more?"
        }
    }

    private func reloadAndScrollToBottom() {
        tableView.reloadData()
        guard !messages.isEmpty else { return }
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }
}

extension ChatBotViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath)

        let msg = messages[indexPath.row]
        cell.textLabel?.text = msg.text
        cell.textLabel?.numberOfLines = 0

        // Simple alignment
        cell.textLabel?.textAlignment = msg.isUser ? .right : .left
        cell.selectionStyle = .none
        cell.backgroundColor = .clear

        return cell
    }
}
extension ChatBotViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendMessage()
        return true
    }
}
