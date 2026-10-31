//
//  UUMockPeripheralScanner.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 10/31/26.
//

#if DEBUG

import Foundation
import CoreBluetooth

///
/// Non Functional scanner for use in building out mocked objects for Swift UI previews
///
public class UUMockPeripheralScanner: UUPeripheralScanner
{
    public var peripherals: [UUPeripheral] = []
    
    public func getPeripheral(identifier: UUID) -> UUPeripheral?
    {
        return UUPeripheral.mocked(identifier: identifier)
    }
    
    var mockIsScanning: Bool = false
    
    public var isScanning: Bool
    {
        return mockIsScanning
    }
    
    public var config: UUPeripheralScannerConfig = UUPeripheralScannerConfig()
    
    public var started: UUPeripheralScannerStartedCallback = { _ in }
    
    public var ended: UUPeripheralScannerStoppedCallback = { _, _ in }
    
    public var listChanged: UUPeripheralListChangedCallback = { _,_ in }
    
    public func start()
    {
    }
    
    public func stop()
    {
    }
}

#endif

