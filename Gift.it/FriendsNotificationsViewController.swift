import UIKit
import FirebaseAuth
import FirebaseFirestore
import Foundation

class FriendsNotificationsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, FriendsNotificationsCellDelegate {

    @IBOutlet weak var tableView: UITableView!

    let db = Firestore.firestore()
    let uid = Auth.auth().currentUser!.uid
    var notifications: [Notification] = []
    var username: String?
    var notificationsListener: ListenerRegistration?

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 80
        addNotificationsListener() // Add the listener
    }

    deinit {
        notificationsListener?.remove() // Clean up the listener when the view controller is deallocated
    }

    func addNotificationsListener() {
        notificationsListener = db.collection("users").document(uid).addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            if let error = error {
                print("Error listening to notifications: \(error)")
                return
            }
            
            guard let data = snapshot?.data() else { return }
            self.username = data["username"] as? String ?? ""
            if let notificationsData = data["notifications"] as? [[String: Any]] {
                self.notifications = notificationsData.compactMap { Notification(dictionary: $0) }
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }
    }

    // Number of rows in section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notifications.count
    }

    // Configure the cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FriendsNotificationsCell", for: indexPath) as! FriendsNotificationsCell
        let notif = notifications[indexPath.row]
        cell.notif = notif
        cell.notifLabel.text = notif.message
        cell.delegate = self // Set the delegate
        return cell
    }

    func acceptFriendRequest(notif: Notification) {
        // Existing implementation of `acceptFriendRequest`...
        let currentUserId = uid
        let db = Firestore.firestore()

        db.collection("users").document(currentUserId).updateData([
            "friendsList": FieldValue.arrayUnion([notif.from])
        ]) { [weak self] error in
            if let error = error {
                print("Error adding friend to current user's friendsList: \(error)")
                return
            }

            db.collection("users").document(notif.from).updateData([
                "friendsList": FieldValue.arrayUnion([currentUserId])
            ]) { error in
                if let error = error {
                    print("Error adding current user to recipient's friendsList: \(error)")
                    return
                }

                if notif.type == "requestNotif" {
                    let approvalNotification = Notification(
                        type: "friendApproval",
                        from: currentUserId,
                        message: "\(self?.username ?? "Someone") has approved your friend request."
                    )

                    db.collection("users").document(notif.from).updateData([
                        "notifications": FieldValue.arrayUnion([approvalNotification.toDictionary()])
                    ]) { error in
                        if let error = error {
                            print("Error sending approval notification: \(error)")
                        }
                    }
                }

                db.collection("users").document(currentUserId).updateData([
                    "notifications": FieldValue.arrayRemove([notif.toDictionary()])
                ]) { error in
                    if let error = error {
                        print("Error removing notification: \(error)")
                    }
                }
            }
        }
    }

    func deleteFriendRequest(notif: Notification) {
        db.collection("users").document(uid).updateData([
            "notifications": FieldValue.arrayRemove([notif.toDictionary()])
        ]) { [weak self] error in
            if let error = error {
                print("Error removing notification: \(error)")
            }
        }
    }
}

class Notification {
    var type: String    // The type of notification (e.g., "friendRequest")
    var from: String    // The ID of the user who sent the notification
    var message: String // The notification message to be displayed

    init(type: String, from: String, message: String) {
        self.type = type
        self.from = from
        self.message = message
    }

    // Initialize from a Firestore dictionary
    convenience init?(dictionary: [String: Any]) {
        guard let type = dictionary["type"] as? String,
              let from = dictionary["from"] as? String,
              let message = dictionary["message"] as? String else { return nil }

        self.init(type: type, from: from, message: message)
    }

    // Convert to a dictionary to store in Firestore
    func toDictionary() -> [String: Any] {
        return [
            "type": type,
            "from": from,
            "message": message
        ]
    }
}
