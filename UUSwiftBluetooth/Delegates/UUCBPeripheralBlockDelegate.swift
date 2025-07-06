//
//  UUPeripheralDelegate.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 8/13/21.
//

import Foundation
import CoreBluetooth
import UUSwiftCore

fileprivate let LOG_TAG = "UUCBPeripheralBlockDelegate"

public typealias UUCBPeripheralBlock = ((CBPeripheral)->())
public typealias UUCBPeripheralErrorBlock = ((CBPeripheral, Error?)->())
public typealias UUCBPeripheralServiceErrorBlock = ((CBPeripheral, CBService, Error?)->())
public typealias UUCBPeripheralCharacteristicErrorBlock = ((CBPeripheral, CBCharacteristic, Error?)->())
public typealias UUCBPeripheralDescriptorErrorBlock = ((CBPeripheral, CBDescriptor, Error?)->())
public typealias UUCBPeripheralIntErrorBlock = ((CBPeripheral, Int, Error?)->())
public typealias UUCBPeripheralServiceListBlock = ((CBPeripheral, [CBService])->())
public typealias UUCBL2CapChannelOpenedBlock = ((CBPeripheral, CBL2CAPChannel?, Error?)->())


public class UUCBPeripheralBlockDelegate: NSObject, CBPeripheralDelegate
{
    // ////////////////////////////////////////////////////////////////////////////////////////////
    // MARK: Private member variables
    // ////////////////////////////////////////////////////////////////////////////////////////////
    
    public var peripheralNameUpdatedBlock: UUCBPeripheralBlock? = nil
    public var didModifyServicesBlock: UUCBPeripheralServiceListBlock? = nil
    public var didReadRssiBlock: UUObjectErrorBlock<Int>? = nil
    public var discoverServicesBlock: UUListErrorBlock<CBService>? = nil
    public var discoverIncludedServicesBlock: UUListErrorBlock<CBService>? = nil
    public var discoverCharacteristicsBlock: UUListErrorBlock<CBCharacteristic>? = nil
    public var discoverDescriptorsBlock: UUListErrorBlock<CBDescriptor>? = nil
    public var setNotifyValueForCharacteristicBlock: UUErrorBlock? = nil
    
    internal var updateValueForCharacteristicBlocks: [String:UUObjectErrorBlock<Data>] = [:]
    internal var readValueForCharacteristicBlocks: [String:UUObjectErrorBlock<Data>] = [:]
    internal var writeValueForCharacteristicBlocks: [String:UUErrorBlock] = [:]
    internal var readValueForDescriptorBlocks: [String:UUObjectErrorBlock<Any>] = [:]
    internal var writeValueForDescriptorBlocks: [String:UUErrorBlock] = [:]
    
    
    private var didOpenL2ChannelBlock: UUCBL2CapChannelOpenedBlock? = nil
    
    // ////////////////////////////////////////////////////////////////////////////////////////////
    // MARK: Public methods
    // ////////////////////////////////////////////////////////////////////////////////////////////
    
    public func clearBlocks()
    {
        peripheralNameUpdatedBlock = nil
        didModifyServicesBlock = nil
        didReadRssiBlock = nil
        discoverServicesBlock = nil
        discoverIncludedServicesBlock = nil
        discoverCharacteristicsBlock = nil
        discoverDescriptorsBlock = nil
        setNotifyValueForCharacteristicBlock = nil
        
        updateValueForCharacteristicBlocks.removeAll()
        readValueForCharacteristicBlocks.removeAll()
        writeValueForCharacteristicBlocks.removeAll()
        readValueForDescriptorBlocks.removeAll()
        writeValueForDescriptorBlocks.removeAll()
        
        
        
        didOpenL2ChannelBlock = nil
    }
    
