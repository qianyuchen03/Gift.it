//
//  FriendsNotificationsCell.swift
//  Gift.it
//
//  Created by Qianyu Chen on 11/13/24.
//

import UIKit

class FriendsNotificationsCell: UITableViewCell {
    
    @IBOutlet weak var notifLabel: UILabel!

    func configure(with friendName : String) {
        
        notifLabel.font = UIFont(name: "Courier New Bold", size: 14)
        notifLabel.text = "\(friendName) added you as a friend"
        
    }

}
