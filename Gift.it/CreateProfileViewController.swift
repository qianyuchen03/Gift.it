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
    
    let db = Firestore.firestore()
    
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
             Auth.auth().createUser(withEmail: emailField.text!, password: passwordField.text!) { authResult, error in
                 if let error = error as NSError? {
                     self.errorMessage.text = "Error: \(error.localizedDescription)"
                 } else {
                     self.saveUserDataToFirestore()
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
       func saveUserDataToFirestore() {
           guard let user = Auth.auth().currentUser else { return }
           
           let userData: [String: Any] = [
               "name": nameField.text ?? "",
               "email": emailField.text ?? "",
               "username": usernameField.text ?? "",
               "birthday": birthdayField.text ?? "",
               "uid": user.uid
           ]
           
           db.collection("users").document(user.uid).setData(userData) { error in
               if let error = error {
                   self.errorMessage.text = "Error saving user data: \(error.localizedDescription)"
               } else {
                   self.saveProfileImageToFirestore(userId: user.uid)
               }
           }
       }
       func saveProfileImageToFirestore(userId: String) {
           guard let image = pfpImageView.image,
                 let base64DataURL = convertImageToDataURL(image) else {
               errorMessage.text = "Failed to process profile image."
               return
           }
           
           db.collection("users").document(userId).updateData([
               "profilePicture": base64DataURL
           ]) { error in
               if let error = error {
                   self.errorMessage.text = "Error saving profile picture: \(error.localizedDescription)"
               } else {
                   self.performSegue(withIdentifier: "CreatedProfileSegue", sender: self)
               }
           }
       }
       
       
       
       func convertImageToDataURL(_ image: UIImage) -> String? {
           // Resize the image to a smaller resolution
           let resizedImage = image.resized(toWidth: 200)
           guard let imageData = resizedImage?.jpegData(compressionQuality: 0.5) else { return nil }
           let base64String = imageData.base64EncodedString()
           return "data:image/jpeg;base64,\(base64String)"
       }
       
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

// UIImage extension for resizing
extension UIImage {
    func resized(toWidth width: CGFloat) -> UIImage? {
        let canvasSize = CGSize(width: width, height: CGFloat(ceil(width / size.width * size.height)))
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: canvasSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}


