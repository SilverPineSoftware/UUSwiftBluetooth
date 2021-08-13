//
//  UUBluetoothScanner.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 8/13/21.
//

import UIKit

public typealias UUPeripheralListBlock = (([UUPeripheral])->())

public class UUBluetoothScanner: NSObject
{
    private var nearbyPeripherals: [String:UUPeripheral] = [:]
    private var nearbyPeripheralCallback: UUPeripheralListBlock = { _ in }
    
    public func startScanning(
        services: [CBUUID]? = nil,
        allowDuplicates: Bool = false,
        peripheralClass: AnyClass? = nil,
        filters: [UUPeripheralFilter]? = nil,
        callback: @escaping UUPeripheralListBlock)
    {
        self.nearbyPeripheralCallback = callback
        UUCoreBluetooth.sharedInstance().startScan(forServices: services, allowDuplicates: allowDuplicates, peripheralClass: peripheralClass, filters: filters, peripheralFoundCallback: self.handlePeripheralFound, willRestoreStateCallback: self.handleWillRestoreState)
    }
    
    public func stopScanning()
    {
        UUCoreBluetooth.sharedInstance().stopScanning()
    }
    
    private func handlePeripheralFound(peripheral: UUPeripheral)
    {
        nearbyPeripherals[peripheral.identifier] = peripheral
        
        let sorted = nearbyPeripherals.values.sorted
        { lhs, rhs in
            return lhs.rssi.intValue > rhs.rssi.intValue
        }
        
        nearbyPeripheralCallback(sorted)
    }
    
    private func handleWillRestoreState(arg: [String:Any]?)
    {
        
    }

}
