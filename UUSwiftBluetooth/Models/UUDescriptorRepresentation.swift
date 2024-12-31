//
//  UUDescriptorRepresentation.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 12/25/24.
//

import Foundation
import CoreBluetooth

/// A representation of a CoreBluetooth descriptor.
///
/// `UUDescriptorRepresentation` models a Bluetooth descriptor, which provides additional metadata or
/// configuration for a Bluetooth characteristic. This class is designed to simplify working with
/// descriptors and their representation in JSON or other data formats.
///
/// ## Features
/// - Conforms to `Codable` for easy serialization and deserialization.
/// - Uses a unique `uuid` attribute to uniquely identify the descriptor.
/// - Includes an optional `name` property for additional context.
/// - Provides convenience initialization from a `CBDescriptor` object.
///
/// ## Properties
/// - `uuid`: A unique identifier for the descriptor, stored as a string. This is marked as unique using the `@Attribute` property wrapper.
/// - `name`: An optional string providing a human-readable name for the descriptor.
///
/// ## Initializers
/// - `init(uuid: String, name: String?)`: Initializes a new descriptor representation with a UUID and an optional name.
/// - `init(from descriptor: CBDescriptor)`: Convenience initializer to create a descriptor representation from a CoreBluetooth `CBDescriptor` object.
/// - `init(from decoder: Decoder)`: Initializes an instance by decoding it from an external representation.
///
/// ## Codable
/// This class conforms to `Codable`, allowing instances to be serialized into or deserialized from JSON.
///
/// ## Example Usage
/// ```swift
/// // Creating a descriptor representation
/// let descriptor = UUDescriptorRepresentation(uuid: "2902", name: "Client Characteristic Configuration")
///
/// // Encoding to JSON
/// let encoder = JSONEncoder()
/// if let jsonData = try? encoder.encode(descriptor),
///    let jsonString = String(data: jsonData, encoding: .utf8) {
///     print(jsonString)
/// }
///
/// // Decoding from JSON
/// let jsonString = """
/// {
///   "uuid": "2902",
///   "name": "Client Characteristic Configuration"
/// }
/// """
/// if let jsonData = jsonString.data(using: .utf8),
///    let decodedDescriptor = try? JSONDecoder().decode(UUDescriptorRepresentation.self, from: jsonData) {
///     print(decodedDescriptor.name ?? "No name") // Output: Client Characteristic Configuration
/// }
/// ```
///
/// ## See Also
/// - `CBDescriptor`
/// - `UUCharacteristicRepresentation`
final public class UUDescriptorRepresentation: Codable
{
    /// A unique identifier for the descriptor.
    public var uuid: String = ""

    /// An optional human-readable name for the descriptor.
    public var name: String? = nil

    /// Initializes a new descriptor representation with a UUID and an optional name.
    /// - Parameters:
    ///   - uuid: The unique identifier for the descriptor.
    ///   - name: An optional human-readable name.
    public init(uuid: String, name: String? = nil)
    {
        self.uuid = uuid
        self.name = name
    }

    /// Convenience initializer to create a descriptor representation from a CoreBluetooth `CBDescriptor`.
    /// - Parameter descriptor: A `CBDescriptor` object from CoreBluetooth.
    public convenience init(from descriptor: CBDescriptor)
    {
        self.init(uuid: descriptor.uuid.uuidString, name: descriptor.uuid.uuCommonName)
    }

    /// Internal keys used for encoding and decoding.
    private enum CodingKeys: String, CodingKey
    {
        case uuid, name
    }

    /// Encodes the descriptor representation into the given encoder.
    /// - Parameter encoder: The encoder to write data to.
    public func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(name, forKey: .name)
    }

    /// Initializes a descriptor representation by decoding it from the given decoder.
    /// - Parameter decoder: The decoder to read data from.
    /// - Throws: An error if the data is invalid or missing.
    required public init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uuid = try container.decode(String.self, forKey: .uuid)
        name = try container.decode(String.self, forKey: .name)
    }
}
