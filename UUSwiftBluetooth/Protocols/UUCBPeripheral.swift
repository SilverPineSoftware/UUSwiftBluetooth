//
//  UUCBPeripheral.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 7/4/25.
//

import Foundation
import CoreBluetooth



/// Protocol wrapping public interface of CBPeripheral
public protocol UUCBPeripheral: UUCBPeer
{
    /**
     *  @property delegate
     *
     *  @discussion The delegate object that will receive peripheral events.
     */
    var delegate: (any CBPeripheralDelegate)? { get set }

    /**
     *  @property name
     *
     *  @discussion The name of the peripheral.
     */
    var name: String? { get }

//    /**
//     *  @property RSSI
//     *
//     *  @discussion The most recently read RSSI, in decibels.
//     *
//     *  @deprecated Use {@link peripheral:didReadRSSI:error:} instead.
//     */
//    @available(iOS, introduced: 5.0, deprecated: 8.0)
//    open var rssi: NSNumber? { get }

    /**
     *  @property state
     *
     *  @discussion The current connection state of the peripheral.
     */
    var state: CBPeripheralState { get }

    /**
     *  @property services
     *
     *  @discussion A list of <code>CBService</code> objects that have been discovered on the peripheral.
     */
    var services: [CBService]? { get }

    /**
     *  @property canSendWriteWithoutResponse
     *
     *  @discussion YES if the remote device has space to send a write without response. If this value is NO,
     *                the value will be set to YES after the current writes have been flushed, and
     *                <link>peripheralIsReadyToSendWriteWithoutResponse:</link> will be called.
     */
    // @available(iOS 11.0, *)
    var canSendWriteWithoutResponse: Bool { get }

    /**
     *  @property ancsAuthorized
     *
     *  @discussion YES if the remote device has been authorized to receive data over ANCS (Apple Notification Service Center) protocol.  If this value is NO,
     *                the value will be set to YES after a user authorization occurs and
     *                <link>didUpdateANCSAuthorizationForPeripheral:</link> will be called.
     */
    //@available(iOS 13.0, *)
    var ancsAuthorized: Bool { get }

    /**
     *  @method readRSSI
     *
     *  @discussion While connected, retrieves the current RSSI of the link.
     *
     *  @see        peripheral:didReadRSSI:error:
     */
    func readRSSI()

    /**
     *  @method discoverServices:
     *
     *  @param serviceUUIDs A list of <code>CBUUID</code> objects representing the service types to be discovered. If <i>nil</i>,
     *                        all services will be discovered.
     *
     *  @discussion            Discovers available service(s) on the peripheral.
     *
     *  @see                peripheral:didDiscoverServices:
     */
    func discoverServices(_ serviceUUIDs: [CBUUID]?)

    /**
     *  @method discoverIncludedServices:forService:
     *
     *  @param includedServiceUUIDs A list of <code>CBUUID</code> objects representing the included service types to be discovered. If <i>nil</i>,
     *                                all of <i>service</i>s included services will be discovered, which is considerably slower and not recommended.
     *  @param service                A GATT service.
     *
     *  @discussion                    Discovers the specified included service(s) of <i>service</i>.
     *
     *  @see                        peripheral:didDiscoverIncludedServicesForService:error:
     */
    func discoverIncludedServices(_ includedServiceUUIDs: [CBUUID]?, for service: CBService)

