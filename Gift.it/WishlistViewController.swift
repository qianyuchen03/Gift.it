//
//  WishlistViewController.swift
//  Gift.it
//
//  Created by Qianyu Chen on 10/19/24.
//

import UIKit

protocol AddItemDelegate {
    func didAddItem(name: String, cost: Double)
}
    
extension WishlistViewController: AddItemDelegate {
    func didAddItem(name: String, cost: Double) {
        wishlistItems.append((name: name, cost: cost))
        wishlistTableView.reloadData()
    }
}

class WishlistViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var wishlistItems: [(name: String, cost: Double)] = []
    
    @IBOutlet weak var wishlistTableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        wishlistTableView.dataSource = self
        wishlistTableView.delegate = self
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
        cell.textLabel?.text = "\(wishlistItems[indexPath.row].name) - $\(wishlistItems[indexPath.row].cost)"
        
        // Add an "X" button to delete the item
//        let deleteButton = UIButton(type: .system)
//        deleteButton.setTitle("X", for: .normal)
//        deleteButton.addTarget(self, action: #selector(deleteItem(_:)), for: .touchUpInside)
//        deleteButton.tag = indexPath.row
//        cell.accessoryView = deleteButton
        return cell
    }
    

//    @objc func deleteItem(_ sender: UIButton) {
//        let index = sender.tag
//        wishlistItems.remove(at: index)
//        wishlistTableView.reloadData()
//    }
}


    


