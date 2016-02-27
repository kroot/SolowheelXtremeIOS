//
//  GaugesViewController.swift
//  Solowheel Xtreme
//
//  Created by kroot on 10/11/15.
//

import Foundation
import UIKit
import WatchConnectivity
import CoreBluetooth

class GaugesViewController: UIViewController, CBPeripheralDelegate, WCSessionDelegate {
    
    @IBOutlet weak var batteryLabel: UILabel!
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var gaugeView: GaugeView!

    internal struct btCentralValues {
        let targetPeripheral:CBPeripheral!
        var targetCharacteristic:CBCharacteristic!
        let battery : String
        let speed : String
    }
    
    var programVar : btCentralValues?
    var isSubscribing:Bool = false

    var myTimer       = NSTimer()
    
    override func viewDidLoad() {
        self.title = ""
    }
    
    override func viewWillAppear(animated: Bool) {
          self.myTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "timerFunc:", userInfo: nil, repeats: true)              
    }
    
    override func viewWillDisappear(animated: Bool) {
        
        self.myTimer.invalidate()
        
        self.performSegueWithIdentifier("exitGaugesVC", sender: self)
    }
    
    func timerFunc(timer:NSTimer!) {

        dispatch_async(dispatch_get_main_queue(), {
            
            self.speedLabel.text = DataSingleton.speed + " MPH"
            self.batteryLabel.text = DataSingleton.batteryText + " %"

            self.gaugeView.setGaugeValue(DataSingleton.battery)
            
            if DataSingleton.connected == false {
                self.myTimer.invalidate()
                self.performSegueWithIdentifier("exitGaugesVC", sender: self)
            }
        })
    }

    func session(session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
        
        if self.isViewLoaded() && !self.view.hidden {
            dispatch_async(dispatch_get_main_queue()) {

                self.myTimer.invalidate()
                self.performSegueWithIdentifier("exitGaugesVC", sender: self)
            }
        }
    }
}