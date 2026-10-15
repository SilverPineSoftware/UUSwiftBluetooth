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
    private let scanGenerationLock = NSLock()
    private var activeScanGeneration: UUID?
    
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
        centralManager.performOnDispatchQueue
        {
            startOnDispatchQueue(self.config)
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
        let generation = UUID()
        scanGenerationLock.withLock { activeScanGeneration = generation }
        clearNearbyPeripherals()

        if (settings.callbackThrottle > 0)
        {
            nearbyPeripheralSubscription = self.$nearbyPeripherals
                .throttle(for: .seconds(settings.callbackThrottle), scheduler: centralManager.dispatchQueue, latest: true)
                .receive(on: centralManager.dispatchQueue)
                .sink
                { [weak self] peripheralList in
                    self?.notifyNearbyPeripherals(peripheralList, generation: generation)
                }
        }
        else
        {
            nearbyPeripheralSubscription = self.$nearbyPeripherals
                .receive(on: centralManager.dispatchQueue)
                .sink
                { [weak self] peripheralList in
                    self?.notifyNearbyPeripherals(peripheralList, generation: generation)
                }
        }
        
        notifyScanStarted()
        centralManager.startScan(
            config: settings,
            advertisementHandler: { [weak self] peripheral in
                self?.handleAdvertisement(peripheral: peripheral)
            },
            scanEnded: { [weak self] error in
                self?.endScanningAfterCentralStopped(error)
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
    
    private func notifyNearbyPeripherals(_ list: [UUPeripheral], generation: UUID)
    {
        guard scanGenerationLock.withLock({ activeScanGeneration == generation }) else { return }
        UULog.debug(tag: LOG_TAG, message: "notifyNearbyPeripherals, list.count: \(list.count)")
        
        let sorted: [UUPeripheral]
        
        if let sorting = activeConfig.peripheralSorting
        {
            sorted = list.sorted(by: sorting.compare)
        }
        else
        {
            sorted = list
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self, self.scanGenerationLock.withLock({ self.activeScanGeneration == generation }) else { return }
            self.listChanged(self, sorted)
        }
    }
    
    public var isScanning: Bool
    {
        return self.centralManager.isScanning
    }
    
    open func stop()
    {
        centralManager.performOnDispatchQueue
        {
            endScanning(nil)
        }
    }
    
    private func endScanning(_ error: Error?)
    {
        let wasActive = scanGenerationLock.withLock { () -> Bool in
            let active = activeScanGeneration != nil
            activeScanGeneration = nil
            return active
        }
        guard wasActive || error != nil else { return }
        nearbyPeripheralSubscription?.cancel()
        nearbyPeripheralSubscription = nil
        
        centralManager.stopScan()
        notifyScanEnded(error)
    }

    private func endScanningAfterCentralStopped(_ error: Error?)
    {
        let wasActive = scanGenerationLock.withLock { () -> Bool in
            let active = activeScanGeneration != nil
            activeScanGeneration = nil
            return active
        }
        guard wasActive else { return }
        nearbyPeripheralSubscription?.cancel()
        nearbyPeripheralSubscription = nil
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
        let candidates = nearbyPeripheralMapLock.withLock
        { () -> [UUPeripheral] in
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
    
}
