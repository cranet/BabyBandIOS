//
//  ViewController.swift
//  BabyBand
//
//  Created by William Zulueta on 11/8/16.
//  Copyright © 2016 BabyBand. All rights reserved.
//

import UIKit
import Firebase
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate,
    CBPeripheralDelegate
{
    /* UI CONNECTIONS */
    @IBOutlet weak var thermoIV: UIImageView!
    @IBOutlet weak var drawingIV: UIImageView!
    @IBOutlet weak var heartIV: UIImageView!
    @IBOutlet weak var temperatureTV: UITextView!
    @IBOutlet weak var heartrateTV: UITextView!
    /* FIREBASE */
    var firebase: FIRDatabaseReference!
    var temperature: Double! = 75
    var heartrate: Int!      = 75
    /* COOL HEART RATE THING STUFF */
    var timer:Timer!
    var heartrateBounds: CGRect!
    var heartrateSize: CGSize!
    var pointArray = [CGPoint]()
    /*bluetooth stuff */
    var bluetoothManager:CBCentralManager!
    var bluetoothDevice:CBPeripheral!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        configureFirebase()
        configureTimer()
        configureBluetooth()
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager)
    {
        if (self.bluetoothManager.state == CBManagerState.poweredOn)
        {
            self.bluetoothManager.scanForPeripherals(withServices: nil, options: nil)
        } else
        {
            print("bluetooth not on")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber)
    {
        print("found device : \(advertisementData), RSSI : \(RSSI)")
    }
    
    func configureBluetooth()
    {
        self.bluetoothManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func configureTimer()
    {
        self.heartrateBounds = CGRect(x: self.heartIV.bounds.minX - 50, y: self.heartIV.bounds.minY, width: self.heartIV.bounds.maxX + 50, height: self.heartIV.bounds.maxY)
        self.heartrateSize = CGSize(width: self.heartrateBounds.maxX - self.heartrateBounds.minX, height: self.heartrateBounds.maxY - self.heartrateBounds.minY)
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.update), userInfo: nil, repeats: true);
    }
    
    func update()
    {
        updateHeartrate()
        updateTemperature()
    }
    
    func updateTemperature()
    {
        if (self.temperature >= 60 && self.temperature <= 100)
        {
            if (self.thermoIV.image != #imageLiteral(resourceName: "thermo_new.png"))
            {
                self.thermoIV.image = #imageLiteral(resourceName: "thermo_new.png")
            }
        } else if (self.temperature < 60)
        {
            self.thermoIV.image = #imageLiteral(resourceName: "thermo_cold")
        } else
        {
            self.thermoIV.image = #imageLiteral(resourceName: "thermo_hot")
        }
    }
    
    func updateHeartrate()
    {
        self.drawingIV.image = nil
        UIGraphicsBeginImageContext(self.heartrateSize)
        let context:CGContext! = UIGraphicsGetCurrentContext()
        let currentPoint:CGPoint = CGPoint(x: self.drawingIV.bounds.maxX - 1, y: (self.drawingIV.bounds.maxY - 1) - CGFloat(self.heartrate / 2))
        //        let currentPoint:CGPoint = CGPoint(x: (Int)(self.heartrateBounds.maxX - (self.heartrateBounds.maxX / 2)), y: ((Int)(self.heartrateBounds.maxY - self.heartrateBounds.maxY / 2) + self.heartrate))
        self.drawingIV.image?.draw(in: self.drawingIV.bounds)
        
        context.move(to: currentPoint)
        //        context.addLine(to: CGPoint(x: currentPoint.x - 50, y: currentPoint.y))
        for value in (0..<self.pointArray.count).reversed()
        {
            self.pointArray[value] = CGPoint(x: self.pointArray[value].x - 5, y: self.pointArray[value].y)
            if (self.pointArray[value].x < self.drawingIV.bounds.minX)
            {
                self.pointArray.remove(at: value);
            } else
            {
                context.addLine(to: self.pointArray[value])
            }
        }
        
        self.pointArray.append(currentPoint)
        context.setLineWidth(CGFloat(1))
        context.setStrokeColor(red: 0, green: 255, blue: 0, alpha: 2)
        context.strokePath()
        self.drawingIV.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    func configureFirebase()
    {
        firebase = FIRDatabase.database().reference();
        firebase.child("Emma").child("SensorData").observe(.value, with: { snapshot in
            
            if !snapshot.exists() { return }
            
            var tempString:String = snapshot.value as! String
            print("Retrived data: \(tempString)")
            if let idx = tempString.characters.index(of: ",")
            {
                self.temperature = Double(tempString.substring(to: idx))
                self.heartrate = Int(tempString.substring(from: tempString.characters.index(after: idx)))
                print("Temperature:\(self.temperature.description)")
                print("Heartrate:\(self.heartrate.description)")
                
                let tempInt:Int = Int(self.temperature)
                self.temperatureTV.text = "\(tempInt.description) F"
                self.heartrateTV.text = "\(self.heartrate.description) BPM"
            }
        })
    }
}
