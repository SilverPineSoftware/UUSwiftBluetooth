//
//  CBCharacteristicProperties+Ext.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 11/30/24.
//

import UIKit
import CoreBluetooth

internal extension CBCharacteristicProperties
{
    var uuAllValues: [CBCharacteristicProperties]
    {
        return [
            .broadcast,
            .read,
            .writeWithoutResponse,
            .write,
            .notify,
            .indicate,
            .authenticatedSignedWrites,
            .extendedProperties,
            .notifyEncryptionRequired,
            .indicateEncryptionRequired,
        ]
    }
    
    var uuSplitValues: [CBCharacteristicProperties]
    {
        var list: [CBCharacteristicProperties] = []
        
        for value in uuAllValues
        {
            if self.contains(value)
            {
                list.append(value)
            }
        }
        
        return list
    }
}
