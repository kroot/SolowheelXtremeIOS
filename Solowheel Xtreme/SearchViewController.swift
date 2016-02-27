
//
//  ViewController.swift
//  Solowheel Xtreme
//
//  Created by kroot on 9/24/15.
//

import UIKit

import CoreBluetooth
import WatchConnectivity

class SearchViewController: UIViewController,
    UINavigationControllerDelegate, CBCentralManagerDelegate,
    CBPeripheralDelegate, WCSessionDelegate {

    enum connectStates
    {
        case initing
        case searchingDevices
        case deviceFound
        case connectingDevice
        case deviceConnected
        case searchingServices
        case serviceFound
        case searchingPorts
        case portFound
        case subscribing
        case subscribed
    }
    
    let INCOMING_SERVICE_UUID_STRING = "FFF0"
    let INCOMING_CHARACTERISTIC_UUID_STRING  =   "FFF7"

    let SUBSCRIPTION_SERVICE_UUID           =   "2ED21E35-18D3-4594-9952-A4FDFA4562C5"
    let SUBSCRIPTION_CHARACTERISTIC_UUID    =   "AFFA1FCD-C755-43C7-B0E3-5870D4728221"
    
    var centralIsScanning:Bool = false
    var centralManager:CBCentralManager?
    var targetPeripheral:CBPeripheral!
    var cbService:CBService?
    var targetCharacteristic:CBCharacteristic!
    
    var currentState:connectStates = connectStates.initing

    var peripherals:[CBPeripheral] = []
    var peripheralMap:[NSUUID:Bool] = [:]
    var incomingServiceUUID:CBUUID!
    var incomingCharacteristicUUID:CBUUID!
    
    var subscribers:[CBCentral] = []
    var isSubscribing:Bool = false
    var lastUpdatedCharacteristic:Int64 = 0
    
    var isGaugesViewVisible = false
    
    var watchSession:WCSession?
    var watchAvailable:Bool = false
    
    var isMetric:Bool = false
    
    @IBOutlet weak var powerOnLabel: UILabel!
    @IBOutlet weak var connectionStatesView: UIStackView!

    @IBOutlet weak var discoveringDeviceLabel: UILabel!
    @IBOutlet weak var discoveredDeviceLabel: UILabel!

    @IBOutlet weak var connectingDeviceLabel: UILabel!
    @IBOutlet weak var connectedDeviceLabel: UILabel!
    
    @IBOutlet weak var discoveringServicesLabel: UILabel!
    @IBOutlet weak var discoveredServicesLabel: UILabel!
    
    @IBOutlet weak var discoveringPortLabel: UILabel!
    @IBOutlet weak var discoveredPortLabel: UILabel!
    
    @IBOutlet weak var subscribingPortLabel: UILabel!
    @IBOutlet weak var subscribedPortLabel: UILabel!
    
    @IBOutlet weak var speedText: UILabel!
    @IBOutlet weak var speedLabel: UILabel!
    
    @IBOutlet weak var batteryText: UILabel!
    @IBOutlet weak var batteryLabel: UILabel!
    
    @IBOutlet weak var ScanButton: UIButton!
    
    @IBAction func ScanButtonHandler(sender: AnyObject) {
        if self.centralIsScanning {
            stopCentralScanning()
            updateConnectionState(connectStates.initing)
            self.ScanButton.setTitle("Start Scanning", forState: UIControlState.Normal )
            
        } else {
            startCentralScanning()
            updateConnectionState(connectStates.searchingDevices)
            self.ScanButton.setTitle("Stop Scanning", forState: UIControlState.Normal )
        }
    }
    
    // called by gauges view when seque unwinds
    @IBAction func unwindToContainerVC(segue: UIStoryboardSegue) {
        if nil != self.targetPeripheral {
            self.targetPeripheral.setNotifyValue(false, forCharacteristic: self.targetCharacteristic)
        }
        reset()
 
        isGaugesViewVisible = false
        updateConnectionState(connectStates.searchingDevices)
    }
    
    func fetch(completion: () -> Void) {
        // do stuff
        
        completion()
    }
    
    func updateUI() {
        // do stuff
    }
    
    func sessionWatchStateDidChange(session: WCSession) {
        print("Session changed")
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (WCSession.isSupported()) {
            if (watchSession == nil) {
                watchSession = WCSession.defaultSession()
                watchSession!.delegate = self
                watchSession!.activateSession()
            }
        }
        
        isMetric = NSLocale.currentLocale().objectForKey(NSLocaleUsesMetricSystem) as! Bool

        lastUpdatedCharacteristic = currentTimeMillis()

        self.incomingServiceUUID = CBUUID(string: INCOMING_SERVICE_UUID_STRING)
        self.incomingCharacteristicUUID = CBUUID(string: INCOMING_CHARACTERISTIC_UUID_STRING)
        
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func updateWatchDisplay(speed: String, battery: String, isConnected: Bool)
    {
        if WCSession.defaultSession().reachable {
            do {
                let applicationContext = [
                    "speed" : speed,
                    "battery" : battery,
                    "isconnected" : isConnected ? "true" : "false"
                ]
                
                try
                    WCSession.defaultSession().updateApplicationContext(applicationContext)
                
            } catch {
                print ("error")
                
            }
        }
    }

    func updateConnectionState(newState: connectStates)
    {
        switch currentState {
            
        case .subscribed:
            if nil != self.targetPeripheral {
                subscribeToCharacteristic(self)
            }
            
        case .deviceConnected:
            if (newState != .searchingServices) {
                reset()
            }
            
        default:
            print("do nothing")

        }
        
        switch newState {
            
        case .searchingDevices:
            print("searching devices")
            self.startCentralScanning()
            
        case .deviceFound:
            self.centralManager!.connectPeripheral(self.targetPeripheral, options: [CBConnectPeripheralOptionNotifyOnDisconnectionKey : true] )
            print("device found")
            
        case .deviceConnected:
            print("device connected")
            self.targetPeripheral.discoverServices([self.incomingServiceUUID])
            
        case .serviceFound:
            print("service found")
            self.targetPeripheral.discoverCharacteristics([self.incomingCharacteristicUUID], forService: self.cbService!)
            
        case .portFound:
            print("port found")
            if nil != self.targetPeripheral {
                subscribeToCharacteristic(self)
            }
            
        case .subscribed:
            print("subscribed")

            if (!isGaugesViewVisible) {
                self.performSegueWithIdentifier("showGauges", sender:self)
                isGaugesViewVisible = true
            }
            
        default:
            print("do nothing")
            
        }
        
        currentState = newState
        updateConnectionStatusDisplayed()
    }
    
    func updateConnectionStatusDisplayed() {
        // default to all hidden. show in switch closure.
        
        var searchingXtremes:Bool = false
        var xtremeFound:Bool = false

        var connectingXtremes:Bool = false
        var xtremeConnected:Bool = false

        var searchingServices:Bool = false
        var serviceFound:Bool = false
        
        var searchingPorts:Bool = false
        var portFound:Bool = false
        
        var portSubscribing:Bool = false
        var portSubscribed:Bool = false
        
        // process in reverse chronological order so visibility is additive
        // by using fallthrough's
        switch currentState {
            
        case .subscribed:
            print("subscribed")
            portSubscribed = true
            fallthrough
            
        case .subscribing:
            print("subscribing")
            portSubscribing = true
            fallthrough
            
        case .portFound:
            print("port found")
            portFound = true
            fallthrough
            
        case .searchingPorts:
            print("searching ports")
            searchingPorts = true
            fallthrough
            
        case .serviceFound:
            print("service found")
            serviceFound = true
            fallthrough
            
        case .searchingServices:
            print("searching service")
            searchingServices = true
            fallthrough
            
        case .deviceConnected:
            print("device connected")
            xtremeConnected = true
            fallthrough
            
        case .connectingDevice:
            print("Connecting device")
            connectingXtremes = true
            fallthrough
            
        case .deviceFound:
            print("device found")
            xtremeFound = true
            fallthrough
            
        case .searchingDevices:
            print("searching devices")
            searchingXtremes = true
            //fallthrough
            
        default:
            print("do nothing")

        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
        
            dispatch_async(dispatch_get_main_queue(), {
                
                self.powerOnLabel.hidden = !searchingXtremes
            
                //self.discoveringDeviceLabel.hidden = !searchingXtremes
                if (searchingXtremes) {
                    self.discoveringDeviceLabel.alpha = 1
                    
                    self.updateWatchDisplay("--- MPH", battery: "--- %", isConnected: true)
                }
                else {
                    self.discoveringDeviceLabel.alpha = 0
                }
                
                if (xtremeFound) {
                    self.discoveredDeviceLabel.alpha = 1
                } else {
                    self.discoveredDeviceLabel.alpha = 0
                }
                
                if connectingXtremes {
                    self.connectingDeviceLabel.alpha = 1
                }
                else {
                    self.connectingDeviceLabel.alpha = 0
                }
                
                if xtremeConnected {
                    self.connectedDeviceLabel.alpha = 1
                }
                else {
                    self.connectedDeviceLabel.alpha = 0
                }
                
                if searchingServices {
                    self.discoveringServicesLabel.alpha = 1
                }
                else {
                    self.discoveringServicesLabel.alpha = 0
                }
                
                if serviceFound {
                    self.discoveredServicesLabel.alpha = 1
                }
                else {
                    self.discoveredServicesLabel.alpha = 0
                }
                
                if searchingPorts {
                    self.discoveringPortLabel.alpha = 1
                }
                else {
                    self.discoveringPortLabel.alpha = 0
                }
                
                if portFound {
                    self.discoveredPortLabel.alpha = 1
                }
                else {
                    self.discoveredPortLabel.alpha = 0
                }
                
                if portSubscribing {
                    self.subscribingPortLabel.alpha = 1
                }
                else {
                    self.subscribingPortLabel.alpha = 0
                }
                
                if portSubscribed {
                    self.subscribedPortLabel.alpha = 1
                }
                else {
                    self.subscribedPortLabel.alpha = 0
                }

                self.view.layoutIfNeeded()
            })

        }
    }


    func session(session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
        
        //let connect = message["connect"] as? String
        
        DataSingleton.battery = 0
        DataSingleton.batteryText = ""
        DataSingleton.speed = ""
        DataSingleton.connected = false
        
        stopCentralScanning()
        reset()
        
        updateConnectionState(connectStates.searchingDevices)
        
//        dispatch_async(dispatch_get_main_queue()) {
//        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func startCentralScanning() {
        self.centralManager?.scanForPeripheralsWithServices(nil, options: nil)
        self.centralIsScanning = true
    }
    
    func stopCentralScanning() {
        self.centralManager?.stopScan()
        self.centralIsScanning = false
    }
    
    func reset() {
        DataSingleton.connected = false
        DataSingleton.battery = 0
        DataSingleton.batteryText = ""
        DataSingleton.speed = ""

        self.peripheralMap.removeAll()
        self.targetPeripheral = nil
        self.targetCharacteristic = nil
        self.subscribers.removeAll(keepCapacity: false)
    }
    
    
    // MARK: CBCentralManagerDelegate methods
    func centralManagerDidUpdateState(central: CBCentralManager) {
        if central.state == CBCentralManagerState.PoweredOn {
            // Bluetooth is ready to go
            // enable the search button
            self.centralIsScanning = false
            
            // remove any subscribers
            self.subscribers.removeAll(keepCapacity: false)
            
            updateConnectionState(connectStates.searchingDevices)
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
            
            if peripheral.name == "SerialCom" || peripheral.name == "EXTREME" {
                self.targetPeripheral = peripheral
                self.targetPeripheral.delegate = self
                
                updateConnectionState(connectStates.deviceFound)
            }
        }
    }

    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        print("didConnectPeripheral")
        
        updateConnectionState(connectStates.deviceConnected)
        updateConnectionState(connectStates.searchingServices)
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        print("didDisconnectPeripheral")
        print (error?.localizedDescription)
    
        DataSingleton.battery = 0
        DataSingleton.batteryText = ""
        DataSingleton.speed = ""
        DataSingleton.connected = false
        
        // peripheral has disconnected
        // make sure we remember that
        
        stopCentralScanning()
        reset()
        
        updateConnectionState(connectStates.searchingDevices)
    }
    
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        // we can only notify the user of the error, and log it

        print("Central failed to connect peripheral [\(peripheral.name)]: error: \(error!.description)")
        
        stopCentralScanning()
        reset()
        
        updateConnectionState(connectStates.searchingDevices)
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
                    
                    self.cbService = cbService
                    updateConnectionState(connectStates.serviceFound)
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
                    
                    self.targetCharacteristic = characteristic

                    updateConnectionState(connectStates.portFound)
                }
            }
        } else {
            // some error occurred
            //self.updateStatus("Error discovering characteristics for [\(peripheral.name)]: error:[\(error.description)]")
        }
    }
    
    func peripheralManager(peripheral: CBPeripheralManager!, central: CBCentral!, didSubscribeToCharacteristic characteristic: CBCharacteristic!) {

        self.subscribers.append(central)
        updateConnectionState(connectStates.subscribed)
    }
    
    func currentTimeMillis() -> Int64{
        let nowDouble = NSDate().timeIntervalSince1970
        return Int64(nowDouble*1000)
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        print("didUpdateValueForCharacteristic")
        
        if (!self.isGaugesViewVisible) {
            updateConnectionState(connectStates.subscribed)
        }

        if nil == error {
            // turn it into a String
            let characteristicString = NSString(data: characteristic.value!, encoding: NSUTF8StringEncoding)
            let currentTime = currentTimeMillis()
            
            if characteristicString != nil && currentTime - lastUpdatedCharacteristic > 300 {

                print(characteristicString!)

                var parts = characteristicString?.componentsSeparatedByString(",")
                
                if (parts?.count == 3)
                {
                    parts?.popLast()
                    let battery = parts?.popLast()

                    let full = 580.0
                    
                    // Mine vibrated at 46.8v when I ran it down completely.
                    let emptyBattery = 470.0
                    
                    let fullRange = full - emptyBattery;
                    
                    let nowBattery: Double = (battery! as NSString).doubleValue
                    var actualRange = nowBattery - emptyBattery
                    
                    actualRange = actualRange < 0 ? 0 : actualRange;  // don't allow negative
                    
                    var percent = ((actualRange * 100) / fullRange)
                    if (percent > 100.0) {
                        percent = 100.0
                    }
                    else if (percent < 0) {
                        percent = 0.0
                    }
                    let percentString = NSString(format: "%.00f", percent)
                    
                    let speedString = parts?.popLast()
                    var speedCmPerSecond: Double = (speedString! as NSString).doubleValue

                    let fudgeFactor = 0.80
                    speedCmPerSecond *= fudgeFactor
                    
                    let speedCmPerHour = speedCmPerSecond * 60 * 60
                    let speedKmPerHour = speedCmPerHour / 100000
                    let speedMPH = speedKmPerHour * 0.6214
                    let speedDisplay = NSString(format: "%.01f", speedMPH)
                    
                    DataSingleton.connected = true
                    DataSingleton.batteryText = percentString as String
                    DataSingleton.battery = Int(percent)
                    DataSingleton.speed = speedDisplay as String
                    
                    updateWatchDisplay((speedDisplay as String) + " MPH", battery: (percentString as String) + " %", isConnected: true)
                }                
            }
            lastUpdatedCharacteristic = currentTime;
            
   
        } else {
            // error occurred reading characteristic

            print("Error reading characteristic for [\(peripheral.name)]: error:[\(error!.description)]")
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
        } else {
            self.targetPeripheral.setNotifyValue(false, forCharacteristic: self.targetCharacteristic)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        
        if segue.identifier == "showGauges"
        {
            // Create a variable that you want to send
            let newProgramVar = GaugesViewController.btCentralValues(
                targetPeripheral: self.targetPeripheral,
                targetCharacteristic: self.targetCharacteristic,
                battery: "0%", speed: "0 MPH")
            
            let destinationVC = segue.destinationViewController as! GaugesViewController
            destinationVC.programVar = newProgramVar
        }
    }
    
}

