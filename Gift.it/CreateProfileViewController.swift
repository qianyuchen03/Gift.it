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
        configureDatePicker()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func configureDatePicker() {
         let datePicker = UIDatePicker()
         datePicker.datePickerMode = .date
         datePicker.maximumDate = Date()
         datePicker.preferredDatePickerStyle = .wheels
         datePicker.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
         
         // Assign the datePicker to the inputView of birthdayField
         birthdayField.inputView = datePicker
         
         // Optionally set an initial date, e.g. today's date
         birthdayField.text = formatDate(date: Date())
     }
    @objc func dateChanged(_ datePicker: UIDatePicker) {
        // Update birthdayField with the selected date in desired format
        birthdayField.text = formatDate(date: datePicker.date)
    }

    func formatDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM dd, yyyy"
        return formatter.string(from: date)
    }
    
    @IBAction func createAccountButtonTapped(_ sender: Any) {
        var valid = validateFields()
        print("The user info was \(valid)")
        if valid == "" {
            // Step 2: Only if validation passes, create the Firebase account
            Auth.auth().createUser(withEmail: emailField.text!, password: passwordField.text!) { authResult, error in
                if let error = error as NSError? {
                    // Display Firebase authentication error
                    self.errorMessage.text = "Error: \(error.localizedDescription)"
                } else {
                    // Step 3: If Firebase account creation is successful, save data to Firestore
                    self.saveUserDataToFirestore()

                }
            }
        }
    }
    
    // Validate all input fields with specific error messages
        func validateFields() -> String {
            var validationMessages: [String] = []
            
            // Check if name is filled
            if nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true {
                validationMessages.append("Name cannot be empty.")
            }
            
            // Check if username is filled
            if usernameField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true {
                validationMessages.append("Username cannot be empty.")
            }
            
            // Check if email is filled and in the correct format
            if emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true {
                validationMessages.append("Email cannot be empty.")
            } else if !isValidEmail(emailField.text ?? "") {
                validationMessages.append("Invalid email format.")
            }
            
            // Check if password is filled and at least 6 characters long
            if passwordField.text?.isEmpty ?? true {
                validationMessages.append("Password cannot be empty.")
            } else if (passwordField.text?.count ?? 0) < 6 {
                validationMessages.append("Password must be at least 6 characters long.")
            }
            
            // Check if birthday is filled
            if birthdayField.text?.isEmpty ?? true {
                validationMessages.append("Birthday cannot be empty.")
            }
            
            // If there are any validation errors, display them and return false
            if !validationMessages.isEmpty {
                errorMessage.text = validationMessages.joined(separator: "\n")
                print(errorMessage.text!)
                return errorMessage.text!
            }
            
            // Clear the error message if everything is valid
            errorMessage.text = ""
            return ""
        }
    
    // Helper function to check valid email format
    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: email)
    }
    
    // Save user data to Firestore after creating the account
        func saveUserDataToFirestore() {
            if let user = Auth.auth().currentUser {
                // Get Firestore database reference
                let db = Firestore.firestore()
                
                // Prepare the data to store in Firestore
                let userData: [String: Any] = [
                    "name": nameField.text ?? "",
                    "email": emailField.text ?? "",
                    "username": usernameField.text ?? "",
                    "birthday": birthdayField.text ?? "",
                    "uid": user.uid
                ]
                
                // Store the user data in Firestore
                db.collection("users").document(user.uid).setData(userData) { error in
                    if let error = error {
                        // Display Firestore write error
                        self.errorMessage.text = "Error saving user data: \(error.localizedDescription)"
                    } else {
                        // Data saved successfully, proceed with the segue
                        self.performSegue(withIdentifier: "CreatedProfileSegue", sender: self)
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


