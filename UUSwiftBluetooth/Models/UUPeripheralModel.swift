//
//  UUPeripheralModel.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 12/25/24.
//

import Foundation
import CoreBluetooth
import UUSwiftCore

public struct UUPeripheralModel: Codable
{
    public var services: [UUServiceModel]? = nil
    
    mutating func populate(from peripheral: CBPeripheral)
    {
        if let services = peripheral.services, !services.isEmpty
        {
            self.services = services.compactMap(
            { service in
                var s = UUServiceModel()
                s.populate(from: service)
                return s
            })
        }
    }
    
    public func registerCommonNames()
    {
        guard let services else
        {
            return
        }
        
        for service in services
        {
            UUCoreBluetooth.register(commonName: service.name, for: service.uuid)
            
            if let chars = service.characteristics
            {
                for chr in chars
                {
                    UUCoreBluetooth.register(commonName: chr.name, for: chr.uuid)
                    
                    if let descs = chr.descriptors
                    {
                        for desc in descs
                        {
                            UUCoreBluetooth.register(commonName: desc.name, for: desc.uuid)
                        }
                    }
                }
            }
        }
        
        let map = UUCoreBluetooth.mappedCommonNames
        UULog.debug(tag: "Mapped common names", message: "\(map)")
    }
}
