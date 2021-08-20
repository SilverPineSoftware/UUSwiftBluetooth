//
//  UUBluetoothScanner.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 8/13/21.
//

import UIKit
import CoreBluetooth
import UUSwiftCore

public class UUBluetoothScanner: NSObject
{
    private var nearbyPeripherals: [String:UUPeripheral] = [:]
    private var nearbyPeripheralCallback: UUPeripheralListBlock = { _ in }
    
    public func startScan(
        services: [CBUUID]? = nil,
        allowDuplicates: Bool = false,
        peripheralClass: AnyClass? = nil,
        filters: [UUPeripheralFilter]? = nil,
        callback: @escaping UUPeripheralListBlock)
    {
        self.nearbyPeripheralCallback = callback
        UUCoreBluetooth.shared.startScan(serviceUuids: services, allowDuplicates: allowDuplicates, peripheralClass: peripheralClass, filters: filters, peripheralFoundCallback: handlePeripheralFound, willRestoreCallback: handleWillRestoreState)
    }
    
    public var isScanning: Bool
    {
        return UUCoreBluetooth.shared.isScanning
    }
    
    public func stopScan()
    {
        UUCoreBluetooth.shared.stopScan()
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
