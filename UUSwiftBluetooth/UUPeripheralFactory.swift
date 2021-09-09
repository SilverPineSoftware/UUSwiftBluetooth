//
//  UUPeripheralFactory.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 9/7/21.
//

import UIKit
import CoreBluetooth

open class UUPeripheralFactory<T: UUPeripheral>
{
    public init()
    {
    }
    
    open func create(_ dispatchQueue: DispatchQueue, _ centralManager: UUCentralManager, _ peripheral: CBPeripheral) -> T
    {
        fatalError("Derived classes must override!")
    }
}
