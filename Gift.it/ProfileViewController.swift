//
//  ProfileViewController.swift
//  Gift.it
//
//  Created by Tanya Joseph on 10/17/24.
//

import UIKit
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

protocol ProfileChanger {
    
    func changeProfile(newName:String, newBirthday:String, newBio:String)
    
}

class ProfileViewController: UIViewController, ProfileChanger {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var birthdayLabel: UILabel!
    @IBOutlet weak var bioTextView: UITextView!
    
    var db: Firestore!
    let uid = Auth.auth().currentUser!.uid
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        db = Firestore.firestore()
        getUserProfile()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "EditProfileSegueIdentifier",
           let nextVC = segue.destination as? EditProfileViewController {
            nextVC.originalName = nameLabel.text!
            nextVC.username = usernameLabel.text!
            nextVC.originalBirthday = birthdayLabel.text!
            nextVC.originalBio = bioTextView.text!
            nextVC.delegate = self
        }
        
        if segue.identifier == "SettingsSegue",
           let nextVC = segue.destination as?
            SettingsViewController {
            nextVC.delegate = self
        }
    }
    
    func getUserProfile() {
        let docRef = db.collection("users").document(uid)

        docRef.getDocument { (document, error) in
            guard error == nil else {
                print("error", error ?? "")
                return
            }

            if let document = document, document.exists {
                let data = document.data()
                if let data = data {
                    print("data", data)
                    self.nameLabel.text = data["name"] as? String ?? ""
                    self.usernameLabel.text = data["username"] as? String ?? ""
                    self.birthdayLabel.text = data["birthday"] as? String ?? ""
                    self.bioTextView.text = data["bio"] as? String ?? "Edit profile to add bio"
                }
            }

        }
    }
    
    func changeProfile(newName:String, newBirthday:String, newBio:String) {
        nameLabel.text = newName
        birthdayLabel.text = newBirthday
        bioTextView.text = newBio
        
        let docRef = db.collection("users").document(uid)
        
        docRef.updateData([
            "name": newName,
            "birthday": newBirthday,
            "bio": newBio
        ])
            
    }

}
