//
//  GiftingGroupInvitationCell.swift
//  Gift.it
//
//  Created by Rachel Huang on 11/12/24.
//

// InvitationCell.swift
import UIKit

protocol GiftingGroupInvitationCellDelegate: AnyObject {
    func didAcceptInvitation(friendId: String, friendBirthday: Date, friendName: String)
    func didDenyInvitation(friendId: String)
}

class GiftingGroupInvitationCell: UITableViewCell {

    @IBOutlet weak var invitationLabel: UILabel!
    
    @IBOutlet weak var denyButton: UIButton!
    @IBOutlet weak var acceptButton: UIButton!
    // Delegate to handle button actions
    var delegate: GiftingGroupInvitationCellDelegate?
    var friendId: String?
    var friendBirthday: Date?
    var friendName: String?

    @IBAction func acceptTapped(_ sender: Any) {
        print("accept tapped")
        if let friendId = friendId, let friendBirthday = friendBirthday, let friendName = friendName {
            print("inside if")
            delegate?.didAcceptInvitation(friendId: friendId, friendBirthday: friendBirthday, friendName: friendName)
        }
    }
    
    @IBAction func denyTapped(_ sender: Any) {
        print("deny tapped")
        if let friendId = friendId {

            delegate?.didDenyInvitation(friendId: friendId)
        }
    }
    
}
