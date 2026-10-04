//
//  UUPeripheralScanner.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 12/16/24.
//

import Foundation

public typealias UUPeripheralListChangedCallback = (UUPeripheralScanner, [UUPeripheral]) -> Void
public typealias UUPeripheralScannerStartedCallback = (UUPeripheralScanner) -> Void
public typealias UUPeripheralScannerStoppedCallback = (UUPeripheralScanner, Error?) -> Void

public protocol UUPeripheralScanner
{
    var isScanning: Bool { get }
    var config: UUPeripheralScannerConfig { get set }
    var peripherals: [UUPeripheral] { get }
    
    var started: UUPeripheralScannerStartedCallback { get set }
    var ended: UUPeripheralScannerStoppedCallback { get set }
    var listChanged: UUPeripheralListChangedCallback { get set }
    
    func start()
    func stop()
    
    func getPeripheral(identifier: UUID) -> UUPeripheral?
}
