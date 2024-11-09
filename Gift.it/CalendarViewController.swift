//
//  CalendarViewController.swift
//  Gift.it
//
//  Created by Qianyu Chen on 11/9/24.
//

import UIKit
import FSCalendar
import FirebaseFirestore

extension UIColor {
    // Hex initializer for custom colors
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        var hexFormatted: String = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexFormatted = hexFormatted.replacingOccurrences(of: "#", with: "")
        
        var rgbValue: UInt64 = 0
        Scanner(string: hexFormatted).scanHexInt64(&rgbValue)
        
        let red = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgbValue & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}

class CalendarViewController: UIViewController, FSCalendarDelegate, FSCalendarDataSource {

    var calendar: FSCalendar!
    var birthdaysByDate: [String: [String]] = [:] // Dictionary to store birthdays by date (formatted as "MM-dd")
    
    override func viewDidLoad() {
        super.viewDidLoad()

        calendar = FSCalendar()
        calendar.delegate = self
        calendar.dataSource = self
        calendar.scrollDirection = .vertical
        calendar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(calendar)
        
        NSLayoutConstraint.activate([
                    calendar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                    calendar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                    calendar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                    calendar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
                ])
        
        calendar.appearance.headerTitleColor = UIColor(hex: "#F299B1")
        calendar.appearance.weekdayTextColor = UIColor(hex: "#F299B1")
        calendar.appearance.todayColor = UIColor(hex: "#F299B1")
        calendar.appearance.selectionColor = UIColor(hex: "#F299B1", alpha: 0.5)
        
        calendar.appearance.titleFont = UIFont(name: "Courier New Bold", size: 16)
        calendar.appearance.headerTitleFont = UIFont(name: "Courier New Bold", size: 18)
        calendar.appearance.weekdayFont = UIFont(name: "Courier New Bold", size: 14)
        
        fetchBirthdays()
    }

    func fetchBirthdays() {
        let db = Firestore.firestore()
        let usersRef = db.collection("users")
        
        // DateFormatter to parse "September 22, 2003" format
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM dd, yyyy" // Firestore date format
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "MM-dd" // Format as "MM-dd" for easy comparison
        
        usersRef.getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching birthdays: \(error)")
                    return
                }
                
            guard let documents = snapshot?.documents else { return }
            
            // Iterate through each document to extract birthday data
            for document in documents {
                let data = document.data()
                if let name = data["name"] as? String,
                   let birthdayString = data["birthday"] as? String,
                   let birthdayDate = dateFormatter.date(from: birthdayString) { // Parse birthday string to Date
                    
                    // Format the Date object to "MM-dd"
                    let formattedBirthday = outputFormatter.string(from: birthdayDate)
                    
                    // Add user to the correct date entry in the dictionary
                    if self.birthdaysByDate[formattedBirthday] != nil {
                        self.birthdaysByDate[formattedBirthday]?.append(name)
                    } else {
                        self.birthdaysByDate[formattedBirthday] = [name]
                    }
                }
            }
        }
    }

    
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM-dd"
            let selectedDate = dateFormatter.string(from: date)
            
            // Retrieve users with birthdays on the selected date
            print(selectedDate)
            if let users = birthdaysByDate[selectedDate] {
                presentBirthdayPopover(for: users)
            }
    }
    
    func presentBirthdayPopover(for users: [String]) {
            let message = users.joined(separator: "\n")
            let alertController = UIAlertController(title: "Birthdays:", message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default))
            present(alertController, animated: true)
        }
    
    // TODO ADD RED DOT
    
//    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, eventDefaultColorFor date: Date) -> UIColor? {
//        let outputFormatter = DateFormatter()
//        outputFormatter.dateFormat = "MM-dd"
//        let dateString = outputFormatter.string(from: date)
//        
//        if let _ = birthdaysByDate[dateString] {
//            return .red
//        }
//        
//        return nil
//    }

}
