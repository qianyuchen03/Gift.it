//  MyFriendsListViewController.swift
//  Gift.it

import UIKit
import FirebaseFirestore
import FirebaseAuth

class MyFriendsListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet var tableView: UITableView!
    
    var friendsList: [User] = []   // Array to hold User objects for the logged-in user's friends
    let db = Firestore.firestore()
    var currentUserId: String? {
        return Auth.auth().currentUser?.uid  // Gets the logged-in user's ID
    }
    var friendsListListener: ListenerRegistration?  // Listener for real-time updates
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friendsList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "FriendCell", for: indexPath) as? FriendCell else {
            return UITableViewCell()
        }
        
        let user = friendsList[indexPath.row]
        cell.usernameLabel?.text = user.username
        
//        // Set up button action for adding friends
//        cell.addButtonAction = { [weak self] in
//            self?.addUserAsFriend(user, at: indexPath)
//        }
        
        return cell
    }
    
    // MARK: - Handling Friend Cell Click

        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            // Get the selected friend
            let selectedFriend = friendsList[indexPath.row]

            // Perform segue or push navigation to the FriendViewController
            performSegue(withIdentifier: "showFriendProfile", sender: selectedFriend)
        }

        // MARK: - Navigation

        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if segue.identifier == "showFriendProfile",
               let destinationVC = segue.destination as? FriendViewController,
               let friend = sender as? User {
                // Pass the selected friend to the FriendViewController
                destinationVC.user = friend
            }
        }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        observeFriendsListChanges()  // Set up real-time listener
    }
    
    deinit {
        // Remove listener when the view controller is deinitialized to avoid memory leaks
        friendsListListener?.remove()
    }

    func observeFriendsListChanges() {
        guard let userId = currentUserId else { return }
        
        friendsListListener = db.collection("users").document(userId).addSnapshotListener { documentSnapshot, error in
            if let error = error {
                print("Error observing friends list: \(error)")
                return
            }
            
            guard let document = documentSnapshot, let friendIds = document.data()?["friendsList"] as? [String] else { return }
            
            // Fetch usernames for each friend ID in the updated friendsList
            self.fetchFriendsDetails(friendIds: friendIds)
        }
    }
    
    func fetchFriendsDetails(friendIds: [String]) {
        let group = DispatchGroup()  // For handling async fetches
        
        friendsList.removeAll()  // Clear previous data to avoid duplicates
        
        for friendId in friendIds {
            group.enter()
            db.collection("users").document(friendId).getDocument { (document, error) in
                defer { group.leave() }  // Ensure we leave the group even if there's an error
                if let error = error {
                    print("Error fetching friend data for ID \(friendId): \(error)")
                    return
                }
                
                if let document = document, document.exists, let username = document.data()?["username"] as? String {
                    let friend = User(id: friendId, username: username)
                    self.friendsList.append(friend)
                }
            }
        }
        
        // Reload the table view once all friend data is fetched
        group.notify(queue: .main) {
            self.tableView.reloadData()
        }
    }
    
    // MARK: - Swipe to delete
//    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
//        let deleteAction = UIContextualAction(style: .destructive, title: "Remove Friend") { (action, view, completionHandler) in
//            // Safely remove the friend only if index is valid
//            guard indexPath.row < self.friendsList.count else {
//                completionHandler(false)
//                return
//            }
//            
//            // Remove the friend from Firestore and the local list
//            let friendToRemove = self.friendsList[indexPath.row]
//            self.removeFriendFromFirestore(friendId: friendToRemove.id) { success in
//                if success {
//                    // Update the local list and table view safely
//                    if let index = self.friendsList.firstIndex(where: { $0.id == friendToRemove.id }) {
//                        self.friendsList.remove(at: index)
//                        tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
//                    }
//                }
//                completionHandler(success)
//            }
//        }
//        
//        return UISwipeActionsConfiguration(actions: [deleteAction])
//    }
//    
//    func removeFriendFromFirestore(friendId: String, completion: @escaping (Bool) -> Void) {
//        guard let userId = currentUserId else {
//            completion(false)
//            return
//        }
//        
//        db.collection("users").document(userId).updateData([
//            "friendsList": FieldValue.arrayRemove([friendId])
//        ]) { error in
//            if let error = error {
//                print("Error removing friend from friends list: \(error)")
//                completion(false)
//            } else {
//                print("Successfully removed friend from friends list.")
//                completion(true)
//            }
//        }
//    }
    
    
    // MARK: - Swipe to delete
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Remove Friend") { (action, view, completionHandler) in
            // Safely remove the friend only if index is valid
            guard indexPath.row < self.friendsList.count else {
                completionHandler(false)
                return
            }
            
            // Get the friend to remove
            let friendToRemove = self.friendsList[indexPath.row]
            
            // Remove the friend relationship from Firestore
            self.removeFriendRelationship(friendId: friendToRemove.id) { success in
                if success {
                    // Update the local list and table view safely
                    if let index = self.friendsList.firstIndex(where: { $0.id == friendToRemove.id }) {
                        self.friendsList.remove(at: index)
                        tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                    }
                }
                completionHandler(success)
            }
        }
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }

    func removeFriendRelationship(friendId: String, completion: @escaping (Bool) -> Void) {
        guard let currentUserId = currentUserId else {
            completion(false)
            return
        }
        
        let db = Firestore.firestore()
        let currentUserRef = db.collection("users").document(currentUserId)
        let friendUserRef = db.collection("users").document(friendId)
        
        // Use a batch to update both users atomically
        let batch = db.batch()
        
        // Remove friendId from current user's friendsList
        batch.updateData(["friendsList": FieldValue.arrayRemove([friendId])], forDocument: currentUserRef)
        
        // Remove currentUserId from friend's friendsList
        batch.updateData(["friendsList": FieldValue.arrayRemove([currentUserId])], forDocument: friendUserRef)
        
        // Commit the batch
        batch.commit { error in
            if let error = error {
                print("Error removing friend relationship: \(error)")
                completion(false)
            } else {
                print("Successfully removed friend relationship.")
                completion(true)
            }
        }
    }

}
