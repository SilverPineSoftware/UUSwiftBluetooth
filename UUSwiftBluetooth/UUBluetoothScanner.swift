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
    private var nearbyPeripheralCallback: (([T])->()) = { _ in }
    private let factory: UUPeripheralFactory<T>?
    
    public required init(centralManager: UUCentralManager = UUCentralManager.shared, peripheralFactory: UUPeripheralFactory<T>? = nil)
    {
        self.centralManager = centralManager
        self.factory = peripheralFactory
    }
    
    public func startScan(
        services: [CBUUID]? = nil,
        allowDuplicates: Bool = false,
        filters: [UUPeripheralFilter]? = nil,
        callback: @escaping ([T])->())
    {
        self.nearbyPeripheralCallback = callback
        self.centralManager.startScan(serviceUuids: services, allowDuplicates: allowDuplicates, peripheralFactory: factory, filters: filters, peripheralFoundCallback: handlePeripheralFound, willRestoreCallback: handleWillRestoreState)
    }
    
    public var isScanning: Bool
    {
        return self.centralManager.isScanning
    }
    
    public func stopScan()
    {
        self.centralManager.stopScan()
    }
    
    private func handlePeripheralFound(peripheral: T)
    {
        nearbyPeripherals[peripheral.identifier] = peripheral
        
        let sorted = nearbyPeripherals.values.sorted
        { lhs, rhs in
            return lhs.rssi > rhs.rssi
        }
        
        nearbyPeripheralCallback(sorted)
    }
    
    private func handleWillRestoreState(arg: [String:Any]?)
    {
        
    }

}
