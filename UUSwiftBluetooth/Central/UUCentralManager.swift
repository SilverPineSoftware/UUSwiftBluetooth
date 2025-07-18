//
//  UUCoreBluetooth.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 8/13/21.
//

import Foundation
import CoreBluetooth
import UUSwiftCore

fileprivate let LOG_TAG = "UUCentralManager"

// MARK:- Common Type Alias Definitions

public typealias UUCentralStateChangedBlock = ((CBManagerState)->())
public typealias UUBluetoothAdvertisementBlock = ((UUAdvertisement)->())
public typealias UUWillRestoreStateBlock = (([String:Any])->())

/**
 *  @class CBCentralManager
 *
 *  @discussion Entry point to the central role. Commands should only be issued when its state is <code>CBCentralManagerStatePoweredOn</code>.
 *
 */
public class UUCentralManager: UUManagerStateMonitor
{
    private(set) internal var dispatchQueue = DispatchQueue(label: "UUCentralManagerQueue", qos: .userInteractive, attributes: [], autoreleaseFrequency: .inherit, target: nil)
    
    private var delegate: UUCentralManagerDelegate
    private var centralManager: UUCBCentralManager
    
    private var scanConfig: UUPeripheralScannerConfig = UUPeripheralScannerConfig()
    private(set) public var isScanning: Bool = false
    
    private var willRestoreStateBlock: UUWillRestoreStateBlock? = nil
    private var options: [String:Any]? = nil
    
    private var managerStateListeners: [String:UUCBManagerStateBlock] = [:]
    
    public static var shared: UUCentralManager
    {
        return UUCentralManagerFactory.sharedCentralManager
    }
    
    required init(options: [String:Any]? = nil, injection: (DispatchQueue, [String:Any]?)->(UUCentralManagerDelegate, UUCBCentralManager))
    {
        UULog.debug(tag: LOG_TAG, message: "Initializing UUCoreBluetooth with options: \(String(describing: options))")
        
        let injected = injection(dispatchQueue, options)
        delegate = injected.0
        centralManager = injected.1
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
    
    public func lookupPeripheral(_ identifier: UUID) -> CBPeripheral?
    {
        return centralManager.retrievePeripherals(withIdentifiers: [identifier]).first
    }
    
    // MARK: UUManagerStateMonitor
    
    public var managerState: CBManagerState
    {
        return centralManager.state
    }
    
    public func registerForStateChanges(identifier: String, handler: @escaping UUCBManagerStateBlock)
    {
        self.managerStateListeners[identifier] = handler
    }
    
    
    
    // PRIVATE
    
    private var canStartScanning: Bool
    {
        return centralManager.state == .poweredOn
    }
    
    private func handleCentralStateChanged(_ state: CBManagerState)
    {
        /*defer { peripheralsMutex.unlock() }
        peripheralsMutex.lock()
        
        peripherals.values.forEach
        { p in
            
            UUDebugLog("Peripheral \(p.identifier)-\(p.name), state is \(UUCBPeripheralStateToString(p.peripheralState)) (\(p.peripheralState) when central state changed to \(UUCBManagerStateToString(state)) (\(state)")
            
            if (state != .poweredOn)
            {
                self.notifyDisconnect(p, nil)
            }
        }*/
        
        switch (state)
        {
            case .poweredOn:
                handleCentralStatePoweredOn()
                
            case .resetting:
                handleCentralReset()
                
            default:
                break
        }
        
        notifyManagerStateListeners(state)
    }
    
    private func notifyManagerStateListeners(_ state: CBManagerState)
    {
        for (_, handler) in managerStateListeners
        {
            handler(state)
        }
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
        UULog.debug(tag: LOG_TAG, message: "Central is resetting")
    }
    
    public func retrieveConnectedPeripherals(withServices services: [CBUUID]) -> [CBPeripheral]
    {
        return self.centralManager.retrieveConnectedPeripherals(withServices: services)
    }
    
    public func startScan(
        config: UUPeripheralScannerConfig,
        advertisementHandler: @escaping UUBluetoothAdvertisementBlock,
        willRestoreCallback: UUWillRestoreStateBlock? = nil)
    {
        UULog.debug(tag: LOG_TAG, message: "starting scan")
        
        scanConfig = config
        isScanning = true
        UULog.debug(tag: LOG_TAG, message: "isScanning: \(isScanning)")
        willRestoreStateBlock = willRestoreCallback
        delegate.didDiscoverPeripheralBlock = advertisementHandler
        resumeScanning()
    }
    
    private func resumeScanning()
    {
        if (self.canStartScanning)
        {
            centralManager.scanForPeripherals(withServices: scanConfig.serviceUUIDs, options: scanConfig.scanOptions)
        }
        else
        {
            UULog.info(tag: LOG_TAG, message: "Unable to start scanning because bluetooth central is not ready.  Scan will resume when powered on.")
        }
    }
    
    private func handleWillRestoreState(_ options: [String:Any])
    {
        willRestoreStateBlock?(options)
    }
    
    public func stopScan()
    {
        UULog.debug(tag: LOG_TAG, message: "stopping scan, isScanning: \(isScanning)")
        
        isScanning = false
        UULog.debug(tag: LOG_TAG, message: "isScanning: \(isScanning)")
        delegate.didDiscoverPeripheralBlock = nil
        centralManager.stopScan()
    }
    
    private func pauseScanning()
    {
        UULog.debug(tag: LOG_TAG, message: "pausing scan, isScanning: \(isScanning)")
        centralManager.stopScan()
    }
    
    
    func registerConnectionBlocks(_ identifier: UUID, _ connectedBlock: @escaping UUCBPeripheralBlock, _ disconnectedBlock: @escaping UUCBPeripheralErrorBlock)
    {
        let key = identifier
        delegate.connectBlocks[key] = connectedBlock
        delegate.disconnectBlocks[key] = disconnectedBlock
    }
    
    func removeConnectionBlocks(_ identifier: UUID)
    {
        let key = identifier
        delegate.connectBlocks.removeValue(forKey: key)
        delegate.disconnectBlocks.removeValue(forKey: key)
    }
    
    func connect(_ identifier: UUID, _ options: [String:Any]?)
    {
        guard let cbPeripheral = centralManager.retrievePeripherals(withIdentifiers: [identifier]).first else
        {
            UULog.debug(tag: LOG_TAG, message: "Unable to find CBPeripheral for \(identifier)")
            return
        }
        
        centralManager.connect(cbPeripheral, options: options)
    }
    
    func cancelPeripheralConnection(_ identifier: UUID)
    {
        guard let cbPeripheral = centralManager.retrievePeripherals(withIdentifiers: [identifier]).first else
        {
            UULog.debug(tag: LOG_TAG, message: "Unable to find CBPeripheral for \(identifier)")
            return
        }
        
        centralManager.cancelPeripheralConnection(cbPeripheral)
    }
    
    func notifyDisconnect(_ identifier: UUID, _ error: Error?)
    {
        guard let cbPeripheral = centralManager.retrievePeripherals(withIdentifiers: [identifier]).first else
        {
            UULog.debug(tag: LOG_TAG, message: "Unable to find CBPeripheral for \(identifier)")
            return
        }
        
       let key = identifier
       let disconnectBlock = delegate.disconnectBlocks[key]
       delegate.disconnectBlocks.removeValue(forKey: key)
       delegate.connectBlocks.removeValue(forKey: key)
       
       if let block = disconnectBlock
       {
            block(cbPeripheral, error)
       }
       else
       {
           UULog.debug(tag: LOG_TAG, message: "No delegate to notify disconnected")
       }
    }
}
