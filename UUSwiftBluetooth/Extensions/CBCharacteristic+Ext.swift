//
//  CBCharacteristic+Extensions.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 8/13/21.
//

import Foundation
import CoreBluetooth
import UUSwiftCore

public extension UUCBCharacteristic
{
    var uuCanToggleNotify: Bool
    {
        return (properties.contains(.notify) || properties.contains(.indicate))
    }

    var uuCanReadData: Bool
    {
        return properties.contains(.read)
    }

    var uuCanWriteData: Bool
    {
        return properties.contains(.write)
    }

    var uuCanWriteWithoutResponse: Bool
    {
        return properties.contains(.writeWithoutResponse)
    }
}

public extension Array where Element: UUCBCharacteristic
{
    func uuFind(_ characteristic: CBUUID) -> UUCBCharacteristic?
    {
        return self.filter({ $0.uuid == characteristic }).first
    }
}
