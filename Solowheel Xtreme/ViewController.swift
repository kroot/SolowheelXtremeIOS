//
//  ViewController.swift
//  Solowheel Xtreme
//
//  Created by kroot on 9/24/15.
//  Copyright © 2015 Inventist. All rights reserved.
//

import UIKit

//import Cocoa
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {

//    let INCOMING_SERVICE_UUID_STRING = "8B3090A8-2C75-0415-743D-D47F14E23E34"
    let INCOMING_SERVICE_UUID_STRING = "FFF0"
    let INCOMING_CHARACTERISTIC_UUID_STRING  =   "FFF7"

    let SUBSCRIPTION_SERVICE_UUID           =   "2ED21E35-18D3-4594-9952-A4FDFA4562C5"
    let SUBSCRIPTION_CHARACTERISTIC_UUID    =   "AFFA1FCD-C755-43C7-B0E3-5870D4728221"
    
    var centralIsScanning:Bool = false
    var centralManager:CBCentralManager?
    var peripherals:[CBPeripheral] = []
    var peripheralMap:[NSUUID:Bool] = [:]
    var incomingServiceUUID:CBUUID!
    var incomingCharacteristicUUID:CBUUID!
    var targetCharacteristic:CBCharacteristic!
    //var peripheral: CBPeripheral!
    var targetPeripheral:CBPeripheral!
    
    var subscribers:[CBCentral] = []
    var isSubscribing:Bool = false


    override func viewDidLoad() {
        super.viewDidLoad()

        self.incomingServiceUUID = CBUUID(string: INCOMING_SERVICE_UUID_STRING)
        self.incomingCharacteristicUUID = CBUUID(string: INCOMING_CHARACTERISTIC_UUID_STRING)
        
        self.centralManager = CBCentralManager(delegate: self, queue: nil)

    }
    
//    override var representedObject: AnyObject? {
//        didSet {
//            // Update the view, if already loaded.
//        }
//    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func handleSearch(sender: AnyObject) {
        //var i:Int = 0
        
        //if self.centralScanning == false {

        //}
    }
    
    // MARK: CBCentralManagerDelegate methods
    func centralManagerDidUpdateState(central: CBCentralManager) {
        if central.state == CBCentralManagerState.PoweredOn {
            // Bluetooth is ready to go
            // enable the search button
            //self.searchButton.enabled = true
            self.centralIsScanning = false
            
            // remove any subscribers
            self.subscribers.removeAll(keepCapacity: false)
            
            //self.centralManager?.scanForPeripheralsWithServices(nil, options: nil)
            self.startCentralScanning()

        }
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber)
    {
        print("didDiscoverPeripheral")
        
        if nil == self.peripheralMap[peripheral.identifier] {
        
            // if we have not yet discovered this peripheral, add it to the cache
            self.peripherals.append(peripheral)
            self.peripheralMap[peripheral.identifier] = true
            //self.peripheralTableView.reloadData()
            
            if peripheral.name == "SerialCom" {
                // peripheral has connected, set us as the delegate
//                peripheral.delegate = self
                
                //self.targetPeripheral = peripheral

                // clear cached characteristic, if any
                //self.targetCharacteristic = nil
                
                self.targetPeripheral = peripheral
                self.targetPeripheral.delegate = self
                //peripheral.delegate = self

                
                //central.cancelPeripheralConnection(peripheral)
                central.connectPeripheral(self.targetPeripheral, options: nil)

                
                //self.targetPeripheral.discoverServices([self.incomingServiceUUID])
                //self.targetPeripheral.discoverServices(nil)
            }
        }
        
    
    }
    
    func startCentralScanning() {
        self.centralManager?.scanForPeripheralsWithServices(nil, options: nil)

        //centralManager!.scanForPeripheralsWithServices([self.incomingServiceUUID], options: nil)
        
        self.centralIsScanning = true
        //self.searchForSourceButton.stringValue = "Stop Search"
        //self.updateStatus("Scanning for Peripherals")
    }
    
    func stopCentralScanning() {
        self.centralManager?.stopScan()
        self.centralIsScanning = false
        //self.searchForSourceButton.stringValue = "Search For Data Source"
        //self.updateStatus("Not scanning")
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        print("didConnectPeripheral")
        
        //central.cancelPeripheralConnection(self.targetPeripheral)

        // peripheral has connected, set us as the delegate
        //self.targetPeripheral.delegate = self
        
        // clear cached characteristic, if any
        //self.targetCharacteristic = nil
        
        // search for services
        //self.updateStatus("Searching for services")
        
        //self.targetPeripheral.discoverServices([self.incomingServiceUUID])
        self.targetPeripheral.discoverServices(nil)
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        print("didDisconnectPeripheral")

        // peripheral has disconnected
        // make sure we remember that
        
        self.targetPeripheral.delegate = nil
        self.targetPeripheral = nil
        self.targetCharacteristic = nil
        
//        self.updateStatus("Peripheral Disconnected")
//        // disable the read characteristic button
//        self.readCharacteristicButton.enabled = false
//        // disable the send response button
//        self.sendResponseButton.enabled = false
        
//        stopCentralScanning();
    }
    
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        // we can only notify the user of the error, and log it
//        self.updateStatus("Central failed to connect peripheral [\(peripheral.name)]")
        print("Central failed to connect peripheral [\(peripheral.name)]: error: \(error!.description)")
    }
    
    // MARK: CBPeripheralDelegate methods
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        print("didDiscoverServices")
        
        if nil == error {
            // valid service discovered
            for cbService in peripheral.services! {
                let service:CBService = cbService as CBService
                let serviceUUID = service.UUID
                if serviceUUID.UUIDString == INCOMING_SERVICE_UUID_STRING {
                    print("didDiscoverServices UUID")

                   // self.updateStatus("Searching service for characteristics")
                    peripheral.discoverCharacteristics([self.incomingCharacteristicUUID], forService: cbService as CBService)
                    break
                }
            }
        } else {
            // some error occurred
            //self.updateStatus("Error discovering services for [\(peripheral.name)]: error:[\(error.description)]")
        }
    }

    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        print("didDiscoverCharacteristicsForService")

        if nil == error {
            //println("discovered characteristic on service")
            for cbCharacteristic in service.characteristics! {
                let characteristic:CBCharacteristic = cbCharacteristic as CBCharacteristic
                let characteristicUUID = characteristic.UUID
                if characteristicUUID.UUIDString == INCOMING_CHARACTERISTIC_UUID_STRING {
                    // since this is the only item we are interested in,
                    // we can stop scanning
                    self.stopCentralScanning()
                    // enable the read button
                    //self.readCharacteristicButton.enabled = true
                    // cache the characteristic
                    
                    self.targetCharacteristic = characteristic
                    //self.updateStatus("Found matching characteristic")
                    
                    if nil != self.targetPeripheral {
                        
                        //self.targetPeripheral.readValueForCharacteristic(self.targetCharacteristic)
                        
                        subscribeToCharacteristic(self)
                    }
                }
            }
        } else {
            // some error occurred
            //self.updateStatus("Error discovering characteristics for [\(peripheral.name)]: error:[\(error.description)]")
        }
    }
    
    func peripheralManager(peripheral: CBPeripheralManager!, central: CBCentral!, didSubscribeToCharacteristic characteristic: CBCharacteristic!) {
//        self.updateStatus("Central [\(central.identifier)] has subscribed")
        self.subscribers.append(central)
    }
    
    //var foo:NSString!

    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        print("didUpdateValueForCharacteristic")
        
        if nil == error {
            // turn it into a String
            let characteristicString = NSString(data: characteristic.value!, encoding: NSUTF8StringEncoding)
            
            print(characteristicString!)
            
//            self.dataReceivedLabel.stringValue = characteristicString!
//            self.updateStatus("Data received from peripheral")
//            self.sendResponseButton.enabled = true
            //foo = characteristicString
            
            
        } else {
            // error occurred reading characteristic
//            self.updateStatus("Error reading characteristic for [\(peripheral.name)]: error:[\(error.description)]")
//            // print to the log, because sometimes the error description is long
//            println("Error reading characteristic for [\(peripheral.name)]: error:[\(error.description)]")
        }
    }
    
    @IBAction func readCharacteristicData(sender: AnyObject) {
        // tell the cached peripheral to read the value for the characteristic
        if nil != self.targetPeripheral {
            self.targetPeripheral.readValueForCharacteristic(self.targetCharacteristic)
        } else {
            //self.updateStatus("Cannot read - no peripheral connected")
        }
    }

    @IBAction func subscribeToCharacteristic(sender: AnyObject) {
        if false == self.isSubscribing {
            self.targetPeripheral.setNotifyValue(true, forCharacteristic: self.targetCharacteristic)
//            self.updateStatus("Telling peripheral we want to subscribe")
        } else {
            self.targetPeripheral.setNotifyValue(false, forCharacteristic: self.targetCharacteristic)
//            self.updateStatus("Telling peripheral we want to unsubscribe")
        }
    }
    
}

