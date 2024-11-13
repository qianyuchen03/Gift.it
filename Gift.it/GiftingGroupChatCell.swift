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
        groupchatName.text = chat.convoID
        groupchatName.font = UIFont(name: "Courier New Bold", size: 20)
                
        latestMessage.text = chat.latestMsg
        latestMessage.font = UIFont(name: "Courier New", size: 16)
        latestMessage.lineBreakMode = .byTruncatingTail
        latestMessage.numberOfLines = 1
                
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        time.text = dateFormatter.string(from: chat.time)
        time.font = UIFont(name: "Courier New", size: 14)
    }

}
