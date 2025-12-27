import UIKit

struct Message {
    let text: String
    let isUser: Bool
}

final class ChatBotViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextField: UITextField!

    private var messages: [Message] = []

    private var menuText: String {
        return """
        Hi 👋 I can help with these topics. Reply with a number:

        1) Moodle login / access
        2) Banner login
        3) Reset password
        4) Wi-Fi / Internet on campus
        5) Contact IT / Get Help

        Type 0 to see this menu again.
        """
    }

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

        messages = [Message(text: menuText, isUser: false)]
        reloadAndScrollToBottom()
    }

    @IBAction func sendButtonTapped(_ sender: UIButton) {
        sendMessage()
    }

    private func sendMessage() {
        let rawText = messageTextField.text ?? ""
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        messages.append(Message(text: text, isUser: true))
        messageTextField.text = ""
        reloadAndScrollToBottom()

        let reply = botReply(for: text)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            self.messages.append(Message(text: reply, isUser: false))
            self.reloadAndScrollToBottom()
        }
    }

    private func normalize(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = trimmed.lowercased()
        let cleaned = lower.components(separatedBy: CharacterSet.alphanumerics.inverted).joined()
        return cleaned
    }

    private func botReply(for input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = normalize(input)

      
        if let choice = Int(trimmed) {
            switch choice {
            case 0:
                return menuText

            case 1:
                return """
                Moodle login ✅
                1) Go to Bahrain Polytechnic website.
                2) Scroll down and tap Moodle.
                3) Choose Student login.
                4) Enter your username & password.

                Need help with username/password? Reply: 3 (Reset password) or 5 (Contact IT).
                """

            case 2:
                return """
                Banner login ✅
                1) Go to Bahrain Polytechnic website.
                2) Tap Banner.
                3) Enter your Student ID + password.

                If it says wrong password, reply: 3 (Reset password).
                """

            case 3:
                return """
                Reset password 🔐
                Tell me which account you mean:
                1) Moodle
                2) Banner

                Reply with: "3-1" for Moodle reset or "3-2" for Banner reset.
                """

            case 4:
                return """
                Wi-Fi / Internet 📶
                Try this:
                1) Turn Wi-Fi off/on.
                2) Forget the network then re-join.
                3) Restart your phone/laptop.

                If it still doesn’t work, reply: 5 (Contact IT) and tell me your device (iPhone/Android/Laptop).
                """

            case 5:
                return """
                Contact IT / Get Help 🧑‍💻
                You can use the Get Help page in the app.
                If you tell me your issue (Moodle/Banner/Wi-Fi), I’ll guide you step-by-step.

                Type 0 to see the menu again.
                """

            default:
                return "I don’t have that option. Reply with 0 to see the menu."
            }
        }


        if normalized == "31" {
            return """
            Moodle reset 🔐
            1) Open Moodle login page.
            2) Tap “Forgot password?” (if available).
            3) Enter your student email/username.
            4) Check your email and follow the reset link.

            If you don’t receive an email, reply: 5 (Contact IT).
            """
        }

        if normalized == "32" {
            return """
            Banner reset 🔐
            Usually this is handled by IT / student services.
            Reply: 5 (Contact IT) and I’ll tell you what info to include (Student ID + issue screenshot).
            """
        }

        // 3) Keyword fallback (ignores upper/lower + punctuation)
        if normalized.contains("menu") || normalized.contains("options") {
            return menuText
        }

        if normalized.contains("moodle") {
            return "For Moodle help, reply 1. Type 0 to see all options."
        }

        if normalized.contains("banner") {
            return "For Banner help, reply 2. Type 0 to see all options."
        }

        if normalized.contains("password") || normalized.contains("reset") || normalized.contains("forgot") {
            return "For password reset, reply 3. Type 0 to see all options."
        }

        if normalized.contains("wifi") || normalized.contains("internet") || normalized.contains("network") {
            return "For Wi-Fi help, reply 4. Type 0 to see all options."
        }

        if normalized.contains("help") || normalized.contains("it") || normalized.contains("support") {
            return "To contact IT / Get Help, reply 5. Type 0 to see all options."
        }

        if normalized.contains("hello") || normalized.contains("hi") || normalized.contains("hey") {
            return menuText
        }

        return "Reply with a number (0–5) so I can help you faster. Type 0 to see the menu."
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
        messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatCell", for: indexPath)

        let msg = messages[indexPath.row]
        cell.textLabel?.text = msg.text
        cell.textLabel?.numberOfLines = 0
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
