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

public extension CBCharacteristicProperties
{
    func uuDescription() -> String
    {
        let props = self
        
        var parts: [String] = []
        
        if (props.contains(.broadcast))
        {
            parts.append("Broadcast")
        }
        
        if (props.contains(.read))
        {
            parts.append("Read")
        }
        
        if (props.contains(.writeWithoutResponse))
        {
            parts.append("WriteWithoutResponse")
        }
        
        if (props.contains(.write))
        {
            parts.append("Write")
        }
        
        if (props.contains(.notify))
        {
            parts.append("Notify")
        }
        
        if (props.contains(.indicate))
        {
            parts.append("Indicate")
        }
        
        if (props.contains(.authenticatedSignedWrites))
        {
            parts.append("AuthenticatedSignedWrites")
        }
        
        if (props.contains(.extendedProperties))
        {
            parts.append("ExtendedProperties")
        }
        
        if (props.contains(.notifyEncryptionRequired))
        {
            parts.append("NotifyEncryptionRequired")
        }
        
        if (props.contains(.indicateEncryptionRequired))
        {
            parts.append("IndicateEncryptionRequired")
        }
        
        return parts.joined(separator: ", ")
    }
}
