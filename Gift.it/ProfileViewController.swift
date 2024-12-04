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

    @IBOutlet weak var pfpImageView: UIImageView!
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
            nextVC.profileImage = pfpImageView.image
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
                    print("Error fetching profile: \(error?.localizedDescription ?? "Unknown error")")
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
                        
                        // Fetch and display profile picture from Base64 string
                        if let imageDataURL = data["profilePicture"] as? String {
                            self.setProfileImage(from: imageDataURL)
                        } else {
                            print("No profile image data URL found.")
                        }
                    }
                }
            }
        }
        func setProfileImage(from dataURL: String) {
            // Extract Base64-encoded part from data URL
            guard let base64String = dataURL.split(separator: ",").last else {
                print("Invalid data URL format.")
                return
            }
            
            // Decode Base64 string into Data
            if let imageData = Data(base64Encoded: String(base64String)),
               let decodedImage = UIImage(data: imageData) {
                DispatchQueue.main.async {
                    self.pfpImageView.image = decodedImage
                }
            } else {
                print("Failed to decode Base64 string into an image.")
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
