import CoreBluetooth
@testable import UUSwiftBluetooth

final class LateResponsePeripheral: TestPeripheral
{
    var responses: [(Error?) -> Void] = []

    func deliverResponses()
    {
        let pending = responses
        responses.removeAll()
        pending.forEach { $0(nil) }
    }

    override func discoverServices(_ serviceUUIDs: [CBUUID]?)
    {
        responses.append { error in self.delegate?.peripheral?(self.backingPeripheral, didDiscoverServices: error) }
    }

    override func discoverIncludedServices(_ includedServiceUUIDs: [CBUUID]?, for service: CBService)
    {
        responses.append { error in self.delegate?.peripheral?(self.backingPeripheral, didDiscoverIncludedServicesFor: service, error: error) }
    }

    override func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: CBService)
    {
        responses.append { error in self.delegate?.peripheral?(self.backingPeripheral, didDiscoverCharacteristicsFor: service, error: error) }
    }

    override func discoverDescriptors(for characteristic: CBCharacteristic)
    {
        responses.append { error in self.delegate?.peripheral?(self.backingPeripheral, didDiscoverDescriptorsFor: characteristic, error: error) }
    }

    override func readValue(for characteristic: CBCharacteristic)
    {
        responses.append { error in self.delegate?.peripheral?(self.backingPeripheral, didUpdateValueFor: characteristic, error: error) }
    }

    override func readValue(for descriptor: CBDescriptor)
    {
        responses.append { error in self.delegate?.peripheral?(self.backingPeripheral, didUpdateValueFor: descriptor, error: error) }
    }

    override func writeValue(_ data: Data, for characteristic: CBCharacteristic, type: CBCharacteristicWriteType)
    {
        responses.append { error in self.delegate?.peripheral?(self.backingPeripheral, didWriteValueFor: characteristic, error: error) }
    }

    override func writeValue(_ data: Data, for descriptor: CBDescriptor)
    {
        responses.append { error in self.delegate?.peripheral?(self.backingPeripheral, didWriteValueFor: descriptor, error: error) }
    }

    override func setNotifyValue(_ enabled: Bool, for characteristic: CBCharacteristic)
    {
        responses.append { error in self.delegate?.peripheral?(self.backingPeripheral, didUpdateNotificationStateFor: characteristic, error: error) }
    }

    override func readRSSI()
    {
        responses.append { error in self.delegate?.peripheral?(self.backingPeripheral, didReadRSSI: -50, error: error) }
    }

    override func openL2CAPChannel(_ PSM: CBL2CAPPSM)
    {
        responses.append { error in self.delegate?.peripheral?(self.backingPeripheral, didOpen: nil, error: error) }
    }
}