    public func logBlocks()
    {
        UULog.debug(tag: LOG_TAG, message: "peripheralNameUpdatedBlock: \(String(describing: peripheralNameUpdatedBlock))")
        UULog.debug(tag: LOG_TAG, message: "didModifyServicesBlock: \(String(describing: didModifyServicesBlock))")
        UULog.debug(tag: LOG_TAG, message: "didReadRssiBlock: \(String(describing: didReadRssiBlock))")
        UULog.debug(tag: LOG_TAG, message: "discoverServicesBlock: \(String(describing: discoverServicesBlock))")
        UULog.debug(tag: LOG_TAG, message: "discoverIncludedServicesBlock: \(String(describing: discoverIncludedServicesBlock))")
        UULog.debug(tag: LOG_TAG, message: "discoverCharacteristicsBlock: \(String(describing: discoverCharacteristicsBlock))")
        UULog.debug(tag: LOG_TAG, message: "updateValueForCharacteristicBlocks: \(String(describing: updateValueForCharacteristicBlocks))")
        UULog.debug(tag: LOG_TAG, message: "readValueForCharacteristicBlocks: \(String(describing: readValueForCharacteristicBlocks))")
        UULog.debug(tag: LOG_TAG, message: "writeValueForCharacteristicBlocks: \(String(describing: writeValueForCharacteristicBlocks))")
        UULog.debug(tag: LOG_TAG, message: "readValueForDescriptorBlocks: \(String(describing: readValueForDescriptorBlocks))")
        UULog.debug(tag: LOG_TAG, message: "writeValueForDescriptorBlocks: \(String(describing: writeValueForDescriptorBlocks))")
        UULog.debug(tag: LOG_TAG, message: "setNotifyValueForCharacteristicBlock: \(String(describing: setNotifyValueForCharacteristicBlock))")
        UULog.debug(tag: LOG_TAG, message: "discoverDescriptorsBlock: \(String(describing: discoverDescriptorsBlock))")
        UULog.debug(tag: LOG_TAG, message: "didOpenL2ChannelBlock: \(String(describing: didOpenL2ChannelBlock))")
    }

    public func registerDidOpenL2CAPChannelHandler(_ handler: UUCBL2CapChannelOpenedBlock?)
    {
        didOpenL2ChannelBlock = handler
    }
    
    public func clearDidOpenL2CAPChannelHandler()
    {
        didOpenL2ChannelBlock = nil
    }
    
    public func registerUpdateHandler(
        for characteristic: CBCharacteristic,
        handler: UUObjectErrorBlock<Data>?)
    {
        UULog.verbose(tag: LOG_TAG, message: "Adding Update Handler for \(characteristic.uuid.uuCommonName) - \(characteristic.uuid.uuidString)")
        updateValueForCharacteristicBlocks[characteristic.uuid.uuidString] = handler
    }

    public func removeUpdateHandlerForCharacteristic(_ characteristic: CBCharacteristic)
    {
        UULog.verbose(tag: LOG_TAG, message: "Removing Update Handler for \(characteristic.uuid.uuCommonName) - \(characteristic.uuid.uuidString)")
        updateValueForCharacteristicBlocks.removeValue(forKey: characteristic.uuid.uuidString)
    }

    public func registerReadHandler(
        for characteristic: CBCharacteristic,
        handler: UUObjectErrorBlock<Data>?)
    {
        UULog.verbose(tag: LOG_TAG, message: "Adding Read Handler for \(characteristic.uuid.uuCommonName) - \(characteristic.uuid.uuidString)")
        readValueForCharacteristicBlocks[characteristic.uuid.uuidString] = handler
    }

    public func removeReadHandler(
        for characteristic: CBCharacteristic)
    {
        UULog.verbose(tag: LOG_TAG, message: "Removing Read Handler for \(characteristic.uuid.uuCommonName) - \(characteristic.uuid.uuidString)")
        readValueForCharacteristicBlocks.removeValue(forKey: characteristic.uuid.uuidString)
    }

    public func registerWriteHandler(
        for characteristic: CBCharacteristic,
        handler: UUErrorBlock?)
    {
        writeValueForCharacteristicBlocks[characteristic.uuid.uuidString] = handler
    }

    public func removeWriteHandler(for characteristic: CBCharacteristic)
    {
        writeValueForCharacteristicBlocks.removeValue(forKey: characteristic.uuid.uuidString)
    }

    public func registerReadHandler(
        for descriptor: CBDescriptor,
        handler: UUObjectErrorBlock<Any>?)
    {
        readValueForDescriptorBlocks[descriptor.uuid.uuidString] = handler
    }

