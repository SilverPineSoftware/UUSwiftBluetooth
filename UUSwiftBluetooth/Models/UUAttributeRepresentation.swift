//
//  UUAttributeRepresentation.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 12/25/24.
//

import Foundation
import CoreBluetooth

/// A simple model representing a CBAttribute in the CoreBluetooth library.
///
/// The `UUAttributeRepresentation` class provides a lightweight representation of a CoreBluetooth `CBAttribute`,
/// including its `uuid` and an optional human-readable `name`. It conforms to `Codable` for easy serialization
/// and deserialization to/from JSON or other formats.
///
/// ## Properties
/// - `uuid`: A string representation of the attribute's UUID.
/// - `name`: An optional name providing a human-readable description of the attribute.
///
/// ## Codable Conformance
/// The class conforms to the `Codable` protocol, allowing for seamless encoding and decoding to and from JSON.
/// Custom implementations of the `encode(to:)` and `init(from:)` methods ensure proper handling of optional properties.
///
/// ## Example Usage
/// ```swift
/// let attribute = UUAttributeRepresentation()
/// attribute.uuid = "2902"
/// attribute.name = "Client Characteristic Configuration"
///
/// let encoder = JSONEncoder()
/// if let jsonData = try? encoder.encode(attribute),
///    let jsonString = String(data: jsonData, encoding: .utf8) {
///     print(jsonString)
/// }
///
/// // Example output:
/// // {
/// //    "uuid": "2902",
/// //    "name": "Client Characteristic Configuration"
/// // }
/// ```
///
/// ## CoreBluetooth Context
/// This class is designed to work alongside the CoreBluetooth framework, serving as a simplified
/// representation of `CBAttribute` instances for easier manipulation, storage, or serialization.
///
/// ## Thread Safety
/// This class does not provide explicit thread safety guarantees. Ensure thread-safe access if used in
/// concurrent environments.
public class UUAttributeRepresentation: Codable
{
    /// The UUID of the attribute, represented as a string.
    public var uuid: String? = nil

    /// A human-readable name for the attribute, if available.
    public var name: String? = nil

    /// Internal keys used for encoding and decoding.
    private enum CodingKeys: String, CodingKey
    {
        case uuid, name
    }
    
    /// Initializes a `UUAttributeRepresentation` instance with a UUID and an optional name.
    ///
    /// - Parameters:
    ///   - uuid: The UUID of the attribute, represented as a string. Defaults to `nil`.
    ///   - name: An optional human-readable name for the attribute. Defaults to `nil`.
    ///
    /// - Returns: A newly initialized `UUAttributeRepresentation` instance.
    ///
    /// ## Example Usage
    /// ```swift
    /// let attribute = UUAttributeRepresentation(uuid: "2902", name: "Client Characteristic Configuration")
    /// print(attribute.uuid) // Output: "2902"
    /// print(attribute.name) // Output: "Client Characteristic Configuration"
    ///
    /// let unnamedAttribute = UUAttributeRepresentation(uuid: "180D")
    /// print(unnamedAttribute.uuid) // Output: "180D"
    /// print(unnamedAttribute.name) // Output: nil
    /// ```
    public init(uuid: String? = nil, name: String? = nil)
    {
        self.uuid = uuid
        self.name = name
    }
    
    /// Initializes a `UUAttributeRepresentation` instance from a `CBAttribute`.
    ///
    /// This convenience initializer creates a `UUAttributeRepresentation` using the UUID and a common name
    /// derived from a CoreBluetooth `CBAttribute` descendant object.
    ///
    /// - Parameter attribute: The `CBAttribute` instance to initialize the attribute representation from.
    ///   - The `uuid` property of the descriptor is used as the UUID.
    ///   - The `uuCommonName` of the descriptor's UUID is used as the name, if available.
    ///
    /// - Returns: A newly initialized `UUAttributeRepresentation` instance.
    ///
    /// ## Example Usage
    /// ```swift
    /// if let descriptor = characteristic.descriptors?.first {
    ///     let attribute = UUAttributeRepresentation(from: attribute)
    ///     print(attribute.uuid) // Output: UUID string of the attribute
    ///     print(attribute.name) // Output: Common name derived from the attribute's UUID
    /// }
    /// ```
    ///
    /// ## Notes
    /// - This initializer simplifies the creation of attribute representations when working with CoreBluetooth descriptors.
    /// - The `uuCommonName` is a utility extension that provides a more human-readable name for the descriptor's UUID, if implemented.
    ///
    /// ## Thread Safety
    /// Ensure that the `CBDescriptor` object is accessed on the appropriate CoreBluetooth queue when using this initializer.
    public convenience init(from attribute: CBAttribute)
    {
        self.init(uuid: attribute.uuid.uuidString, name: attribute.uuid.uuCommonName)
    }

    /// Encodes this object into the provided encoder.
    ///
    /// - Parameter encoder: The encoder used to encode the object.
    /// - Throws: An error if encoding fails.
    public func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(name, forKey: .name)
    }

    /// Initializes an instance by decoding from the provided decoder.
    ///
    /// - Parameter decoder: The decoder used to decode the object.
    /// - Throws: An error if decoding fails.
    required public init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uuid = try container.decode(String.self, forKey: .uuid)
        name = try container.decode(String.self, forKey: .name)
    }
}
