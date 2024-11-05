//
//  UUCoreBluetooth.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 8/13/21.
//

import UIKit
import CoreBluetooth
import UUSwiftCore

// MARK:- Common Type Alias Definitions

public typealias UUCentralStateChangedBlock = ((CBManagerState)->())
public typealias UUPeripheralFoundBlock = ((CBPeripheral, [String:Any], Int)->())
public typealias UUWillRestoreStateBlock = (([String:Any])->())
public typealias UUPeripheralListBlock = (([UUPeripheral])->())


/**
 
 UUCentralManager is a wrapper for CBCentralManager.   It provides a block based interface to CoreBluetooth operations.
 
 */
public class UUCentralManager
{
    private(set) public var dispatchQueue = DispatchQueue(label: "UUCentralManagerQueue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .inherit, target: nil)
    
    private var delegate: UUCentralManagerDelegate
    var centralManager: CBCentralManager
    
    private var peripherals: [String: UUPeripheral] = [:]
    private var peripheralsMutex = NSRecursiveLock()
    
    private var scanUuidList: [CBUUID]? = nil
    private var scanOptions: [String:Any]? = nil
    private var scanFilters: [UUPeripheralFilter]? = nil
    private(set) public var isScanning: Bool = false
    private var isConfiguredForStateRestoration: Bool = false
    
    private var centralStateChangedBlock: UUCentralStateChangedBlock? = nil
    private var rssiPollingBlocks: [String:UUPeripheralBlock] = [:]
    private var willRestoreStateBlock: UUWillRestoreStateBlock? = nil
    private var options: [String:Any]? = nil
    
    public static var shared: UUCentralManager
    {
        return UUCentralManagerFactory.sharedCentralManager
    }
    
    required init(_ opts: [String:Any]?)
    {
        NSLog("Initializing UUCoreBluetooth with options: \(String(describing: opts))")
        
        options = opts
        isConfiguredForStateRestoration = (options?.uuGetString(CBCentralManagerOptionRestoreIdentifierKey) != nil)
        delegate = isConfiguredForStateRestoration ? UUCentralManagerRestoringDelegate() : UUCentralManagerDelegate()
        centralManager = CBCentralManager(delegate: delegate, queue: dispatchQueue, options: options)
        delegate.centralStateChangedBlock = handleCentralStateChanged
    }
    
    public var centralState: CBManagerState
    {
        return centralManager.state
    }
    
    // Returns a flag indicating whether the central state is powered on or not.
    public var isPoweredOn: Bool
    {
        return centralManager.state == .poweredOn
    }
    
    public func registerForCentralStateChanges(_ block: UUCentralStateChangedBlock?)
    {
        centralStateChangedBlock = block
    }
    
    
    
    // PRIVATE
    
    private func handleCentralStateChanged(_ state: CBManagerState)
    {
        peripherals.values.forEach
        { p in
            
            NSLog("Peripheral \(p.identifier)-\(p.name), state is \(UUCBPeripheralStateToString(p.peripheralState)) (\(p.peripheralState) when central state changed to \(UUCBManagerStateToString(state)) (\(state)")
            
            if (state != .poweredOn)
            {
                self.notifyDisconnect(p, nil)
            }
        }
        
        switch (state)
        {
            case .poweredOn:
                handleCentralStatePoweredOn()
                
            case .resetting:
                handleCentralReset()
                
            default:
                break
        }
        
        centralStateChangedBlock?(state)
    }
    
    private func handleCentralStatePoweredOn()
    {
        if isScanning
        {
            resumeScanning()
        }
    }
    
    private func handleCentralReset()
    {
        NSLog("Central is resetting")
    }
    
    public func startScan(
        serviceUuids: [CBUUID]?,
        allowDuplicates: Bool,
        //peripheralFactory: UUPeripheralFactory<T>?,
        filters: [UUPeripheralFilter]?,
        peripheralFoundCallback: @escaping ((UUPeripheral)->()),
        willRestoreCallback: @escaping UUWillRestoreStateBlock)
    {
        NSLog("starting scan")
        
        var opts: [String:Any] = [:]
        opts[CBCentralManagerScanOptionAllowDuplicatesKey] = allowDuplicates
        
        scanUuidList = serviceUuids
        scanOptions = opts
        scanFilters = filters
        isScanning = true
        NSLog("isScanning: \(isScanning)")
        willRestoreStateBlock = willRestoreCallback
        delegate.peripheralFoundBlock =
        { peripheral, advertisementData, rssi in
            
            //let uuPeripheral: T = self.updatedPeripheralFromScan(peripheral, advertisementData, rssi)
            //var uuPeripheral: T? = peripheralFactory?.create(self.dispatchQueue, self, peripheral)
            if let p = self.updatePeripheralFromScan(peripheral, advertisementData, rssi)
            {
                NSLog("Updated peripheral after scan. peripheral: \(String(describing: p.underlyingPeripheral)), rssi: \(p.rssi), advertisement: \(p.advertisementData)")
                
                if (self.shouldDiscoverPeripheral(p))
                {
                    peripheralFoundCallback(p)
                }
            }
            
            /*
            if (uuPeripheral == nil)
            {
                uuPeripheral = UUPeripheral(self.dispatchQueue, self, peripheral) as? T
            }
            
            if let p = uuPeripheral
            {
                NSLog("Updated peripheral after scan. peripheral: \(String(describing: p.underlyingPeripheral)), rssi: \(p.rssi), advertisement: \(p.advertisementData)")
                
                if (self.shouldDiscoverPeripheral(p))
                {
                    peripheralFoundCallback(p)
                }
            }*/
        }
       
        resumeScanning()
    }

    private func resumeScanning()
    {
        centralManager.scanForPeripherals(withServices: scanUuidList, options: scanOptions)
    }
    
    internal func restartScanning()
    {
        pauseScanning()
        resumeScanning()
    }
    
    private func handleWillRestoreState(_ options: [String:Any])
    {
        willRestoreStateBlock?(options)
    }
    
    private func shouldDiscoverPeripheral(_ peripheral: UUPeripheral) -> Bool
    {
        guard let filters = scanFilters else
        {
            return true
        }
        
        for f in filters
        {
            if (!f.shouldDiscover(peripheral))
            {
                return false
            }
        }
        
        return true
    }
    
    public func stopScan()
    {
        NSLog("stopping scan, isScanning: \(isScanning)")
        
        isScanning = false
        NSLog("isScanning: \(isScanning)")
        //peripheralFoundBlock = nil
        //handlePeripheralFound = nil
        delegate.peripheralFoundBlock = nil
        centralManager.stopScan()
    }
    
    private func pauseScanning()
    {
        NSLog("pausing scan, isScanning: \(isScanning)")
        centralManager.stopScan()
    }
    
    
    func registerConnectionBlocks(_ peripheral: UUPeripheral, _ connectedBlock: @escaping UUCBPeripheralBlock, _ disconnectedBlock: @escaping UUCBPeripheralErrorBlock)
    {
        let key = peripheral.identifier
        delegate.connectBlocks[key] = connectedBlock
        delegate.disconnectBlocks[key] = disconnectedBlock
    }
    
    func removeConnectionBlocks(_ peripheral: UUPeripheral)
    {
        let key = peripheral.identifier
        delegate.connectBlocks.removeValue(forKey: key)
        delegate.disconnectBlocks.removeValue(forKey: key)
    }
    
    func connect(_ peripheral: UUPeripheral, _ options: [String:Any]?)
    {
        centralManager.connect(peripheral.underlyingPeripheral, options: options)
    }
    
    func cancelPeripheralConnection(_ peripheral: UUPeripheral)
    {
        centralManager.cancelPeripheralConnection(peripheral.underlyingPeripheral)
    }
    
    func notifyDisconnect(_ peripheral: UUPeripheral, _ error: Error?)
    {
       let key = peripheral.identifier
       let disconnectBlock = delegate.disconnectBlocks[key]
       delegate.disconnectBlocks.removeValue(forKey: key)
       delegate.connectBlocks.removeValue(forKey: key)
       
       if let block = disconnectBlock
       {
            block(peripheral.underlyingPeripheral, error)
       }
       else
       {
           NSLog("No delegate to notify disconnected")
       }
   }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    /*
    // Begins polling RSSI for a peripheral.  When the RSSI is successfully
    // retrieved, the peripheralFoundBlock is called.  This method is useful to
    // perform a crude 'ranging' logic when already connected to a peripheral
    - (void) startRssiPolling:(nonnull UUPeripheral*)peripheral
                     interval:(NSTimeInterval)interval
            peripheralUpdated:(nonnull UUPeripheralBlock)peripheralUpdated
    {
        [self.rssiPollingBlocks uuSafeSetValue:peripheralUpdated forKey:peripheral.identifier];
        
        NSString* timerId = [peripheral.peripheral uuPollRssiTimerId];
        [UUCoreBluetooth cancelWatchdogTimer:timerId];
        
        [peripheral.peripheral uuReadRssi:kUUCoreBluetoothTimeoutDisabled
                               completion:^(CBPeripheral * _Nonnull cbPeripheral, NSNumber * _Nonnull rssi, NSError * _Nullable error)
        {
            UUCoreBluetoothLog(@"RSSI Updated for %@-%@, %@, error: %@", cbPeripheral.uuIdentifier, cbPeripheral.name, rssi, error);
            
            UUPeripheralBlock block = [self.rssiPollingBlocks uuSafeGet:cbPeripheral.uuIdentifier];

            if (!error)
            {
                UUPeripheral* peripheral = [self updatedPeripheralFromRssiRead:cbPeripheral rssi:rssi];
                
                if (block)
                {
                    block(peripheral);
                }
            }
            else
            {
                UUCoreBluetoothLog(@"Error while reading RSSI: %@", error);
            }
            
            if (block)
            {
                [UUCoreBluetooth startWatchdogTimer:timerId
                                            timeout:interval
                                           userInfo:peripheral
                                              block:^(id  _Nullable userInfo)
                 {
                     UUPeripheral* peripheral = userInfo;
                     UUCoreBluetoothLog(@"RSSI Polling timer %@ - %@", peripheral.identifier, peripheral.name);
                     
                     UUPeripheralBlock block = [self.rssiPollingBlocks uuSafeGet:peripheral.identifier];
                     if (!block)
                     {
                         UUCoreBluetoothLog(@"Peripheral %@-%@ not polling anymore", peripheral.identifier, peripheral.name);
                     }
                     else if (peripheral.peripheralState == CBPeripheralStateConnected)
                     {
                         [self startRssiPolling:peripheral interval:interval peripheralUpdated:peripheralUpdated];
                     }
                     else
                     {
                         UUCoreBluetoothLog(@"Peripheral %@-%@ is not connected anymore, cannot poll for RSSI", peripheral.identifier, peripheral.name);
                     }
                 }];
            }
            
        }];
    }

    - (void) stopRssiPolling:(nonnull UUPeripheral*)peripheral
    {
        [self.rssiPollingBlocks uuSafeRemove:peripheral.identifier];
    }

    - (BOOL) isPollingForRssi:(nonnull UUPeripheral*)peripheral
    {
        return ([self.rssiPollingBlocks uuSafeGet:peripheral.identifier] != nil);
    }

     */
    
    /*
    private func createPeripheral<T: UUPeripheral>(_ peripheral: CBPeripheral) -> T
    {
        var p: T? = nil//peripheralFactory?.create(dispatchQueue, self, peripheral)
        
        if (p == nil)
        {
            //p = UUPeripheral(dispatchQueue, self, peripheral)
        }
        
        return p!
    }
    
    private func findPeripheralFromCbPeripheral<T: UUPeripheral>(_ peripheral: CBPeripheral) -> T
    {
        defer { peripheralsMutex.unlock() }
        peripheralsMutex.lock()
        
        var uuPeripheral = peripherals[peripheral.identifier.uuidString]
        if (uuPeripheral == nil)
        {
            uuPeripheral = createPeripheral(peripheral)
        }
        
        return uuPeripheral as! T
    }
    
    private func updatedPeripheralFromCbPeripheral<T: UUPeripheral>(_ peripheral: CBPeripheral) -> T
    {
        let uuPeripheral = findPeripheralFromCbPeripheral(peripheral)
        uuPeripheral.underlyingPeripheral = peripheral
        updatePeripheral(uuPeripheral)
        return uuPeripheral as! T
    }
    
    private func updatedPeripheralFromScan<T: UUPeripheral>(
        _ peripheral: CBPeripheral,
        _ advertisementData: [String:Any],
        _ rssi: Int) -> T
    {
        let uuPeripheral: T = findPeripheralFromCbPeripheral(peripheral)
        uuPeripheral.updateFromScan(peripheral, advertisementData, rssi)
        updatePeripheral(uuPeripheral)
        return uuPeripheral
    }*/

    /*
    - (nonnull UUPeripheral*) updatedPeripheralFromRssiRead:(nonnull CBPeripheral*)peripheral
                                                       rssi:(nullable NSNumber*)rssi
    {
        UUPeripheral* uuPeripheral = [self findPeripheralFromCbPeripheral:peripheral];
        
        NSNumber* oldRssi = uuPeripheral.rssi;
        #pragma unused(oldRssi)
        
        [uuPeripheral updateRssi:rssi];
        
        UUCoreBluetoothLog(@"peripheralRssiChanged, %@ - %@, from: %@ to %@", uuPeripheral.identifier, uuPeripheral.name, oldRssi, rssi);
        
        [self updatePeripheral:uuPeripheral];
        
        return uuPeripheral;
    }*/
    
    private func getOrCreatePeripheral(/*_ factory: UUPeripheralFactory<T>?, */_ cbPeripheral: CBPeripheral) -> UUPeripheral?
    {
        var p = findPeripheralFromCbPeripheral(cbPeripheral)
        if (p == nil)
        {
            p = UUPeripheral(dispatchQueue: self.dispatchQueue, centralManager: self, peripheral: cbPeripheral)
        }
        
        return p
    }
    
//    private func createPeripheral<T: UUPeripheral>(_ factory: UUPeripheralFactory<T>?, _ cbPeripheral: CBPeripheral) -> T?
//    {
//        var p = factory?.create(self.dispatchQueue, self, cbPeripheral)
//        if (p == nil)
//        {
//            p = UUPeripheral(dispatchQueue: self.dispatchQueue, centralManager: self, peripheral: cbPeripheral) as? T
//        }
//        
//        return p
//    }
    
    private func findPeripheralFromCbPeripheral(_ peripheral: CBPeripheral) -> UUPeripheral?
    {
        defer { peripheralsMutex.unlock() }
        peripheralsMutex.lock()
        
        return peripherals[peripheral.identifier.uuidString]
    }
    
    private func updatePeripheralFromScan(
        //_ factory: UUPeripheralFactory<T>?,
        _ peripheral: CBPeripheral,
        _ advertisementData: [String:Any],
        _ rssi: Int) -> UUPeripheral?
    {
        guard let uuPeripheral = getOrCreatePeripheral(peripheral) else
        {
            return nil
        }
        
        uuPeripheral.updateFromScan(peripheral, advertisementData, rssi)
        updatePeripheral(uuPeripheral)
        return uuPeripheral
    }
    
    private func updatePeripheral(_ peripheral: UUPeripheral)
    {
        defer { peripheralsMutex.unlock() }
        peripheralsMutex.lock()
        
        peripherals[peripheral.identifier] = peripheral
    }
    
    private func removePeripheral(_ peripheral: UUPeripheral)
    {
        defer { peripheralsMutex.unlock() }
        peripheralsMutex.lock()
        
        peripherals.removeValue(forKey: peripheral.identifier)
    }
}

// MARK:- Global Helper functions

public func UUCBManagerStateToString(_ state: CBManagerState) -> String
{
    switch (state)
    {
        case .unknown:
            return "Unknown"
            
        case .resetting:
            return "Resetting"
            
        case .unsupported:
            return "Unsupported"
            
        case .unauthorized:
            return "Unauthorized"
            
        case .poweredOff:
            return "PoweredOff"
            
        case .poweredOn:
            return "PoweredOn"
            
        default:
            return "CBManagerState-\(state)"
    }
}

public func UUCBPeripheralStateToString(_ state: CBPeripheralState) -> String
{
    switch (state)
    {
        case .disconnected:
            return "Disconnected"
            
        case .connecting:
            return "Connecting"
            
        case .connected:
            return "Connected"
            
        case .disconnecting:
            return "Disconnecting"
            
        default:
            return "CBPeripheralState-\(state)"
    }
}

func UUIsCBCharacteristicPropertySet(_ props: CBCharacteristicProperties, _ check: CBCharacteristicProperties) -> Bool
{
    return props.contains(check)
}

public func UUCBCharacteristicPropertiesToString(_ props: CBCharacteristicProperties) -> String
{
    var parts: [String] = []
    
    if (UUIsCBCharacteristicPropertySet(props, .broadcast))
    {
        parts.append("Broadcast")
    }
    
    if (UUIsCBCharacteristicPropertySet(props, .read))
    {
        parts.append("Read")
    }
    
    if (UUIsCBCharacteristicPropertySet(props, .writeWithoutResponse))
    {
        parts.append("WriteWithoutResponse")
    }
    
    if (UUIsCBCharacteristicPropertySet(props, .write))
    {
        parts.append("Write")
    }
    
    if (UUIsCBCharacteristicPropertySet(props, .notify))
    {
        parts.append("Notify")
    }
    
    if (UUIsCBCharacteristicPropertySet(props, .indicate))
    {
        parts.append("Indicate")
    }
    
    if (UUIsCBCharacteristicPropertySet(props, .authenticatedSignedWrites))
    {
        parts.append("AuthenticatedSignedWrites")
    }
    
    if (UUIsCBCharacteristicPropertySet(props, .extendedProperties))
    {
        parts.append("ExtendedProperties")
    }
    if (UUIsCBCharacteristicPropertySet(props, .notifyEncryptionRequired))
    {
        parts.append("NotifyEncryptionRequired")
    }
    
    if (UUIsCBCharacteristicPropertySet(props, .indicateEncryptionRequired))
    {
        parts.append("IndicateEncryptionRequired")
    }
    
    return parts.joined(separator: ", ")
}



/*
extension UUCentralManager // Timers
{
    static func startWatchdogTimer(_ timerId: String, timeout: TimeInterval, userInfo: Any?, block: UUWatchdogTimerBlock?)
    {
        UUTimer.startWatchdogTimer(timerId, timeout, userInfo, queue: dispatchQueue, block)
    }
}*/
