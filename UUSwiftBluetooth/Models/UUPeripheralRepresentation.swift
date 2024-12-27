//
//  UUPeripheralRepresentation.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 12/25/24.
//

import Foundation
import CoreBluetooth
import UUSwiftCore

/// `UUPeripheralRepresentation` is a class that represents a Bluetooth peripheral, encapsulating the services that the peripheral offers.
///
/// This class is designed to be Codable, enabling easy serialization and deserialization of peripheral representations, which can be useful for saving state or for network communication.
public class UUPeripheralRepresentation: Codable
{
    /// An array of services associated with this peripheral.
    ///
    /// Each service is represented by a `UUServiceRepresentation` object. This array may be nil if the peripheral does not have any services or if they have not been discovered yet.
    public var services: [UUServiceRepresentation]? = nil
    
    /// Initializes a new instance of `UUPeripheralRepresentation`.
    ///
    /// This initializer creates an empty representation of a peripheral, with no services initialized.
    public init()
    {
    }
    
    /// Initializes a new instance of `UUPeripheralRepresentation` from a Core Bluetooth `CBPeripheral`.
    ///
    /// This convenience initializer processes a `CBPeripheral` object to extract its services and populate the `services`
    /// property with `UUServiceRepresentation` objects, if any services are available.
    ///
    /// - Parameter peripheral: The `CBPeripheral` from which to create a peripheral representation.
    public convenience init(from peripheral: CBPeripheral)
    {
        self.init()
        
        if let services = peripheral.services, !services.isEmpty
        {
            self.services = services.compactMap { service in
                // Convert CBService to UUServiceRepresentation
                return UUServiceRepresentation(from: service)
            }
        }
    }
    
    /// Internal keys used for encoding and decoding.
    private enum CodingKeys: String, CodingKey
    {
        case services
    }
    
    /// Encodes this object into the provided encoder.
    ///
    /// - Parameter encoder: The encoder used to encode the object.
    /// - Throws: An error if encoding fails.
    public func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(services, forKey: .services)
    }

    /// Initializes an instance by decoding from the provided decoder.
    ///
    /// - Parameter decoder: The decoder used to decode the object.
    /// - Throws: An error if decoding fails.
    required public init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        services = try container.decodeIfPresent([UUServiceRepresentation].self, forKey: .services)
    }
    
    ///
    /// Registers all uuid common names with the UUCoreBluetooth mapping system
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
