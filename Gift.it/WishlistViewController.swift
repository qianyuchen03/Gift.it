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
        wishlistItems.append((name, cost))
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


    


