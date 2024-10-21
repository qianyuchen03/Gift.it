//
//  SelectionViewController.swift
//  Gift.it
//
//  Created by Qianyu Chen on 10/19/24.
//

import UIKit

class SettingsViewController: UIViewController {
    
    var delegate: UIViewController!
    
    
    @IBOutlet weak var modeSwitch1: UISwitch!
    @IBOutlet weak var modeSwitch2: UISwitch!
    @IBOutlet weak var modeSwitch3: UISwitch!
    @IBOutlet weak var bdaySwitch: UISwitch!
    @IBOutlet weak var notifSwitch: UISwitch!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        modeSwitch2.isOn = true
        modeSwitch1.isOn = false
        modeSwitch3.isOn = false
        bdaySwitch.isOn = false
        notifSwitch.isOn = false
        // Do any additional setup after loading the view.
    }
    
    @IBAction func hideBdaySwitch(_ sender: Any) {
    }
    
    @IBAction func notificationSwitch(_ sender: Any) {
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
    }

}
