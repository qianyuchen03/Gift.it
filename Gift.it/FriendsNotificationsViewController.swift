//
//  FriendsNotificationsViewController.swift
//  Gift.it
//
//  Created by Qianyu Chen on 11/13/24.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class FriendsNotificationsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{
    
    @IBOutlet weak var tableView: UITableView!
    
    var notifs: [String] = []
    let db = Firestore.firestore()
    let uid = Auth.auth().currentUser!.uid

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        fetchFriendsNames()
    }
    
    func fetchFriendsNames() {
        let usersRef = db.collection("users")
        
        // Fetch the friendsList array for the logged-in user
        usersRef.document(uid).getDocument { (document, error) in
            if let error = error {
                print("Error fetching user document: \(error.localizedDescription)")
                return
            }
            
            guard let data = document?.data(),
                  let friendsList = data["friendsList"] as? [String] else {
                print("No friends list found for this user.")
                return
            }
            
            // Group dispatch for asynchronous operations
            let dispatchGroup = DispatchGroup()
            
            // Fetch each friend's name
            for friendUID in friendsList {
                dispatchGroup.enter()
                usersRef.document(friendUID).getDocument { (friendDocument, error) in
                    if let error = error {
                        print("Error fetching friend document for UID \(friendUID): \(error.localizedDescription)")
                    } else if let friendData = friendDocument?.data(),
                              let friendName = friendData["name"] as? String {
                        self.notifs.append(friendName)
                    }
                    dispatchGroup.leave()
                }
            }
            
            // Completion after all friends are fetched
            dispatchGroup.notify(queue: .main) {
                print("Friends' names: \(self.notifs)")
                self.tableView.reloadData()
            }
        }
    }

    
    // Number of rows in section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notifs.count
    }
        
        // Configure the cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "FriendsNotificationsCell", for: indexPath) as! FriendsNotificationsCell
        
        let friendName = notifs[indexPath.row]
        cell.configure(with: friendName)
        
        return cell
    }

}
