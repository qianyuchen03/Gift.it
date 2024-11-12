//
//  GiftingGroupInvitationCell.swift
//  Gift.it
//
//  Created by Rachel Huang on 11/12/24.
//

// InvitationCell.swift
import UIKit

protocol GiftingGroupInvitationCellDelegate: AnyObject {
    func didAcceptInvitation(friendId: String, friendBirthday: Date)
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

    @IBAction func acceptTapped(_ sender: Any) {
        if let friendId = friendId, let friendBirthday = friendBirthday {
            delegate?.didAcceptInvitation(friendId: friendId, friendBirthday: friendBirthday)
        }
    }
    
    @IBAction func denyTapped(_ sender: Any) {
        if let friendId = friendId {
            delegate?.didDenyInvitation(friendId: friendId)
        }
    }
    
}
