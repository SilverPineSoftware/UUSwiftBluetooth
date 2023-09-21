//
//  L2CapServerController.swift
//  UUSwiftBluetoothTester
//
//  Created by Rhonda DeVore on 9/15/23.
//

import UIKit
import CoreBluetooth
import UUSwiftBluetooth

class L2CapServerController:L2CapController
{
    var manager: CBPeripheralManager? = nil
    private let cbUUID:CBUUID = CBUUID(string: "E3AAE22C-8E52-47E3-9E03-629C62C542B9")
    private var psm:CBL2CAPPSM? = nil
    
    private var channel:UUL2CapChannel? = nil
    private var streamDelegate:UUStreamDelegate = UUStreamDelegate()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.title = "L2Cap Server"
        
        self.configureLeftButton("Listen", listen)
        self.configureRightButton("Stop", stop)
        
        self.initialOutputline = "Tap Listen to Begin"
        self.clearOutput()
        
        
        self.streamDelegate.bytesReceivedCallback =
        { bytesReceived in
            
            if let rec = bytesReceived
            {
                self.addOutputLine("Recieved \(rec.count) bytes. Raw Bytes:\n\(rec.uuToHexString())\n")
            }
            else
            {
                self.addOutputLine("Received nil bytes!")
            }
            
            self.echoBack(bytesReceived)
            
        }
        
        self.streamDelegate.bytesSentCallback =
        { numberOfBytesSent in
            
            self.addOutputLine("\(numberOfBytesSent) Bytes Sent!")
            
        }
    }
    
    func listen()
    {
        self.manager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    func stop()
    {
        self.manager?.stopAdvertising()
        self.manager?.removeAllServices()
        self.channel?.closeStreams()
        stopL2CAPChannel()
        
        if (manager?.isAdvertising == false)
        {
            self.addOutputLine("Peripheral is not advertising", "stop()")
        }
        else
        {
            //Wait 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2)
            {
                if (self.manager?.isAdvertising == false)
                {
                    self.addOutputLine("Peripheral is not advertising", "stop()")
                }
            }
        }
    }
    
    func echoBack(_ receivedBytes:Data?)
    {
        
        let tx = String("\(receivedBytes?.uuToHexString() ?? "nil")".reversed())
        
        self.addOutputLine("Echoing back...")
        self.addOutputLine("TX: \(tx)")
        
        let data = Data(tx.uuToHexData() ?? NSData())
        
        self.channel?.sendData(data)
        { error in
            self.addOutputLine("Data sent! Error: \(self.errorDescription(error))")

        }
    }
        
    func startAdvertising()
    {
        self.addOutputLine("Starting Advertising...")
        if (self.manager?.isAdvertising == true)
        {
            self.manager?.stopAdvertising()
        }
        
        let uuidlist = [cbUUID]

        var name:String = "L2CapServer-"
        if let num = psm
        {
            name += "\(num)"
        }

        let advertisingData: [String:Any] = [CBAdvertisementDataServiceUUIDsKey:uuidlist, CBAdvertisementDataLocalNameKey:name]

        self.manager?.startAdvertising(advertisingData)
    }
    
    func startL2CAPChannel()
    {
        self.addOutputLine("Starting L2Cap Channel...", "startstartL2CAPChannel(:)")
        self.manager?.publishL2CAPChannel(withEncryption: true)
    }
    
    func stopL2CAPChannel()
    {
        if let psm = self.psm
        {
            self.manager?.unpublishL2CAPChannel(psm)
        }
        else
        {
            self.addOutputLine("Cannot unpublish. PSM Unknown!", "stopL2CAPChannel()")
        }
    }
}

extension L2CapServerController: CBPeripheralManagerDelegate
{
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager)
    {
        var line:String = "Peripheral State Changed: "
        
        if (peripheral.state == .poweredOn)
        {
            line += "POWERED ON"
            startL2CAPChannel()
        }
        else if (peripheral.state == .poweredOff)
        {
            line += "POWERED OFF"
        }
        else if (peripheral.state == .resetting)
        {
            line += "RESETTING"
        }
        else if (peripheral.state == .unauthorized)
        {
            line += "UNAUTHORIZED"
        }
        else if (peripheral.state == .unsupported)
        {
            line += "UNSUPPORTED"
        }
        else if (peripheral.state == .unknown)
        {
            line += "UNKNOWN"
        }
        
        self.addOutputLine(line)
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didPublishL2CAPChannel PSM: CBL2CAPPSM, error: Error?)
    {
        self.psm = PSM
        self.addOutputLine("Did publish L2CAPChannel with psm \(PSM). Error: \(errorDescription(error))")
        
        self.startAdvertising()
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didUnpublishL2CAPChannel PSM: CBL2CAPPSM, error: Error?)
    {
        self.addOutputLine("Did unpublish L2CAPChannel with psm \(PSM). Error: \(errorDescription(error))")
        self.channel = nil
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didOpen channel: CBL2CAPChannel?, error: Error?)
    {
        if let c = channel
        {
            self.addOutputLine("Did open L2CAPChannel with psm \(c.psm). Error: \(errorDescription(error))")
            self.channel = UUL2CapChannel(c, delegate: self.streamDelegate)
            self.channel?.openStreams()
        }
        else
        {
            self.addOutputLine("Did open L2CAPChannel but returned channel is nil! Error: \(errorDescription(error))")
        }
    }
}
