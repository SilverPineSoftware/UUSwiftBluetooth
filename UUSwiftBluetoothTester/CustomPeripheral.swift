//
//  CustomPeripheral.swift
//  UUSwiftBluetoothTester
//
//  Created by Ryan DeVore on 9/8/21.
//

import UIKit
import CoreBluetooth
import UUSwiftBluetooth

class CustomPeripheral: UUPeripheral
{
    required init(_ dispatchQueue: DispatchQueue, _ centralManager: UUCentralManager, _ peripheral: CBPeripheral)
    {
        super.init(dispatchQueue, centralManager, peripheral)
    }
}
