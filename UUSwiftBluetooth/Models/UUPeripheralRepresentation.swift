//
//  UUPeripheralRepresentation.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 12/25/24.
//

import Foundation
import CoreBluetooth
import UUSwiftCore

/// A representation of a CoreBluetooth peripheral.
///
/// `UUPeripheralRepresentation` models a Bluetooth peripheral, providing access to its associated services.
/// This class is designed to work with CoreBluetooth and facilitate encoding and decoding as JSON for storage or communication.
///
/// ## Features
/// - Conforms to `Codable` for seamless JSON serialization and deserialization.
/// - Supports initialization from CoreBluetooth's `CBPeripheral`.
/// - Provides a method to register common names for services, characteristics, and descriptors.
///
/// ## Properties
/// - `services`: An optional array of `UUServiceRepresentation` objects representing the services available on the peripheral.
///
/// ## Initializers
/// - `init()`: Creates a new, empty peripheral representation.
/// - `init(from peripheral: CBPeripheral)`: Convenience initializer to create a peripheral representation from a CoreBluetooth `CBPeripheral`.
/// - `init(from decoder: Decoder)`: Initializes an instance by decoding it from an external representation.
///
/// ## Methods
/// - `registerCommonNames()`: Registers human-readable common names for services, characteristics, and descriptors in the peripheral.
///
/// ## Codable
/// This class conforms to `Codable`, making it easy to serialize into or deserialize from JSON.
///
/// ## Example Usage
/// ```swift
/// // Create a peripheral representation
/// let peripheral = UUPeripheralRepresentation()
///
/// // Decode from JSON
/// let jsonString = """
/// {
///   "services": [
///     {
///       "uuid": "180D",
///       "name": "Heart Rate",
///       "isPrimary": true,
///       "includedServices": [],
///       "characteristics": [
///         {
///           "uuid": "2A37",
///           "name": "Heart Rate Measurement",
///           "properties": ["Notify"],
///           "descriptors": []
///         }
///       ]
///     }
///   ]
/// }
/// """
/// if let jsonData = jsonString.data(using: .utf8),
///    let decodedPeripheral = try? JSONDecoder().decode(UUPeripheralRepresentation.self, from: jsonData)
/// {
///     print(decodedPeripheral.services?.first?.name ?? "No services")
/// }
///
/// // Register common names
/// decodedPeripheral?.registerCommonNames()
/// ```
///
/// ## See Also
/// - `CBPeripheral`
/// - `UUServiceRepresentation`
final public class UUPeripheralRepresentation: Codable
{
    /// An optional array of services available on the peripheral.
    public var services: [UUServiceRepresentation]? = nil

    /// Creates a new, empty peripheral representation.
    public init()
    {
        
    }

    /// Convenience initializer to create a peripheral representation from a CoreBluetooth `CBPeripheral`.
    /// - Parameter peripheral: A `CBPeripheral` object from CoreBluetooth.
    public convenience init(from peripheral: CBPeripheral)
    {
        self.init()

        if let services = peripheral.services, !services.isEmpty
        {
            self.services = services.compactMap { UUServiceRepresentation(from: $0) }
        }
    }

    /// Internal keys used for encoding and decoding.
    private enum CodingKeys: String, CodingKey
    {
        case services
    }

    /// Encodes the peripheral representation into the given encoder.
    /// - Parameter encoder: The encoder to write data to.
    /// - Throws: An error if encoding fails.
    public func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(services, forKey: .services)
    }

    /// Initializes a peripheral representation by decoding it from the given decoder.
    /// - Parameter decoder: The decoder to read data from.
    /// - Throws: An error if decoding fails or required fields are missing.
    required public init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        services = try container.decodeIfPresent([UUServiceRepresentation].self, forKey: .services)
    }

    /// Registers common names for services, characteristics, and descriptors.
    ///
    /// This method iterates through all services, characteristics, and descriptors associated with
    /// the peripheral and registers their common names with `UUCoreBluetooth`. It logs the final
    /// mapping of common names.
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
