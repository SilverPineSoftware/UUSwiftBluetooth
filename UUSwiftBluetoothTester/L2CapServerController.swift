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
    private var channel:CBL2CAPChannel? = nil
    
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
        self.closeChannelStreams()
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
        
        self.bytesToSend = Data(tx.uuToHexData() ?? NSData())
        
        if let outputStream = self.channel?.outputStream as? OutputStream
        {
            self.sendData(outputStream: outputStream, bytesPreviouslySent: nil)
            { totalBytesSent in
                
                if let total = totalBytesSent
                {
                    self.addOutputLine("\(total) Total Bytes Sent!")
                }
                else
                {
                    self.addOutputLine("Total Bytes Sent is nil!")
                }
                
            }
        }
    }
    
    private var bytesToSend:Data? = nil
    
    private func sendData(outputStream:OutputStream, bytesPreviouslySent:Int?, completion:((Int?) -> Void))
    {
        guard let dataToSend = bytesToSend, dataToSend.count > 0 else
        {
            completion(bytesPreviouslySent)
            return
        }
        
        
        let numberOfBytesSent = outputStream.uuWriteData(data: dataToSend)
        let totalBytesSent = (bytesPreviouslySent ?? 0) + numberOfBytesSent

        if (numberOfBytesSent < (self.bytesToSend?.count ?? 0))
        {
            self.bytesToSend = self.bytesToSend?.advanced(by: numberOfBytesSent)
            sendData(outputStream: outputStream, bytesPreviouslySent: totalBytesSent, completion: completion)
        }
        else
        {
            completion(totalBytesSent)
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
    
    private func openChannelStreams()
    {
        self.channel?.inputStream.delegate = self
        self.channel?.outputStream.delegate = self
        
        self.channel?.inputStream.schedule(in: RunLoop.main, forMode: .default)
        self.channel?.outputStream.schedule(in: RunLoop.main, forMode: .default)
        
        self.channel?.inputStream.open()
        self.channel?.outputStream.open()
    }
    
    private func closeChannelStreams()
    {
        self.channel?.inputStream.close()
        self.channel?.outputStream.close()
        
        self.channel?.inputStream.remove(from: RunLoop.main, forMode: .default)
        self.channel?.outputStream.remove(from: RunLoop.main, forMode: .default)
        
        self.channel?.inputStream.delegate = nil
        self.channel?.outputStream.delegate = nil
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
        self.closeChannelStreams()
        self.channel = nil

    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didOpen channel: CBL2CAPChannel?, error: Error?)
    {
        self.channel = channel
        self.openChannelStreams()
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


extension L2CapServerController: StreamDelegate
{
    public func stream(_ stream: Stream, handle eventCode: Stream.Event)
    {
        switch eventCode
        {
        case Stream.Event.openCompleted:
            NSLog("Stream Opened: \(stream.debugDescription)")

        case Stream.Event.endEncountered:
            NSLog("Stream End Encountered: \(stream.debugDescription)")

        case Stream.Event.hasBytesAvailable:
            NSLog("Stream HasBytesAvailable: \(stream.debugDescription)")
            if let inputStream = stream as? InputStream
            {
                self.readAvailableData(inputStream: inputStream, data: nil)
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
            }

        case Stream.Event.hasSpaceAvailable:
            NSLog("Stream Has Space Available: \(stream.debugDescription)")

        case Stream.Event.errorOccurred:
            NSLog("Stream Error Occurred: \(stream.debugDescription)")

        default:
            NSLog("Unhandled Stream event code: \(eventCode)")
        }
    }
    
    private func readAvailableData(inputStream:InputStream, data:Data?, completion:((Data?) -> Void))
    {
        var workingData:Data? = data
        
        let dataRead = inputStream.uuReadData(1024)

        if let data = dataRead
        {
            if (workingData == nil)
            {
                workingData = Data()
                workingData?.append(data)
            }
        }
        
        if (inputStream.hasBytesAvailable)
        {
            self.readAvailableData(inputStream:inputStream, data: workingData, completion: completion)
        }
        else
        {
            completion(workingData)
        }
    }
}
