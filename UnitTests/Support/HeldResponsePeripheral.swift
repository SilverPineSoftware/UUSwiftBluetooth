import CoreBluetooth
@testable import UUSwiftBluetooth

/// Test-only backend: native responses are released by the test, never by sleeps.
/// It uses the test-only native object bridge but bypasses delayed responses.
final class HeldResponsePeripheral: TestPeripheral
{
    var responses: [() -> Void] = []

    func deliverResponses()
    {
        let pending = responses
        responses.removeAll()
        pending.forEach { $0() }
    }

    override func discoverServices(_ serviceUUIDs: [CBUUID]?)
    {
        responses.append { self.delegate?.peripheral?(self.backingPeripheral, didDiscoverServices: nil) }
    }

    override func discoverIncludedServices(_ includedServiceUUIDs: [CBUUID]?, for service: CBService)
    {
        responses.append { self.delegate?.peripheral?(self.backingPeripheral, didDiscoverIncludedServicesFor: service, error: nil) }
    }

    override func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: CBService)
    {
        responses.append { self.delegate?.peripheral?(self.backingPeripheral, didDiscoverCharacteristicsFor: service, error: nil) }
    }

    override func discoverDescriptors(for characteristic: CBCharacteristic)
    {
        responses.append { self.delegate?.peripheral?(self.backingPeripheral, didDiscoverDescriptorsFor: characteristic, error: nil) }
    }

    override func readValue(for characteristic: CBCharacteristic)
    {
        responses.append { self.delegate?.peripheral?(self.backingPeripheral, didUpdateValueFor: characteristic, error: nil) }
    }

    override func readValue(for descriptor: CBDescriptor)
    {
        responses.append { self.delegate?.peripheral?(self.backingPeripheral, didUpdateValueFor: descriptor, error: nil) }
    }

    override func writeValue(_ data: Data, for characteristic: CBCharacteristic, type: CBCharacteristicWriteType)
    {
        responses.append { self.delegate?.peripheral?(self.backingPeripheral, didWriteValueFor: characteristic, error: nil) }
    }

    override func writeValue(_ data: Data, for descriptor: CBDescriptor)
    {
        responses.append { self.delegate?.peripheral?(self.backingPeripheral, didWriteValueFor: descriptor, error: nil) }
    }

    override func setNotifyValue(_ enabled: Bool, for characteristic: CBCharacteristic)
    {
        responses.append { self.delegate?.peripheral?(self.backingPeripheral, didUpdateNotificationStateFor: characteristic, error: nil) }
    }

    override func readRSSI()
    {
        responses.append { self.delegate?.peripheral?(self.backingPeripheral, didReadRSSI: -50, error: nil) }
    }

    override func openL2CAPChannel(_ PSM: CBL2CAPPSM)
    {
        responses.append { self.delegate?.peripheral?(self.backingPeripheral, didOpen: nil, error: nil) }
    }
}
