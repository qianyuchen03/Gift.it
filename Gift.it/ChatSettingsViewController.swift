//
//  ChatSettingsViewController.swift
//  Gift.it
//
//  Created by Tanya Joseph on 11/22/24.
//

import UIKit
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

struct AllMembersData: Codable {
    var members: [String]
}

class ChatSettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {

    @IBOutlet weak var chatNameLabel: UILabel!
    @IBOutlet weak var numMembersLabel: UILabel!
    @IBOutlet weak var membersTableView: UITableView!
    @IBOutlet weak var editChatNameTextField: UITextField!
    
    var db: Firestore!
    var originalChatName = ""
    var conversationId = ""
    var members = [String]()
    var memberDetails: [(name: String, picture: UIImage?)] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        db = Firestore.firestore()
        
        chatNameLabel.text = originalChatName
        editChatNameTextField.text = originalChatName
        editChatNameTextField.isHidden = true
        
        membersTableView.delegate = self
        membersTableView.dataSource = self
        editChatNameTextField.delegate = self
        
        getMembers()
    }
    
    @IBAction func changeGroupNameButtonPressed(_ sender: Any) {
        chatNameLabel.isHidden = true
        editChatNameTextField.isHidden = false
        editChatNameTextField.becomeFirstResponder()
    }
    
    func getMembers() {
        let docRef = db.collection("chats").document(conversationId)
        
        docRef.getDocument { (document, error) in
            guard error == nil else {
                print("Error fetching chat members: \(error?.localizedDescription ?? "")")
                return
            }
            
            if let document = document, document.exists {
                do {
                    let allMembers = try document.data(as: AllMembersData.self)
                    var memberDetailsTemp: [(name: String, picture: UIImage?)] = []
                    let dispatchGroup = DispatchGroup()
                    
                    for member in allMembers.members {
                        dispatchGroup.enter()
                        
                        self.getDisplayNameAndPicture(userUID: member) { name, picture in
                            memberDetailsTemp.append((name, picture))
                            dispatchGroup.leave()
                        }
                    }
                    
                    dispatchGroup.notify(queue: .main) {
                        // Populate memberDetails with fetched data
                        self.memberDetails = memberDetailsTemp
                        
                        // Update only the display names for the members array
                        self.members = self.memberDetails.map { $0.name }
                        
                        // Update the UI (numMembers and table view)
                        self.numMembersLabel.text = "\(self.members.count) People"
                        self.membersTableView.reloadData()
                    }
                } catch {
                    print("Error decoding members: \(error.localizedDescription)")
                }
            }
        }
    }

    
    func getDisplayNameAndPicture(userUID: String, completion: @escaping (String, UIImage?) -> Void) {
        let docRef = db.collection("users").document(userUID)

        docRef.getDocument { (document, error) in
            guard error == nil else {
                print("Error fetching user info: \(error?.localizedDescription ?? "")")
                completion("", nil) // Return empty name and nil image on error
                return
            }

            if let document = document, document.exists {
                let data = document.data()
                let displayName = data?["name"] as? String ?? ""
                
                if let profilePictureDataURL = data?["profilePicture"] as? String {
                    self.setProfileImage(from: profilePictureDataURL) { image in
                        completion(displayName, image) // Return display name and image
                    }
                } else {
                    completion(displayName, nil) // Return display name and nil image if no profile picture
                }
            } else {
                completion("", nil) // Document not found, return empty name and nil image
            }
        }
    }
    
    func changeChatName() {
        let newChatName = editChatNameTextField.text
        chatNameLabel.text = newChatName
        editChatNameTextField.isHidden = true
        chatNameLabel.isHidden = false
        
        let docRef = db.collection("chats").document(conversationId)
        
        docRef.updateData([
            "gc_name": newChatName
        ])
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return members.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "FriendCell", for: indexPath) as? FriendCell else {
            return UITableViewCell()
        }

        let memberDetail = memberDetails[indexPath.row]
        cell.usernameLabel?.text = memberDetail.name

        if let profilePicture = memberDetail.picture {
            cell.profileImageView.image = profilePicture
        } else {
            cell.profileImageView.image = UIImage(systemName: "person.circle") // Placeholder
        }

        return cell
    }


    // Use the same setProfileImage method for Base64 decoding as in MyFriendsListViewController
    func setProfileImage(from dataURL: String, completion: @escaping (UIImage?) -> Void) {
        guard let base64String = dataURL.split(separator: ",").last else {
            print("Invalid data URL format.")
            completion(nil)
            return
        }

        if let imageData = Data(base64Encoded: String(base64String)),
           let decodedImage = UIImage(data: imageData) {
            completion(decodedImage)
        } else {
            print("Failed to decode Base64 string into an image.")
            completion(nil)
        }
    }
    
    
    // This function is to fetch profile picture from Firebase
    func fetchProfilePicture(userUID: String, completion: @escaping (UIImage?) -> Void) {
        let docRef = db.collection("users").document(userUID)

        docRef.getDocument { (document, error) in
            guard error == nil else {
                print("Error fetching profile picture: \(error?.localizedDescription ?? "")")
                completion(nil)
                return
            }

            if let document = document, document.exists {
                if let profilePictureDataURL = document.data()?["profilePicture"] as? String {
                    self.setProfileImage(from: profilePictureDataURL, completion: completion)
                } else {
                    completion(nil) // No profile picture, return nil
                }
            } else {
                completion(nil) // Document not found, return nil
            }
        }
    }
    
    // Called when 'return' key pressed

    func textFieldShouldReturn(_ textField:UITextField) -> Bool {
        textField.resignFirstResponder()
        changeChatName()
        return true
    }
    
    // Called when the user clicks on the view outside of the UITextField

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
        changeChatName()
    }
}
