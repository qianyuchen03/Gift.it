//  MyFriendsListViewController.swift
//  Gift.it

import UIKit
import FirebaseFirestore
import FirebaseAuth

class MyFriendsListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var bellButton: UIButton!
    
    
    var friendsList: [User] = []   // Array to hold User objects for the logged-in user's friends
    var filteredFriendsList: [User] = [] // Array to hold filtered User objects for search
    let db = Firestore.firestore()
    var currentUserId: String? {
        return Auth.auth().currentUser?.uid  // Gets the logged-in user's ID
    }
    var friendsListListener: ListenerRegistration?  // Listener for real-time updates
    var notifSwitch: Bool?
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredFriendsList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "FriendCell", for: indexPath) as? FriendCell else {
            return UITableViewCell()
        }

        let user = filteredFriendsList[indexPath.row]
        cell.usernameLabel?.text = user.username

        // Fetch and display profile picture from Base64 string (Data URL)
        if let imageDataURL = user.profilePicture {
            setProfileImage(from: imageDataURL, for: cell)
        } else {
            // Use a default placeholder image if no profile picture is available
            cell.profileImageView.image = UIImage(systemName: "person.circle")
        }

        return cell
    }
    
    func setProfileImage(from dataURL: String, for cell: FriendCell) {
        // Extract Base64-encoded part from data URL
        guard let base64String = dataURL.split(separator: ",").last else {
            print("Invalid data URL format.")
            return
        }
        
        // Decode Base64 string into Data
        if let imageData = Data(base64Encoded: String(base64String)),
           let decodedImage = UIImage(data: imageData) {
            DispatchQueue.main.async {
                cell.profileImageView.image = decodedImage
            }
        } else {
            print("Failed to decode Base64 string into an image.")
        }
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
        searchBar.delegate = self  // Set search bar delegate
        observeFriendsListChanges()  // Set up real-time listener
        print("GOOD TILL HERE")
        fetchNotifSwitchState()
        print("GOOD TILL HERE 2")
        updateBellButtonState()
        print("AND HERE")
    }
    
    deinit {
        // Remove listener when the view controller is deinitialized to avoid memory leaks
        friendsListListener?.remove()
        friendsListListener = nil
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
        let group = DispatchGroup() // Handle async fetches

        friendsList.removeAll() // Clear previous data to avoid duplicates

        for friendId in friendIds {
            group.enter()
            db.collection("users").document(friendId).getDocument { (document, error) in
                defer { group.leave() } // Ensure we leave the group even if there's an error
                if let error = error {
                    print("Error fetching friend data for ID \(friendId): \(error)")
                    return
                }

                if let document = document, document.exists {
                    let data = document.data()
                    let username = data?["username"] as? String ?? "Unknown"
                    let profilePicture = data?["profilePicture"] as? String

                    let friend = User(id: friendId, username: username, profilePicture: profilePicture)
                    self.friendsList.append(friend)
                }
            }
        }

        group.notify(queue: .main) {
            self.filteredFriendsList = self.friendsList // Initially, show all friends
            self.tableView.reloadData()
        }
    }
    
    // MARK: - Search Bar Methods
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            if searchText.isEmpty {
                filteredFriendsList = friendsList  // Show all friends if search text is empty
            } else {
                filteredFriendsList = friendsList.filter { $0.username.lowercased().contains(searchText.lowercased()) }
            }
            tableView.reloadData()
        }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
            searchBar.text = ""
            filteredFriendsList = friendsList  // Reset to show all friends
            tableView.reloadData()
            searchBar.resignFirstResponder()
        }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
           searchBar.resignFirstResponder()  // Dismiss keyboard
       }
    
    
    // MARK: - Swipe to delete
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Remove Friend") { (action, view, completionHandler) in
            // Safely remove the friend only if index is valid
            guard indexPath.row < self.filteredFriendsList.count else {
                completionHandler(false)
                return
            }

            // Get the friend to remove
            let friendToRemove = self.filteredFriendsList[indexPath.row]

            // Remove the friend relationship from Firestore
            self.removeFriendRelationship(friendId: friendToRemove.id) { success in
                if success {
                    // Update the local list safely
                    if let index = self.friendsList.firstIndex(where: { $0.id == friendToRemove.id }) {
                        self.friendsList.remove(at: index)
                    }
                    
                    if let index = self.filteredFriendsList.firstIndex(where: { $0.id == friendToRemove.id }) {
                        self.filteredFriendsList.remove(at: index)
                        tableView.deleteRows(at: [indexPath], with: .automatic)
                    }
                }
                self.tableView.reloadData()
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
    
    func updateBellButtonState() {
        
        let userRef = db.collection("users").document(currentUserId!)
        
        userRef.getDocument { [weak self] (document, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching user data for bell button: \(error)")
                return
            }
            
            if let document = document, document.exists {
                // Check the notifSwitch status
                let notifSwitch = document.data()?["notifSwitch"] as? Bool ?? false
                
                if !notifSwitch {
                    // If notifSwitch is false, set the bell to always empty
                    self.bellButton.setImage(UIImage(systemName: "bell"), for: .normal)
                    print("Notifs off")
                    return
                }
                
                // Check the notifications array
                let notifications = document.data()?["notifications"] as? [[String: Any]] ?? []
                
                if notifications.isEmpty {
                    // If no notifications, set the bell to empty
                    self.bellButton.setImage(UIImage(systemName: "bell"), for: .normal)
                    print("No notifs!!")
                } else {
                    // If there are notifications, set the bell to filled
                    self.bellButton.setImage(UIImage(systemName: "bell.fill"), for: .normal)
                    print("You have notifs!")
                }
            }
        }
    }

    
    func fetchNotifSwitchState() {
        guard let currentUserId = currentUserId else { return }
        
        let userRef = db.collection("users").document(currentUserId)
        
        userRef.addSnapshotListener { [weak self] (snapshot, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Error listening for notifSwitch changes: \(error)")
                return
            }
            
            if let snapshot = snapshot, snapshot.exists {
                self.notifSwitch = snapshot.data()?["notifSwitch"] as? Bool ?? false
                self.updateBellButtonState()  // Update bell button whenever data changes
            }
        }
    }

    @IBAction func bellButtonTapped(_ sender: Any) {
        print("bell button tapped")
        performSegue(withIdentifier: "toFriendsNotificationsVC", sender: self)
    }
    
}
