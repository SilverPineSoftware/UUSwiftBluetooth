//
//  UUMockPeripheral.swift
//  BluetoothExplorer
//
//  Created by Ryan DeVore on 11/10/24.
//

#if DEBUG

import Foundation
import CoreBluetooth

///
/// Non Functional peripheral for use in building out mocked objects for Swift UI previews
///
public extension UUPeripheral
{
    static func mocked(
        identifier: UUID = UUID.init(),
        rssi: Int = -57,
        name: String? = "Mock Peripheral",
        advertisement: UUAdvertisement = UUAdvertisement()
    ) -> UUPeripheral
    {
        let p = UUPeripheral(
            dispatchQueue: DispatchQueue.global(qos: .userInitiated),
            centralState: .poweredOn,
            peripheral: UUMockCBPeripheral(
                identifier: identifier,
                name: name
            ),
            advertisement: advertisement)
        
        p.updateRssi(rssi)
        
        return p
    }
}

#endif
