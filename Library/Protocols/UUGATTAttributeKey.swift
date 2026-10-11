import CoreBluetooth

// UUID paths identify attributes within a peripheral, not repeated instances
// with identical paths. Keep callback, subscription, timer, and token keys aligned.
internal extension UUCBCharacteristic
{
    var uuAttributeKey: String
    {
        "\(serviceUUID?.uuidString ?? "_")/\(uuid.uuidString)"
    }
}

internal extension UUCBDescriptor
{
    var uuAttributeKey: String
    {
        "\(characteristic?.serviceUUID?.uuidString ?? "_")/\(characteristicUUID?.uuidString ?? "_")/\(uuid.uuidString)"
    }
}
