//
//  Helpers.swift
//  UUSwiftBluetoothTests
//
//  Created by Ryan DeVore on 5/4/25.
//

import Foundation
import UUSwiftCore
import UUSwiftBluetooth
import UUSwiftTestCore
import XCTest

/*
public extension UUPeripheralScanner
{
    mutating func scanForPeripheral(timeout: TimeInterval, filter: @escaping (UUPeripheral)->Bool) async -> UUPeripheral?
    {
        return await withCheckedContinuation
        { continuation in
            
            let timerId = "scanForPeripheralTimerId"
            
            config = UUPeripheralScannerConfig()
            config.discoveryFilters = [SinglePeripheralFilter(filter) ]
            
            listChanged =
            { scanner, peripherals in
                
                //NSLog("Discovered peripherals: \(peripherals)")
                
                if let p = peripherals.first
                {
                    UUTimerPool.shared.cancel(by: timerId)
                    scanner.stop()
                    continuation.resume(returning: p)
                }
            }
            
            start()
            
            // Stop scanning after timeout
            UUTimerPool.shared.start(identifier: timerId, timeout: 5.0, userInfo: self)
            { scanner in
                
                (scanner as? UUPeripheralScanner)?.stop()
                continuation.resume(returning: nil)
            }
        }
    }
}*/

public extension XCTestCase
{
    func scanForPeripheral(name: String, timeout: TimeInterval = 10.0) throws -> (any UUPeripheral)
    {
        let scanner = UUBluetooth.scanner
        let peripheralOpt = scanForPeripheral(scanner: scanner, timeout: timeout, filter: UUPeripheralNameFilter(name))
        let peripheral = try XCTUnwrap(peripheralOpt)
        return peripheral
    }
    
    func scanForPeripheral(
        scanner: UUPeripheralScanner,
        timeout: TimeInterval,
        filter: @escaping (UUPeripheral)->Bool) -> UUPeripheral?
    {
        let exp = uuExpectationForMethod()
        
        let timerId = "scanForPeripheralTimerId"
        
        let config = UUPeripheralScannerConfig()
        config.discoveryFilters = [SinglePeripheralFilter(filter) ]
        
        var scanner = scanner
        
        var foundPeripheral: UUPeripheral? = nil
        
        scanner.listChanged =
        { scanner, peripherals in
            
            if let p = peripherals.first
            {
                UUTimerPool.shared.cancel(by: timerId)
                foundPeripheral = p
                NSLog("Found Peripheral: \(p)")
                scanner.stop()
            }
        }
        
        scanner.ended =
        { scanner, error in
            NSLog("Scan Ended")
            exp.fulfill()
        }
        
        scanner.start()
        
        UUTimerPool.shared.start(identifier: timerId, timeout: 10.0, userInfo: scanner)
        { _ in
            
            scanner.stop()
        }
        
        //uuWaitForExpectations(30.0)
        wait(for: [exp], timeout: 30.0)
        
        return foundPeripheral
    }
}


public class SinglePeripheralFilter: UUPeripheralFilter
{
    private let filterMethod: ((any UUPeripheral)->Bool)
    
    init (_ filterMethod: @escaping ((any UUPeripheral) -> Bool))
    {
        self.filterMethod = filterMethod
    }
    
    public func shouldDiscover(_ peripheral: any UUPeripheral) -> Bool
    {
        return filterMethod(peripheral)
    }
}

public func UUPeripheralNameFilter(_ name: String) -> ((UUPeripheral)->Bool)
{
    return { peripheral in
        
        NSLog("UUPeripheralNameFilter, checking: \(peripheral.identifier), \(peripheral.name), \(peripheral.rssi), \(peripheral.advertisement.localName)")
        
        return peripheral.advertisement.localName == name
    }
}
