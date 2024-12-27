//
//  UUServiceRepresentation.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 12/25/24.
//

import Foundation
import CoreBluetooth

/// `UUServiceRepresentation` is a representation of a Bluetooth service, encompassing various attributes and characteristics associated with a service on a Bluetooth device.
///
/// This class extends `UUAttributeRepresentation` to include properties specific to Bluetooth services, such as whether it is a primary service, any included services, and the characteristics it possesses.
public class UUServiceRepresentation: UUAttributeRepresentation
{   
    /// A boolean indicating whether this is the primary service.
    public var isPrimary: Bool? = nil
    
    /// An array of included services.
    ///
    /// These are services that are associated with the current service. This property allows for a hierarchical structuring of services, where one service can include other services.
    public var includedServices: [UUServiceRepresentation]? = nil
    
    /// An array of characteristics associated with this service.
    ///
    /// Characteristics provide further detail into what a service can do or what data it contains. Each characteristic can be represented by a `UUCharacteristicRepresentation`.
    public var characteristics: [UUCharacteristicRepresentation]? = nil
    
    /// Initializes a new instance of `UUServiceRepresentation` with optional UUID and name attributes.
    ///
    /// - Parameters:
    ///   - uuid: An optional string representing the UUID of the service.
    ///   - name: An optional string representing the name of the service.
    public override init(uuid: String? = nil, name: String? = nil)
    {
        super.init(uuid: uuid, name: name)
    }
    
    /// Initializes a new instance of `UUServiceRepresentation` from a Core Bluetooth `CBService`.
    ///
    /// This convenience initializer allows for easy conversion of a `CBService` object,
    /// typically obtained during Bluetooth operations, into a `UUServiceRepresentation` object.
    ///
    /// - Parameter service: The `CBService` instance to initialize from.
    public convenience init(from service: CBService)
    {
        self.init(uuid: service.uuid.uuidString, name: service.uuid.uuCommonName)
        
        if let list = service.includedServices, !list.isEmpty
        {
            self.includedServices = list.compactMap(
            { service in
                let s = UUServiceRepresentation(from: service)
                return s
            })
        }
        
        if let list = service.characteristics, !list.isEmpty
        {
            self.characteristics = list.compactMap(
            { characterstic in
                let c = UUCharacteristicRepresentation(from: characterstic)
                return c
            })
        }
    }
    
    /// Internal keys used for encoding and decoding.
    private enum CodingKeys: String, CodingKey
    {
        case isPrimary, includedServices, characteristics
    }
    
    /// Encodes this object into the provided encoder.
    ///
    /// - Parameter encoder: The encoder used to encode the object.
    /// - Throws: An error if encoding fails.
    public override func encode(to encoder: Encoder) throws
    {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isPrimary, forKey: .isPrimary)
        try container.encode(includedServices, forKey: .includedServices)
        try container.encode(characteristics, forKey: .characteristics)
    }

    /// Initializes an instance by decoding from the provided decoder.
    ///
    /// - Parameter decoder: The decoder used to decode the object.
    /// - Throws: An error if decoding fails.
    required public init(from decoder: Decoder) throws
    {
        try super.init(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isPrimary = try container.decodeIfPresent(Bool.self, forKey: .isPrimary)
        characteristics = try container.decodeIfPresent([UUCharacteristicRepresentation].self, forKey: .characteristics)
        includedServices = try container.decodeIfPresent([UUServiceRepresentation].self, forKey: .includedServices)
    }
}
