//
//  UUBluetoothProvider.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 5/10/25.
//

import Foundation

public protocol UUBluetoothProvider
{
    var scanner: UUPeripheralScanner { get }
    
    //func createSession(peripheral: UUPeripheral) -> UUPeripheralSession
}
