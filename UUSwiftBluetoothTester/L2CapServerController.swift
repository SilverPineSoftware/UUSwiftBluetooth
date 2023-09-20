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

//    private var service: CBMutableService? = nil
//    private var characteristic: CBMutableCharacteristic? = nil
//    private var subscribedCentrals = [CBCharacteristic:[CBCentral]]()
//
    
    private let cbUUID:CBUUID = CBUUID(string: "E3AAE22C-8E52-47E3-9E03-629C62C542B9")

    
    private var psm:CBL2CAPPSM? = nil


    private var l2CapChannel:CBL2CAPChannel? = nil

    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.title = "L2Cap Server"
        
        self.configureLeftButton("Listen", listen)
        self.configureRightButton("Stop", stop)
        
        
        self.initialOutputline = "Tap Listen to Begin"
        self.clearOutput()
    }
    
    func listen()
    {
        self.manager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    func stop()
    {
        
        self.manager?.stopAdvertising()
        self.manager?.removeAllServices()
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

    func peripheralManager(_ peripheral: CBPeripheralManager, willRestoreState dict: [String : Any])
    {
        self.addOutputLine("Will restore state.")
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?)
    {
        self.addOutputLine("Did start Advertising. Error: \(errorDescription(error))")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?)
    {
        self.addOutputLine("Did add service (\(service.uuid.uuidString)). Error: \(errorDescription(error))")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic)
    {
        self.addOutputLine("Did subscribe to characteristic (\(characteristic.uuid.uuidString))")
        
        //Not sure if I really need this but it was in the example
//        var centrals = self.subscribedCentrals[characteristic] ?? [CBCentral]()
//        centrals.append(central)
//        self.subscribedCentrals[characteristic] = centrals
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic)
    {
        self.addOutputLine("Did unsubscribe to characteristic (\(characteristic.uuid.uuidString))")
        
//        if var current = self.subscribedCentrals[characteristic]
//        {
//            current.removeAll(where: { $0 == central })
//            self.subscribedCentrals[characteristic] = current
//        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest)
    {
        self.addOutputLine("Did receive read request. (\(request.characteristic.uuid.uuidString))")
        
        //Do the read and then call
        //peripheral.respond(to: <#T##CBATTRequest#>, withResult: <#T##CBATTError.Code#>)
        
        peripheral.respond(to: request, withResult: .success)
    }
    
     

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest])
    {
        let requestUUIDList:String = requests.map({ $0.characteristic.uuid.uuidString }).joined(separator: ", ")
        self.addOutputLine("Did receive write requests. (\(requestUUIDList))")
        
        //Do the read and then call
        //peripheral.respond(to: <#T##CBATTRequest#>, withResult: <#T##CBATTError.Code#>)

    }

    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager)
    {
        self.addOutputLine("Manager is ready to update subscribers.")
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
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didOpen channel: CBL2CAPChannel?, error: Error?)
    {
        self.l2CapChannel = channel
        self.l2CapChannel?.inputStream.delegate = self
        self.l2CapChannel?.outputStream.delegate = self
        
        self.l2CapChannel?.inputStream.schedule(in: RunLoop.main, forMode: .default)
        self.l2CapChannel?.outputStream.schedule(in: RunLoop.main, forMode: .default)
        
        //Since it was just opened, I shouln't need to call open, right?
//        self.l2CapChannel?.inputStream.open()
//        self.l2CapChannel?.outputStream.open()
//        
        //save this channel for future use... set it on the peripheral
        if let c = channel
        {
            self.addOutputLine("Did open L2CAPChannel with psm \(c.psm). Error: \(errorDescription(error))")
        }
        else
        {
            self.addOutputLine("Did open L2CAPChannel but returned channel is nil! Error: \(errorDescription(error))")
        }
    }
    
}

extension L2CapServerController:StreamDelegate
{
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        
        func stream(_ aStream: Stream, handle eventCode: Stream.Event)
        {
            switch eventCode
            {
            case Stream.Event.openCompleted:
                self.addOutputLine("Stream Open Completed")
                
            case Stream.Event.endEncountered:
                self.addOutputLine("Stream end encountered")
                
            case Stream.Event.hasBytesAvailable:
                self.addOutputLine("Stream has bytes available")
                self.readAvailableData(aStream)
                
            case Stream.Event.hasSpaceAvailable:
                self.addOutputLine("Stream has space available")
                
            case Stream.Event.errorOccurred:
                self.addOutputLine("Stream error occurred!")
                
            default:
                   NSLog("Unhandled Stream event code: \(eventCode)")
            }
        }
    }
    
    
    func readAvailableData(_ stream:Stream)
    {
        let readReturn = stream.readData(1024)
        
        DispatchQueue.main.async
        {
            if let data = readReturn.dataRead
            {
                self.addOutputLine("Recieved \(data.count) bytes. Raw Bytes:\n\(data.uuToHexString())\n")
            }
            else
            {
                self.addOutputLine("Received nil bytes!")
            }
        }
        
        
        if (readReturn.hasBytesAvailable)
        {
            //Keep Reading if there is more data!
            self.readAvailableData(stream)
        }
    }
}




