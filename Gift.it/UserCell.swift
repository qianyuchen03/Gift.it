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
        addButtonAction?()
    }
}