    /**
     *  @method discoverCharacteristics:forService:
     *
     *  @param characteristicUUIDs    A list of <code>CBUUID</code> objects representing the characteristic types to be discovered. If <i>nil</i>,
     *                                all characteristics of <i>service</i> will be discovered.
     *  @param service                A GATT service.
     *
     *  @discussion                    Discovers the specified characteristic(s) of <i>service</i>.
     *
     *  @see                        peripheral:didDiscoverCharacteristicsForService:error:
     */
    func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: CBService)

    /**
     *  @method readValueForCharacteristic:
     *
     *  @param characteristic    A GATT characteristic.
     *
     *  @discussion                Reads the characteristic value for <i>characteristic</i>.
     *
     *  @see                    peripheral:didUpdateValueForCharacteristic:error:
     */
    func readValue(for characteristic: CBCharacteristic)

    /**
     *  @method        maximumWriteValueLengthForType:
     *
     *  @discussion    The maximum amount of data, in bytes, that can be sent to a characteristic in a single write type.
     *
     *  @see        writeValue:forCharacteristic:type:
     */
    //@available(iOS 9.0, *)
    func maximumWriteValueLength(for type: CBCharacteristicWriteType) -> Int

    /**
     *  @method writeValue:forCharacteristic:type:
     *
     *  @param data                The value to write.
     *  @param characteristic    The characteristic whose characteristic value will be written.
     *  @param type                The type of write to be executed.
     *
     *  @discussion                Writes <i>value</i> to <i>characteristic</i>'s characteristic value.
     *                            If the <code>CBCharacteristicWriteWithResponse</code> type is specified, {@link peripheral:didWriteValueForCharacteristic:error:}
     *                            is called with the result of the write request.
     *                            If the <code>CBCharacteristicWriteWithoutResponse</code> type is specified, and canSendWriteWithoutResponse is false, the delivery
     *                             of the data is best-effort and may not be guaranteed.
     *
     *  @see                    peripheral:didWriteValueForCharacteristic:error:
     *  @see                    peripheralIsReadyToSendWriteWithoutResponse:
     *    @see                    canSendWriteWithoutResponse
     *    @see                    CBCharacteristicWriteType
     */
    func writeValue(_ data: Data, for characteristic: CBCharacteristic, type: CBCharacteristicWriteType)

    /**
     *  @method setNotifyValue:forCharacteristic:
     *
     *  @param enabled            Whether or not notifications/indications should be enabled.
     *  @param characteristic    The characteristic containing the client characteristic configuration descriptor.
     *
     *  @discussion                Enables or disables notifications/indications for the characteristic value of <i>characteristic</i>. If <i>characteristic</i>
     *                            allows both, notifications will be used.
     *                          When notifications/indications are enabled, updates to the characteristic value will be received via delegate method
     *                          @link peripheral:didUpdateValueForCharacteristic:error: @/link. Since it is the peripheral that chooses when to send an update,
     *                          the application should be prepared to handle them as long as notifications/indications remain enabled.
     *
     *  @see                    peripheral:didUpdateNotificationStateForCharacteristic:error:
     *  @seealso                CBConnectPeripheralOptionNotifyOnNotificationKey
     */
    func setNotifyValue(_ enabled: Bool, for characteristic: CBCharacteristic)

    /**
     *  @method discoverDescriptorsForCharacteristic:
     *
     *  @param characteristic    A GATT characteristic.
     *
     *  @discussion                Discovers the characteristic descriptor(s) of <i>characteristic</i>.
     *
     *  @see                    peripheral:didDiscoverDescriptorsForCharacteristic:error:
     */
    func discoverDescriptors(for characteristic: CBCharacteristic)

    /**
     *  @method readValueForDescriptor:
     *
     *  @param descriptor    A GATT characteristic descriptor.
     *
     *  @discussion            Reads the value of <i>descriptor</i>.
     *
     *  @see                peripheral:didUpdateValueForDescriptor:error:
     */
    func readValue(for descriptor: CBDescriptor)

    /**
     *  @method writeValue:forDescriptor:
     *
     *  @param data            The value to write.
     *  @param descriptor    A GATT characteristic descriptor.
     *
     *  @discussion            Writes <i>data</i> to <i>descriptor</i>'s value. Client characteristic configuration descriptors cannot be written using
     *                        this method, and should instead use @link setNotifyValue:forCharacteristic: @/link.
     *
     *  @see                peripheral:didWriteValueForCharacteristic:error:
     */
    func writeValue(_ data: Data, for descriptor: CBDescriptor)

    /**
     *  @method openL2CAPChannel:
     *
     *  @param PSM            The PSM of the channel to open
     *
     *  @discussion            Attempt to open an L2CAP channel to the peripheral using the supplied PSM.
     *
     *  @see                peripheral:didWriteValueForCharacteristic:error:
     */
    //@available(iOS 11.0, *)
    func openL2CAPChannel(_ PSM: CBL2CAPPSM)
    
    
    
    func discoverIncludedServices(_ includedServiceUUIDs: [CBUUID]?, _ service: UUCBService) -> Error?
    func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, _ service: UUCBService) -> Error?
    func discoverDescriptors(_ characteristic: UUCBCharacteristic) -> Error?
    
    func setNotifyValue(_ enabled: Bool, for characteristic: any UUCBCharacteristic) -> Error?
    func readValue(_ characteristic: any UUCBCharacteristic) -> Error?
    func readValue(_ descriptor: any UUCBDescriptor) -> Error?
    func writeCharacteristicValue(_ data: Data, _ characteristic: UUCBCharacteristic, _ type: CBCharacteristicWriteType) -> Error?
    func writeDescriptorValue(_ data: Data, _ descriptor: UUCBDescriptor) -> Error?
    
}

