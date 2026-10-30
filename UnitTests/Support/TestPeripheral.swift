// Test-only native peripheral bridge (constructed by TestShared/Mocks.swift).
// no Bluetooth manager or hardware connection is created here.
import Foundation
import CoreBluetooth
@testable import UUSwiftBluetooth

class TestPeripheral: UUCBPeripheral
{
    var delegate: (any CBPeripheralDelegate)?
    {
        get
        {
            return backingPeripheral.delegate
        }

        set (val)
        {
            backingPeripheral.delegate = val
        }
    }

    var identifier: UUID
    {
        return backingPeripheral.identifier
    }

    var name: String?
    {
        return backingPeripheral.name
    }

    var state: CBPeripheralState
    {
        return backingPeripheral.state
    }

    var services: [CBService]?
    {
        return backingPeripheral.services
    }

    var canSendWriteWithoutResponse: Bool
    {
        return backingPeripheral.canSendWriteWithoutResponse
    }

#if os(iOS)
    var ancsAuthorized: Bool
    {
        return backingPeripheral.ancsAuthorized
    }
#endif

    var backingPeripheral: CBPeripheral

    // Configuration
    var mockDispatchQueue: DispatchQueue = DispatchQueue(label: "TestPeripheral_DispatchQueue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .inherit, target: nil)

    // Mocked Values

    ///
    /// The mocked GATT database.  Fill Services and Characteristics
    ///
    var mockServices: [CBMutableService] = []

    ///
    /// Number of seconds each api call will delay before returning an async result
    ///
    var mockCallbackTime: TimeInterval = 0.01

    ///
    /// Mock result
    ///
    var mockCallbackError: Error? = nil

    var mockMaximumWriteValueLengths: [CBCharacteristicWriteType:Int] = [.withResponse: 20, .withoutResponse: 20]

    var mockRssi: Int = 0

    var mockL2CapChannel: CBL2CAPChannel? = nil

    // Maintain a single copy of the 'discovered' GATT database
    private var discoveredServices: [CBMutableService] = []

    func mockSetState(_ state: CBPeripheralState)
    {
        backingPeripheral.setValue(NSNumber(integerLiteral: state.rawValue), forKey: "state")
    }

    init(
        identifier: UUID = UUID(),
        name: String = "",
        state: CBPeripheralState = .disconnected,
        services: [CBMutableService]? = nil)
    {
        backingPeripheral = uuMakeCBPeripheral(uuid: identifier, name: name, services: services)!
        mockSetState(state)
    }

    func readRSSI()
    {
        dispatch
        {
            self.delegate?.peripheral?(self.backingPeripheral, didReadRSSI: NSNumber(integerLiteral: self.mockRssi), error: self.mockCallbackError)
        }
    }

    func discoverServices(_ serviceUUIDs: [CBUUID]?)
    {
        dispatch
        {
            if let err = self.mockCallbackError
            {
                self.backingPeripheral.setValue(nil, forKey: "services")
                self.delegate?.peripheral?(self.backingPeripheral, didDiscoverServices: err)
            }
            else
            {
                self.discoveredServices = self.mockServices.map { CBMutableService(type: $0.uuid, primary: $0.isPrimary) }

                // Fill in the services of the backing peripheral with the updated 'discovered' services
                self.backingPeripheral.setValue(self.discoveredServices, forKey: "services")
                self.delegate?.peripheral?(self.backingPeripheral, didDiscoverServices: nil)
            }
        }
    }

    func discoverIncludedServices(_ includedServiceUUIDs: [CBUUID]?, for service: CBService)
    {
        dispatch
        {
            self.delegate?.peripheral?(self.backingPeripheral, didDiscoverIncludedServicesFor: service, error: self.mockCallbackError)
        }
    }

    func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: CBService)
    {
        dispatch
        {
            if let err = self.mockCallbackError
            {
                self.delegate?.peripheral?(self.backingPeripheral, didDiscoverCharacteristicsFor: service, error: err)
            }
            else
            {
                let svc = self.mockServices.first { $0.uuid == service.uuid }

                let chars = svc?.characteristics
                let resultChars = chars?.map {
                    let mc = CBMutableCharacteristic(type: $0.uuid, properties: $0.properties, value: nil, permissions: [])
                    mc.setValue(service, forKey: "service")
                    return mc
                }

                var resultServiceOpt: CBService? = nil

                // Add the 'discovered' chars to the appropriate service
                for svc in self.discoveredServices
                {
                    if svc.uuid == service.uuid
                    {
                        svc.characteristics = resultChars
                        resultServiceOpt = svc
                        break
                    }
                }

                // Fill in the services of the backing peripheral with the updated 'discovered' services
                self.backingPeripheral.setValue(self.discoveredServices, forKey: "services")

                if let resultService = resultServiceOpt
                {
                    self.delegate?.peripheral?(self.backingPeripheral, didDiscoverCharacteristicsFor: resultService, error: nil)
                }
                else
                {
                    self.delegate?.peripheral?(self.backingPeripheral, didDiscoverCharacteristicsFor: service, error: nil)
                }
            }
        }
    }

