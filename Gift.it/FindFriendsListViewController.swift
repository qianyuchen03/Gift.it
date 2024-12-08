import UIKit
import FirebaseFirestore
import FirebaseAuth

struct User {
    let id: String
    let username: String
}

class FindFriendsListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var searchBar: UISearchBar!
    var users: [User] = []
    var filteredUsers: [User] = [] // Array for filtered results
    var isSearchActive: Bool = false // Track search state
    var friendsList: [String] = [] // Store only the IDs of friends for easier filtering
    let db = Firestore.firestore()
    
    var currentUserId: String? {
        return Auth.auth().currentUser?.uid
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self // Set delegate for UISearchBar
        loadFriendsList()
    }
    
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearchActive ? filteredUsers.count : users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath) as? UserCell else {
            return UITableViewCell()
        }
        
        let user = isSearchActive ? filteredUsers[indexPath.row] : users[indexPath.row]
        cell.usernameLabel?.text = user.username
        cell.selectionStyle = .none // Prevent selection highlight
        
        // Add button action for adding friends
        cell.addButtonAction = { [weak self] in
            self?.addUserAsFriend(for: user, at: indexPath)
        }
        
        return cell
    }
    
    // MARK: - UISearchBarDelegate
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            isSearchActive = false
            filteredUsers.removeAll()
        } else {
            isSearchActive = true
            filteredUsers = users.filter { $0.username.lowercased().contains(searchText.lowercased()) }
        }
        tableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        isSearchActive = false
        searchBar.text = ""
        tableView.reloadData()
    }
    
    // MARK: - Data Loading
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
    
    // MARK: - Friend Request
    func addUserAsFriend(for user: User, at indexPath: IndexPath) {
        guard let currentUserId = currentUserId else { return }
        
        // Fetch the current user's document to get their username
        db.collection("users").document(currentUserId).getDocument { [weak self] document, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching user document: \(error)")
                return
            }
            
            guard let data = document?.data(), let currentUserName = data["username"] as? String else {
                print("Error fetching or parsing current user data.")
                return
            }
            
            // Create the notification data
            let notificationData: [String: Any] = [
                "type": "requestNotif",
                "from": currentUserId,
                "message": "\(currentUserName) has sent you a friend request."
            ]
            
            // Add the notification to the recipient user's notifications array
            db.collection("users").document(user.id).updateData([
                "notifications": FieldValue.arrayUnion([notificationData])
            ]) { error in
                if let error = error {
                    print("Error sending friend request notification: \(error)")
                    return
                }
                print("Friend request notification sent to \(user.id)")
            }
        }
    }
}
