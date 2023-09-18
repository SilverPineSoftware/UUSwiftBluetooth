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

    private var psm:CBL2CAPPSM? = nil

    private let uuid:CBUUID = CBUUID(string: "E3AAE22C-8E52-47E3-9E03-629C62C542B9")

    
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
        
        let uuidlist = [uuid]

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
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic)
    {
        self.addOutputLine("Did unsubscribe to characteristic (\(characteristic.uuid.uuidString))")
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest)
    {
        self.addOutputLine("Did receive read request. (\(request.characteristic.uuid.uuidString))")

    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest])
    {
        var requestUUIDList:String = requests.map({ $0.characteristic.uuid.uuidString }).joined(separator: ", ")
        self.addOutputLine("Did receive write requests. (\(requestUUIDList))")
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




