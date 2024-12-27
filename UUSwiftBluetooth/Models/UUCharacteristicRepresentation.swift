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
/// `UUCharacteristicRepresentation` extends `UUAttributeRepresentation` to model additional information
/// specific to Bluetooth characteristics, including their properties and descriptors.
///
/// ## Overview
/// Bluetooth characteristics define specific pieces of data and how they can be interacted with.
/// This class represents these characteristics in a structured format, making it suitable for
/// tasks such as JSON serialization or debugging.
///
/// ## Properties
/// - `uuid`: The universally unique identifier (UUID) of the characteristic, inherited from `UUAttributeRepresentation`.
/// - `name`: An optional name of the characteristic, inherited from `UUAttributeRepresentation`.
/// - `properties`: A list of strings describing the characteristic's properties, such as "read", "write", or "notify".
/// - `descriptors`: An optional array of `UUDescriptorRepresentation` objects representing the characteristic's descriptors.
///
/// ## Codable
/// This class conforms to `Codable`, enabling it to be easily serialized to and deserialized from JSON.
///
/// ## Example Usage
/// ```swift
/// let descriptor = UUDescriptorRepresentation()
/// descriptor.uuid = "2902"
/// descriptor.name = "Client Characteristic Configuration"
///
/// let characteristic = UUCharacteristicRepresentation()
/// characteristic.uuid = "2A37"
/// characteristic.name = "Heart Rate Measurement"
/// characteristic.properties = ["notify"]
/// characteristic.descriptors = [descriptor]
///
/// // Serialize to JSON
/// let encoder = JSONEncoder()
/// encoder.outputFormatting = .prettyPrinted
/// if let jsonData = try? encoder.encode(characteristic),
///    let jsonString = String(data: jsonData, encoding: .utf8) {
///     print(jsonString)
/// }
///
/// // Deserialize from JSON
/// let jsonString = """
/// {
///   "uuid": "2A37",
///   "name": "Heart Rate Measurement",
///   "properties": ["notify"],
///   "descriptors": [
///     {
///       "uuid": "2902",
///       "name": "Client Characteristic Configuration"
///     }
///   ]
/// }
/// """
/// if let jsonData = jsonString.data(using: .utf8),
///    let decodedCharacteristic = try? JSONDecoder().decode(UUCharacteristicRepresentation.self, from: jsonData) {
///     print(decodedCharacteristic.name) // Output: Heart Rate Measurement
/// }
/// ```
///
/// ## See Also
/// - `UUAttributeRepresentation`
/// - `UUDescriptorRepresentation`
public class UUCharacteristicRepresentation: UUAttributeRepresentation
{
    /// A list of properties associated with the characteristic, such as "read", "write", or "notify".
    public var properties: [String]? = nil

    /// An array of descriptors associated with the characteristic, represented as `UUDescriptorRepresentation`.
    public var descriptors: [UUDescriptorRepresentation]? = nil

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
    public override init(uuid: String? = nil, name: String? = nil)
    {
        super.init(uuid: uuid, name: name)
    }
    
    /// Initializes a `UUCharacteristicRepresentation` instance from a `CBCharacteristic`.
    ///
    /// This convenience initializer creates a `UUCharacteristicRepresentation` using the UUID, properties,
    /// and descriptors of a CoreBluetooth `CBCharacteristic` object.
    ///
    /// - Parameter characteristic: The `CBCharacteristic` instance to initialize the characteristic representation from.
    ///   - The `uuid` property of the characteristic is used as the UUID.
    ///   - The `properties` of the characteristic are mapped to a list of human-readable strings (e.g., "read", "write").
    ///   - The `descriptors` of the characteristic, if available, are converted to an array of `UUDescriptorRepresentation` objects.
    ///
    /// - Returns: A newly initialized `UUCharacteristicRepresentation` instance.
    ///
    /// ## Example Usage
    /// ```swift
    /// if let cbCharacteristic = service.characteristics?.first {
    ///     let characteristicRepresentation = UUCharacteristicRepresentation(from: cbCharacteristic)
    ///     print(characteristicRepresentation.uuid) // UUID string of the characteristic
    ///     print(characteristicRepresentation.properties) // Human-readable properties of the characteristic
    ///     print(characteristicRepresentation.descriptors?.count) // Number of associated descriptors
    /// }
    /// ```
    ///
    /// ## Notes
    /// - This initializer simplifies the process of creating characteristic representations when working with CoreBluetooth.
    /// - The `properties` are derived from the `CBCharacteristic`'s properties using a utility mapping function.
    ///
    /// ## Thread Safety
    /// Ensure that the `CBCharacteristic` object is accessed on the appropriate CoreBluetooth queue when using this initializer.
    public convenience init(from characteristic: CBCharacteristic)
    {
        self.init(uuid: characteristic.uuid.uuidString, name: characteristic.uuid.uuCommonName)
        
        self.properties = characteristic.properties.uuSplitValues
            .compactMap({ props in
                UUCBCharacteristicPropertiesToString(props)
            })
        
        if let descriptors = characteristic.descriptors, !descriptors.isEmpty
        {
            self.descriptors = descriptors.compactMap({ descriptor in
                let d = UUDescriptorRepresentation(from: descriptor)
                return d
            })
        }
    }
    
    /// Internal keys used for encoding and decoding.
    private enum CodingKeys: String, CodingKey
    {
        case properties, descriptors
    }
    
    /// Encodes this object into the provided encoder.
    ///
    /// - Parameter encoder: The encoder used to encode the object.
    /// - Throws: An error if encoding fails.
    public override func encode(to encoder: Encoder) throws
    {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(properties, forKey: .properties)
        try container.encode(descriptors, forKey: .descriptors)
    }

    /// Initializes an instance by decoding from the provided decoder.
    ///
    /// - Parameter decoder: The decoder used to decode the object.
    /// - Throws: An error if decoding fails.
    required public init(from decoder: Decoder) throws
    {
        try super.init(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        properties = try container.decodeIfPresent([String].self, forKey: .properties)
        descriptors = try container.decodeIfPresent([UUDescriptorRepresentation].self, forKey: .descriptors)
    }
}
