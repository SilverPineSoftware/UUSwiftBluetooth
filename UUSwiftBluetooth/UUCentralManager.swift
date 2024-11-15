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
public typealias UUBluetoothAdvertisementBlock = ((UUBluetoothAdvertisement)->())
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
    
    // Keep track of connected peripherals
    private var peripherals: [UUID: UUPeripheral] = [:]
    private var peripheralsMutex = NSRecursiveLock()
    
    private var scanUuidList: [CBUUID]? = nil
    private var scanOptions: [String:Any]? = nil
    //private var scanFilters: [UUPeripheralFilter]? = nil
    private(set) public var isScanning: Bool = false
    private var isConfiguredForStateRestoration: Bool = false
    
    private var centralStateChangedBlock: UUCentralStateChangedBlock? = nil
    private var rssiPollingBlocks: [String:UUPeripheralBlock] = [:]
    private var peripheralFoundBlock: UUPeripheralBlock? = nil
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
        defer { peripheralsMutex.unlock() }
        peripheralsMutex.lock()
        
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
    
    public func retrieveConnectedPeripherals(withServices services: [CBUUID]) -> [CBPeripheral]
    {
        return self.centralManager.retrieveConnectedPeripherals(withServices: services)
    }
    
    public func startScan(
        serviceUuids: [CBUUID]?,
        allowDuplicates: Bool,
        peripheralFoundCallback: @escaping UUPeripheralBlock,
        willRestoreCallback: @escaping UUWillRestoreStateBlock)
    {
        NSLog("Clearing nearby peripherals")
        clearNearbyPeripherals()
        
        NSLog("starting scan")
        
        var opts: [String:Any] = [:]
        opts[CBCentralManagerScanOptionAllowDuplicatesKey] = allowDuplicates
        
        scanUuidList = serviceUuids
        scanOptions = opts
        isScanning = true
        NSLog("isScanning: \(isScanning)")
        willRestoreStateBlock = willRestoreCallback
        peripheralFoundBlock = peripheralFoundCallback
        delegate.peripheralFoundBlock = handleAdvertisement
        resumeScanning()
    }
    
    private func handleAdvertisement(_ advertisement: UUBluetoothAdvertisement)
    {
        defer { peripheralsMutex.unlock() }
        peripheralsMutex.lock()
        
        let uuid = advertisement.peripheral.identifier
        
        var lookup = peripherals[uuid]
        if (lookup == nil)
        {
            lookup = UUPeripheral(dispatchQueue: self.dispatchQueue, centralManager: self, peripheral: advertisement.peripheral)
        }
        
        guard let p = lookup else
        {
            // Should never happen, but we are safe coders!
            return
        }
        
        p.appendAdvertisement(advertisement)
        peripherals[uuid] = p
        
        guard let block = peripheralFoundBlock else
        {
            return
        }
        
        block(p)
    }
    
    private func clearNearbyPeripherals()
    {
        defer { peripheralsMutex.unlock() }
        peripheralsMutex.lock()
        
        let keep = peripherals.values.filter
        { p in
            p.peripheralState != .disconnected
        }
        
        peripherals.removeAll()
        
        for p in keep
        {
            p.clearAdvertisements()
            peripherals[p.identifier] = p
        }
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
    
    /*
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
    }*/
    
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
    
    
    /*private func getOrCreatePeripheral(_ cbPeripheral: CBPeripheral) -> UUPeripheral?
    {
        var p = findPeripheralFromCbPeripheral(cbPeripheral)
        if (p == nil)
        {
            p = UUPeripheral(dispatchQueue: self.dispatchQueue, centralManager: self, peripheral: cbPeripheral)
        }
        
        return p
    }*/
    
    /*private func findPeripheralFromCbPeripheral(_ peripheral: CBPeripheral) -> UUPeripheral?
    {
        defer { peripheralsMutex.unlock() }
        peripheralsMutex.lock()
        
        return peripherals[peripheral.identifier]
    }*/
    
    /*private func updatePeripheralFromScan(_ advertisement: UUBluetoothAdvertisement) -> UUPeripheral?
    {
        guard let uuPeripheral = getOrCreatePeripheral(advertisement.peripheral) else
        {
            return nil
        }
        
        uuPeripheral.appendAdvertisement(advertisement)
        updatePeripheral(uuPeripheral)
        return uuPeripheral
    }*/
    
    /*private func updatePeripheral(_ peripheral: UUPeripheral)
    {
        defer { peripheralsMutex.unlock() }
        peripheralsMutex.lock()
        
        peripherals[peripheral.identifier] = peripheral
    }*/
    
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
