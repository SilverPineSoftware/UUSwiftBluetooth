//
//  UUBluetoothScanner.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 8/13/21.
//

import UIKit
import CoreBluetooth
import UUSwiftCore

public class UUBluetoothScanner //: ObservableObject
{
    private let kSimulatedRangingWatchdogTimerId = "UUBluetoothScanner_simulatedRangingWatchdogTimer"
    
    private let centralManager: UUCentralManager
    private var nearbyPeripheralMap: [UUID: UUPeripheral] = [:]
    private var nearbyPeripheralMapLock = NSRecursiveLock()
    
    private var scanSettings = UUBluetoothScanSettings()
    
    private var nearbyPeripheralCallback: (([UUPeripheral])->()) = { _ in }
    
    //@Published public var nearbyPeripherals: [UUPeripheral] = []
    
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
        
        self.centralManager.startScan(
            serviceUuids: settings.serviceUUIDs,
            allowDuplicates: settings.allowDuplicates,
            peripheralFoundCallback: handlePeripheralFound,
            willRestoreCallback: handleWillRestoreState)
        
        self.startSimulatedRangingWatchdogTimer()
    }
    
    public var isScanning: Bool
    {
        return self.centralManager.isScanning
    }
    
    public func stopScan()
    {
        self.centralManager.stopScan()
        self.stopSimulatedRangingWatchdogTimer()
    }
    
    private func handlePeripheralFound(peripheral: UUPeripheral)
    {
        defer { nearbyPeripheralMapLock.unlock() }
        nearbyPeripheralMapLock.lock()
        
        startSimulatedRangingWatchdogTimer()
        
        // Always update
        nearbyPeripheralMap[peripheral.identifier] = peripheral
        
        let sorted = sortedPeripherals()
        
        //self.nearbyPeripherals = sorted
        
        nearbyPeripheralCallback(sorted)
        
        NSLog("There are \(sorted.count) peripherals nearby")
    }
    
    private func sortedPeripherals() -> [UUPeripheral]
    {
        return nearbyPeripheralMap.values.sorted
        { lhs, rhs in
            return lhs.rssi > rhs.rssi
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
    
    private func shouldSimulateRanging() -> Bool
    {
        // The scan watchdog serves as a way to collect more real time advertisements from the app.  By default Core Bluetooth
        // will aggregate and only deliver advertisements once per scan api call.  The allow duplicates flag can be used when
        // the app is in the foreground to make Core Bluetooth return all advertisements.  When this value is true there is no
        // need for this ranging behavior.  Similarly, if the calling app hasn't configured any out of range filters, there is no
        // need for this.  The main purpose of 'ranging' is to monitor the advertisement data over time and potentially make
        // decisions like in or out of range.
        return (scanSettings.simulatedRanging == true &&
                scanSettings.simulatedRangingWatchdogTimeout > 0 &&
                scanSettings.allowDuplicates == false)
    }
    
    private func startSimulatedRangingWatchdogTimer()
    {
        stopSimulatedRangingWatchdogTimer()
        
        if (shouldSimulateRanging())
        {
            let t = UUTimer(identifier: kSimulatedRangingWatchdogTimerId, interval: scanSettings.simulatedRangingWatchdogTimeout, userInfo: nil, shouldRepeat: true, pool: UUTimerPool.shared)
            { t in
                
                if (self.isScanning)
                {
                    NSLog("Restarting scanning after scan watchdog timeout")
                    self.centralManager.restartScanning()
                }
                else
                {
                    NSLog("Scan was stopped, skipping scan restart")
                }
            }
            
            t.start()
        }
    }
    
    private func stopSimulatedRangingWatchdogTimer()
    {
        UUTimerPool.shared.cancel(by: kSimulatedRangingWatchdogTimerId)
    }
}
