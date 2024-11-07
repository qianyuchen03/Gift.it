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
//        db = Firestore.firestore()
//        let docRef = db.collection("users").document(uid)
//        docRef.updateData(["wishlistItems" : wishlistItems])
        fetchWishlist()
    }
    
    func updateWishlist() {
        db = Firestore.firestore()
        let docRef = db.collection("users").document(uid)
        let encoded = FieldValue.arrayUnion(wishlistItems.compactMap( { _ in try? Firestore.Encoder().encode(0) } ) )
        docRef.updateData(["wishlistItems" : encoded])
    }
    
    func fetchWishlist() {
        
        db = Firestore.firestore()
        let docRef = db.collection("users").document(uid)
        
        docRef.getDocument { (document, error) in
            guard error == nil else {
                print("error", error ?? "")
                return
            }
            if let document = document, document.exists {
                let data = document.data()
                print("data", data as Any)
                if let items = data!["wishlistItems"] as? [[String: Any]] {
                            // Update the wishlistItems array
                            self.wishlistItems = items.compactMap { itemDict in
                                if let name = itemDict["name"] as? String,
                                   let cost = itemDict["cost"] as? Double {
                                    return (name: name, cost: cost)
                                }
                                return nil
                            }
                            // Reload the table view to reflect the changes
                    self.wishlistTableView.reloadData()
                }
                
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
            wishlistItems.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
}


    


