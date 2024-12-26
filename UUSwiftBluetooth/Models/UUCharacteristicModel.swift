//
//  UUCharacteristicModel.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 12/25/24.
//

import Foundation
import CoreBluetooth

public struct UUCharacteristicModel: UUAttributeProtocol
{
    public var uuid: String? = nil
    public var name: String? = nil
    public var properties: [String]? = nil
    public var descriptors: [UUDescriptorModel]? = nil
    
    mutating func populate(from characteristic: CBCharacteristic)
    {
        self.uuid = characteristic.uuid.uuidString
        self.name = characteristic.uuid.uuCommonName
   
        self.properties = characteristic.properties.uuSplitValues
            .compactMap({ props in
                UUCBCharacteristicPropertiesToString(props)
            })
        
        if let descriptors = characteristic.descriptors, !descriptors.isEmpty
        {
            self.descriptors = descriptors.compactMap({ descriptor in
                var d = UUDescriptorModel()
                d.populate(from: descriptor)
                return d
            })
        }
    }
}
