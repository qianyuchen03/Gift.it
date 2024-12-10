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
    
    @IBOutlet weak var bellButton: UIButton!
    
    
    let db = Firestore.firestore()
    var isDataLoaded = false
    let uid = Auth.auth().currentUser!.uid

    var listener: ListenerRegistration?
    var chats: [Chat] = []
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        listener?.remove()
        print("Listener removed in viewWillDisappear.")
    }
    
    override func viewWillAppear(_ animated: Bool) {
         super.viewWillAppear(animated)
         
         // These methods will now be called every time the screen appears
         fetchChats()
         checkFriendsForUpcomingBirthdays()
         checkForPendingInvitations()
     }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 80 // Adjust as needed
        fetchChats()
        self.checkFriendsForUpcomingBirthdays()
        self.checkForPendingInvitations()
    }
    
    func fetchChats() {
        let chatsRef = db.collection("chats")
        
        // Remove any previous listener
        listener?.remove()
        
        // Add a listener to the chats collection
        listener = chatsRef.addSnapshotListener { (snapshot, error) in
            if let error = error {
                print("Error listening for chats updates: \(error.localizedDescription)")
                return
            }
            
            // Update the `chats` array with new data
            self.chats = snapshot?.documents.compactMap { document in
                let data = document.data()
                let members = data["members"] as? [String] ?? []
                
                // Check if current user is a member of the chat
                if members.contains(self.uid) {
                    return Chat(
                        convoID: data["conversation_id"] as? String ?? "Unknown ID",
                        latestMsg: (data["latest_message"] as? [String: Any])?["latest_message"] as? String ?? "No message",
                        time: ((data["latest_message"] as? [String: Any])?["date"] as? Timestamp)?.dateValue() ?? Date(),
                        members: members,
                        gcName: data["gc_name"] as? String ?? "No groupchat name"
                    )
                }
                
                // If current user is not in the members array, return nil to exclude this chat
                print("User is not in chat")
                return nil
            } ?? []
            
            // Update the table view on the main thread
            DispatchQueue.main.async {
                self.isDataLoaded = true
                self.tableView.reloadData()
            }
        }
    }


    
    // Number of rows in section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return isDataLoaded ? chats.count : 0
        }
        
        // Configure the cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Check if data is loaded; if not, return a placeholder cell
        guard isDataLoaded else {
            let cell = UITableViewCell(style: .default, reuseIdentifier: "PlaceholderCell")
            cell.textLabel?.text = "Loading..."
            cell.textLabel?.font = UIFont(name: "Courier New Bold", size: 20)
            return cell
        }
        
        // Proceed with setting up the actual cell if data is loaded
        let cell = tableView.dequeueReusableCell(withIdentifier: "GiftingGroupChatCell", for: indexPath) as! GiftingGroupChatCell
        cell.textLabel?.font = UIFont(name: "Courier New Bold", size: 20)
        
        let chat = chats[indexPath.row]
        cell.configure(with: chat)
        
        return cell
    }

    
    // Prepare for segue to the chat screen
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if segue.identifier == "ChatSegue" {
                if let chatVC = segue.destination as? ChatViewController,
                   let selectedChatIndex = tableView.indexPathForSelectedRow?.row {
                    let selectedChat = chats[selectedChatIndex]
                    chatVC.conversationId = selectedChat.convoID
                    chatVC.chatName = selectedChat.gcName
                }
            }
        }
    
    func isBirthdayWithinNextMonth(birthday: Date) -> Bool {
          let today = Date()
          let calendar = Calendar.current
          // Get the current month and day
          let todayComponents = calendar.dateComponents([.month, .day], from: today)
          
          // Get the target date, one month from today
          guard let oneMonthFromToday = calendar.date(byAdding: .month, value: 1, to: today) else {
              return false
          }
          let oneMonthFromTodayComponents = calendar.dateComponents([.month, .day], from: oneMonthFromToday)
          // Extract only the month and day components of the birthday
          let birthdayComponents = calendar.dateComponents([.month, .day], from: birthday)
          // Check if the birthday is within the next month, regardless of year
          if let birthdayMonth = birthdayComponents.month,
             let birthdayDay = birthdayComponents.day,
             let todayMonth = todayComponents.month,
             let todayDay = todayComponents.day,
             let nextMonth = oneMonthFromTodayComponents.month,
             let nextDay = oneMonthFromTodayComponents.day {
              // Birthday is within the next month if it falls between today and one month from today
              return (birthdayMonth == todayMonth && birthdayDay >= todayDay) ||
                     (birthdayMonth == nextMonth && birthdayDay <= nextDay)
          }
          return false
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
                    
                    // Attempt to get the birthday as a string and parse it
                    if let birthdayString = friendData["birthday"] as? String,
                       let friendBirthday = self.parseDate(from: birthdayString),
                       let friendName = friendData["name"] as? String,
                       
                       !invitationsSent.contains(friendId),
                       self.isBirthdayWithinNextMonth(birthday: friendBirthday) {
                        
                        print("Birthday for friend \(friendId) is within next month: \(friendBirthday)")
                        
                        // Check if an invitation already exists for this friend
                        self.checkIfInvitationExists(toUserId: currentUserId, fromUserId: friendId) { exists in
                            if !exists {
                                // Send invitation since it's within a month, hasn't been sent yet, and no invitation exists
                                self.sendInvitation(toUserId: currentUserId, fromUserId: friendId, friendName: friendName, friendBirthday: birthdayString)
                                
                                // Update Firestore to mark the invitation as sent
                                self.updateInvitationsSent(currentUserId: currentUserId, friendId: friendId)
                            } else {
                                print("Invitation already exists for friend \(friendId). Skipping.")
                            }
                        }
                    } else {
                        print("Friend \(friendId) has no valid or upcoming birthday.")
                    }
                }
            }
        }
    }

    
    func checkIfInvitationExists(toUserId: String, fromUserId: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()

        // Query Firestore for any existing invitations with the same recipient (toUserId), sender (fromUserId), and status is pending
        db.collection("invitations")
            .whereField("toUserId", isEqualTo: toUserId)
            .whereField("fromUserId", isEqualTo: fromUserId)
            .whereField("status", isEqualTo: "pending")
            .getDocuments { querySnapshot, error in
                if let error = error {
                    print("Error checking existing invitations: \(error.localizedDescription)")
                    completion(false) // Return false if there is an error
                    return
                }

                // If there is a document in the result, that means the invitation exists
                if let snapshot = querySnapshot, !snapshot.isEmpty {
                    print("Invitation already exists for this friend.")
                    completion(true)
                } else {
                    print("No existing invitation found.")
                    completion(false)
                }
            }
    }

    
    // Helper function to parse the birthday string into a Date
    func parseDate(from birthdayString: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM dd, yyyy" // Adjust the format to match your stored birthday strings
        return dateFormatter.date(from: birthdayString)
    }


    
    func sendInvitation(toUserId: String, fromUserId: String, friendName: String, friendBirthday: String) {
        let db = Firestore.firestore()
        let invitationData: [String: Any] = [
            "toUserId": toUserId,
            "fromUserId": fromUserId,
            "createdAt": Timestamp(),
            "friendName": friendName,
            "friendBirthday": friendBirthday,
            "status": "pending"
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
                .whereField("toUserId", isEqualTo: currentUserId)
                .whereField("status", isEqualTo: "pending")
                .getDocuments { (querySnapshot, error) in
                    if let error = error {
                        print("Error checking pending invitations: \(error.localizedDescription)")
                        return
                    }
                    
                    // If there are any pending invitations, highlight the bell icon
                    if let snapshot = querySnapshot, !snapshot.isEmpty {
                        self.updateBellButton(hasPendingInvitations: true)
                    } else {
                        self.updateBellButton(hasPendingInvitations: false)
                    }
                }
        }
    
    func updateBellButton(hasPendingInvitations: Bool) {
        
        let userRef = db.collection("users").document(uid)
        
        userRef.getDocument { [weak self] (document, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching user data for bell button: \(error)")
                return
            }
            
            if let document = document, document.exists {
                let notifSwitch = document.data()?["notifSwitch"] as? Bool ?? false
                
                if !notifSwitch {
                    // If notifSwitch is false, set the bell to always empty
                    self.bellButton.setImage(UIImage(systemName: "bell"), for: .normal)
                    print("Notifs off")
                    return
                }
                
                if !hasPendingInvitations {
                    self.bellButton.setImage(UIImage(systemName: "bell"), for: .normal)
                    print("No invites!!")
                } else {
                    self.bellButton.setImage(UIImage(systemName: "bell.fill"), for: .normal)
                    print("You have invites!")
                }
            }
        }
    }
    
    @IBAction func bellButtonTapped(_ sender: Any) {
        print("bell button tapped")
        performSegue(withIdentifier: "toGiftingGroupNotificationVC", sender: self)
    }
    



}

class Chat {
    
    var convoID : String
    var latestMsg : String
    var time : Date
    var members : [String]
    var gcName : String
    
    init(convoID: String, latestMsg: String, time: Date, members: [String], gcName : String) {
        self.convoID = convoID
        self.latestMsg = latestMsg
        self.time = time
        self.members = members
        self.gcName = gcName
    }
    
}
