//
//  UUCentralManagerDelegate.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 8/13/21.
//

import UIKit
import CoreBluetooth
import UUSwiftCore

class UUCentralManagerDelegate: NSObject, CBCentralManagerDelegate
{
    var centralStateChangedBlock: UUCentralStateChangedBlock? = nil
    var peripheralFoundBlock: UUPeripheralFoundBlock? = nil
    var connectBlocks: [String: UUCBPeripheralBlock] = [:]
    var disconnectBlocks: [String: UUCBPeripheralErrorBlock] = [:]
    
    // MARK:- CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager)
    {
        NSLog("Central state changed to \(UUCBManagerStateToString(central.state)) (\(central.state))")
        centralStateChangedBlock?(central.state)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber)
    {
        NSLog("peripheral: %@, RSSI: %@, advertisement: %@", peripheral, RSSI, advertisementData)
        
        peripheralFoundBlock?(peripheral, advertisementData, RSSI.intValue)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral)
    {
        let key = peripheral.identifier.uuidString
        let block = connectBlocks[key]
        connectBlocks.removeValue(forKey: key)
        block?(peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?)
    {
        let key = peripheral.identifier.uuidString
        let block = disconnectBlocks[key]
        disconnectBlocks.removeValue(forKey: key)
        connectBlocks.removeValue(forKey: key)
        block?(peripheral, NSError.uuConnectionFailedError(error as NSError?))
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?)
    {
        let key = peripheral.identifier.uuidString
        let block = disconnectBlocks[key]
        disconnectBlocks.removeValue(forKey: key)
        connectBlocks.removeValue(forKey: key)
        block?(peripheral, NSError.uuDisconnectedError(error as NSError?))
    }
}

class UUCentralManagerRestoringDelegate: UUCentralManagerDelegate
{
    var willRestoreBlock: UUWillRestoreStateBlock? = nil
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any])
    {
        NSLog("Restoring state, dict: \(dict)")
        willRestoreBlock?(dict)
    }
}

