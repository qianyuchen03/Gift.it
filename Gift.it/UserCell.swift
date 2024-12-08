//
//  UserCell.swift
//  Gift.it
//
//  Created by Prerna Singh on 11/11/24.
//

import UIKit

class UserCell: UITableViewCell {

    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var addButton: UIButton!
    
    var addButtonAction: (() -> Void)?

//    @IBAction func addButtonTapped(_ sender: UIButton) {
//        print("BUTTON IS TAPPED")
//        addButtonAction?()
//    }
    @IBAction func addButtonTapped(_ sender: Any) {
        print("BUTTON IS TAPPED")
        
        // Adjust the font size and other properties for better fit
        addButton.titleLabel?.font = UIFont.systemFont(ofSize: 8, weight: .medium) // Adjust font size if needed
        addButton.titleLabel?.adjustsFontSizeToFitWidth = true // Ensure text scales to fit
        addButton.titleLabel?.minimumScaleFactor = 0.8 // Allow slight shrinking if necessary
        addButton.titleLabel?.numberOfLines = 1 // Ensure single-line text
        
        // Update button state
        addButton.setTitle("Pending", for: .normal)
        addButton.isEnabled = false
        addButtonAction?()
    }

}
