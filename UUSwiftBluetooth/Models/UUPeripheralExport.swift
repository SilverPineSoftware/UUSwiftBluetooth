//
//  UUPeripheralExport.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 11/30/24.
//

import UIKit
import CoreBluetooth

public struct UUPeripheralExport: Codable
{
    var services: [UUServiceExport]? = nil
    
    mutating func populate(from peripheral: CBPeripheral)
    {
        if let services = peripheral.services, !services.isEmpty
        {
            self.services = services.compactMap(
            { service in
                var s = UUServiceExport()
                s.populate(from: service)
                return s
            })
        }
    }
}

public struct UUDescriptorExport: Codable
{
    var uuid: String? = nil
    var name: String? = nil
    
    mutating func populate(from descriptor: CBDescriptor)
    {
        self.uuid = descriptor.uuid.uuidString
        self.name = descriptor.uuid.uuCommonName
    }
}

public struct UUCharacteristicExport: Codable
{
    var uuid: String? = nil
    var name: String? = nil
    var properties: [String]? = nil
    var descriptors: [UUDescriptorExport]? = nil
    
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
                var d = UUDescriptorExport()
                d.populate(from: descriptor)
                return d
            })
        }
    }
}


public struct UUServiceExport: Codable
{
    var uuid: String? = nil
    var name: String? = nil
    var isPrimary: Bool? = nil
    var includedServices: [UUServiceExport]? = nil
    var characteristics: [UUCharacteristicExport]? = nil
    
    mutating func populate(from service: CBService)
    {
        self.uuid = service.uuid.uuidString
        self.name = service.uuid.uuCommonName
        
        if let list = service.includedServices, !list.isEmpty
        {
            self.includedServices = list.compactMap(
            { service in
                var s = UUServiceExport()
                s.populate(from: service)
                return s
            })
        }
        
        if let list = service.characteristics, !list.isEmpty
        {
            self.characteristics = list.compactMap(
            { characterstic in
                var c = UUCharacteristicExport()
                c.populate(from: characterstic)
                return c
            })
        }
    }
}
