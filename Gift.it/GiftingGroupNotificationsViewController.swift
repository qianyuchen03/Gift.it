//
//  GiftingGroupNotificationsViewController.swift
//  Gift.it
//
//  Created by Rachel Huang on 11/12/24.
//

import UIKit
import UIKit
import FirebaseFirestore
import FirebaseAuth

class GiftingGroupNotificationsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, GiftingGroupInvitationCellDelegate {    

    @IBOutlet weak var tableView: UITableView!
    
    var invitations: [GiftingGroupInvitation] = []
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
        
        fetchInvitations()
    }
    
    func fetchInvitations() {
            guard let currentUserId = Auth.auth().currentUser?.uid else { return }
            
            db.collection("invitations")
                .whereField("recipientId", isEqualTo: currentUserId)
                .getDocuments { (querySnapshot, error) in
                    if let error = error {
                        print("Error fetching invitations: \(error.localizedDescription)")
                        return
                    }
                    
                    self.invitations = querySnapshot?.documents.compactMap { document in
                        let data = document.data()
                        let senderName = data["senderName"] as? String ?? "Unknown"
                        let senderId = data["senderId"] as? String ?? ""
                        let friendBirthday = data["friendBirthday"] as? Timestamp
                        
                        // Check if friendBirthday exists and convert it to Date
                        var birthday: Date? = nil
                        if let friendBirthdayTimestamp = friendBirthday {
                            birthday = friendBirthdayTimestamp.dateValue() // Convert Timestamp to Date
                        }
                        
                        // Return the invitation object with the sender name, sender ID, and birthday
                        return GiftingGroupInvitation(senderName: senderName, senderId: senderId, birthday: birthday!)
                        
                    } ?? []
                    
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
        }
        
        // MARK: - Table View Data Source
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return invitations.count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "GiftingGroupInvitationCell", for: indexPath) as! GiftingGroupInvitationCell
            let invitation = invitations[indexPath.row]
            
            cell.invitationLabel.text = "You're invited to \(invitation.senderName)'s Gifting Group"
            cell.friendId = invitation.senderId
            cell.friendBirthday = invitation.birthday
            cell.delegate = self // Set the delegate
            
            return cell
        }
        
        // MARK: - InvitationCellDelegate
    func didAcceptInvitation(friendId: String, friendBirthday: Date) {
        print("Accepted invitation from friendId: \(friendId)")
        
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // Generate unique gifting group ID using the friend's ID and birthday
        let groupId = "\(friendId)_\(formatDate(friendBirthday))"
        
        // Check if the gifting group exists or create it if it doesn't
        checkAndCreateGiftingGroup(currentUserId: currentUserId, friendId: friendId, groupId: groupId) { [weak self] success in
            if success {
                // Update Firestore to mark the invitation as accepted
                self?.updateInvitationStatus(friendId: friendId, status: "accepted")
            } else {
                print("Failed to create or join gifting group.")
            }
        }
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"  // Use a format that avoids special characters
        return formatter.string(from: date)
    }

        
        func didDenyInvitation(friendId: String) {
            print("Denied invitation from friendId: \(friendId)")
            
            // Perform Firestore update to mark the invitation as denied
            updateInvitationStatus(friendId: friendId, status: "denied")
        }
        
        func updateInvitationStatus(friendId: String, status: String) {
            guard let currentUserId = Auth.auth().currentUser?.uid else { return }
            
            // Update Firestore to reflect the user's response to the invitation
            db.collection("invitations")
                .whereField("senderId", isEqualTo: friendId)
                .whereField("recipientId", isEqualTo: currentUserId)
                .getDocuments { (querySnapshot, error) in
                    if let error = error {
                        print("Error updating invitation status: \(error.localizedDescription)")
                        return
                    }
                    
                    querySnapshot?.documents.forEach { document in
                        document.reference.updateData(["status": status]) { error in
                            if let error = error {
                                print("Error updating document: \(error.localizedDescription)")
                            } else {
                                print("Invitation status updated to \(status) for friendId: \(friendId)")
                            }
                        }
                    }
                    
                    // Refresh the invitations list after updating Firestore
                    self.fetchInvitations()
                }
        }
    
    
    func checkAndCreateGiftingGroup(currentUserId: String, friendId: String, groupId: String, completion: @escaping (Bool) -> Void) {
        let groupRef = db.collection("gifting_groups").document(groupId)
        
        groupRef.getDocument { (document, error) in
            if let error = error {
                print("Error checking for existing gifting group: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            if document?.exists == true {
                // Group already exists, just add the current user if they aren't in it
                groupRef.updateData([
                    "members": FieldValue.arrayUnion([currentUserId])
                ]) { error in
                    if let error = error {
                        print("Error adding user to existing group: \(error.localizedDescription)")
                        completion(false)
                    } else {
                        completion(true)
                    }
                }
            } else {
                // Create a new gifting group with the current user
                let newGroupData = [
                    "members": [currentUserId],
                    "createdAt": Timestamp(date: Date())
                ] as [String: Any]
                
                groupRef.setData(newGroupData) { error in
                    if let error = error {
                        print("Error creating gifting group: \(error.localizedDescription)")
                        completion(false)
                    } else {
                        print("Gifting group created successfully with ID \(groupId)")
                        completion(true)
                    }
                }
            }
        }
    }

    
    
    }
