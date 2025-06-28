//
//  UUDefaultProvider.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 5/10/25.
//

import Foundation

public class UUDefaultProvider: UUBluetoothProvider
{
    public var scanner: UUPeripheralScanner = UUCoreBluetoothPeripheralScanner()
    
//    public func createSession(peripheral: any UUPeripheral) -> any UUPeripheralSession
//    {
//        return UUCoreBluetoothPeripheralSession(peripheral: peripheral)
//    }
}
