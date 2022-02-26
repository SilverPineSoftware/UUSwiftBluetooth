//
//  UUBluetoothScanner.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 8/13/21.
//

import UIKit
import CoreBluetooth
import UUSwiftCore

public class UUBluetoothScanner<T: UUPeripheral>
{
    private let centralManager: UUCentralManager
    private var nearbyPeripherals: [String:T] = [:]
    private var nearbyPeripheralsLock = NSRecursiveLock()
    
    private var nearbyPeripheralCallback: (([T])->()) = { _ in }
    private let factory: UUPeripheralFactory<T>?
    private var outOfRangeFilters: [UUOutOfRangePeripheralFilter]? = nil
    public var outOfRangeFilterEvaluationFrequency: TimeInterval = 0.5
    
    public required init(centralManager: UUCentralManager = UUCentralManager.shared, peripheralFactory: UUPeripheralFactory<T>? = nil)
    {
        self.centralManager = centralManager
        self.factory = peripheralFactory
    }
    
    public func startScan(
        services: [CBUUID]? = nil,
        allowDuplicates: Bool = false,
        filters: [UUPeripheralFilter]? = nil,
        outOfRangeFilters: [UUOutOfRangePeripheralFilter]? = nil,
        callback: @escaping ([T])->())
    {
        self.nearbyPeripheralCallback = callback
        self.outOfRangeFilters = outOfRangeFilters
        self.centralManager.startScan(serviceUuids: services, allowDuplicates: allowDuplicates, peripheralFactory: factory, filters: filters, peripheralFoundCallback: handlePeripheralFound, willRestoreCallback: handleWillRestoreState)
        self.startOutOfRangeEvaluationTimer()
    }
    
    public var isScanning: Bool
    {
        return self.centralManager.isScanning
    }
    
    public func stopScan()
    {
        self.centralManager.stopScan()
        self.stopOutOfRangeEvaluationTimer()
    }
    
    private func handlePeripheralFound(peripheral: T)
    {
        defer { nearbyPeripheralsLock.unlock() }
        nearbyPeripheralsLock.lock()
        
        nearbyPeripherals[peripheral.identifier] = peripheral
        
        let sorted = sortedPeripherals()
        nearbyPeripheralCallback(sorted)
    }
    
    private func sortedPeripherals() -> [T]
    {
        return nearbyPeripherals.values.sorted
        { lhs, rhs in
            return lhs.rssi > rhs.rssi
        }
    }
    
    private func handleWillRestoreState(arg: [String:Any]?)
    {
        
    }
    
    private let outOfRangeFilterEvaluationFrequencyTimerId = "UUBluetoothScanner_outOfRangeFilterEvaluationFrequency"

    private func startOutOfRangeEvaluationTimer()
    {
        stopOutOfRangeEvaluationTimer()
        
        guard let filters = self.outOfRangeFilters else
        {
            return
        }

        let t = UUTimer(identifier: outOfRangeFilterEvaluationFrequencyTimerId, interval: outOfRangeFilterEvaluationFrequency, userInfo: nil, shouldRepeat: true, pool: UUTimerPool.shared)
        { t in
            
            defer { self.nearbyPeripheralsLock.unlock() }
            self.nearbyPeripheralsLock.lock()
            
            var didChange = false

            var keep: [T] = []
            
            for peripheral in self.nearbyPeripherals.values
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

            self.nearbyPeripherals.removeAll()

            for peripheral in keep
            {
                self.nearbyPeripherals[peripheral.identifier] = peripheral
            }

            if (didChange)
            {
                let sorted = self.sortedPeripherals()
                self.nearbyPeripheralCallback(sorted)
            }
        }

        t.start()
    }

    private func stopOutOfRangeEvaluationTimer()
    {
        UUTimerPool.shared.cancel(by: outOfRangeFilterEvaluationFrequencyTimerId)
    }

}
