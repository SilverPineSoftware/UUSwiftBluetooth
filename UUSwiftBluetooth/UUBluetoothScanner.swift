//
//  UUBluetoothScanner.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 8/13/21.
//

import UIKit
import CoreBluetooth
import UUSwiftCore

public struct UUBluetoothScanSettings
{
   public init(allowDuplicates: Bool = false,
                serviceUUIDs: [CBUUID]? = nil,
                filters: [UUPeripheralFilter]? = nil,
                outOfRangeFilters: [UUOutOfRangePeripheralFilter]? = nil,
                outOfRangeFilterEvaluationFrequency: TimeInterval = 0.5,
                scanWatchdogTimeout: TimeInterval = 0.5)
    {
        self.allowDuplicates = allowDuplicates
        self.serviceUUIDs = serviceUUIDs
        self.filters = filters
        self.outOfRangeFilters = outOfRangeFilters
        self.outOfRangeFilterEvaluationFrequency = outOfRangeFilterEvaluationFrequency
        self.scanWatchdogTimeout = scanWatchdogTimeout
    }
    
    public var allowDuplicates: Bool = false
    public var serviceUUIDs: [CBUUID]? = nil
    public var filters: [UUPeripheralFilter]? = nil
    public var outOfRangeFilters: [UUOutOfRangePeripheralFilter]? = nil
    public var outOfRangeFilterEvaluationFrequency: TimeInterval = 0.5
    public var scanWatchdogTimeout: TimeInterval = 0.0
}

public class UUBluetoothScanner //: ObservableObject
{
    private let outOfRangeFilterEvaluationFrequencyTimerId = "UUBluetoothScanner_outOfRangeFilterEvaluationFrequency"
    private let scanWatchdogTimerId = "UUBluetoothScanner_scanWatchdogTimer"
    
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
            filters: settings.filters,
            peripheralFoundCallback: handlePeripheralFound,
            willRestoreCallback: handleWillRestoreState)
        
        self.startOutOfRangeEvaluationTimer()
        self.startScanWatchdogTimer()
    }
    
    public var isScanning: Bool
    {
        return self.centralManager.isScanning
    }
    
    public func stopScan()
    {
        self.centralManager.stopScan()
        self.stopOutOfRangeEvaluationTimer()
        self.stopScanWatchdogTimer()
    }
    
    private func handlePeripheralFound(peripheral: UUPeripheral)
    {
        defer { nearbyPeripheralMapLock.unlock() }
        nearbyPeripheralMapLock.lock()
        
        startScanWatchdogTimer()
        
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
    
    private func handleWillRestoreState(arg: [String:Any]?)
    {
        
    }
    
    private func startOutOfRangeEvaluationTimer()
    {
        stopOutOfRangeEvaluationTimer()
        
        guard let filters = scanSettings.outOfRangeFilters else
        {
            return
        }

        let t = UUTimer(identifier: outOfRangeFilterEvaluationFrequencyTimerId, interval: scanSettings.outOfRangeFilterEvaluationFrequency, userInfo: nil, shouldRepeat: true, pool: UUTimerPool.shared)
        { t in
            
            defer { self.nearbyPeripheralMapLock.unlock() }
            self.nearbyPeripheralMapLock.lock()
            
            var didChange = false

            var keep: [UUPeripheral] = []
            
            for peripheral in self.nearbyPeripheralMap.values
            {
                var outOfRange = false

                for filter in filters
                {
                    if (filter.checkPeripheralRange(peripheral) == .outOfRange)
                    {
                        outOfRange = true
                        didChange = true
                        break;
                    }
                }

                if (!outOfRange)
                {
                    keep.append(peripheral)
                }
            }

            self.nearbyPeripheralMap.removeAll()

            for peripheral in keep
            {
                self.nearbyPeripheralMap[peripheral.identifier] = peripheral
            }

            if (didChange)
            {
                let sorted = self.sortedPeripherals()
                //self.nearbyPeripherals = sorted
                self.nearbyPeripheralCallback(sorted)
            }
        }

        t.start()
    }

    private func stopOutOfRangeEvaluationTimer()
    {
        UUTimerPool.shared.cancel(by: outOfRangeFilterEvaluationFrequencyTimerId)
    }
    
    private func shouldUseScanWatchdog() -> Bool
    {
        // The scan watchdog serves as a way to collect more real time advertisements from the app.  By default Core Bluetooth
        // will aggregate and only deliver advertisements once per scan api call.  The allow duplicates flag can be used when
        // the app is in the foreground to make Core Bluetooth return all advertisements.  When this value is true there is no
        // need for this ranging behavior.  Similarly, if the calling app hasn't configured any out of range filters, there is no
        // need for this.  The main purpose of 'ranging' is to monitor the advertisement data over time and potentially make
        // decisions like in or out of range.
        return (scanSettings.scanWatchdogTimeout > 0 &&
                scanSettings.allowDuplicates == false &&
                scanSettings.outOfRangeFilters != nil &&
                scanSettings.outOfRangeFilters?.isEmpty == false)
    }
    
    private func startScanWatchdogTimer()
    {
        stopScanWatchdogTimer()
        
        if (shouldUseScanWatchdog())
        {
            let t = UUTimer(identifier: scanWatchdogTimerId, interval: scanSettings.scanWatchdogTimeout, userInfo: nil, shouldRepeat: true, pool: UUTimerPool.shared)
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
    
    private func stopScanWatchdogTimer()
    {
        UUTimerPool.shared.cancel(by: scanWatchdogTimerId)
    }
}
