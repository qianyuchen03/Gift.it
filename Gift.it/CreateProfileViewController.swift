//
//  CreateProfileViewController.swift
//  Gift.it
//
//  Created by Rachel Huang on 10/18/24.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

class CreateProfileViewController: UIViewController {

    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var birthdayField: UITextField!
    @IBOutlet weak var errorMessage: UILabel!
    
    @IBOutlet weak var pfpImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        configureDatePicker()
        configureProfileImageTap()
        
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
    
    func configureProfileImageTap() {
        // Enable user interaction on the UIImageView
        pfpImageView.isUserInteractionEnabled = true
        
        // Create and add a tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(profileImageTapped))
        pfpImageView.addGestureRecognizer(tapGesture)
    }
    
    @objc func profileImageTapped() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true  // Enables the cropping overlay
        present(imagePicker, animated: true, completion: nil)
    }

    
    func createCircularOverlay() -> UIView {
        // Create an overlay view matching the screen size
        let overlay = UIView(frame: UIScreen.main.bounds)
        overlay.backgroundColor = UIColor.clear

        // Create a dimmed background with a circular cut-out
        let backgroundView = UIView(frame: overlay.bounds)
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        overlay.addSubview(backgroundView)
        
        // Create a circular path for the cut-out
        let circlePath = UIBezierPath(rect: overlay.bounds)
        let radius = min(overlay.bounds.width, overlay.bounds.height) / 2.5 // Adjust radius as needed
        let circularCutOut = UIBezierPath(ovalIn: CGRect(
            x: overlay.bounds.midX - radius,
            y: overlay.bounds.midY - radius,
            width: 2 * radius,
            height: 2 * radius
        ))
        circlePath.append(circularCutOut)
        circlePath.usesEvenOddFillRule = true

        // Mask the background view to show only the circular cut-out
        let maskLayer = CAShapeLayer()
        maskLayer.path = circlePath.cgPath
        maskLayer.fillRule = .evenOdd
        backgroundView.layer.mask = maskLayer
        
        return overlay
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
        if validateFields() {

                       Auth.auth().createUser(withEmail: self.emailField.text!, password: self.passwordField.text!) { authResult, error in
                           if let error = error as NSError? {
                               // Handle error in Firebase Authentication
                               self.errorMessage.text = "Error: \(error.localizedDescription)"
                           } else {
                               // Step 3: Save the user data to Firestore if authentication is successful
                               self.saveUserDataToFirestore { isSuccess in
                                   if isSuccess {
                                       // Step 4: Upload the profile picture and update Firestore with the image URL
                                       self.uploadProfileImageAndUpdateFirestore()
                                   } else {
                                       self.errorMessage.text = "Failed to save user data."
                                   }
                               }
                           }
                       }
                   }
               }
    
    
    
    // Validate all input fields with specific error messages
        func validateFields() -> Bool{
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
                return false
            }
            
            // Clear the error message if everything is valid
            errorMessage.text = ""
            return true
        }
    
    // Helper function to check valid email format
    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: email)
    }
    
    // Save user data to Firestore after creating the account
    func saveUserDataToFirestore(completion: @escaping (Bool) -> Void) {
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
                    completion(false)
                } else {
                    // Data saved successfully
                    completion(true)
                }
            }
        }
    }

    func uploadProfileImageAndUpdateFirestore() {
        if let profileImage = pfpImageView.image {
            // Step 1: Upload the profile image to Firebase Storage
            uploadProfileImage(image: profileImage) { imageUrl in
                if let imageUrl = imageUrl {
                    // Step 2: Update Firestore with the profile image URL
                    self.updateProfileImageInFirestore(imageUrl: imageUrl)
                } else {
                    self.errorMessage.text = "Failed to upload profile image."
                }
            }
        } else {
            self.errorMessage.text = "Profile image is missing."
        }
    }

    
    func uploadProfileImage(image: UIImage, completion: @escaping (String?) -> Void) {
        // Create a reference to Firebase Storage
        let storageRef = Storage.storage().reference()

        // Generate a unique image name (based on the user's UID or random UUID)
        let imageName = UUID().uuidString
        let imageRef = storageRef.child("profile_pictures/\(imageName).jpg")

        // Compress the image to JPEG data
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            // Upload the image to Firebase Storage
            imageRef.putData(imageData, metadata: nil) { metadata, error in
                if let error = error {
                    print("Error uploading image: \(error.localizedDescription)")
                    completion(nil)
                    return
                }

                // Once the upload is complete, get the image URL
                imageRef.downloadURL { url, error in
                    if let error = error {
                        print("Error getting image URL: \(error.localizedDescription)")
                        completion(nil)
                    } else if let url = url {
                        // Return the download URL
                        completion(url.absoluteString)
                    }
                }
            }
        } else {
            completion(nil)
        }
    }

    
    func updateProfileImageInFirestore(imageUrl: String) {
        if let user = Auth.auth().currentUser {
            // Get Firestore database reference
            let db = Firestore.firestore()

            // Update the user's Firestore document with the profile image URL
            db.collection("users").document(user.uid).updateData([
                "profileImageUrl": imageUrl
            ]) { error in
                if let error = error {
                    // Handle error in updating Firestore
                    self.errorMessage.text = "Error saving image URL to Firestore: \(error.localizedDescription)"
                } else {
                    // Successfully updated Firestore, navigate to next screen
                    self.performSegue(withIdentifier: "CreatedProfileSegue", sender: self)
                }
            }
        }
    }

    


    // Function to check if the username is unique
//    func checkUsernameUnique(completion: @escaping (Bool) -> Void) {
//        let db = Firestore.firestore()
//        
//        // Query Firestore for any users with the same username
//        db.collection("users").whereField("username", isEqualTo: usernameField.text ?? "")
//            .getDocuments { querySnapshot, error in
//                if let error = error {
//                    print("Error checking username uniqueness: \(error)")
//                    completion(false)
//                } else {
//                    if let documents = querySnapshot?.documents, !documents.isEmpty {
//                        // Username already exists
//                        completion(false)
//                    } else {
//                        // Username is unique
//                        completion(true)
//                    }
//                }
//            }
//        
//    }
}

// Image picker delegate methods
extension CreateProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // Get the edited image (cropped to a square by UIImagePickerController)
        if let editedImage = info[.editedImage] as? UIImage {
            // Crop the square image to a circle
            let circularImage = cropImageToCircle(image: editedImage)
            
            // Set the circular image to the profile picture ImageView
            pfpImageView.image = circularImage
        }
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    func cropImageToCircle(image: UIImage) -> UIImage? {
        let squareSize = min(image.size.width, image.size.height)
        let imageView = UIImageView(image: image)
        
        // Create a circular path to clip the image
        UIGraphicsBeginImageContextWithOptions(CGSize(width: squareSize, height: squareSize), false, 0.0)
        let path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: squareSize, height: squareSize))
        path.addClip()
        
        // Draw the image within the circular path
        imageView.draw(CGRect(x: 0, y: 0, width: squareSize, height: squareSize))
        
        // Capture the clipped image
        let circularImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return circularImage
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}


