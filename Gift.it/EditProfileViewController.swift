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

        // Do any additional setup after loading the view.
        nameTextField.text = originalName
        birthdayTextField.text = originalBirthday
        editBioTextView.text = originalBio
        
        nameTextField.delegate = self
        birthdayTextField.delegate = self
        editBioTextView.delegate = self
        
        updateCharacterCount()
        
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.addTarget(self, action: #selector(dateChange(datePicker:)), for: UIControl.Event.valueChanged)
        datePicker.frame.size = CGSize(width: 0, height: 300)
        datePicker.preferredDatePickerStyle = .wheels
        
        birthdayTextField.inputView = datePicker
//        birthdayTextField.text = formatDate(date: Date()) // sets field to todays date
    }
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        let otherVC = delegate as! ProfileChanger
        otherVC.changeProfile(newName: nameTextField.text!, newBirthday: birthdayTextField.text!, newBio: editBioTextView.text!)
    }
    
    @objc func dateChange(datePicker: UIDatePicker) {
        birthdayTextField.text = formatDate(date: datePicker.date)
    }
    
    func formatDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM dd, yyyy"
        return formatter.string(from: date)
    }
    
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
    
    // Called when 'return' key pressed

    func textFieldShouldReturn(_ textField:UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // Called when the user clicks on the view outside of the UITextField

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    // 4 funcs To dimiss keyboard and move the textView UP/Down when the keyboard shows
    @objc func tap(_ sender: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        textView.layer.borderWidth = 2
        textView.layer.borderColor = UIColor.clear.cgColor
        animateViewMoving(true, moveValue: 175)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        textView.layer.borderWidth = 0
        textView.layer.borderColor = UIColor.clear.cgColor
        animateViewMoving(false, moveValue: 175)
    }
    
    func animateViewMoving (_ up:Bool, moveValue :CGFloat){
        let movementDuration:TimeInterval = 0.3
        let movement:CGFloat = ( up ? -moveValue : moveValue)
        UIView.beginAnimations( "animateView", context: nil)
        UIView.setAnimationBeginsFromCurrentState(true)
        UIView.setAnimationDuration(movementDuration )
        self.view.frame = self.view.frame.offsetBy(dx: 0,  dy: movement)
        UIView.commitAnimations()
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
