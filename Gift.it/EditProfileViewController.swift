//
//  EditProfileViewController.swift
//  Gift.it
//
//  Created by Tanya Joseph on 10/17/24.
//

import UIKit

class EditProfileViewController: UIViewController, UITextViewDelegate, UITextFieldDelegate {

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var birthdayTextField: UITextField!
    @IBOutlet weak var editBioTextView: UITextView!
    @IBOutlet weak var characterCounterLabel: UILabel!
    
    var originalName = ""
    var originalBirthday = ""
    var originalBio = ""
    var delegate: UIViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        nameTextField.text = originalName
        birthdayTextField.text = originalBirthday
        editBioTextView.text = originalBio == "Edit profile to add bio" ? "" : originalBio
        
        nameTextField.delegate = self
        birthdayTextField.delegate = self
        editBioTextView.delegate = self
        
        /* To set the character counter*/
        updateCharacterCount()
        
        /* To use the date picker to edit the text field */
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.addTarget(self, action: #selector(dateChange(datePicker:)), for: UIControl.Event.valueChanged)
        datePicker.frame.size = CGSize(width: 0, height: 300)
        datePicker.preferredDatePickerStyle = .wheels
        birthdayTextField.inputView = datePicker
        // setting initial date
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = "MMMM dd, yyyy"
        if let date = dateFormatterGet.date(from: birthdayTextField.text!) {
            birthdayTextField.text = formatDate(date: date)
            datePicker.date = date
        } else {
            birthdayTextField.text = formatDate(date: Date())
        }
        
        /* To move text view when field is pressed so software keyboard does not cover it */
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: UIWindow.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillBeHidden), name: UIWindow.keyboardWillHideNotification, object: nil)

    }
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        let otherVC = delegate as! ProfileChanger
        otherVC.changeProfile(newName: nameTextField.text!, newBirthday: birthdayTextField.text!, newBio: editBioTextView.text!)
    }
    
    /* To use the date picker to edit the text field */
    
    @objc func dateChange(datePicker: UIDatePicker) {
        birthdayTextField.text = formatDate(date: datePicker.date)
    }
    
    func formatDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM dd, yyyy"
        return formatter.string(from: date)
    }
    
    /* To set the character counter and limit */
    
    func textViewDidChange(_ textView: UITextView) {
        updateCharacterCount()
    }
    
    func updateCharacterCount() {
        let characterCount = editBioTextView.text.count
        characterCounterLabel.text = "\(characterCount)/100"
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // get the current text, or use an empty string if that failed
        let currentText = textView.text ?? ""

        // attempt to read the range they are trying to change, or exit if we can't
        guard let stringRange = Range(range, in: currentText) else { return false }

        // add their new text to the existing text
        let updatedText = currentText.replacingCharacters(in: stringRange, with: text)

        // make sure the result is under 16 characters
        return updatedText.count <= 100
    }
    
    /* To move text view when field is pressed so software keyboard does not cover it */
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if self.editBioTextView.isFirstResponder == true {
            self.view.frame.origin.y -= 175
         }
    }

    @objc func keyboardWillBeHidden(notification: NSNotification){
        if self.editBioTextView.isFirstResponder == true {
           self.view.frame.origin.y += 175
        }
    }
    
    /* To automatically remove keyboard when user returns or touches out of the field */
    
    // Called when 'return' key pressed
    func textFieldShouldReturn(_ textField:UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // Called when the user clicks on the view outside of the UITextField
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }

}
