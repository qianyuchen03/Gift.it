//
//  ChatViewController.swift
//  Gift.it
//
//  Created by Tanya Joseph on 11/4/24.
//

import UIKit
import MessageKit
import InputBarAccessoryView

struct Message: MessageType {
    var sender: any MessageKit.SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKit.MessageKind
}

struct Sender: SenderType {
    var photoURL: String
    var senderId: String
    var displayName: String
}

class ChatViewController: MessagesViewController {
    
    public static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    
    public var isNewConversation = false // TODO MAYBE CHANGE THIS DEPENDING ON NEEDS
    
    private var messages = [Message]()
    
    private let selfSender = Sender(photoURL: "", senderId: "1", displayName: "Doris") // TODO CHANGE THIS

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Donkey's Birthday" // TODO CHANGE THIS
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
        
        listenForMessages()
        messagesCollectionView.reloadData()
    }
    
    func createMessageId() -> String {
        // date, conversationId, senderEmail
        let dateString = Self.dateFormatter.string(from: Date())
        let conversationId = "rawr"
        let senderEmail = "doris@gmail.com"
        
        let identifier = "\(dateString)_\(conversationId)_\(senderEmail)"
        return identifier
    }
    
    func listenForMessages() {
        // TODO
    }
    
    /* Database management */
    
    func getAllMessagesForConversation(with id: String, completion: @escaping (Result<String, Error>) -> Void) {
        // TODO
    }
    
    func sendMessage(to conversation: String, message: Message, completion: @escaping (Bool) -> Void) {
         // TODO
    }

}

extension ChatViewController: InputBarAccessoryViewDelegate {
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            return
        }
        
        let message = Message(sender: selfSender,
                               messageId: createMessageId(),
                               sentDate: Date(),
                               kind: .text(text))
        
        if isNewConversation {
            // create new conversation
        } else {
            // append to existing conversation
            // add new message to messages
            // update db
            messages.append(message)
            messagesCollectionView.reloadData()
            inputBar.inputTextView.text = ""
        }
    }
}

extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    var currentSender: any MessageKit.SenderType {
        return selfSender
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessageKit.MessagesCollectionView) -> any MessageKit.MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessageKit.MessagesCollectionView) -> Int {
        return messages.count
    }
}