    func readValue(for characteristic: CBCharacteristic)
    {
        dispatch
        {
            self.delegate?.peripheral?(self.backingPeripheral, didUpdateValueFor: characteristic, error: self.mockCallbackError)
        }
    }

    func maximumWriteValueLength(for type: CBCharacteristicWriteType) -> Int
    {
        return self.mockMaximumWriteValueLengths[type] ?? 0
    }

    func writeValue(_ data: Data, for characteristic: CBCharacteristic, type: CBCharacteristicWriteType)
    {
        dispatch
        {
            self.delegate?.peripheral?(self.backingPeripheral, didWriteValueFor: characteristic, error: self.mockCallbackError)
        }
    }

    func setNotifyValue(_ enabled: Bool, for characteristic: CBCharacteristic)
    {
        dispatch
        {
            self.delegate?.peripheral?(self.backingPeripheral, didUpdateNotificationStateFor: characteristic, error: self.mockCallbackError)
        }
    }

    func discoverDescriptors(for characteristic: CBCharacteristic)
    {
        dispatch
        {
            if let err = self.mockCallbackError
            {
                // Create a charactistic copy with no descriptors
                let mc = CBMutableCharacteristic(type: characteristic.uuid, properties: characteristic.properties, value: characteristic.value, permissions: [])
                mc.setValue(characteristic.service, forKey: "service")

                self.delegate?.peripheral?(self.backingPeripheral, didDiscoverDescriptorsFor: mc, error: err)
            }
            else
            {
                // Find the descriptor list in the source mock Gatt db
                let svc = self.mockServices.first { $0.uuid == characteristic.serviceUUID }
                let char = svc?.characteristics?.first { $0.uuid == characteristic.uuid }

                let descs = char?.descriptors
                let resultDescs = descs?.map {
                    let mc = CBMutableDescriptor(type: $0.uuid, value: $0.value)
                    mc.setValue(char, forKey: "characteristic")
                    return mc
                }

                var resultCharOpt: CBCharacteristic? = nil

                // Add the 'discovered' chars to the appropriate service
                for svc in self.discoveredServices
                {
                    if svc.uuid == characteristic.serviceUUID
                    {
                        for char in svc.characteristics ?? []
                        {
                            if char.uuid == characteristic.uuid
                            {
                                if let mutableChar = char as? CBMutableCharacteristic
                                {
                                    resultCharOpt = mutableChar
                                    mutableChar.descriptors = resultDescs
                                    break
                                }
                            }
                        }
                    }
                }

                // Fill in the services of the backing peripheral with the updated 'discovered' services
                self.backingPeripheral.setValue(self.discoveredServices, forKey: "services")

                if let resultChar = resultCharOpt
                {
                    self.delegate?.peripheral?(self.backingPeripheral, didDiscoverDescriptorsFor: resultChar, error: nil)
                }
                else
                {
                    self.delegate?.peripheral?(self.backingPeripheral, didDiscoverDescriptorsFor: characteristic, error: nil)
                }
            }
        }
    }

    func readValue(for descriptor: CBDescriptor)
    {
        dispatch
        {
            self.delegate?.peripheral?(self.backingPeripheral, didUpdateValueFor: descriptor, error: self.mockCallbackError)
        }
    }

    func writeValue(_ data: Data, for descriptor: CBDescriptor)
    {
        dispatch
        {
            self.delegate?.peripheral?(self.backingPeripheral, didWriteValueFor: descriptor, error: self.mockCallbackError)
        }
    }

    func openL2CAPChannel(_ PSM: CBL2CAPPSM)
    {
        dispatch
        {
            self.delegate?.peripheral?(self.backingPeripheral, didOpen: self.mockL2CapChannel, error: self.mockCallbackError)
        }
    }

    private func dispatch(_ block: @escaping ()->Void)
    {
        mockDispatchQueue.asyncAfter(deadline: .now() + .milliseconds(Int(self.mockCallbackTime * 1000.0)), execute: block)
    }
}
