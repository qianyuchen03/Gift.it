//
//  LoginViewController.swift
//  Gift.it
//
//  Created by Prerna Singh on 10/15/24.
//

import UIKit

class LoginViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    
    @IBAction func loginButtonTapped(_ sender: UIButton) {
        // Perform the segue to go to the next view controller
        performSegue(withIdentifier: "LoginSegue", sender: self)
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