    public func removeReadHandler(for descriptor: CBDescriptor)
    {
        readValueForDescriptorBlocks.removeValue(forKey: descriptor.uuid.uuidString)
    }

    public func registerWriteHandler(for descriptor: CBDescriptor, handler: UUErrorBlock?)
    {
        writeValueForDescriptorBlocks[descriptor.uuid.uuidString] = handler
    }

    public func removeWriteHandler(for descriptor: CBDescriptor)
    {
        writeValueForDescriptorBlocks.removeValue(forKey: descriptor.uuid.uuidString)
    }
    
    // ////////////////////////////////////////////////////////////////////////////////////////////
    // MARK: CBPeripheralDelegate methods
    // ////////////////////////////////////////////////////////////////////////////////////////////
    
    public func peripheralDidUpdateName(_ peripheral: CBPeripheral)
    {
        // Don't clear this one because it's an async event not invoked in direct response to a method call.
        peripheralNameUpdatedBlock?(peripheral)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService])
    {
        // Don't clear this one because it's an async event not invoked in direct response to a method call.
        didModifyServicesBlock?(peripheral, invalidatedServices)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?)
    {
        let block = didReadRssiBlock
        didReadRssiBlock = nil
        block?(RSSI.intValue, error)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?)
    {
        let block = discoverServicesBlock
        discoverServicesBlock = nil
        block?(peripheral.services, error)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?)
    {
        let block = discoverIncludedServicesBlock
        discoverIncludedServicesBlock = nil
        
        let updatedService = peripheral.services?.first { $0.uuid == service.uuid }
        
        block?(updatedService?.includedServices, error)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?)
    {
        let block = discoverCharacteristicsBlock
        discoverCharacteristicsBlock = nil
        block?(service.characteristics, error)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?)
    {
        let key = characteristic.uuid.uuidString
        if let updateBlock = updateValueForCharacteristicBlocks[key]
        {
            UULog.verbose(tag: LOG_TAG, message: "Invoking Update Block for \(characteristic.uuid.uuCommonName) - \(characteristic.uuid.uuidString)")
            // Do not clear the block because updates can come in async
            updateBlock(characteristic.value, error)
        }
        
        if let readBlock = readValueForCharacteristicBlocks[key]
        {
            UULog.verbose(tag: LOG_TAG, message: "Invoking Read Block for \(characteristic.uuid.uuCommonName) - \(characteristic.uuid.uuidString)")
            removeReadHandler(for: characteristic)
            readBlock(characteristic.value, error)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?)
    {
        if let writeBlock = writeValueForCharacteristicBlocks[characteristic.uuid.uuidString]
        {
            removeWriteHandler(for: characteristic)
            writeBlock(error)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?)
    {
        let block = setNotifyValueForCharacteristicBlock
        setNotifyValueForCharacteristicBlock = nil
        block?(error)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?)
    {
        let block = discoverDescriptorsBlock
        discoverDescriptorsBlock = nil
        block?(characteristic.descriptors, error)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?)
    {
        if let readBlock = readValueForDescriptorBlocks[descriptor.uuid.uuidString]
        {
            removeReadHandler(for: descriptor)
            readBlock(descriptor.value, error)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?)
    {
        if let writeBlock = writeValueForDescriptorBlocks[descriptor.uuid.uuidString]
        {
            removeWriteHandler(for: descriptor)
            writeBlock(error)
        }
    }
    
    /**
     *  @method peripheralIsReadyToSendWriteWithoutResponse:
     *
     *  @param peripheral   The peripheral providing this update.
     *
     *  @discussion         This method is invoked after a failed call to @link writeValue:forCharacteristic:type: @/link, when <i>peripheral</i> is again
     *                      ready to send characteristic value updates.
     *
     */
//    public func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral)
//    {
//     // TODO: implement this
//    }
    
    public func peripheral(_ peripheral: CBPeripheral, didOpen channel: CBL2CAPChannel?, error: Error?)
    {
        didOpenL2ChannelBlock?(peripheral, channel, error)
    }
}
