import UIKit

class FriendWishlistViewController: UIViewController {

    
    @IBOutlet var middleView: UIView!
    
    @IBOutlet var xButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupDismissGesture()
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
}
