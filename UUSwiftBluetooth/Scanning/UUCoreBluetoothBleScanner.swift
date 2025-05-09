//
//  UUBluetoothScanner.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 8/13/21.
//

import Foundation
import CoreBluetooth
import UUSwiftCore
import Combine

fileprivate let LOG_TAG = "UUCoreBluetoothBleScanner"

internal class UUCoreBluetoothBleScanner: UUPeripheralScanner
{
    var config: UUPeripheralScannerConfig = UUPeripheralScannerConfig()
    var started: UUPeripheralScannerStartedCallback = { _ in }
    
    var ended: UUPeripheralScannerStoppedCallback = { _, _ in }
    
    var listChanged: UUPeripheralListChangedCallback = { _, _ in }
    
    private let centralManager: UUCentralManager
    private var nearbyPeripheralMap: [UUID: (UUPeripheral & UUPeripheralInternal)] = [:]
    private var nearbyPeripheralMapLock = NSRecursiveLock()
    
    @Published private var nearbyPeripherals: [UUPeripheral] = []
    
    private var nearbyPeripheralSubscription: AnyCancellable? = nil
    
    public required init(centralManager: UUCentralManager = UUCentralManager.shared)
    {
        self.centralManager = centralManager
    }
    
    open func start()
    {
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
            serviceUuids: config.serviceUUIDs,
            allowDuplicates: config.allowDuplicates,
            advertisementHandler: handleAdvertisement,
            willRestoreCallback: handleWillRestoreState)
    }
    
    private func notifyScanStarted()
    {
        started(self)
    }
    
    private func notifyScanEnded(_ error: Error?)
    {
        ended(self, error)
    }
    
    private func notifyNearbyPeripherals(_ list: [UUPeripheral])
    {
        //let sorted = config.peripheralSorting.map { list.sorted(using: $0) } ?? list
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
        nearbyPeripheralSubscription?.cancel()
        nearbyPeripheralSubscription = nil
        
        centralManager.stopScan()
        notifyScanEnded(nil)
    }
    
    private func clearNearbyPeripherals()
    {
        defer { nearbyPeripheralMapLock.unlock() }
        nearbyPeripheralMapLock.lock()
        
        nearbyPeripheralMap.removeAll()
        nearbyPeripherals = []
    }
    
    private func handleAdvertisement(advertisement: UUBluetoothAdvertisement)
    {
        defer { nearbyPeripheralMapLock.unlock() }
        nearbyPeripheralMapLock.lock()
        
        let peripheral = nearbyPeripheralMap[advertisement.peripheral.identifier] ?? UUCoreBluetoothPeripheral(centralManager: centralManager, peripheral: advertisement.peripheral, advertisement: advertisement)
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
