//
//  WishlistViewController.swift
//  Gift.it
//
//  Created by Qianyu Chen on 10/19/24.
//

import UIKit
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

protocol AddItemDelegate {
    func didAddItem(name: String, cost: Double)
}
    
extension WishlistViewController: AddItemDelegate {
    func didAddItem(name: String, cost: Double) {
        wishlistItems.append((name, cost))
        updateWishlist()
        wishlistTableView.reloadData()
    }
}

class WishlistViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var wishlistItems: [(name: String, cost: Double)] = []
    
    @IBOutlet weak var wishlistTableView: UITableView!
    
    var db: Firestore!
    let uid = Auth.auth().currentUser!.uid
    
    override func viewDidLoad() {
        super.viewDidLoad()
        wishlistTableView.dataSource = self
        wishlistTableView.delegate = self
        fetchWishlist()
    }
    
    func updateWishlist() {
        let db = Firestore.firestore()
        let docRef = db.collection("users").document(uid)
        
        // Convert each tuple in wishlistItems to a dictionary
        let encodedWishlistItems = wishlistItems.map { item in
            return ["name": item.name, "cost": item.cost]
        }
        
        // Update Firestore with the encoded array
        docRef.updateData(["wishlistItems": encodedWishlistItems]) { error in
            if let error = error {
                print("Error updating wishlist in Firestore: \(error)")
            } else {
                print("Wishlist successfully updated in Firestore!")
            }
        }
    }

    func fetchWishlist() {
        let db = Firestore.firestore()
        let docRef = db.collection("users").document(uid)
        
        docRef.getDocument { (document, error) in
            if let error = error {
                print("Error fetching wishlist data: \(error)")
                return
            }
            
            if let document = document, document.exists {
                if let wishlistArray = document.data()?["wishlistItems"] as? [[String: Any]] {
                    self.wishlistItems = wishlistArray.compactMap { itemData in
                        guard let name = itemData["name"] as? String,
                              let cost = itemData["cost"] as? Double else {
                            return nil
                        }
                        return (name: name, cost: cost)
                    }
                    
                    // Reload the view or update the UI as needed
                    print("Wishlist items successfully loaded: \(self.wishlistItems)")
                    self.wishlistTableView.reloadData()
                } else {
                    print("No wishlist items found.")
                }
            } else {
                print("Document does not exist.")
            }
        }
    }
    
    func deleteItemFromFirestore(item: (name: String, cost: Double)) {
            let db = Firestore.firestore()
            let docRef = db.collection("users").document(uid)
            
            let itemToDelete: [String: Any] = ["name": item.name, "cost": item.cost]
            
            docRef.updateData([
                "wishlistItems": FieldValue.arrayRemove([itemToDelete])
            ]) { error in
                if let error = error {
                    print("Error deleting item from wishlist in Firestore: \(error)")
                } else {
                    print("Item successfully deleted from wishlist in Firestore!")
                }
            }
        }

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if segue.identifier == "ShowAddItemSegue" {
                if let addItemVC = segue.destination as? AddItemViewController {
                    addItemVC.delegate = self
                }
            }
        }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return wishlistItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "WishlistItemCell", for: indexPath)
        cell.textLabel?.font = UIFont(name: "Courier New Bold", size: 20)
        cell.textLabel?.text = "\(wishlistItems[indexPath.row].name) - $\(wishlistItems[indexPath.row].cost)"
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let deletedItem = wishlistItems[indexPath.row]
            wishlistItems.remove(at: indexPath.row)
            deleteItemFromFirestore(item: deletedItem)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
}


    


