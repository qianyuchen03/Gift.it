//
//  CartViewController.swift
//  Gift.it
//
//  Created by Tanya Joseph on 12/4/24.
//

import UIKit
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

protocol CartItemAdder {
    func addCartItem(name: String, cost: Double)
}

class CartViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, CartItemAdder {
    
    @IBOutlet weak var cartTableView: UITableView!
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var splitLabel: UILabel!
    
    var cartItems: [(name: String, cost: Double)] = []
    
    var db: Firestore!
    var conversationId = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        db = Firestore.firestore()
        
        cartTableView.dataSource = self
        cartTableView.delegate = self
        fetchCart()
    }
    
    func addCartItem(name: String, cost: Double) {
        cartItems.append((name, cost))
        updateCart()
        cartTableView.reloadData()
    }
    
    func updateCart() {
        let docRef = db.collection("chats").document(conversationId)
        
        let encodedCartItems = cartItems.map { item in
            return ["name": item.name, "cost": item.cost]
        }
        
        docRef.updateData(["cartItems": encodedCartItems]) { error in
            if let error = error {
                print("Error updating cart in Firestore: \(error)")
            } else {
                print("Cart successfully updated in Firestore!")
            }
        }
    }

    func fetchCart() {
        let docRef = db.collection("chats").document(conversationId)
        
        docRef.getDocument { (document, error) in
            if let error = error {
                print("Error fetching cart data: \(error)")
                return
            }
            
            if let document = document, document.exists {
                if let cartArray = document.data()?["cartItems"] as? [[String: Any]] {
                    self.cartItems = cartArray.compactMap { itemData in
                        guard let name = itemData["name"] as? String,
                              let cost = itemData["cost"] as? Double else {
                            return nil
                        }
                        return (name: name, cost: cost)
                    }
                    
                    print("Cart items successfully loaded")
                    self.cartTableView.reloadData()
                } else {
                    print("No cart items found.")
                }
            } else {
                print("Document does not exist.")
            }
        }
    }
    
    func deleteItemFromFirestore(item: (name: String, cost: Double)) {
        let docRef = db.collection("chats").document(conversationId)
        
        let itemToDelete: [String: Any] = ["name": item.name, "cost": item.cost]
        
        docRef.updateData([
            "cartItems": FieldValue.arrayRemove([itemToDelete])
        ]) { error in
            if let error = error {
                print("Error deleting item from cart in Firestore: \(error)")
            } else {
                print("Item successfully deleted from cart in Firestore!")
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "AddCartItemSegueIdentifier" {
            if let destination = segue.destination as? AddCartItemViewController {
                destination.delegate = self
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cartItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CartItemCell", for: indexPath)
        cell.textLabel?.font = UIFont(name: "Courier New Bold", size: 20)
        cell.textLabel?.text = "\(cartItems[indexPath.row].name) - $\(cartItems[indexPath.row].cost)"
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let deletedItem = cartItems[indexPath.row]
            cartItems.remove(at: indexPath.row)
            deleteItemFromFirestore(item: deletedItem)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}
