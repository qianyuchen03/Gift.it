import UIKit
import FirebaseFirestore
import FirebaseAuth

struct WishListItem {
    var name: String
    var cost: Double
}

class FriendViewController: UIViewController, UIPopoverPresentationControllerDelegate {
    var user: User?
    var wishListItems: [[String: Any]] = []
    @IBOutlet var viewWishlistButton: UIButton!
    let db = Firestore.firestore() // Initialize Firestore database

    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var bioLabel: UILabel!
    @IBOutlet var birthdayLabel: UILabel!
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    
    var wishlistVisibility: Bool?
    let uid = Auth.auth().currentUser!.uid
    
    override func viewDidLoad() {
        super.viewDidLoad()

        print("IN VIEW DID LOAD")

        if let user = user {
            print("User ID: \(user.id)")
            fetchUserData(userId: user.id)
            fetchWishlistVisibility(userId: user.id)
        }
        setupProfileImageView()
    }
    
    func setupProfileImageView() {
        profileImageView.layer.cornerRadius = profileImageView.frame.height / 2
        profileImageView.clipsToBounds = true
        profileImageView.contentMode = .scaleAspectFill
    }
    
    func fetchWishlistVisibility(userId: String) {
            let db = Firestore.firestore()
            let userRef = db.collection("users").document(userId)
            
            userRef.getDocument { [weak self] (document, error) in
                guard let self = self else { return }
                if let error = error {
                    print("Error fetching modeSwitch3 state: \(error)")
                    return
                }
                if let document = document, document.exists {
                    self.wishlistVisibility = document.data()?["modeSwitch3"] as? Bool ?? true
                    print("wishlistVisibility: \(self.wishlistVisibility ?? false)")

                    // Update the button visibility on the main thread
                    DispatchQueue.main.async {
                        self.viewWishlistButton.isHidden = self.wishlistVisibility ?? false
                    }
                }
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
                
                // Load profile picture
                if let profilePictureBase64 = data?["profilePicture"] as? String,
                   let imageData = Data(base64Encoded: profilePictureBase64),
                   let image = UIImage(data: imageData) {
                    self.profileImageView.image = image
                } else {
                    self.profileImageView.image = UIImage(systemName: "person.circle") // Default placeholder
                }
            
                
                // Load wishlist items
                if let wishlistData = data?["wishlistItems"] as? [[String: Any]] {
                    self.wishListItems = wishlistData
                }
                
                

                } else {
                print("Document does not exist")
            }
        }
    }
    
    @IBAction func viewWishlistButtonPressed(_ sender: Any) {
        print("STOPPPP")
    if let friendWishlistVC = self.storyboard?.instantiateViewController(withIdentifier: "FriendWishlistViewController") as? FriendWishlistViewController {
        // Pass the wishListItems to FriendWishlistViewController
        friendWishlistVC.wishListItems = wishListItems
        
        
        // Set the presentation style to popover
             friendWishlistVC.modalPresentationStyle = .popover
             if let popoverPresentationController = friendWishlistVC.popoverPresentationController {
                 popoverPresentationController.sourceView = self.view // The view from which the popover should originate
                 popoverPresentationController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0) // Center of the view
                 popoverPresentationController.permittedArrowDirections = [] // No arrow, center the popover
                 popoverPresentationController.delegate = self
             }
             
             // Present the popover
             present(friendWishlistVC, animated: true, completion: nil)


    }
    }
    //    func navigateToFriendWishlistViewController() {
//        // Make sure FriendWishlistViewController is part of the storyboard
//        if let friendWishlistVC = storyboard?.instantiateViewController(withIdentifier: "FriendWishlistViewController") as? FriendWishlistViewController {
//            // Pass the wishListItems to FriendWishlistViewController
//            friendWishlistVC.wishListItems = self.wishListItems
//
//        }
//    }
}
