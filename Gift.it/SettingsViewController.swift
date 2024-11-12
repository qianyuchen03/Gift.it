//
//  SelectionViewController.swift
//  Gift.it
//
//  Created by Qianyu Chen on 10/19/24.
//

import UIKit
import FirebaseAuth
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class SettingsViewController: UIViewController {
    
    var delegate: UIViewController!
    
    var db: Firestore!
    let uid = Auth.auth().currentUser!.uid
    
    @IBOutlet weak var modeSwitch1: UISwitch!
    @IBOutlet weak var modeSwitch2: UISwitch!
    @IBOutlet weak var modeSwitch3: UISwitch!
    @IBOutlet weak var bdaySwitch: UISwitch!
    @IBOutlet weak var notifSwitch: UISwitch!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchSettingsFirestore()
    }
    
    func fetchSettingsFirestore() {
        let db = Firestore.firestore()
        let docRef = db.collection("users").document(uid)
        
        docRef.getDocument { [self] (document, error) in
            if let error = error {
                print("Error fetching settings data: \(error)")
                return
            }
            
            if let document = document, document.exists {
                let data = document.data()
                if let mode2 = data?["modeSwitch2"], let mode1 = data?["modeSwitch1"], let mode3 = data?["modeSwitch3"], let notif = data?["notifSwitch"], let bday = data?["bdaySwitch"] {
                    self.modeSwitch2.isOn = mode2 as! Bool
                    self.modeSwitch1.isOn = mode1 as! Bool
                    self.modeSwitch3.isOn = mode3 as! Bool
                    self.bdaySwitch.isOn = bday as! Bool
                    self.notifSwitch.isOn = notif as! Bool
                } else {
                    print("Set to default settings.")
                    self.modeSwitch2.isOn = true
                    self.modeSwitch1.isOn = false
                    self.modeSwitch3.isOn = false
                    self.bdaySwitch.isOn = false
                    self.notifSwitch.isOn = false
                }
            } else {
                print("Document does not exist.")
            }
        }
    }
    
    func updateSettingsFirestore() {
        let db = Firestore.firestore()
        let docRef = db.collection("users").document(uid)
        
        docRef.updateData(["modeSwitch2" : modeSwitch2.isOn, "modeSwitch1" : modeSwitch1.isOn, "modeSwitch3" : modeSwitch3.isOn, "bdaySwitch" : bdaySwitch.isOn, "notifSwitch" : notifSwitch.isOn])
    }
    
    @IBAction func logoutButtonPressed(_ sender: Any) {
        do{
            try Auth.auth().signOut()
            self.performSegue(withIdentifier: "LoginbackSegue", sender: nil)

        } catch {
            print("Sign Out Error")
        }
    }
    
    @IBAction func hideBdaySwitch(_ sender: Any) {
        updateSettingsFirestore()
    }
    
    @IBAction func notificationSwitch(_ sender: Any) {
        updateSettingsFirestore()
    }
    
    @IBAction func switch1On(_ sender: Any) {
        updateSelectedSwitch(sender as! UISwitch)
    }
    
    @IBAction func switch2On(_ sender: Any) {
        updateSelectedSwitch(sender as! UISwitch)
    }
    
    @IBAction func switch3On(_ sender: Any) {
        updateSelectedSwitch(sender as! UISwitch)
    }
    
    func updateSelectedSwitch(_ selectedSwitch: UISwitch) {
        let switches = [modeSwitch1, modeSwitch2, modeSwitch3]
        
        for swi in switches {
            if swi == selectedSwitch {
                swi?.setOn(true, animated: true)
            } else {
                swi?.setOn(false, animated: true)
            }
        }
        
        updateSettingsFirestore()
    }

}
