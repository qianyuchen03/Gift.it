//
//  ChatViewController.swift
//  Gift.it
//
//  Created by Tanya Joseph on 11/4/24.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

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

struct MessageData: Codable {
    var content: String
    var date: Date
    var id: String
    var senderId: String
}

struct AllMessagesData: Codable {
    var messages: [MessageData]
}

class ChatViewController: MessagesViewController {
    
    public static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    
    var db: Firestore!
    var listener: ListenerRegistration?
    let uid = Auth.auth().currentUser!.uid
    
    var selfSender = Sender(photoURL: "", senderId: "", displayName: "")
    var conversationId = ""
    var chatName = ""
    var isNewConversation = false // TODO MAYBE CHANGE THIS DEPENDING ON NEEDS
    var messages = [Message]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        db = Firestore.firestore()
        
//        getChatName() { chatName in
//            self.title = chatName
//        }
        
        self.title = chatName // TODO CHANGE THIS
        
        getDisplayName(userUID: "exampleUID") { displayName in
            self.selfSender = Sender(photoURL: "", senderId: self.uid, displayName: displayName)
        }
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
        
        listenForMessages()
    }
    
    func getChatName(completion: @escaping (String) -> Void) {
        let docRef = db.collection("chats").document(conversationId)

        docRef.getDocument { (document, error) in
            guard error == nil else {
                print("error", error ?? "")
                completion("")  // Return an empty string if there's an error
                return
            }

            if let document = document, document.exists {
                let data = document.data()
                let chatName = data?["title"] as? String ?? ""
                completion(chatName)  // Pass the displayName to the completion handler
            } else {
                completion("")  // Return an empty string if the document does not exist
            }
        }
    }
    
    func getDisplayName(userUID: String, completion: @escaping (String) -> Void) {
        let docRef = db.collection("users").document(userUID)

        docRef.getDocument { (document, error) in
            guard error == nil else {
                print("error", error ?? "")
                completion("")  // Return an empty string if there's an error
                return
            }

            if let document = document, document.exists {
                let data = document.data()
                let displayName = data?["name"] as? String ?? ""
                completion(displayName)  // Pass the displayName to the completion handler
            } else {
                completion("")  // Return an empty string if the document does not exist
            }
        }
    }
    
    func createMessageId() -> String {
        // date, conversationId, senderEmail
        let dateString = Self.dateFormatter.string(from: Date())
        let conversationId = conversationId
        let senderId = uid
        
        let identifier = "\(dateString)_\(conversationId)_\(senderId)"
        return identifier
    }
    
    func listenForMessages() {
        // Remove any existing listener to avoid duplicates when switching chats
        listener?.remove()
        
        listener = db.collection("chats").document(conversationId)
            .addSnapshotListener { [weak self] documentSnapshot, error in
                guard let self = self else { return } // Ensure self is still available
                guard let document = documentSnapshot else {
                    print("Error fetching document: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                do {
                    let allMessages = try document.data(as: AllMessagesData.self)
                    var messagesWithSenders: [Message] = []
                    let dispatchGroup = DispatchGroup()

                    for message in allMessages.messages {
                        dispatchGroup.enter()
                        
                        self.getDisplayName(userUID: message.senderId) { displayName in
                            let sender = Sender(photoURL: "", senderId: message.senderId, displayName: displayName)
                            let myAttribute = [NSAttributedString.Key.font: UIFont(name: "Courier New", size: 18.0)!]
                            let message = Message(sender: sender, messageId: message.id, sentDate: message.date, kind: .attributedText(NSAttributedString(string: message.content, attributes: myAttribute)))
                            
                            messagesWithSenders.append(message)
                            dispatchGroup.leave()
                        }
                    }
                    
                    dispatchGroup.notify(queue: .main) {
                        self.messages = messagesWithSenders.sorted(by: { $0.sentDate < $1.sentDate })
                        self.messagesCollectionView.reloadData()
                        self.messagesCollectionView.scrollToItem(at: IndexPath(row: 0, section: self.messages.count - 1), at: .top, animated: false)
                    }
                } catch {
                    print("Error decoding messages: \(error.localizedDescription)")
                }
        }
    }
    
    /* Database management */
    
    func sendMessage(message: String, date: Date, messageId: String, senderId: String) {
        let newMessage = ["content": message, "date": date, "id": messageId, "senderId": senderId] as [String: Any]
        let newLatestMessage = ["date": date, "latest_message": message] as [String : Any]
        
        let docRef = db.collection("chats").document(conversationId)
        
        docRef.updateData([
            "messages": FieldValue.arrayUnion([newMessage]),
            "latest_message": newLatestMessage
        ])
    }

}

extension ChatViewController: InputBarAccessoryViewDelegate {
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            return
        }
        
        let date = Date()
        let messageId = createMessageId()
        
        let message = Message(sender: selfSender,
                               messageId: messageId,
                               sentDate: date,
                               kind: .text(text))
        
        if isNewConversation {
            // create new conversation
        } else {
            sendMessage(message: text, date: date, messageId: messageId, senderId: uid)
            messages.append(message)
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
    
    func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        print("PRINTING NAME PRINTING NAME")
        print(message.sender.displayName)
        print(message)
        return NSAttributedString(string: message.sender.displayName)
    }
    
    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
            return 10
    }
    
    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
            return 23
    }
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? UIColor(hex: "#F2EFDC", alpha: 0.75) : UIColor(hex: "#D9D9D9", alpha: 1.0)
    }
    
    func messageColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return UIColor(hex: "#555555", alpha: 1.0)
    }

}
