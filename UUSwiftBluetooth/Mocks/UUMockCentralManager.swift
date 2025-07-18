//
//  UUMockCentralManager.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 7/18/25.
//

import Foundation
import CoreBluetooth

public class UUMockCentralManager
{
    public var mockCentral: UUCentralManager
    
    public init(peripherals: [CBPeripheral] = [])
    {
        self.mockCentral = UUCentralManager(injection: { q, o in
            
            let delegate = UUCentralManagerDelegate()
            let mgr = UUMockCBCentralManager(delegate: delegate, queue: q, options: o)
            mgr.mockPeripherals = peripherals
            UUMockPeripheral.mockCBCentral = mgr
            return (delegate, mgr)
        })
    }
}
