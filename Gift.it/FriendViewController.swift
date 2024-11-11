import UIKit
import FirebaseFirestore

class FriendViewController: UIViewController {
    var user: User?
    let db = Firestore.firestore() // Initialize Firestore database

    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var bioLabel: UILabel!
    @IBOutlet var birthdayLabel: UILabel!
    @IBOutlet var usernameLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()

        print("IN VIEW DID LOAD")

        if let user = user {
            print("User ID: \(user.id)")
            fetchUserData(userId: user.id)
            
        }
    }
    
    func fetchUserData(userId: String) {
        // Reference to the users collection
        let userRef = db.collection("users").document(userId)

        // Fetch user data
        userRef.getDocument { (document, error) in
            if let error = error {
                print("Error getting document: \(error.localizedDescription)")
            } else if let document = document, document.exists {
                // Assuming user data is stored in Firestore as fields
                let data = document.data()
                print("User Data: \(String(describing: data))")

                // You can now use this data to populate your UI or store in a model
                
                // Example: If the user data has fields "username" and "email"
                if let username = data?["username"] as? String {
                    print("Username: \(username)")
                    self.usernameLabel.text = "@" + username
                }
                if let name = data?["name"] as? String {
                    print("Name: \(name)")
                    self.nameLabel.text = name
                }
                if let birthday = data?["birthday"] as? String {
                    self.birthdayLabel.text = birthday
                }
                
                if let bio = data?["bio"] as? String {
                        self.bioLabel.text = "Bio : " + bio
                } else {
                    self.bioLabel.text = "Bio : No bio yet"
                }
                
            } else {
                print("Document does not exist")
            }
        }
    }
}
