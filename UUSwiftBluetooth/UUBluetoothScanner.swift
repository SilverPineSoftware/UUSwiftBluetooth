//
//  UUBluetoothScanner.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 8/13/21.
//

import UIKit
import CoreBluetooth
import UUSwiftCore

public class UUBluetoothScanner //: NSObject
{
    private var centralManager: UUCentralManager
//    private var delegate: UUCentralManagerDelegate
//    private var centralManager: CBCentralManager
    private var nearbyPeripherals: [String:UUPeripheral] = [:]
    private var nearbyPeripheralCallback: UUPeripheralListBlock = { _ in }
    
    public required init(_ centralManager: UUCentralManager)
    {
        self.centralManager = centralManager
    }
    
//    required init(_ centralManager: CBCentralManager)
//    {
//        self.centralManager = centralManager
//    }
    
    public func startScan(
        services: [CBUUID]? = nil,
        allowDuplicates: Bool = false,
        peripheralClass: AnyClass? = nil,
        filters: [UUPeripheralFilter]? = nil,
        callback: @escaping UUPeripheralListBlock)
    {
        self.nearbyPeripheralCallback = callback
        self.centralManager.startScan(serviceUuids: services, allowDuplicates: allowDuplicates, peripheralClass: peripheralClass, filters: filters, peripheralFoundCallback: handlePeripheralFound, willRestoreCallback: handleWillRestoreState)
    }
    
    public var isScanning: Bool
    {
        return self.centralManager.isScanning
    }
    
    public func stopScan()
    {
        self.centralManager.stopScan()
    }
    
    private func handlePeripheralFound(peripheral: UUPeripheral)
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