public extension UUCBPeripheral
{
    func findService(_ serviceUUID: CBUUID) -> CBService?
    {
        return services?.first { $0.uuid == serviceUUID }
    }
    
    func findCharacteristic(_ serviceUUID: CBUUID, _ characteristicUUID: CBUUID) -> CBCharacteristic?
    {
        return findService(serviceUUID)?.characteristics?.first { $0.uuid == characteristicUUID }
    }
    
    func findDescriptor(_ serviceUUID: CBUUID, _ characteristicUUID: CBUUID, _ descriptorUUID: CBUUID) -> CBDescriptor?
    {
        guard let characteristic = findCharacteristic(serviceUUID, characteristicUUID) else
        {
            return nil
        }
        
        return characteristic.descriptors?.first { $0.uuid == descriptorUUID }
    }
    
    func findCharacteristic(_ characteristic: any UUCBCharacteristic) -> CBCharacteristic?
    {
        guard let serviceUUID = characteristic.serviceUUID else
        {
            return nil
        }
        
        return findCharacteristic(serviceUUID, characteristic.uuid)
    }
    
    func findDescriptor(_ descriptor: any UUCBDescriptor) -> CBDescriptor?
    {
        guard let serviceUUID = descriptor.characteristic?.serviceUUID else
        {
            return nil
        }
        
        guard let characteristicUUID = descriptor.characteristicUUID else
        {
            return nil
        }
        
        return findDescriptor(serviceUUID, characteristicUUID, descriptor.uuid)
    }
}

/**
 Provide default conformance of UU specific extensions to CBPeripehral
 */
public extension UUCBPeripheral // Default Implementations
{
    func discoverIncludedServices(_ includedServiceUUIDs: [CBUUID]?, _ service: any UUCBService) -> (any Error)?
    {
        guard let cbService = self.findService(service.uuid) else
        {
            return NSError.uuRequiredServiceNotFoundError(service.uuid)
        }
        
        discoverIncludedServices(includedServiceUUIDs, for: cbService)
        return nil
    }
    
    func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, _ service: any UUCBService) -> (any Error)?
    {
        guard let cbService = self.findService(service.uuid) else
        {
            return NSError.uuRequiredServiceNotFoundError(service.uuid)
        }
        
        discoverCharacteristics(characteristicUUIDs, for: cbService)
        return nil
    }
    
    func discoverDescriptors(_ characteristic: any UUCBCharacteristic) -> (any Error)?
    {
        guard let cbCharacteristic = self.findCharacteristic(characteristic) else
        {
            return NSError.uuRequiredCharacteristicNotFoundError(characteristic.uuid)
        }
        
        discoverDescriptors(for: cbCharacteristic)
        return nil
    }
    
    func setNotifyValue(_ enabled: Bool, for characteristic: any UUCBCharacteristic) -> (any Error)?
    {
        guard let cbCharacteristic = self.findCharacteristic(characteristic) else
        {
            return NSError.uuRequiredCharacteristicNotFoundError(characteristic.uuid)
        }
        
        setNotifyValue(enabled, for: cbCharacteristic)
        return nil
    }
    
    func readValue(_ characteristic: any UUCBCharacteristic) -> Error?
    {
        guard let cbCharacteristic = self.findCharacteristic(characteristic) else
        {
            return NSError.uuRequiredCharacteristicNotFoundError(characteristic.uuid)
        }
        
        readValue(for: cbCharacteristic)
        return nil
    }
    
    func readValue(_ descriptor: any UUCBDescriptor) -> (any Error)?
    {
        guard let cbDescriptor = self.findDescriptor(descriptor) else
        {
            return NSError.uuRequiredDescriptorNotFoundError(descriptor.uuid)
        }
        
        readValue(for: cbDescriptor)
        return nil
    }
    
    func writeCharacteristicValue(_ data: Data, _ characteristic: any UUCBCharacteristic, _ type: CBCharacteristicWriteType) -> (any Error)?
    {
        guard let cbCharacteristic = self.findCharacteristic(characteristic) else
        {
            return NSError.uuRequiredCharacteristicNotFoundError(characteristic.uuid)
        }
        
        writeValue(data, for: cbCharacteristic, type: type)
        return nil
    }
    
    func writeDescriptorValue(_ data: Data, _ descriptor: any UUCBDescriptor) -> (any Error)?
    {
        guard let cbDescriptor = self.findDescriptor(descriptor) else
        {
            return NSError.uuRequiredDescriptorNotFoundError(descriptor.uuid)
        }
        
        writeValue(data, for: cbDescriptor)
        return nil
    }
}



extension CBPeripheral: UUCBPeripheral
{
    
}
