//
//  UUBluetoothScanner.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 8/13/21.
//

import UIKit
import CoreBluetooth
import UUSwiftCore
import Combine

internal class UUCoreBluetoothBleScanner: UUPeripheralScanner
{
    private let centralManager: UUCentralManager
    private var nearbyPeripheralMap: [UUID: (UUPeripheral & UUPeripheralInternal)] = [:]
    private var nearbyPeripheralMapLock = NSRecursiveLock()
    
    private var scanSettings = UUBluetoothScanSettings()
    
    private var nearbyPeripheralCallback: (([UUPeripheral])->()) = { _ in }
    
    @Published private var nearbyPeripherals: [UUPeripheral] = []
    
    private var nearbyPeripheralSubscription: AnyCancellable? = nil
    
    public required init(centralManager: UUCentralManager = UUCentralManager.shared)
    {
        self.centralManager = centralManager
    }
    
    public func startScan(
        _ settings: UUBluetoothScanSettings,
        callback: @escaping ([UUPeripheral])->())
    {
        self.scanSettings = settings
        self.nearbyPeripheralCallback = callback
        
        clearNearbyPeripherals()
        
        if (settings.callbackThrottle > 0)
        {
            nearbyPeripheralSubscription = self.$nearbyPeripherals
                .throttle(for: .seconds(scanSettings.callbackThrottle), scheduler: centralManager.dispatchQueue, latest: true)
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
        
        centralManager.startScan(
            serviceUuids: settings.serviceUUIDs,
            allowDuplicates: settings.allowDuplicates,
            advertisementHandler: handleAdvertisement,
            willRestoreCallback: handleWillRestoreState)
    }
    
    private func notifyNearbyPeripherals(_ list: [UUPeripheral])
    {
        let sorted = scanSettings.peripheralSorting.map { list.sorted(using: $0) } ?? list
        
        DispatchQueue.main.async
        {
            self.nearbyPeripheralCallback(sorted)
        }
    }
    
    public var isScanning: Bool
    {
        return self.centralManager.isScanning
    }
    
    public func stopScan()
    {
        self.centralManager.stopScan()
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
        
        let peripheral = nearbyPeripheralMap[advertisement.peripheral.identifier] ?? UUCoreBluetoothPeripheral(centralManager: centralManager, peripheral: advertisement.peripheral)
        peripheral.update(advertisement: advertisement)
        
        nearbyPeripheralMap[peripheral.identifier] = peripheral
        
        self.nearbyPeripherals = nearbyPeripheralMap.values
            .filter(shouldDiscoverPeripheral)
        
        UUDebugLog("There are \(self.nearbyPeripherals.count) peripherals nearby")
    }
    
    private func shouldDiscoverPeripheral(_ peripheral: UUPeripheral) -> Bool
    {
        guard let filters = scanSettings.discoveryFilters else
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
