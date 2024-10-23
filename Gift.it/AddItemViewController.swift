//
//  AddItemViewController.swift
//  Gift.it
//
//  Created by Qianyu Chen on 10/19/24.
//

import UIKit

class AddItemViewController: UIViewController {
    
    @IBOutlet weak var itemCostTextField: UITextField!
    @IBOutlet weak var itemNameTextField: UITextField!
    
    var delegate: AddItemDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.5) // Semi-transparent background
    }

    @IBAction func addToWishlistTapped(_ sender: UIButton) {

        let str2 = itemCostTextField.text!
        var itemCost = 0.0
        
        if itemNameTextField.text!.isEmpty {
            showError(message: "Missing Item Name")
        } else if Double(str2) == nil {
            showError(message: "Please enter a numerical value")
        } else {
            itemCost = Double(str2)!
            let itemName = itemNameTextField.text!
            delegate?.didAddItem(name: itemName, cost: itemCost)
        }
    
        dismiss(animated: true, completion: nil)
    }
    
    func showError(message: String) {
        let controller = UIAlertController(
            title: "Invalid input",
            message: message,
            preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: "OK", style: .default))
        present(controller, animated: true)
    }
    
    @IBAction func closeTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
}

