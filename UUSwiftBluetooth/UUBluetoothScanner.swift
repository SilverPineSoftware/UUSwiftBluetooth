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

public class UUBluetoothScanner
{
    private let centralManager: UUCentralManager
    private var nearbyPeripheralMap: [UUID: UUPeripheral] = [:]
    private var nearbyPeripheralMapLock = NSRecursiveLock()
    
    private var scanSettings = UUBluetoothScanSettings()
    
    private var nearbyPeripheralCallback: (([UUPeripheral])->()) = { _ in }
    
    @Published private var nearbyPeripherals: [UUPeripheral] = []
    
    private var nearbyPeripheralSubscription: AnyCancellable? = nil
    
    public required init(centralManager: UUCentralManager = UUCentralManager.shared)
    {
        self.centralManager = centralManager
    }
    
    private var callbackTime: TimeInterval = 0
    public func startScan(
        _ settings: UUBluetoothScanSettings,
        callback: @escaping ([UUPeripheral])->())
    {
        self.scanSettings = settings
        self.nearbyPeripheralCallback = callback
        
        
        if (settings.callbackThrottle > 0)
        {
            nearbyPeripheralSubscription = self.$nearbyPeripherals
                .throttle(for: .seconds(scanSettings.callbackThrottle), scheduler: RunLoop.main, latest: true)
                .receive(on: DispatchQueue.global(qos: .userInitiated))
                .sink
                { peripheralList in
                    
                    let delta = self.callbackTime - Date.timeIntervalSinceReferenceDate
                    self.callbackTime = Date.timeIntervalSinceReferenceDate
                    
                    NSLog("Notifying nearby devices callback with \(peripheralList.count) devices, callback time delta: \(delta)")
                    self.nearbyPeripheralCallback(peripheralList)
                }
        }
        else
        {
            nearbyPeripheralSubscription = self.$nearbyPeripherals
                .receive(on: DispatchQueue.global(qos: .userInitiated))
                .sink
                { peripheralList in
                    
                    let delta = self.callbackTime - Date.timeIntervalSinceReferenceDate
                    self.callbackTime = Date.timeIntervalSinceReferenceDate
                    
                    NSLog("Notifying nearby devices callback with \(peripheralList.count) devices, callback time delta: \(delta)")
                    self.nearbyPeripheralCallback(peripheralList)
                }
        }
        
        self.centralManager.startScan(
            serviceUuids: settings.serviceUUIDs,
            allowDuplicates: settings.allowDuplicates,
            advertisementHandler: handleAdvertisement,
            willRestoreCallback: handleWillRestoreState)
    }
    
    public var isScanning: Bool
    {
        return self.centralManager.isScanning
    }
    
    public func stopScan()
    {
        self.centralManager.stopScan()
    }
    
    private func handleAdvertisement(advertisement: UUBluetoothAdvertisement)
    {
        let peripheral = UUPeripheral(centralManager: centralManager,
                                      peripheral: advertisement.peripheral)
        
        peripheral.updateAdvertisement(advertisement)
        
        handlePeripheralFound(peripheral: peripheral)
    }
    
    private func handlePeripheralFound(peripheral: UUPeripheral)
    {
        defer { nearbyPeripheralMapLock.unlock() }
        nearbyPeripheralMapLock.lock()
        
        // Always update
        nearbyPeripheralMap[peripheral.identifier] = peripheral
        
        let sorted = sortedPeripherals()
        self.nearbyPeripherals = sorted
        
        NSLog("There are \(sorted.count) peripherals nearby")
    }
    
    private func sortedPeripherals() -> [UUPeripheral]
    {
        return nearbyPeripheralMap.values.sorted
        { lhs, rhs in
            return (lhs.rssi ?? 0) > (rhs.rssi ?? 0)
        }
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
