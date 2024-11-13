import UIKit

class FriendWishlistViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    

    
    @IBOutlet var middleView: UIView!
    
    @IBOutlet var nowishlistLabel: UILabel!
    @IBOutlet var xButton: UIButton!
    @IBOutlet var wishTable: UITableView!
    var wishListItems: [[String : Any]] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupDismissGesture()
        
        wishTable.delegate = self
        wishTable.dataSource = self
    }
    
    private func setupDismissGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapOutsideMiddleView))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func handleTapOutsideMiddleView(_ sender: UITapGestureRecognizer) {
        let touchPoint = sender.location(in: view)
        
        // Check if the touch is outside the middle view
        if !middleView.frame.contains(touchPoint) {
            // Dismiss the popover or take the desired action
            dismiss(animated: true, completion: nil)
        }
    }
    @IBAction func xButtonPressed(_ sender: Any) {
        print("EXITING")
        dismiss(animated: true, completion: nil)
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(wishListItems.count == 0) {
            nowishlistLabel.text = "No wishlist items yet! :("
        }
        return wishListItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "WishListItemCell", for: indexPath)
                
                let item = wishListItems[indexPath.row]
                let itemName = item["name"] as? String ?? "Unnamed Item"
                let itemCost = item["cost"] as? NSNumber ?? 0
                cell.textLabel?.font = UIFont(name: "Courier New", size: 17) // Adjust size as needed

        cell.textLabel?.text = itemName + " - " + "$" + itemCost.description
                return cell
    }
}
