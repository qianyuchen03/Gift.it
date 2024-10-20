//
//  CreateProfileViewController.swift
//  Gift.it
//
//  Created by Rachel Huang on 10/18/24.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class CreateProfileViewController: UIViewController {

    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var birthdayField: UITextField!
    @IBOutlet weak var errorMessage: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func createAccountButtonTapped(_ sender: Any) {
        Auth.auth().createUser(withEmail: emailField.text!, password: passwordField.text!){
            (authResult, error) in
            if let error = error as NSError? {
                self.errorMessage.text = "\(error.localizedDescription)"
            } else {
                self.errorMessage.text = ""
                if let user = Auth.auth().currentUser {
                    // Get the Firestore database reference
                    let db = Firestore.firestore()
                    
                    // Prepare the data to store in Firestore
                    let userData: [String: Any] = [
                        "name": self.nameField.text ?? "",
                        "email": self.emailField.text ?? "",
                        "username": self.usernameField.text ?? "",
                        "birthday": self.birthdayField.text ?? "",
                        "uid": user.uid
                    ]
                    
                    // Store the user data in the "users" collection with the user's UID as the document ID
                    db.collection("users").document(user.uid).setData(userData) { error in
                        if let error = error {
                            // Handle Firestore write error
                            self.errorMessage.text = "Error saving user data: \(error.localizedDescription)"
                        } else {
                            // Successfully saved the user's data in Firestore
                            self.errorMessage.text = ""
                            
                            // Perform the segue to the next screen after successful account creation and data storage
                            self.performSegue(withIdentifier: "CreatedProfileSegue", sender: self)
                        }
                    }
                }
            }
            
        }

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
