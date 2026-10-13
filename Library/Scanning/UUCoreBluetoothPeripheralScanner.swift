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
    private var activeConfig = UUPeripheralScannerConfig()
    
    @Published private var nearbyPeripherals: [UUPeripheral] = []
    
    private var nearbyPeripheralSubscription: AnyCancellable? = nil
    
    
    public required init(centralManager: UUCentralManager)
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
        // Capture the settings for this scan; later changes to config apply to
        // the next scan rather than racing advertisement filtering and sorting.
        let settings = config.snapshot()
        centralManager.performOnDispatchQueue
        {
            startOnDispatchQueue(settings)
        }
    }

    private func startOnDispatchQueue(_ settings: UUPeripheralScannerConfig)
    {
        if let err = checkCentralState()
        {
            endScanning(err)
            return
        }

        activeConfig = settings
        clearNearbyPeripherals()

        if (settings.callbackThrottle > 0)
        {
            nearbyPeripheralSubscription = self.$nearbyPeripherals
                .throttle(for: .seconds(settings.callbackThrottle), scheduler: centralManager.dispatchQueue, latest: true)
                .receive(on: centralManager.dispatchQueue)
                .sink
                { [weak self] peripheralList in
                    
                    self?.notifyNearbyPeripherals(peripheralList)
                }
        }
        else
        {
            nearbyPeripheralSubscription = self.$nearbyPeripherals
                .receive(on: centralManager.dispatchQueue)
                .sink
                { [weak self] peripheralList in
                    
                    self?.notifyNearbyPeripherals(peripheralList)
                }
        }
        
        notifyScanStarted()
        centralManager.startScan(
            config: settings,
            advertisementHandler: { [weak self] peripheral in
                self?.handleAdvertisement(peripheral: peripheral)
            },
            willRestoreCallback: { [weak self] state in
                self?.handleWillRestoreState(arg: state)
            })
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
        UULog.debug(tag: LOG_TAG, message: "notifyNearbyPeripherals, list.count: \(list.count)")
        
        if let err = checkCentralState()
        {
            UULog.debug(tag: LOG_TAG, message: "Ending scan in notifyNearbyPeripherals because of a central state error: \(String(describing: err))")
            endScanning(err)
            return
        }
        
        let sorted: [UUPeripheral]
        
        if let sorting = activeConfig.peripheralSorting
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
        centralManager.performOnDispatchQueue { endScanning(nil) }
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
        return nearbyPeripheralMapLock.withLock { nearbyPeripherals }
    }
    
    public func getPeripheral(identifier: UUID) -> UUPeripheral?
    {
        return nearbyPeripheralMapLock.withLock { nearbyPeripheralMap[identifier] }
    }
    
    private func clearNearbyPeripherals()
    {
        defer { nearbyPeripheralMapLock.unlock() }
        nearbyPeripheralMapLock.lock()
        
        nearbyPeripheralMap.removeAll()
        nearbyPeripherals = []
    }
    
    private func handleAdvertisement(peripheral: UUPeripheral)
    {
        let candidates = nearbyPeripheralMapLock.withLock { () -> [UUPeripheral] in
            nearbyPeripheralMap[peripheral.identifier] = peripheral
            return Array(nearbyPeripheralMap.values)
        }
        let discovered = candidates.filter(shouldDiscoverPeripheral)
        nearbyPeripheralMapLock.withLock { nearbyPeripherals = discovered }
        UULog.verbose(tag: LOG_TAG, message: "There are \(discovered.count) peripherals nearby")
    }
    
    private func shouldDiscoverPeripheral(_ peripheral: UUPeripheral) -> Bool
    {
        guard let filters = activeConfig.discoveryFilters else
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
