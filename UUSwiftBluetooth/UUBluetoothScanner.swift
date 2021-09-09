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
    private var centralManager: UUCentralManager
    private var nearbyPeripherals: [String:T] = [:]
    private var nearbyPeripheralCallback: (([T])->()) = { _ in }
    private var factory: UUPeripheralFactory<T>? = nil
    
    public required init(_ centralManager: UUCentralManager, _ factory: UUPeripheralFactory<T>?)
    {
        self.centralManager = centralManager
        self.factory = factory
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
