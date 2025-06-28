//
//  Helpers.swift
//  UUSwiftBluetoothTests
//
//  Created by Ryan DeVore on 5/4/25.
//

import Foundation
import UUSwiftCore
import UUSwiftBluetooth


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
        
        //NSLog("Peripheral: \(peripheral.identifier), \(peripheral.name), \(peripheral.rssi), \(peripheral.advertisement.localName)")
        
        return peripheral.advertisement.localName == name
    }
}
