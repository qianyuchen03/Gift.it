//
//  AddItemViewController.swift
//  Gift.it
//
//  Created by Qianyu Chen on 10/19/24.
//

import UIKit

class AddItemViewController: UIViewController {
    
    @IBOutlet weak var itemNameTextField: UITextField!
    @IBOutlet weak var itemCostTextField: UITextField!
    
    var delegate: AddItemDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.5) // Semi-transparent background
    }

    @IBAction func addToWishlistTapped(_ sender: UIButton) {

        var str2 = itemCostTextField.text!
        var itemCost = 0.0
        if let price = Double(str2) {
            itemCost = Double(str2)!
        } else {
            let controller = UIAlertController(
                title: "Invalid input",
                message: "Please enter a numerical price",
                preferredStyle: .alert)
            controller.addAction(UIAlertAction(title: "OK", style: .default))
            present(controller, animated: true)
        }
        
        let itemName = itemNameTextField.text!
        delegate?.didAddItem(name: itemName, cost: itemCost)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func closeTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
}

