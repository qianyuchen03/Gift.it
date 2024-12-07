//
//  FriendsNotificationsCell.swift
//  Gift.it
//
//  Created by Qianyu Chen on 11/13/24.
//

import UIKit

protocol FriendsNotificationsCellDelegate: AnyObject {
    func acceptFriendRequest(notif: Notification)
    func deleteFriendRequest(notif: Notification)
}

class FriendsNotificationsCell: UITableViewCell {
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @IBOutlet weak var notifLabel: UILabel!
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var denyButton: UIButton!
    var delegate: FriendsNotificationsCellDelegate?
    var notif: Notification

    func configure(with notif : Notification) {
        
        self.notif = notif
        notifLabel.font = UIFont(name: "Courier New Bold", size: 14)
        notifLabel.text = notif.message
        
    }
    
    @IBAction func acceptTapped(_ sender: Any) {
        print("accept tapped")
        delegate?.acceptFriendRequest(notif: notif)
    }
    
    @IBAction func denyTapped(_ sender: Any) {
        print("deny tapped")
        delegate?.deleteFriendRequest(notif: notif)
    }
    

}
