//
//  UUPeripheralScanner.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 12/16/24.
//

import UIKit

public protocol UUPeripheralScanner
{
    var isScanning: Bool { get }
    
    func startScan(_ settings: UUBluetoothScanSettings, callback: @escaping ([UUPeripheral]) ->())
    func stopScan()
}

public extension UUCoreBluetooth
{
    static var defaultScanner: UUPeripheralScanner
    {
        return UUCoreBluetoothBleScanner()
    }
}
