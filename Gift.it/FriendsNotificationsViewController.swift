//
//  FriendsNotificationsViewController.swift
//  Gift.it
//
//  Created by Qianyu Chen on 11/13/24.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import Foundation

class FriendsNotificationsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, FriendsNotificationsCellDelegate{
    
    
    @IBOutlet weak var tableView: UITableView!
    
    
    let db = Firestore.firestore()
    let uid = Auth.auth().currentUser!.uid

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 80
        fetchNotifications()
    }
    
    var notifications: [Notification] = []
    var username: String?

    func fetchNotifications() {
        let db = Firestore.firestore()
        
        db.collection("users").document(uid).getDocument { [weak self] document, error in
            if let error = error {
                print("Error fetching notifications: \(error)")
                return
            }
            
            if let data = document?.data(),
               let notificationsData = data["notifications"] as? [[String: Any]] {
                self?.username = data["username"] as? String ?? ""
                self?.notifications = notificationsData.compactMap { Notification(dictionary: $0) }
                self?.tableView.reloadData()
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
        let db = Firestore.firestore()
        
        let currentUserId = uid
        
        // Add the recipient (notif.from) to the current user's friendsList
        db.collection("users").document(currentUserId).updateData([
            "friendsList": FieldValue.arrayUnion([notif.from])
        ]) { [weak self] error in
            if let error = error {
                print("Error adding friend to current user's friendsList: \(error)")
                return
            }
            
            // Add the current user to the recipient's friendsList
            db.collection("users").document(notif.from).updateData([
                "friendsList": FieldValue.arrayUnion([currentUserId])
            ]) { error in
                if let error = error {
                    print("Error adding current user to recipient's friendsList: \(error)")
                    return
                }
                
                // Send approval notification to the recipient
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
                
                // Remove the notification from Firestore and the local list
                db.collection("users").document(currentUserId).updateData([
                    "notifications": FieldValue.arrayRemove([notif.toDictionary()])
                ]) { [weak self] error in
                    if let error = error {
                        print("Error removing notification: \(error)")
                    } else {
                        // Remove the notification from the local list and UI
                        if let index = self?.notifications.firstIndex(where: { $0.from == notif.from }) {
                            self?.notifications.remove(at: index)
                        }
                    }
                }
            }
        }
    }

    
    func deleteFriendRequest(notif: Notification){
        
        // Remove the notification from Firestore and the local list
        db.collection("users").document(self.uid).updateData([
            "notifications": FieldValue.arrayRemove([notif.toDictionary()])
        ]) { [weak self] error in
            if let error = error {
                print("Error removing notification: \(error)")
            } else {
                // Remove the notification from the local list and UI
                if let index = self?.notifications.firstIndex(where: { $0.from == notif.from }) {
                    self?.notifications.remove(at: index)
                }
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



