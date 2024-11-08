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
    let uid = Auth.auth().currentUser!.uid
    
    var selfSender = Sender(photoURL: "", senderId: "", displayName: "")
    let conversationId = "dqUzhK0Njia6fVucPHns"
    var isNewConversation = false // TODO MAYBE CHANGE THIS DEPENDING ON NEEDS
    var messages = [Message]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        db = Firestore.firestore()
        
        self.title = "Donkey's Birthday" // TODO CHANGE THIS
        
        getDisplayName(userUID: "exampleUID") { displayName in
            self.selfSender = Sender(photoURL: "", senderId: self.uid, displayName: displayName)
        }
        
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
        
//        getAllMessagesForConversation()
        
        listenForMessages()
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
        let conversationId = "rawr"
        let senderEmail = "doris@gmail.com"
        
        let identifier = "\(dateString)_\(conversationId)_\(senderEmail)"
        return identifier
    }
    
    func listenForMessages() {
        db.collection("chats").document(conversationId)
            .addSnapshotListener { [weak self] documentSnapshot, error in
            guard let document = documentSnapshot else {
              print("Error fetching document: \(error!)")
              return
            }
                do {
                    let allMessages = try document.data(as: AllMessagesData.self)
                    var messagesWithSenders: [Message] = []
                    let dispatchGroup = DispatchGroup()

                    for message in allMessages.messages {
                        dispatchGroup.enter()
                        
                        self!.getDisplayName(userUID: message.senderId) { displayName in
                            let sender = Sender(photoURL: "", senderId: message.senderId, displayName: displayName)
                            let message = Message(sender: sender, messageId: message.id, sentDate: message.date, kind: .text(message.content))
                            
                            messagesWithSenders.append(message)
                            dispatchGroup.leave()
                        }
                    }
                    
                    // This block is called when all display names have been fetched
                    dispatchGroup.notify(queue: .main) {
                        self!.messages = messagesWithSenders
                        print(self!.messages)
                        self!.messagesCollectionView.reloadData()
                    }
                } catch {
                    print(error)
                }
          }
    }
    
    /* Database management */
    
//    func getAllMessagesForConversation() {
//        let docRef = db.collection("chats").document(conversationId)
//
//        docRef.getDocument { (document, error) in
//            guard error == nil else {
//                print("error", error ?? "")
//                return
//            }
//
//            if let document = document, document.exists {
//                let data = document.data()
//                if let data = data {
//                    print("data", data)
//                    let messagesData = data["messages"]
//                    print(messagesData)
//                }
//            }
//
//        }
//    }
    
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
            return 25
    }

}
