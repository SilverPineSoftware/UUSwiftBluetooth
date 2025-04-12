//
//  UUCharacteristicRepresentation.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 12/25/24.
//

import Foundation
import CoreBluetooth

/// A representation of a CoreBluetooth characteristic.
///
/// `UUCharacteristicRepresentation` models a Bluetooth characteristic, providing essential details
/// such as its UUID, name, properties, and associated descriptors. This class is designed to work with
/// CoreBluetooth and to facilitate encoding and decoding as JSON for storage or communication.
///
/// ## Features
/// - Conforms to `Codable` for seamless JSON serialization and deserialization.
/// - Supports initialization from CoreBluetooth's `CBCharacteristic`.
/// - Includes an optional list of properties and descriptors associated with the characteristic.
///
/// ## Properties
/// - `uuid`: A unique identifier for the characteristic, stored as a string. This is marked as unique using the `@Attribute` property wrapper.
/// - `name`: An optional human-readable name for the characteristic.
/// - `properties`: An optional array of property strings that describe the characteristic's features.
/// - `descriptors`: An optional array of `UUDescriptorRepresentation` objects representing the characteristic's descriptors.
///
/// ## Initializers
/// - `init(uuid: String, name: String?, properties: [String]?, descriptors: [UUDescriptorRepresentation]?)`: Initializes a new characteristic representation with a UUID, name, properties, and descriptors.
/// - `init(from characteristic: CBCharacteristic)`: Convenience initializer to create a characteristic representation from a CoreBluetooth `CBCharacteristic`.
/// - `init(from decoder: Decoder)`: Initializes an instance by decoding it from an external representation.
///
/// ## Codable
/// This class conforms to `Codable`, making it easy to serialize into or deserialize from JSON.
///
/// ## Example Usage
/// ```swift
/// // Create a characteristic representation
/// let characteristic = UUCharacteristicRepresentation(
///     uuid: "2A37",
///     name: "Heart Rate Measurement",
///     properties: ["Notify"],
///     descriptors: [UUDescriptorRepresentation(uuid: "2902", name: "Client Characteristic Configuration")]
/// )
///
/// // Encode to JSON
/// let encoder = JSONEncoder()
/// if let jsonData = try? encoder.encode(characteristic),
///    let jsonString = String(data: jsonData, encoding: .utf8)
/// {
///     print(jsonString)
/// }
///
/// // Decode from JSON
/// let jsonString = """
/// {
///   "uuid": "2A37",
///   "name": "Heart Rate Measurement",
///   "properties": ["Notify"],
///   "descriptors": [
///     { "uuid": "2902", "name": "Client Characteristic Configuration" }
///   ]
/// }
/// """
/// if let jsonData = jsonString.data(using: .utf8),
///    let decodedCharacteristic = try? JSONDecoder().decode(UUCharacteristicRepresentation.self, from: jsonData)
/// {
///     print(decodedCharacteristic.name ?? "No name")
/// }
/// ```
///
/// ## See Also
/// - `CBCharacteristic`
/// - `UUDescriptorRepresentation`
final public class UUCharacteristicRepresentation: Codable
{
    /// A unique identifier for the characteristic.
    public var uuid: String = ""

    /// An optional human-readable name for the characteristic.
    public var name: String? = nil

    /// An optional list of property strings describing the characteristic's features.
    public var properties: [String]? = nil

    /// An optional list of descriptors associated with the characteristic.
    public var descriptors: [UUDescriptorRepresentation]? = nil

    /// Initializes a new characteristic representation with the specified properties.
    /// - Parameters:
    ///   - uuid: The unique identifier for the characteristic.
    ///   - name: An optional human-readable name.
    ///   - properties: An optional array of property strings describing the characteristic.
    ///   - descriptors: An optional array of descriptors associated with the characteristic.
    public init(uuid: String, name: String? = nil, properties: [String]? = nil, descriptors: [UUDescriptorRepresentation]? = nil)
    {
        self.uuid = uuid
        self.name = name
        self.properties = properties
        self.descriptors = descriptors
    }

    /// Convenience initializer to create a characteristic representation from a CoreBluetooth `CBCharacteristic`.
    /// - Parameter characteristic: A `CBCharacteristic` object from CoreBluetooth.
    public convenience init(from characteristic: CBCharacteristic)
    {
        self.init(
            uuid: characteristic.uuid.uuidString,
            name: characteristic.uuid.uuCommonName,
            properties: characteristic.properties.uuSplitValues.compactMap { $0.uuDescription() }
        )
        
        if let descriptors = characteristic.descriptors, !descriptors.isEmpty
        {
            self.descriptors = descriptors.compactMap { UUDescriptorRepresentation(from: $0) }
        }
    }

    /// Internal keys used for encoding and decoding.
    private enum CodingKeys: String, CodingKey
    {
        case uuid, name, properties, descriptors
    }

    /// Encodes the characteristic representation into the given encoder.
    /// - Parameter encoder: The encoder to write data to.
    /// - Throws: An error if encoding fails.
    public func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(name, forKey: .name)
        try container.encode(properties, forKey: .properties)
        try container.encode(descriptors, forKey: .descriptors)
    }

    /// Initializes a characteristic representation by decoding it from the given decoder.
    /// - Parameter decoder: The decoder to read data from.
    /// - Throws: An error if decoding fails or required fields are missing.
    required public init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uuid = try container.decode(String.self, forKey: .uuid)
        name = try container.decode(String.self, forKey: .name)
        properties = try container.decodeIfPresent([String].self, forKey: .properties)
        descriptors = try container.decodeIfPresent([UUDescriptorRepresentation].self, forKey: .descriptors)
    }
}
