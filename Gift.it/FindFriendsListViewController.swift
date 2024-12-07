import UIKit
import FirebaseFirestore
import FirebaseAuth

struct User {
    let id: String
    let username: String
}

class FindFriendsListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var tableView: UITableView!
    var users: [User] = []
    var friendsList: [String] = []  // Store only the IDs of friends for easier filtering
    let db = Firestore.firestore()
    var currentUserId: String? {
        return Auth.auth().currentUser?.uid
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath) as? UserCell else {
            return UITableViewCell()
        }
        
        let user = users[indexPath.row]
        cell.usernameLabel?.text = user.username
        
        // Prevent row from becoming gray when selected
        cell.selectionStyle = .none
        
        // Set up button action for adding friends
        cell.addButtonAction = { [weak self] in
            self?.addUserAsFriend(for: user, at: indexPath)
        }
        
        return cell
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        loadFriendsList()
    }
    
    func loadFriendsList() {
        if let userId = currentUserId {
            db.collection("users").document(userId).getDocument { (document, error) in
                if let error = error {
                    print("Error fetching friends list: \(error)")
                    return
                }
                
                if let document = document, document.exists {
                    self.friendsList = document.data()?["friendsList"] as? [String] ?? []
                }
                
                self.fetchUsers()
            }
        }
    }
    
    func fetchUsers() {
        db.collection("users").getDocuments { (snapshot, error) in
            if let error = error {
                print("Error fetching users: \(error)")
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            self.users = documents.compactMap { document in
                let data = document.data()
                let userId = document.documentID
                if let username = data["username"] as? String, !self.friendsList.contains(userId) {
                    return User(id: userId, username: username)
                }
                return nil
            }
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    //    func addUserAsFriend(_ user: User, at indexPath: IndexPath) {
    //        // Add selected user to the logged-in user's friends list in Firestore
    //        if let userId = currentUserId {
    //            db.collection("users").document(userId).updateData([
    //                "friendsList": FieldValue.arrayUnion([user.id])
    //            ]) { [weak self] error in
    //                if let error = error {
    //                    print("Error updating friends list: \(error)")
    //                } else {
    //                    print("Successfully updated friends list.")
    //                    // Update local friends list
    //                    self?.friendsList.append(user.id)  // Update local friends list
    //                    // Remove the user from the users array
    //                    self?.users.remove(at: indexPath.row)  // Remove the user from the list
    //
    //                    // Re-fetch the users list to ensure the data is accurate
    //                    self?.fetchUsers()
    //
    //                    // Ensure indexPath is valid before deleting the row
    //                    if indexPath.row < self?.users.count ?? 0 {
    //                        self?.tableView.deleteRows(at: [indexPath], with: .automatic)  // Update the table view
    //                    }
    //                }
    //            }
    //        }
    //    }
    
    func addUserAsFriend(for user: User, at indexPath: IndexPath) {
        let db = Firestore.firestore()
        
        // Create the friend request notification
        db.collection("users").document(currentUserId!).getDocument { document, error in
            if let error = error {
                print("Error fetching user document: \(error)")
                return
            }
            
            let data = document?.data()
            let currentUserName = data?["username"]
            let notificationData: [String: Any] = [
                "type": "requestNotif",
                "from": self.currentUserId ?? "none",
                "message": "\(currentUserName ?? "Someone") has sent you a friend request."
            ]
            
            // Add the notification to the target user's notifications collection
            db.collection("users").document(user.id).updateData([
                "notifications": FieldValue.arrayUnion([notificationData])
            ]) { [weak self] error in
                if let error = error {
                    print("Error sending friend request notification: \(error)")
                    return
                }
            }
            
            
            
        }
    }
}
