//
//  UUCoreBluetoothPeripheralScanner.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 8/13/21.
//

import Foundation
import CoreBluetooth
import UUSwiftCore
import Combine

fileprivate let LOG_TAG = "UUCoreBluetoothBleScanner"

open class UUCoreBluetoothPeripheralScanner: UUPeripheralScanner
{
    public var config: UUPeripheralScannerConfig = UUPeripheralScannerConfig()
    public var started: UUPeripheralScannerStartedCallback = { _ in }
    public var ended: UUPeripheralScannerStoppedCallback = { _, _ in }
    public var listChanged: UUPeripheralListChangedCallback = { _, _ in }
    
    private let centralManager: UUCentralManager
    private var nearbyPeripheralMap: [UUID: (UUPeripheral)] = [:]
    private var nearbyPeripheralMapLock = NSRecursiveLock()
    
    @Published private var nearbyPeripherals: [UUPeripheral] = []
    
    private var nearbyPeripheralSubscription: AnyCancellable? = nil
    
    
    public required init(centralManager: UUCentralManager = UUCentralManager.shared)
    {
        self.centralManager = centralManager
    }
    
    private func checkCentralState() -> Error?
    {
        // Let scan start in central unknown state because at app launch the central state immediately reads unknown
        // and the UUCentralManager logic will wait for the poweredOn event.
        let state = centralManager.centralState
        UULog.debug(tag: LOG_TAG, message: "centralState: \(state)")
        switch (state)
        {
            case .unknown, .poweredOn:
                return nil
            
            default:
                return NSError.uuCentralStateNotReadyError(state)
        }
    }
    
    open func start()
    {
        if let err = checkCentralState()
        {
            endScanning(err)
            return
        }
        
        clearNearbyPeripherals()
        
        if (config.callbackThrottle > 0)
        {
            nearbyPeripheralSubscription = self.$nearbyPeripherals
                .throttle(for: .seconds(config.callbackThrottle), scheduler: centralManager.dispatchQueue, latest: true)
                .receive(on: centralManager.dispatchQueue)
                .sink
                { peripheralList in
                    
                    self.notifyNearbyPeripherals(peripheralList)
                }
        }
        else
        {
            nearbyPeripheralSubscription = self.$nearbyPeripherals
                .receive(on: centralManager.dispatchQueue)
                .sink
                { peripheralList in
                    
                    self.notifyNearbyPeripherals(peripheralList)
                }
        }
        
        notifyScanStarted()
        centralManager.startScan(
            config: config,
            advertisementHandler: handleAdvertisement,
            willRestoreCallback: handleWillRestoreState)
    }
    
    private func notifyScanStarted()
    {
        DispatchQueue.main.async
        {
            self.started(self)
        }
    }
    
    private func notifyScanEnded(_ error: Error?)
    {
        DispatchQueue.main.async
        {
            self.ended(self, error)
        }
    }
    
    private func notifyNearbyPeripherals(_ list: [UUPeripheral])
    {
        guard centralManager.isPoweredOn else
        {
            let err = NSError.uuCentralStateNotReadyError(centralManager.centralState)
            endScanning(err)
            return
        }
        
        let sorted: [UUPeripheral]
        
        if let sorting = config.peripheralSorting
        {
            sorted = list.sorted(by: sorting.compare)
        }
        else
        {
            sorted = list
        }
        
        DispatchQueue.main.async
        {
            self.listChanged(self, sorted)
        }
    }
    
    public var isScanning: Bool
    {
        return self.centralManager.isScanning
    }
    
    open func stop()
    {
        endScanning(nil)
    }
    
    private func endScanning(_ error: Error?)
    {
        nearbyPeripheralSubscription?.cancel()
        nearbyPeripheralSubscription = nil
        
        centralManager.stopScan()
        notifyScanEnded(error)
    }
    
    public var peripherals: [UUPeripheral]
    {
        return nearbyPeripherals
    }
    
    public func getPeripheral(identifier: UUID) -> UUPeripheral?
    {
        return nearbyPeripheralMap[identifier]
    }
    
    private func clearNearbyPeripherals()
    {
        defer { nearbyPeripheralMapLock.unlock() }
        nearbyPeripheralMapLock.lock()
        
        nearbyPeripheralMap.removeAll()
        nearbyPeripherals = []
    }
    
    private func handleAdvertisement(advertisement: UUAdvertisement)
    {
        defer { nearbyPeripheralMapLock.unlock() }
        nearbyPeripheralMapLock.lock()
        
        guard let cbPeripheral = centralManager.lookupPeripheral(advertisement.identifier) else
        {
            UULog.verbose(tag: LOG_TAG, message: "Unable to obtain CBPeripheral for \(advertisement.identifier)")
            return
        }
        
        let peripheral = nearbyPeripheralMap[advertisement.identifier] ?? UUPeripheral(centralManager: centralManager, peripheral: cbPeripheral, advertisement: advertisement)
        peripheral.update(advertisement: advertisement)
        
        nearbyPeripheralMap[peripheral.identifier] = peripheral
        
        self.nearbyPeripherals = nearbyPeripheralMap.values
            .filter(shouldDiscoverPeripheral)
        
        UULog.verbose(tag: LOG_TAG, message: "There are \(self.nearbyPeripherals.count) peripherals nearby")
    }
    
    private func shouldDiscoverPeripheral(_ peripheral: UUPeripheral) -> Bool
    {
        guard let filters = config.discoveryFilters else
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
    
    private func handleWillRestoreState(arg: [String:Any]?)
    {
        
    }
}
