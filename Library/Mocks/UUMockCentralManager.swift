//
//  UUMockCentralManager.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 7/18/25.
//

#if DEBUG

import Foundation
import CoreBluetooth

///
/// Non Functional central manager for use in building out mocked objects for Swift UI previews
///
public extension UUCentralManager
{
    static func mocked() -> UUCentralManager
    {
        return UUCentralManager(options: UUCentralManagerOptions(), injection: { q, o in
            
            let delegate = UUCentralManagerDelegate()
            let mgr = UUMockCBCentralManager(delegate: delegate, queue: q, options: o.coreBluetoothOptions)
            return (delegate, mgr)
        })
    }
}

#endif
