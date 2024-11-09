//
//  GiftingGroupViewController.swift
//  Gift.it
//
//  Created by Qianyu Chen on 11/9/24.
//

import UIKit

class GiftingGroupViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    
    var giftingGroups: [(name: String, chatID: String)] = [
            ("Pog Group", "chat1"),
            ("Donkey Group", "chat2"),
            ("Shrek Group", "chat3")
        ]

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
    }
    
    // Number of rows in section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return giftingGroups.count
        }
        
        // Configure the cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ChatCell", for: indexPath)
            
            cell.textLabel?.font = UIFont(name: "Courier New Bold", size: 20)
            
            let group = giftingGroups[indexPath.row]
            cell.textLabel?.text = group.name // Set the cell's text label to the group name
            
            return cell
        }
    
    // Handle cell selection (segue to the chat screen)
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//            let selectedGroup = giftingGroups[indexPath.row]
//            
//            // Perform a segue to the chat screen
//            performSegue(withIdentifier: "ChatSegue", sender: selectedGroup)
//        }
    
    // Prepare for segue to the chat screen
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if segue.identifier == "ChatSegue" {
                if let chatVC = segue.destination as? ChatViewController,
                   let selectedGroup = sender as? (name: String, chatID: String) {
                    // Pass the selected group data (chatID) to the ChatViewController
//                    chatVC.chatID = selectedGroup.chatID
                }
            }
        }
    
    //TODO DELETE GROUPS
    

}
