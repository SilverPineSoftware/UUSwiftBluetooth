//
//  UUDescriptorModel.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 12/25/24.
//

import Foundation
import CoreBluetooth

public struct UUDescriptorModel: UUAttributeProtocol
{
    public var uuid: String? = nil
    public var name: String? = nil
    
    mutating func populate(from descriptor: CBDescriptor)
    {
        self.uuid = descriptor.uuid.uuidString
        self.name = descriptor.uuid.uuCommonName
    }
}
