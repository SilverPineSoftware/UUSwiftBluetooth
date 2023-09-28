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
    var peripheral:UUPeripheral!
    private var channel:UUL2CapChannel? = nil
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.title = "L2Cap Client"
        
        self.configureLeftButton("Connect", connect)
        self.configureRightButton("Ping", ping)
        
        
        self.initialOutputline = "Tap Connect to Begin"
        self.clearOutput()
    }
    
    func connect()
    {
        self.addOutputLine("Connecting...")
        self.peripheral.connect(timeout: UUPeripheral.Defaults.connectTimeout)
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
        self.readL2CapSettings
        { foundPsm, foundEncrypted, error in
            
            guard let psm = foundPsm else
            {
                self.addOutputLine("No PSM found! Cannot start channel!")
                return
            }
            
            self.addOutputLine("L2Cap Settings (psm:\(psm), encrypted:\(String(describing: foundEncrypted)))")
            
            self.addOutputLine("Opening L2CapChannel with psm \(psm)...")

            self.channel = UUL2CapChannel(self.peripheral)
            
            self.channel?.open(psm: psm, timeout: 10.0, completion:
            { error in
                            
                if let err = error
                {
                    self.addOutputLine("Error: \(err)")
                }
                else if let _ = self.channel
                {
                    self.addOutputLine("L2Cap Channel Connected!")
                }
                else
                {
                    self.addOutputLine("L2Cap Channel connect attempt returned no error but no channel was created!")
                }
                
            })
            
        }
    }
    
    func ping()
    {
        let tx = "4747474747"
        self.addOutputLine("TX: \(tx)")
        
        let data = Data(tx.uuToHexData() ?? NSData())
        
        self.channel?.sendMessage(data, 10.0,
        { progressBytesSent in
            
            if (data.count > 0)
            {
                self.addOutputLine("Data Send Progress: \((progressBytesSent/UInt32(data.count))*100)%")
            }
        },
        { totalBytesSent, dataReceived, error in
            
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
        })
    }
    
    
    private func readL2CapSettings(completion: @escaping ((CBL2CAPPSM?, Bool?, Error?) -> Void))
    {
        self.addOutputLine("Reading L2Cap Settings...")
        self.discoverL2CapService(completion: completion)
    }
    
    private func discoverL2CapService(completion: @escaping ((CBL2CAPPSM?, Bool?, Error?) -> Void))
    {
        self.peripheral.discoverServices([UUL2CapConstants.UU_L2CAP_SERVICE_UUID], timeout: 10)
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
        self.peripheral.discoverCharacteristics([UUL2CapConstants.UU_L2CAP_PSM_CHARACTERISTIC_UUID, UUL2CapConstants.UU_L2CAP_CHANNEL_ENCRYPTED_CHARACTERISTIC_UUID], for: service, timeout: 10)
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
        self.peripheral.readValue(for: characteristic)
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
        self.peripheral.readValue(for: characteristic)
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

