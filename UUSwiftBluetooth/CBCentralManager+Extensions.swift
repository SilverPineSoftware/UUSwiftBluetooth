//
//  CBCentralManager+Extensions.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 8/13/21.
//

import UIKit
import CoreBluetooth
import UUSwiftCore

extension CBCentralManager
{
    private var uuCentralManagerDelegate: UUCentralManagerDelegate?
    {
        return delegate as? UUCentralManagerDelegate
    }
    
    // Returns a flag indicating whether the central state is powered on or not.
    public var uuIsPoweredOn: Bool
    {
        return state == .poweredOn
    }
    
     // Block based wrapper around CBCentralManager scanForPeripheralsWithServices:options
     public func uuScanForPeripherals(
        _ serviceUUIDS: [CBUUID]?,
        _ options: [String:Any]?,
        _ peripheralFoundBlock: @escaping UUPeripheralFoundBlock,
        _ willRestoreStateCallback: @escaping UUWillRestoreStateBlock)
     {
        NSLog("Starting BTLE scan, serviceUUIDs: \(String(describing: serviceUUIDS)), options: \(String(describing: options)), state: \(UUCBManagerStateToString(state))")
        
        guard uuIsPoweredOn else
        {
            NSLog("Central is not powered on, cannot start scanning now!")
            return
        }
        
        let delegate = uuCentralManagerDelegate
        delegate?.peripheralFoundBlock = peripheralFoundBlock
        
        if let restoringDelegate = delegate as? UUCentralManagerRestoringDelegate
        {
            restoringDelegate.willRestoreBlock = willRestoreStateCallback
        }
        
        scanForPeripherals(withServices: serviceUUIDS, options: options)
     }
    
    public func uuStopScan()
    {
        // Convenience wrapper around CBCentralManager stopScan
        
        NSLog("Stopping BTLE scan, state: \(UUCBManagerStateToString(state))")
        
        guard uuIsPoweredOn else
        {
            NSLog("Central is not powered on, cannot stop scanning now!")
            return
        }
        
        let delegate = uuCentralManagerDelegate
        delegate?.peripheralFoundBlock = nil
        
        stopScan()
    }
    
     // Block based wrapper around CBCentralManager connectPeripheral:options with a
     // timeout value.  If a negative timeout is passed there will be no timeout used.
     // The connected block is only invoked upon successfully connection.  The
     // disconnected block is invoked in the case of a connection failure, timeout
     // or disconnection.
     //
     // Each block will only be invoked at most one time.  After a successful
     // connection, the disconnect block will be called back when the peripheral
     // is disconnected from the phone side, or if the remote device disconnects
     // from the phone
     public func uuConnectPeripheral(
        _ peripheral: CBPeripheral,
        _ options: [String:Any]?,
        _ timeout: TimeInterval,
        _ disconnectTimeout: TimeInterval,
        _ connected: @escaping UUPeripheralConnectedBlock,
        _ disconnected: @escaping UUPeripheralDisconnectedBlock)
     {
        NSLog("Connecting to \(peripheral.uuIdentifier) - \(peripheral.uuName), timeout: \(timeout)")
        
        guard uuIsPoweredOn else
        {
            let err = NSError.uuCoreBluetoothError(.centralNotReady)
            disconnected(peripheral, err)
            return
        }
        
        let timerId = peripheral.uuConnectWatchdogTimerId()
        
        let delegate = uuCentralManagerDelegate
        
        let connectedBlock: UUPeripheralConnectedBlock =
        { peripheral in
            
            NSLog("Connected to \(peripheral.uuIdentifier) - \(peripheral.uuName)")
            
            peripheral.uuCancelTimer(timerId)
            connected(peripheral)
        };
        
        let disconnectedBlock: UUPeripheralDisconnectedBlock =
        { peripheral, error in
            
            NSLog("Disconnected from \(peripheral.uuIdentifier) - \(peripheral.uuName), error: \(String(describing: error))")
            
            peripheral.uuCancelTimer(timerId)
            disconnected(peripheral, error)
        }
        
        delegate?.connectBlocks[peripheral.uuIdentifier] = connectedBlock
        delegate?.disconnectBlocks[peripheral.uuIdentifier] = disconnectedBlock
        
        peripheral.uuStartTimer(timerId, timeout)
        { peripheral in
            
            NSLog("Connect timeout for \(peripheral.uuIdentifier) - \(peripheral.uuName)")
             
            delegate?.connectBlocks.removeValue(forKey: peripheral.uuIdentifier)
            delegate?.disconnectBlocks.removeValue(forKey: peripheral.uuIdentifier)
             
             // Issue the disconnect but disconnect any delegate's.  In the case of
             // CBCentralManager being off or reset when this happens, immediately
             // calling the disconnected block ensures there is not an infinite
             // timeout situation.
            self.uuDisconnectPeripheral(peripheral, disconnectTimeout)
             
            let err = NSError.uuCoreBluetoothError(.timeout)
            peripheral.uuCancelTimer(timerId)
            disconnected(peripheral, err)
        }
        
        connect(peripheral, options: options)
     }

     // Wrapper around CBCentralManager cancelPeripheralConnection.  After calling this
     // method, the disconnected block passed in at connect time will be invoked.
    public func uuDisconnectPeripheral(
        _ peripheral: CBPeripheral,
        _ timeout: TimeInterval)
    {
        NSLog("Cancelling connection to peripheral \(peripheral.uuIdentifier) - \(peripheral.uuName), timeout: \(timeout)")
        
        guard uuIsPoweredOn else
        {
            NSLog("Central is not powered on, cannot cancel a connection!")
            let err = NSError.uuCoreBluetoothError(.centralNotReady)
            uuNotifyDisconnect(peripheral, err)
            return
        }
        
        let timerId = peripheral.uuDisconnectWatchdogTimerId()
        
        peripheral.uuStartTimer(timerId, timeout)
        { peripheral in
            
            NSLog("Disconnect timeout for \(peripheral.uuIdentifier) - \(peripheral.uuName)")
            
            peripheral.uuCancelTimer(timerId)
            self.uuNotifyDisconnect(peripheral, NSError.uuCoreBluetoothError(.timeout))
            
            // Just in case the timeout fires and a real disconnect is needed, this is the last
            // ditch effort to close the connection
            self.cancelPeripheralConnection(peripheral)
        }
        
        cancelPeripheralConnection(peripheral)
    }
    
    func uuNotifyDisconnect(_ peripheral: CBPeripheral, _ error: Error?)
    {
        let delegate = uuCentralManagerDelegate
        
        let key = peripheral.uuIdentifier
        let disconnectBlock = delegate?.disconnectBlocks[key]
        delegate?.disconnectBlocks.removeValue(forKey: key)
        delegate?.connectBlocks.removeValue(forKey: key)
        
        if let block = disconnectBlock
        {
            block(peripheral, error)
        }
        else
        {
            NSLog("No delegate to notify disconnected")
        }
    }
}
