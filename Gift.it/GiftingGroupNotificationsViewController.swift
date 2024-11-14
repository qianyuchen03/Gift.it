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
        tableView.rowHeight = 80
        
        fetchInvitations()
    }
    
    func fetchInvitations() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("invitations")
            .whereField("toUserId", isEqualTo: currentUserId)
            .whereField("status", isEqualTo: "pending")  // Filter for pending invitations
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error fetching invitations: \(error.localizedDescription)")
                    return
                }
                
                self.invitations = querySnapshot?.documents.compactMap { document in
                    let data = document.data()
                    let senderName = data["friendName"] as? String ?? "Unknown"
                    let senderId = data["fromUserId"] as? String ?? ""
                    let friendBirthday = data["friendBirthday"] as? String
                    let birthday = self.convertStringToDate(dateString: friendBirthday!, format: "MMMM dd, yyyy")
                    
                    return GiftingGroupInvitation(senderName: senderName, senderId: senderId, birthday: birthday!)

                } ?? []
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
    }
    
    
    func convertStringToDate(dateString: String, format: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format // Set the format that matches the string
        dateFormatter.locale = Locale(identifier: "en_US_POSIX") // Use this to avoid issues with locale-specific formats
        return dateFormatter.date(from: dateString)
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
        cell.friendName = invitation.senderName
        cell.delegate = self // Set the delegate
        
        return cell
    }

        
        // MARK: - InvitationCellDelegate
    func didAcceptInvitation(friendId: String, friendBirthday: Date, friendName: String) {
        print("Accepted invitation from friendId: \(friendId)")
        
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // Generate unique gifting group ID using the friend's ID and birthday
        let groupId = "\(friendId)_\(formatDate(friendBirthday))"
        
        // Check if the gifting group exists or create it if it doesn't
        checkAndCreateGiftingGroup(currentUserId: currentUserId, friendId: friendId, groupId: groupId, friendName: friendName, friendBirthday: friendBirthday) { [weak self] success in
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
            .whereField("fromUserId", isEqualTo: friendId)
            .whereField("toUserId", isEqualTo: currentUserId)
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
                            
                            // Remove the invitation from the list if it is accepted or denied
                            if let index = self.invitations.firstIndex(where: { $0.senderId == friendId }) {
                                self.invitations.remove(at: index)
                            }
                            
                            // Refresh the table view to reflect the updated list of invitations
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                            }
                        }
                    }
                }
            }
    }

    
    func checkAndCreateGiftingGroup(currentUserId: String, friendId: String, groupId: String, friendName: String, friendBirthday: Date, completion: @escaping (Bool) -> Void) {
        let groupRef = db.collection("chats").document(groupId)
        
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
                        print("User added to existing group")
                        completion(true)
                    }
                }
            } else {
                // Create a new gifting group with the current user
                let newGroupData = [
                    "chat_birthday": Timestamp(date: friendBirthday),  // friend's birthday as the group birthday
                    "gc_name": "\(friendName)'s Birthday",  // group chat name as "Friend's Birthday"
                    "members": [currentUserId, friendId],  // Add the current user and the friend as members
                    "createdAt": Timestamp(date: Date()),  // creation time of the group
                    "conversation_id": groupId,
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
