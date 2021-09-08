//
//  UUPeripheralFactory.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 9/7/21.
//

import UIKit
import CoreBluetooth

public protocol UUPeripheralFactory
{
    func create(_ dispatchQueue: DispatchQueue, _ centralManager: UUCentralManager, _ peripheral: CBPeripheral) -> UUPeripheral
}
