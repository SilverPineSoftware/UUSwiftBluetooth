//
//  UUServiceRepresentation.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 12/25/24.
//

import Foundation
import CoreBluetooth

/// A representation of a CoreBluetooth service.
///
/// `UUServiceRepresentation` models a Bluetooth service, providing essential details
/// such as its UUID, name, primary status, included services, and associated characteristics.
/// This class is designed to work with CoreBluetooth and facilitate encoding and decoding
/// as JSON for storage or communication.
///
/// ## Features
/// - Conforms to `Codable` for seamless JSON serialization and deserialization.
/// - Supports initialization from CoreBluetooth's `CBService`.
/// - Includes an optional list of included services and characteristics associated with the service.
///
/// ## Properties
/// - `uuid`: A unique identifier for the service, stored as a string. This is marked as unique using the `@Attribute` property wrapper.
/// - `name`: An optional human-readable name for the service.
/// - `isPrimary`: An optional boolean indicating whether the service is a primary service.
/// - `includedServices`: An optional array of `UUServiceRepresentation` objects representing the included services.
/// - `characteristics`: An optional array of `UUCharacteristicRepresentation` objects representing the service's characteristics.
///
/// ## Initializers
/// - `init(uuid: String, name: String?, isPrimary: Bool?)`: Initializes a new service representation with a UUID, name, and primary status.
/// - `init(from service: CBService)`: Convenience initializer to create a service representation from a CoreBluetooth `CBService`.
/// - `init(from decoder: Decoder)`: Initializes an instance by decoding it from an external representation.
///
/// ## Codable
/// This class conforms to `Codable`, making it easy to serialize into or deserialize from JSON.
///
/// ## Example Usage
/// ```swift
/// // Create a service representation
/// let service = UUServiceRepresentation(
///     uuid: "180D",
///     name: "Heart Rate",
///     isPrimary: true
/// )
///
/// // Encode to JSON
/// let encoder = JSONEncoder()
/// if let jsonData = try? encoder.encode(service),
///    let jsonString = String(data: jsonData, encoding: .utf8)
/// {
///     print(jsonString)
/// }
///
/// // Decode from JSON
/// let jsonString = """
/// {
///   "uuid": "180D",
///   "name": "Heart Rate",
///   "isPrimary": true,
///   "includedServices": [],
///   "characteristics": []
/// }
/// """
/// if let jsonData = jsonString.data(using: .utf8),
///    let decodedService = try? JSONDecoder().decode(UUServiceRepresentation.self, from: jsonData)
/// {
///     print(decodedService.name ?? "No name")
/// }
/// ```
///
/// ## See Also
/// - `CBService`
/// - `UUCharacteristicRepresentation`
final public class UUServiceRepresentation: Codable
{
    /// A unique identifier for the service.
    public var uuid: String = ""

    /// An optional human-readable name for the service.
    public var name: String? = nil

    /// An optional boolean indicating whether the service is primary.
    public var isPrimary: Bool? = nil

    /// An optional list of included services for this service.
    public var includedServices: [UUServiceRepresentation]? = nil

    /// An optional list of characteristics associated with this service.
    public var characteristics: [UUCharacteristicRepresentation]? = nil

    /// Initializes a new service representation with the specified properties.
    /// - Parameters:
    ///   - uuid: The unique identifier for the service.
    ///   - name: An optional human-readable name.
    ///   - isPrimary: An optional boolean indicating whether the service is primary.
    public init(uuid: String, name: String? = nil, isPrimary: Bool? = nil)
    {
        self.uuid = uuid
        self.name = name
        self.isPrimary = isPrimary
    }

    /// Convenience initializer to create a service representation from a CoreBluetooth `CBService`.
    /// - Parameter service: A `CBService` object from CoreBluetooth.
    public convenience init(from service: CBService)
    {
        self.init(uuid: service.uuid.uuidString, name: service.uuid.uuCommonName, isPrimary: service.isPrimary)

        if let list = service.includedServices, !list.isEmpty
        {
            self.includedServices = list.compactMap { UUServiceRepresentation(from: $0) }
        }

        if let list = service.characteristics, !list.isEmpty
        {
            self.characteristics = list.compactMap { UUCharacteristicRepresentation(from: $0) }
        }
    }

    /// Internal keys used for encoding and decoding.
    private enum CodingKeys: String, CodingKey
    {
        case uuid, name, isPrimary, includedServices, characteristics
    }

    /// Encodes the service representation into the given encoder.
    /// - Parameter encoder: The encoder to write data to.
    /// - Throws: An error if encoding fails.
    public func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(name, forKey: .name)
        try container.encode(isPrimary, forKey: .isPrimary)
        try container.encode(includedServices, forKey: .includedServices)
        try container.encode(characteristics, forKey: .characteristics)
    }

    /// Initializes a service representation by decoding it from the given decoder.
    /// - Parameter decoder: The decoder to read data from.
    /// - Throws: An error if decoding fails or required fields are missing.
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uuid = try container.decode(String.self, forKey: .uuid)
        name = try container.decode(String.self, forKey: .name)
        isPrimary = try container.decodeIfPresent(Bool.self, forKey: .isPrimary)
        includedServices = try container.decodeIfPresent([UUServiceRepresentation].self, forKey: .includedServices)
        characteristics = try container.decodeIfPresent([UUCharacteristicRepresentation].self, forKey: .characteristics)
    }
}
