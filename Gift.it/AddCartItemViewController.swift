//
//  AddCartItemViewController.swift
//  Gift.it
//
//  Created by Tanya Joseph on 12/4/24.
//

import UIKit

class AddCartItemViewController: UIViewController {
    
    @IBOutlet weak var itemNameTextField: UITextField!
    @IBOutlet weak var priceTextField: UITextField!
    
    var delegate: CartItemAdder?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
    }
    
    @IBAction func addToCartButtonPressed(_ sender: Any) {
        let itemName = itemNameTextField.text!
        let price = priceTextField.text!
        
        if itemName.isEmpty {
            showError(message: "Missing Item Name")
        } else if price.isEmpty {
            showError(message: "Missing Price")
        } else if Double(price) == nil {
            showError(message: "Please enter a numerical value")
        } else {
            let priceDouble = Double(price)!
            delegate?.addCartItem(name: itemName, cost: priceDouble)
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
    
    @IBAction func closeButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
