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
        return (UUIsCBCharacteristicPropertySet(properties, .notify) ||
               UUIsCBCharacteristicPropertySet(properties, .indicate))
    }

    var uuCanReadData: Bool
    {
        return UUIsCBCharacteristicPropertySet(properties, .read)
    }

    var uuCanWriteData: Bool
    {
        return UUIsCBCharacteristicPropertySet(properties, .write)
    }

    var uuCanWriteWithoutResponse: Bool
    {
        return UUIsCBCharacteristicPropertySet(properties, .writeWithoutResponse)
    }
}
