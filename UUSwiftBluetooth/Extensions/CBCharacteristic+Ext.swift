//
//  CBCharacteristic+Extensions.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 8/13/21.
//

import UIKit
import CoreBluetooth
import UUSwiftCore

public extension CBCharacteristic
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

public extension Array where Element: CBCharacteristic
{
    func uuFind(_ characteristic: CBUUID) -> CBCharacteristic?
    {
        return self.filter({ $0.uuid == characteristic }).first
    }
}
