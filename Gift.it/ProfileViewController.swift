//
//  ProfileViewController.swift
//  Gift.it
//
//  Created by Tanya Joseph on 10/17/24.
//

import UIKit

protocol ProfileChanger {
    
    func changeProfile(newName:String, newBirthday:String, newBio:String)
    
}

class ProfileViewController: UIViewController, ProfileChanger {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var birthdayLabel: UILabel!
    @IBOutlet weak var bioTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "EditProfileSegueIdentifier",
           let nextVC = segue.destination as? EditProfileViewController {
            nextVC.originalName = nameLabel.text!
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
    
    func changeProfile(newName:String, newBirthday:String, newBio:String) {
        nameLabel.text = newName
        birthdayLabel.text = newBirthday
        bioTextView.text = newBio
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
