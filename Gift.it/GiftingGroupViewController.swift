//
//  GiftingGroupViewController.swift
//  Gift.it
//
//  Created by Qianyu Chen on 11/9/24.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class GiftingGroupViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var bellIcon: UIButton!
    
    let db = Firestore.firestore()
    
    var giftingGroups: [(name: String, chatID: String)] = [
            ("Pog Group", "chat1"),
            ("Donkey Group", "chat2"),
            ("Shrek Group", "chat3")
        ]

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        checkFriendsForUpcomingBirthdays()
        checkForPendingInvitations()
    }
    
    // Number of rows in section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return giftingGroups.count
        }
        
        // Configure the cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ChatCell", for: indexPath)
            
            cell.textLabel?.font = UIFont(name: "Courier New Bold", size: 20)
            
            let group = giftingGroups[indexPath.row]
            cell.textLabel?.text = group.name // Set the cell's text label to the group name
            
            return cell
        }
    
    // Handle cell selection (segue to the chat screen)
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//            let selectedGroup = giftingGroups[indexPath.row]
//            
//            // Perform a segue to the chat screen
//            performSegue(withIdentifier: "ChatSegue", sender: selectedGroup)
//        }
    
    // Prepare for segue to the chat screen
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if segue.identifier == "ChatSegue" {
                if let chatVC = segue.destination as? ChatViewController,
                   let selectedGroup = sender as? (name: String, chatID: String) {
                    // Pass the selected group data (chatID) to the ChatViewController
//                    chatVC.chatID = selectedGroup.chatID
                }
            }
        }
    
    //TODO DELETE GROUPS
    func isBirthdayWithinNextMonth(birthday: Date) -> Bool {
        let today = Date()
        let calendar = Calendar.current
        guard let oneMonthFromToday = calendar.date(byAdding: .month, value: 1, to: today) else { return false }
        return birthday >= today && birthday <= oneMonthFromToday
    }
    
    func checkFriendsForUpcomingBirthdays() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        db.collection("users").document(currentUserId).getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {
                print("Error fetching user data: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            let friends = data["friendsList"] as? [String] ?? []
            let invitationsSent = Set(data["invitationsSent"] as? [String] ?? [])
            
            for friendId in friends {
                db.collection("users").document(friendId).getDocument { friendSnapshot, friendError in
                    guard let friendData = friendSnapshot?.data(), friendError == nil else {
                        print("Error fetching friend data: \(friendError?.localizedDescription ?? "Unknown error")")
                        return
                    }
                    
                    if let birthdayTimestamp = friendData["birthday"] as? Timestamp,
                       !invitationsSent.contains(friendId), // Check if invitation hasn't been sent
                       self.isBirthdayWithinNextMonth(birthday: birthdayTimestamp.dateValue()) {
                        
                        // Send invitation since it's within a month and hasn't been sent
                        self.sendInvitation(toUserId: friendId, fromUserId: currentUserId)
                        
                        // Update Firestore to mark the invitation as sent
                        self.updateInvitationsSent(currentUserId: currentUserId, friendId: friendId)
                    }
                }

            }
        }
    }
    
    
    func sendInvitation(toUserId: String, fromUserId: String) {
        let db = Firestore.firestore()
        let invitationData: [String: Any] = [
            "toUserId": toUserId,
            "fromUserId": fromUserId,
            "createdAt": Timestamp()
        ]
        db.collection("invitations").addDocument(data: invitationData) { error in
            if let error = error {
                print("Error sending invitation: \(error.localizedDescription)")
            } else {
                print("Invitation sent to user \(toUserId)")
            }
        }
    }
    
    func updateInvitationsSent(currentUserId: String, friendId: String) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(currentUserId)
        
        userRef.updateData([
            "invitationsSent": FieldValue.arrayUnion([friendId])
        ]) { error in
            if let error = error {
                print("Error updating invitations sent: \(error.localizedDescription)")
            } else {
                print("Updated invitationsSent for user \(currentUserId)")
            }
        }
    }


    
    func checkForPendingInvitations() {
            guard let currentUserId = Auth.auth().currentUser?.uid else { return }
            
            // Query Firestore for invitations where recipientId matches the current user and status is "pending"
            db.collection("invitations")
                .whereField("recipientId", isEqualTo: currentUserId)
                .whereField("status", isEqualTo: "pending")
                .getDocuments { (querySnapshot, error) in
                    if let error = error {
                        print("Error checking pending invitations: \(error.localizedDescription)")
                        return
                    }
                    
                    // If there are any pending invitations, highlight the bell icon
                    if let snapshot = querySnapshot, !snapshot.isEmpty {
                        self.updateBellIcon(hasPendingInvitations: true)
                    } else {
                        self.updateBellIcon(hasPendingInvitations: false)
                    }
                }
        }
    
    
    func updateBellIcon(hasPendingInvitations: Bool) {
        if hasPendingInvitations {
            bellIcon.setImage(UIImage(named: "bell.badge.fill"), for: .normal)
        } else {
            bellIcon.setImage(UIImage(named: "bell.fill"), for: .normal)
        }
    }


}
