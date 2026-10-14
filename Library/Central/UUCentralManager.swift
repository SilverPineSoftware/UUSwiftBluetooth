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
public typealias UUPeripheralBlock = ((UUPeripheral)->())
public typealias UUBluetoothAdvertisementBlock = ((CBPeripheral, [String : Any], NSNumber)->())
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
    private let queueKey = DispatchSpecificKey<UUID>()
    private let queueID = UUID()
    private let scanStateLock = NSLock()
    private var _isScanning = false
    
    private var delegate: UUCentralManagerDelegate
    private var centralManager: UUCBCentralManager
    
    private var scanConfig: UUPeripheralScannerConfig = UUPeripheralScannerConfig()
    public var isScanning: Bool { scanStateLock.withLock { _isScanning } }
    
    private var willRestoreStateBlock: UUWillRestoreStateBlock? = nil
    //private var options: [String:Any]? = nil
    
    private var peripheralMap: [UUID: (UUPeripheral)] = [:]
    private var peripheralMapLock = NSRecursiveLock()

    private var peripheralFoundBlock: UUPeripheralBlock? = nil
    private var connectTimeoutTokens: [UUID: UUID] = [:]
    private var disconnectTimeoutTokens: [UUID: UUID] = [:]

    private var managerStateListeners: [String:UUCBManagerStateBlock] = [:]
    private let managerStateListenersLock = NSLock()
    
    required init(
        options: UUCentralManagerOptions,
        injection: (DispatchQueue, UUCentralManagerOptions)->(UUCentralManagerDelegate, UUCBCentralManager) = injectCentral)
    {
        UULog.debug(tag: LOG_TAG, message: "Initializing UUCoreBluetooth with options: \(String(describing: options))")
        dispatchQueue.setSpecific(key: queueKey, value: queueID)
        
        let injected = injection(dispatchQueue, options)
        delegate = injected.0
        centralManager = injected.1
        delegate.centralStateChangedBlock = { [weak self] state in self?.handleCentralStateChanged(state) }
        
        let state = centralManager.state
        UULog.debug(tag: LOG_TAG, message: "Central State is: \(state)")
    }
    
    private static func injectCentral(_ dispatchQueue: DispatchQueue, _ options: UUCentralManagerOptions) -> (UUCentralManagerDelegate, UUCBCentralManager)
    {
        let delegate = options.usesStateRestoration ? UUCentralManagerRestoringDelegate() : UUCentralManagerDelegate()
        let centralManager = CBCentralManager(delegate: delegate, queue: dispatchQueue, options: options.coreBluetoothOptions)
        return (delegate, centralManager)
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
        managerStateListenersLock.withLock
        {
            managerStateListeners[identifier] = handler
        }
    }

    // Scan APIs remain synchronous for callers, including callbacks already on
    // the central queue. Only that queue touches scan configuration and handlers.
    func performOnDispatchQueue(_ block: () -> Void)
    {
        if DispatchQueue.getSpecific(key: queueKey) == queueID
        {
            block()
        }
        else
        {
            dispatchQueue.sync(execute: block)
        }
    }
    
    
    
    // PRIVATE
    
    private var canStartScanning: Bool
    {
        return centralManager.state == .poweredOn
    }
    
    private func handleCentralStateChanged(_ state: CBManagerState)
    {
        switch (state)
        {
            case .poweredOn:
                handleCentralStatePoweredOn()
                
            case .resetting:
                handleCentralReset()
                
            default:
                break
        }
        
        for peripheral in Array(peripheralMap.values)
        {
            peripheral.updateCentralState(state)
        }
        
        if state != .poweredOn
        {
            for identifier in Array(delegate.disconnectBlocks.keys)
            {
                notifyDisconnect(identifier, NSError.uuCentralStateNotReadyError(state))
            }
        }
        
        notifyManagerStateListeners(state)
    }
    
    private func notifyManagerStateListeners(_ state: CBManagerState)
    {
        let handlers = managerStateListenersLock.withLock { Array(managerStateListeners.values) }
        for handler in handlers
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
        advertisementHandler: @escaping UUPeripheralBlock,
        willRestoreCallback: UUWillRestoreStateBlock? = nil)
    {
        performOnDispatchQueue
        {
            UULog.debug(tag: LOG_TAG, message: "starting scan")
            scanConfig = config
            scanStateLock.withLock { _isScanning = true }
            peripheralFoundBlock = advertisementHandler
            willRestoreStateBlock = willRestoreCallback
            delegate.didDiscoverPeripheralBlock =
            { [weak self] peripheral, advertisementData, rssi in
                self?.handleAdvertisement(peripheral, advertisementData, rssi)
            }
            resumeScanning()
        }
    }
    
    private func handleAdvertisement(_ peripheral: CBPeripheral, _ advertisementData: [String : Any], _ rssi: NSNumber)
    {
        peripheralMapLock.withLock
        {
            guard let block = self.peripheralFoundBlock else
            {
                return
            }

            let advertisement = UUAdvertisement(peripheral.identifier, advertisementData, rssi.intValue)
            let uuPeripheral = self.peripheralMap[peripheral.identifier] ?? UUPeripheral(dispatchQueue: dispatchQueue, centralState: centralState, peripheral: peripheral, advertisement: advertisement)
            uuPeripheral.update(advertisement: advertisement)
            self.peripheralMap[peripheral.identifier] = uuPeripheral

            block(uuPeripheral)
        }
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
        performOnDispatchQueue
        {
            UULog.debug(tag: LOG_TAG, message: "stopping scan, isScanning: \(isScanning)")
            scanStateLock.withLock { _isScanning = false }
            delegate.didDiscoverPeripheralBlock = nil
            peripheralFoundBlock = nil
            willRestoreStateBlock = nil

            // Xcode logs API misuse warnings if we make this call while state is anything but poweredOn
            if (isPoweredOn)
            {
                centralManager.stopScan()
            }
        }
    }
    
    private func pauseScanning()
    {
        UULog.debug(tag: LOG_TAG, message: "pausing scan, isScanning: \(isScanning)")
        
        // Xcode logs API misuse warnings if we make this call while state is anything but poweredOn
        if (isPoweredOn)
        {
            centralManager.stopScan()
        }
    }
    
    
    /// Connect a peripheral owned by this central. Completions run on the
    /// central callback queue.
    public func connect(_ peripheral: UUPeripheral,
                        timeout: TimeInterval = UUBluetooth.Defaults.connectTimeout,
                        connected: @escaping UUVoidBlock,
                        disconnected: @escaping UUErrorBlock)
    {
        dispatchQueue.async
        { [self] in

            let identifier = peripheral.identifier

            guard isPoweredOn else
            {
                disconnected(NSError.uuCentralStateNotReadyError(centralState))
                return
            }

            let timerName = "connect"
            let token = UUID()

            let connectedBlock: UUCBPeripheralBlock =
            { [weak self] _ in
                self?.connectTimeoutTokens.removeValue(forKey: identifier)
                peripheral.cancelTimer(name: timerName)
                connected()
            }

            let disconnectedBlock: UUCBPeripheralErrorBlock =
            { [weak self] _, error in
                self?.connectTimeoutTokens.removeValue(forKey: identifier)
                self?.disconnectTimeoutTokens.removeValue(forKey: identifier)
                peripheral.cancelTimer(name: timerName)
                peripheral.cancelTimer(name: "disconnect")
                peripheral.connectionEnded(error)
                disconnected(error)
            }

            guard registerConnectionBlocks(identifier, connectedBlock, disconnectedBlock) else
            {
                disconnected(NSError.uuCoreBluetoothError(.operationInProgress))
                return
            }

            connectTimeoutTokens[identifier] = token

            peripheral.startTimer(name: timerName, timeout: timeout)
            { [self] in

                dispatchQueue.async
                { [self] in

                    guard connectTimeoutTokens[identifier] == token else
                    {
                        return
                    }

                    connectTimeoutTokens.removeValue(forKey: identifier)
                    peripheral.cancelTimer(name: timerName)
                    removeConnectionBlocks(identifier)
                    cancelPeripheralConnection(identifier)

                    let error = NSError.uuCoreBluetoothError(.timeout)
                    peripheral.connectionEnded(error)
                    disconnected(error)
                }
            }

            connect(identifier, nil)
        }
    }

    /// Cancel the connection. The `disconnected` callback registered at connect
    /// time completes after the peripheral's pending operations are drained.
    public func disconnect(_ peripheral: UUPeripheral,
                           timeout: TimeInterval = UUBluetooth.Defaults.disconnectTimeout)
    {
        dispatchQueue.async
        { [self] in
            let identifier = peripheral.identifier
            guard isPoweredOn else
            {
                notifyDisconnect(identifier, NSError.uuCentralStateNotReadyError(centralState))
                return
            }

            let token = UUID()
            disconnectTimeoutTokens[identifier] = token
            peripheral.startTimer(name: "disconnect", timeout: timeout)
            { [self] in

                dispatchQueue.async
                { [self] in
                    guard disconnectTimeoutTokens[identifier] == token else { return }
                    disconnectTimeoutTokens.removeValue(forKey: identifier)
                    peripheral.cancelTimer(name: "disconnect")
                    notifyDisconnect(identifier, NSError.uuCoreBluetoothError(.timeout))
                    cancelPeripheralConnection(identifier)
                }
            }

            cancelPeripheralConnection(identifier)
        }
    }

    func registerConnectionBlocks(_ identifier: UUID, _ connectedBlock: @escaping UUCBPeripheralBlock, _ disconnectedBlock: @escaping UUCBPeripheralErrorBlock) -> Bool
    {
        let key = identifier
        guard delegate.connectBlocks[key] == nil, delegate.disconnectBlocks[key] == nil else { return false }
        delegate.connectBlocks[key] = connectedBlock
        delegate.disconnectBlocks[key] = disconnectedBlock
        return true
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
