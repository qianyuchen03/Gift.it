//
//  GiftingGroupChatCell.swift
//  Gift.it
//
//  Created by Qianyu Chen on 11/12/24.
//

import UIKit

class GiftingGroupChatCell: UITableViewCell {
    
    @IBOutlet weak var groupchatName: UILabel!
    @IBOutlet weak var latestMessage: UILabel!
    @IBOutlet weak var time: UILabel!
    
    func configure(with chat: Chat) {
        groupchatName.text = String(chat.convoID)
        latestMessage.text = String(chat.latestMsg)
        let date = chat.time
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        let dateString = dateFormatter.string(from: date)
        time.text = dateString
    }
    

}
