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

public class UUBluetoothScanner//: ObservableObject
{
    private let centralManager: UUCentralManager
    private var nearbyPeripheralMap: [UUID: UUPeripheral] = [:]
    private var nearbyPeripheralMapLock = NSRecursiveLock()
    
    private var scanSettings = UUBluetoothScanSettings()
    
    private var nearbyPeripheralCallback: (([UUPeripheral])->()) = { _ in }
    
    @Published private var nearbyPeripherals: [UUPeripheral] = []
    @Published private var shouldThrottle: Bool = false

    private var nearbyPeripheralSubscription: AnyCancellable? = nil
    //private var cancellables: Set<AnyCancellable> = Set<AnyCancellable>()
    
    private var updateCount: Int = 0
        
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
                    
                    NSLog("Notifying nearby devices callback with \(peripheralList.count) devices, callback time delta: \(delta), update count: \(self.updateCount)")
                    self.nearbyPeripheralCallback(peripheralList)
                    self.updateCount = 0
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
                    
                    NSLog("Notifying nearby devices callback with \(peripheralList.count) devices, callback time delta: \(delta), update count: \(self.updateCount)")
                    self.nearbyPeripheralCallback(peripheralList)
                    self.updateCount = 0
                }
        }
        
        /*
         // does not work
        self.$nearbyPeripherals
            .flatMap
        { [weak self] values -> AnyPublisher<[UUPeripheral], Never> in
            guard let self = self else
            {
                return Just(values).eraseToAnyPublisher()
            }
            
            if scanSettings.callbackThrottle > 0
            {
                NSLog("Using throttling for callback")
                // Apply throttling when `shouldThrottle` is true
                return Just(values)
                    .throttle(for: .seconds(scanSettings.callbackThrottle), scheduler: DispatchQueue.main, latest: true)
                    .eraseToAnyPublisher()
            }
            else
            {
                NSLog("No throttling")
                // Pass through the array immediately
                return Just(values).eraseToAnyPublisher()
            }
        }
        .sink
        { peripheralList in
            //print("Received values: \(updatedValues)")
            
            let delta = self.callbackTime - Date.timeIntervalSinceReferenceDate
            self.callbackTime = Date.timeIntervalSinceReferenceDate
            
            NSLog("Notifying nearby devices callback with \(peripheralList.count) devices, callback time delta: \(delta), update count: \(self.updateCount)")
            self.nearbyPeripheralCallback(peripheralList)
            self.updateCount = 0
        }
        .store(in: &cancellables)
        */
        
        /*
         
         // does not work
        shouldThrottle = scanSettings.callbackThrottle > 0 ? true : false
        
        $shouldThrottle
            .combineLatest($nearbyPeripherals)
            .flatMap
            { shouldThrottle, values -> AnyPublisher<[UUPeripheral], Never> in
                
                if shouldThrottle
                {
                    // Apply throttle operator
                    return Just(values)
                        .throttle(for: .seconds(self.scanSettings.callbackThrottle), scheduler: DispatchQueue.main, latest: true)
                        .eraseToAnyPublisher()
                }
                else
                {
                    // Pass values through immediately
                    return Just(values).eraseToAnyPublisher()
                }
            }
            .sink
            { peripheralList in
                //print("Received values: \(updatedValues)")
                
                let delta = self.callbackTime - Date.timeIntervalSinceReferenceDate
                self.callbackTime = Date.timeIntervalSinceReferenceDate
                
                NSLog("Notifying nearby devices callback with \(peripheralList.count) devices, callback time delta: \(delta), update count: \(self.updateCount)")
                self.nearbyPeripheralCallback(peripheralList)
                self.updateCount = 0
            }
            .store(in: &cancellables)
        */
        
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
        self.updateCount = self.updateCount + 1
        self.nearbyPeripherals = sorted
        
        //self.nearbyPeripherals = sorted
        
        //nearbyPeripheralCallback(sorted)
        
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
