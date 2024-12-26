//
//  UUServiceModel.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 12/25/24.
//

import Foundation
import CoreBluetooth

public struct UUServiceModel: UUAttributeProtocol
{
    public var uuid: String? = nil
    public var name: String? = nil
    public var isPrimary: Bool? = nil
    public var includedServices: [UUServiceModel]? = nil
    public var characteristics: [UUCharacteristicModel]? = nil
    
    mutating func populate(from service: CBService)
    {
        self.uuid = service.uuid.uuidString
        self.name = service.uuid.uuCommonName
        
        if let list = service.includedServices, !list.isEmpty
        {
            self.includedServices = list.compactMap(
            { service in
                var s = UUServiceModel()
                s.populate(from: service)
                return s
            })
        }
        
        if let list = service.characteristics, !list.isEmpty
        {
            self.characteristics = list.compactMap(
            { characterstic in
                var c = UUCharacteristicModel()
                c.populate(from: characterstic)
                return c
            })
        }
    }
}
