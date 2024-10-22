//
//  LoginViewController.swift
//  Gift.it
//
//  Created by Prerna Singh on 10/15/24.
//

import UIKit
import FirebaseAuth

class LoginViewController: UIViewController {
    @IBOutlet var passwordField: UITextField!
    @IBOutlet var errorField: UILabel!
    @IBOutlet var emailField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        Auth.auth().addStateDidChangeListener() {
            (auth, user) in
            if user != nil {
                self.performSegue(withIdentifier: "LoginSegue", sender: nil)
                self.emailField.text = nil
                self.passwordField.text = nil
            }
        }
        // Do any additional setup after loading the view.
    }
    
    @IBAction func loginButtonTapped(_ sender: Any) {
        // Perform the segue to go to the next view controller
        
        Auth.auth().signIn(withEmail: emailField.text!, password: passwordField.text!) { result, error in
            if let error {
                self.errorField.text = "Wrong Credentials, Please Try Again."
                return
            } else {
                self.errorField.text = ""
//                performSegue(withIdentifier: "LoginSegue", sender: self)
            }
        }
        
    }
    

    
    @IBAction func signUpButtonTapped(_ sender: Any) {
        //performSegue(withIdentifier: "CreateProfileSegue", sender: self)
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
