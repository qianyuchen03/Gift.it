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
                print("error", error ?? "")
                return
            }
            
            if let document = document, document.exists {
                do {
                    let allMembers = try document.data(as: AllMembersData.self)
                    var memberDisplayNames: [String] = []
                    let dispatchGroup = DispatchGroup()
                    
                    for member in allMembers.members {
                        dispatchGroup.enter()
                        
                        self.getDisplayName(userUID: member) { displayName in
                            memberDisplayNames.append(displayName)
                            dispatchGroup.leave()
                        }
                    }
                    
                    dispatchGroup.notify(queue: .main) {
                        self.members = memberDisplayNames
                        self.numMembersLabel.text = "\(self.members.count) People"
                        self.membersTableView.reloadData()
                    }
                } catch {
                    print("Error decoding messages: \(error.localizedDescription)")
                }
                
            }
        }
    }
    
    func getDisplayName(userUID: String, completion: @escaping (String) -> Void) {
        let docRef = db.collection("users").document(userUID)

        docRef.getDocument { (document, error) in
            guard error == nil else {
                print("error", error ?? "")
                completion("")  // Return an empty string if there's an error
                return
            }

            if let document = document, document.exists {
                let data = document.data()
                let displayName = data?["name"] as? String ?? ""
                completion(displayName)  // Pass the displayName to the completion handler
            } else {
                completion("")  // Return an empty string if the document does not exist
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
        
        let displayName = members[indexPath.row]
        cell.usernameLabel?.text = displayName
        
        return cell
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
