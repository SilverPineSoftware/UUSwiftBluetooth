//
//  L2CapClientController.swift
//  UUSwiftBluetoothTester
//
//  Created by Rhonda DeVore on 9/14/23.
//

import UIKit
import CoreBluetooth
import UUSwiftBluetooth

class L2CapClientController:L2CapController
{
    var peripheral: (UUPeripheral)? = nil
    private var channel:UUL2CapChannel? = nil
    
    
    override func buildMenu() -> UIMenu?
    {
        var actions:[UIAction] = []
        
        if (channel == nil)
        {
            actions.append(UIAction(title: "Start Channel", handler: { _ in self.connect() }))
        }
        else
        {
            actions.append(UIAction(title: "Ping", handler: { _ in self.ping() }))
            actions.append(UIAction(title: "Send Image 1", handler: { _ in self.sendImage1() }))
            actions.append(UIAction(title: "Send Image 2", handler: { _ in self.sendImage2() }))
            actions.append(UIAction(title: "Clear Output", handler: { _ in self.clearOutput() }))
        }
        

        return UIMenu(title: "Client Actions", image: nil, identifier: nil, options: [], children: actions)
    }
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.title = "L2Cap Client"
        
        self.initialOutputline = "Tap Connect to Begin"
        self.clearOutput()
    }
    
    func connect()
    {
        self.addOutputLine("Connecting...")
        self.peripheral?.connect(timeout: 20.0)
        {
            self.addOutputLine("Connected")
            self.startChannel()
            
        } disconnected:
        { error in
            
            self.addOutputLine("Disconnected. Error: \(self.errorDescription(error))")
        }

    }
    
    
    func startChannel()
    {
        guard let p = self.peripheral else { return }
        
        self.readL2CapSettings
        { foundPsm, foundEncrypted, error in
            
            guard let psm = foundPsm else
            {
                self.addOutputLine("No PSM found! Cannot start channel!")
                return
            }
            
            self.addOutputLine("L2Cap Settings (psm:\(psm), encrypted:\(String(describing: foundEncrypted)))")
            
            self.addOutputLine("Opening L2CapChannel with psm \(psm)...")

            self.channel = UUL2CapChannel(p)
            
            self.channel?.open(psm: psm, timeout: 10.0, completion:
            { error in
                            
                if let err = error
                {
                    self.addOutputLine("Error: \(err)")
                    self.channel = nil
                }
                else if let _ = self.channel
                {
                    self.addOutputLine("L2Cap Channel Connected!")
                }
                else
                {
                    self.channel = nil
                    self.addOutputLine("L2Cap Channel connect attempt returned no error but no channel was created!")
                }
                
                self.refreshMenu()
                
            })
            
        }
    }
    
    func ping()
    {
        let tx = "4747474747"
        let command = UUL2CapCommand.createToSend(.echo, Data(tx.uuToHexData() ?? NSData()))
        
        let commandAsData = command.toData()
        let totalBytesToSend = commandAsData.count
        
        self.addOutputLine("TX: \(commandAsData.uuToHexString())")
        
        
        
        self.channel?.sendMessage(command.toData(), 10.0,
        { progressBytesSent in
            
            
            if (totalBytesToSend > 0)
            {
                
                let percent = Float(progressBytesSent)/Float(totalBytesToSend)
                self.updateProgressRow(percent)

                let remaining = UInt32(totalBytesToSend) - progressBytesSent
                NSLog("Send Progress: (\(progressBytesSent)/\(totalBytesToSend))  \(remaining) Remaining")
                
            }
            
            
        },
        { totalBytesSent, dataReceived, error in
            
            DispatchQueue.main.async
            {
                if let total = totalBytesSent
                {
                    self.addOutputLine("\(total) Total Bytes Sent!")
                }
                else
                {
                    self.addOutputLine("Total Bytes Sent is nil!")
                }
                
                
                if let rec = dataReceived
                {
                    self.addOutputLine("Recieved \(rec.count) bytes. Raw Bytes:\n\(rec.uuToHexString())\n")
                }
                else
                {
                    self.addOutputLine("Received nil bytes!")
                }
            }
            
        })
    }
    
    private func sendImage1()
    {
        self.sendImage("image_one")
    }
    
    private func sendImage2()
    {
        self.sendImage("image_two")
    }
    
    private func sendImage(_ name:String)
    {
        guard let imageOneData = getImageFromBundle(name) else
        {
            self.addOutputLine("Couldn't load \(name) from bundle!")
            return
        }
        
        let command = UUL2CapCommand.createToSend(.sendImage, imageOneData)
        let messageData = command.toData()
        
        
        self.addOutputLine("Sending \(name)... total image bytes: \(imageOneData.count)")
        
        let start = Date().timeIntervalSinceReferenceDate
        
        
        let totalBytesToSend = messageData.count
        
        self.channel?.sendMessage(messageData, 120,
        { progress in
            
            if (totalBytesToSend > 0)
            {
                let percent:Float = Float(progress)/Float(totalBytesToSend)
                self.updateProgressRow(percent)
                let remaining = UInt32(totalBytesToSend) - progress
                NSLog("Send Progress: (\(progress)/\(totalBytesToSend))  \(remaining) Remaining")
            }
            
        },
        { totalBytesSent, rxReceived, error in
            
            DispatchQueue.main.async 
            {
                self.addOutputLine("Send \(name) complete! Error: \(self.errorDescription(error))")
                
                self.addOutputLine("Total bytes sent: \(totalBytesSent ?? 0)")
                
                let duration = Date().timeIntervalSinceReferenceDate - start
                self.addOutputLine("Total Duration: \(duration)")
                
                self.addOutputLine("RX: \(rxReceived?.uuToHexString() ?? "nil")")
            }
           
            
        })
    }
    
    
    private func getImageFromBundle(_ name:String) -> Data?
    {
        guard let path = Bundle.main.path(forResource: name, ofType: ".jpg") else
        {
            return nil
        }
        
        guard let image = UIImage(contentsOfFile: path) else
        {
            return nil
        }
       
        guard let imageData = image.jpegData(compressionQuality: 0.5) else
        {
            return nil
        }
        
        return imageData
    }
    
    
    private func readL2CapSettings(completion: @escaping ((CBL2CAPPSM?, Bool?, Error?) -> Void))
    {
        self.addOutputLine("Reading L2Cap Settings...")
        self.discoverL2CapService(completion: completion)
    }
    
    private func discoverL2CapService(completion: @escaping ((CBL2CAPPSM?, Bool?, Error?) -> Void))
    {
        self.peripheral?.discoverServices(serviceUUIDs: [UUL2CapConstants.UU_L2CAP_SERVICE_UUID], timeout: 10)
        { discoveredServices, error in
            
            guard let service = discoveredServices?.first(where: { $0.uuid == UUL2CapConstants.UU_L2CAP_SERVICE_UUID }) else
            {
                self.addOutputLine("Couldn't find L2Cap Service!")
                completion(nil, nil, error)
                return
            }
            
            
            self.discoverL2CapCharacteristics(service: service, completion: completion)
        }
    }
    
    private func discoverL2CapCharacteristics(service:CBService, completion: @escaping ((CBL2CAPPSM?, Bool?, Error?) -> Void))
    {
        self.peripheral?.discoverCharacteristics(characteristicUUIDs: [UUL2CapConstants.UU_L2CAP_PSM_CHARACTERISTIC_UUID, UUL2CapConstants.UU_L2CAP_CHANNEL_ENCRYPTED_CHARACTERISTIC_UUID], for: service, timeout: 10)
        { discoveredCharacteristics, error in
            
            guard let psmCharacteristic = discoveredCharacteristics?.first(where: { $0.uuid == UUL2CapConstants.UU_L2CAP_PSM_CHARACTERISTIC_UUID }),
                  let encrytpedCharacteristic = discoveredCharacteristics?.first(where: { $0.uuid == UUL2CapConstants.UU_L2CAP_CHANNEL_ENCRYPTED_CHARACTERISTIC_UUID }) else
            {
                self.addOutputLine("Couldn't find L2Cap Characteristics!")
                completion(nil, nil, error)
                return
            }
            
            
            self.readL2CapCharacteristicValues(psmCharacteristic: psmCharacteristic, encryptionCharacteristic: encrytpedCharacteristic, completion: completion)
        }
    }
    
    private func readL2CapCharacteristicValues(psmCharacteristic:CBCharacteristic, encryptionCharacteristic:CBCharacteristic, completion: @escaping ((CBL2CAPPSM?, Bool?, Error?) -> Void))
    {
        self.readL2CapPSMValue(characteristic: psmCharacteristic)
        { foundPSM, error in
            
            guard let psm = foundPSM else
            {
                self.addOutputLine("Couldn't find L2Cap PSM")
                completion(nil, nil, error)
                return
            }
            
            
            self.readL2CapEncryptionValue(characteristic: encryptionCharacteristic)
            { foundEncryption, error in
                
                completion(psm, foundEncryption, error)
            }

        }
    }
    
    
    private func readL2CapPSMValue(characteristic:CBCharacteristic, completion: @escaping ((CBL2CAPPSM?, Error?) -> Void))
    {
        self.peripheral?.readValue(for: characteristic, timeout: 20.0)
        { _, characteristic, error in
            
            guard let psmData = characteristic.value else
            {
                completion(nil, error)
                return
            }
                    
            
            let psm = psmData.withUnsafeBytes({ $0.load(as: UInt16.self )})
            completion(psm, error)
        }
    }
    
    private func readL2CapEncryptionValue(characteristic:CBCharacteristic, completion: @escaping ((Bool?, Error?) -> Void))
    {
        self.peripheral?.readValue(for: characteristic, timeout: 20.0)
        { _, characteristic, error in
            
            guard let encryptedData = characteristic.value else
            {
                completion(nil, error)
                return
            }
                    
            
            let encrypted = encryptedData.withUnsafeBytes({ $0.load(as: UInt8.self )}) == 0
            completion(encrypted, error)
        }
    }
}

