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



public typealias UUListErrorBlock<T> = (([T]?, Error?) -> Void)

public class UUCBPeripheralBlockDelegate: NSObject, CBPeripheralDelegate
{
    // ////////////////////////////////////////////////////////////////////////////////////////////
    // MARK: Private member variables
    // ////////////////////////////////////////////////////////////////////////////////////////////
    
    private var peripheralNameUpdatedBlock: UUCBPeripheralBlock? = nil
    private var didModifyServicesBlock: UUCBPeripheralServiceListBlock? = nil
    private var didReadRssiBlock: UUCBPeripheralIntErrorBlock? = nil
    private var discoverServicesBlock: UUListErrorBlock<CBService>? = nil
    private var discoverIncludedServicesBlock: UUCBPeripheralServiceErrorBlock? = nil
    private var discoverCharacteristicsBlock: UUCBPeripheralServiceErrorBlock? = nil
    private var updateValueForCharacteristicBlocks: [String:UUCBPeripheralCharacteristicErrorBlock] = [:]
    private var readValueForCharacteristicBlocks: [String:UUCBPeripheralCharacteristicErrorBlock] = [:]
    private var writeValueForCharacteristicBlocks: [String:UUCBPeripheralCharacteristicErrorBlock] = [:]
    private var updateValueForDescriptorBlocks: [String:UUCBPeripheralDescriptorErrorBlock] = [:]
    private var readValueForDescriptorBlocks: [String:UUCBPeripheralDescriptorErrorBlock] = [:]
    private var writeValueForDescriptorBlocks: [String:UUCBPeripheralDescriptorErrorBlock] = [:]
    private var setNotifyValueForCharacteristicBlock: UUCBPeripheralCharacteristicErrorBlock? = nil
    private var discoverDescriptorsBlock: UUCBPeripheralCharacteristicErrorBlock? = nil
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
        updateValueForCharacteristicBlocks.removeAll()
        readValueForCharacteristicBlocks.removeAll()
        writeValueForCharacteristicBlocks.removeAll()
        updateValueForDescriptorBlocks.removeAll()
        readValueForDescriptorBlocks.removeAll()
        writeValueForDescriptorBlocks.removeAll()
        setNotifyValueForCharacteristicBlock = nil
        discoverDescriptorsBlock = nil
        
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
        UULog.debug(tag: LOG_TAG, message: "updateValueForDescriptorBlocks: \(String(describing: updateValueForDescriptorBlocks))")
        UULog.debug(tag: LOG_TAG, message: "readValueForDescriptorBlocks: \(String(describing: readValueForDescriptorBlocks))")
        UULog.debug(tag: LOG_TAG, message: "writeValueForDescriptorBlocks: \(String(describing: writeValueForDescriptorBlocks))")
        UULog.debug(tag: LOG_TAG, message: "setNotifyValueForCharacteristicBlock: \(String(describing: setNotifyValueForCharacteristicBlock))")
        UULog.debug(tag: LOG_TAG, message: "discoverDescriptorsBlock: \(String(describing: discoverDescriptorsBlock))")
        UULog.debug(tag: LOG_TAG, message: "didOpenL2ChannelBlock: \(String(describing: didOpenL2ChannelBlock))")
    }
    
    public func registerNameUpdateHandler(_ handler: UUCBPeripheralBlock?)
    {
        peripheralNameUpdatedBlock = handler
    }
    
    public func clearNameUpdateHandler()
    {
        peripheralNameUpdatedBlock = nil
    }
    
    public func registerDiscoverServicesHandler(_ handler: UUListErrorBlock<CBService>?)
    {
        discoverServicesBlock = handler
    }
    
    public func clearDiscoverServicesHandler()
    {
        discoverServicesBlock = nil
    }
    
    public func registerDiscoverCharacteristicsHandler(_ handler: UUCBPeripheralServiceErrorBlock?)
    {
        discoverCharacteristicsBlock = handler
    }
    
    public func clearDiscoverCharacteristicsHandler()
    {
        discoverCharacteristicsBlock = nil
    }
    
    public func registerDiscoverIncludedServicesHandler(_ handler: UUCBPeripheralServiceErrorBlock?)
    {
        discoverIncludedServicesBlock = handler
    }
    
    public func clearDiscoverIncludedServicesHandler()
    {
        discoverIncludedServicesBlock = nil
    }
    
    public func registerDiscoverDescriptorsHandler(_ handler: UUCBPeripheralCharacteristicErrorBlock?)
    {
        discoverDescriptorsBlock = handler
    }
    
    public func clearDiscoverDescriptorsHandler()
    {
        discoverDescriptorsBlock = nil
    }
    
    public func registerSetNotifyValueHandler(_ handler: UUCBPeripheralCharacteristicErrorBlock?)
    {
        setNotifyValueForCharacteristicBlock = handler
    }
    
    public func clearSetNotifyValueHandler()
    {
        setNotifyValueForCharacteristicBlock = nil
    }
    
    public func registerReadRssiaHandler(_ handler: UUCBPeripheralIntErrorBlock?)
    {
        didReadRssiBlock = handler
    }
    
    public func clearReadRssiaHandler()
    {
        didReadRssiBlock = nil
    }
    
    public func registerDidOpenL2CAPChannelHandler(_ handler: UUCBL2CapChannelOpenedBlock?)
    {
        didOpenL2ChannelBlock = handler
    }
    
    public func clearDidOpenL2CAPChannelHandler()
    {
        didOpenL2ChannelBlock = nil
    }
    
    public func registerUpdateHandler(_ handler: UUCBPeripheralCharacteristicErrorBlock?, _ characteristic: CBCharacteristic)
    {
        UULog.verbose(tag: LOG_TAG, message: "Adding Update Handler for \(characteristic.uuid.uuCommonName) - \(characteristic.uuid.uuidString)")
        updateValueForCharacteristicBlocks[characteristic.uuid.uuidString] = handler
    }

    public func removeUpdateHandlerForCharacteristic(_ characteristic: CBCharacteristic)
    {
        UULog.verbose(tag: LOG_TAG, message: "Removing Update Handler for \(characteristic.uuid.uuCommonName) - \(characteristic.uuid.uuidString)")
        updateValueForCharacteristicBlocks.removeValue(forKey: characteristic.uuid.uuidString)
    }

    public func registerReadHandler(_ handler: UUCBPeripheralCharacteristicErrorBlock?, _ characteristic: CBCharacteristic)
    {
        UULog.verbose(tag: LOG_TAG, message: "Adding Read Handler for \(characteristic.uuid.uuCommonName) - \(characteristic.uuid.uuidString)")
        readValueForCharacteristicBlocks[characteristic.uuid.uuidString] = handler
    }

    public func removeReadHandler(_ characteristic: CBCharacteristic)
    {
        UULog.verbose(tag: LOG_TAG, message: "Removing Read Handler for \(characteristic.uuid.uuCommonName) - \(characteristic.uuid.uuidString)")
        readValueForCharacteristicBlocks.removeValue(forKey: characteristic.uuid.uuidString)
    }

    public func registerWriteHandler(_ handler: UUCBPeripheralCharacteristicErrorBlock?, _ characteristic: CBCharacteristic)
    {
        writeValueForCharacteristicBlocks[characteristic.uuid.uuidString] = handler
    }

    public func removeWriteHandler(_ characteristic: CBCharacteristic)
    {
        writeValueForCharacteristicBlocks.removeValue(forKey: characteristic.uuid.uuidString)
    }
    
    public func registerUpdateHandler(_ handler: UUCBPeripheralDescriptorErrorBlock?, _ descriptor: CBDescriptor)
    {
        updateValueForDescriptorBlocks[descriptor.uuid.uuidString] = handler
    }

    public func removeUpdateHandler(_ descriptor: CBDescriptor)
    {
        updateValueForDescriptorBlocks.removeValue(forKey: descriptor.uuid.uuidString)
    }

    public func registerReadHandler(_ handler: UUCBPeripheralDescriptorErrorBlock?, _ descriptor: CBDescriptor)
    {
        readValueForDescriptorBlocks[descriptor.uuid.uuidString] = handler
    }

    public func removeReadHandler(_ descriptor: CBDescriptor)
    {
        readValueForDescriptorBlocks.removeValue(forKey: descriptor.uuid.uuidString)
    }

    public func registerWriteHandler(_ handler: UUCBPeripheralDescriptorErrorBlock?, _ descriptor: CBDescriptor)
    {
        writeValueForDescriptorBlocks[descriptor.uuid.uuidString] = handler
    }

    public func removeWriteHandler(_ descriptor: CBDescriptor)
    {
        writeValueForDescriptorBlocks.removeValue(forKey: descriptor.uuid.uuidString)
    }
    
    // ////////////////////////////////////////////////////////////////////////////////////////////
    // MARK: CBPeripheralDelegate methods
    // ////////////////////////////////////////////////////////////////////////////////////////////
    
    public func peripheralDidUpdateName(_ peripheral: CBPeripheral)
    {
        peripheralNameUpdatedBlock?(peripheral)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService])
    {
        didModifyServicesBlock?(peripheral, invalidatedServices)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?)
    {
        let block = didReadRssiBlock
        didReadRssiBlock = nil
        block?(peripheral, RSSI.intValue, error)
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
        block?(peripheral, service, error)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?)
    {
        let block = discoverCharacteristicsBlock
        discoverCharacteristicsBlock = nil
        block?(peripheral, service, error)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?)
    {
        let key = characteristic.uuid.uuidString
        if let updateBlock = updateValueForCharacteristicBlocks[key]
        {
            UULog.verbose(tag: LOG_TAG, message: "Invoking Update Block for \(characteristic.uuid.uuCommonName) - \(characteristic.uuid.uuidString)")
            updateBlock(peripheral, characteristic, error)
        }
        
        if let readBlock = readValueForCharacteristicBlocks[key]
        {
            UULog.verbose(tag: LOG_TAG, message: "Invoking Read Block for \(characteristic.uuid.uuCommonName) - \(characteristic.uuid.uuidString)")
            readBlock(peripheral, characteristic, error)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?)
    {
        if let writeBlock = writeValueForCharacteristicBlocks[characteristic.uuid.uuidString]
        {
            writeBlock(peripheral, characteristic, error)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?)
    {
        let block = setNotifyValueForCharacteristicBlock
        setNotifyValueForCharacteristicBlock = nil
        block?(peripheral, characteristic, error)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?)
    {
        let block = discoverDescriptorsBlock
        discoverDescriptorsBlock = nil
        block?(peripheral, characteristic, error)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?)
    {
        let key = descriptor.uuid.uuidString
        if let updateBlock = updateValueForDescriptorBlocks[key]
        {
            updateBlock(peripheral, descriptor, error)
        }
        
        if let readBlock = readValueForDescriptorBlocks[key]
        {
            readBlock(peripheral, descriptor, error)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?)
    {
        if let writeBlock = writeValueForDescriptorBlocks[descriptor.uuid.uuidString]
        {
            writeBlock(peripheral, descriptor, error)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didOpen channel: CBL2CAPChannel?, error: Error?)
    {
        didOpenL2ChannelBlock?(peripheral, channel, error)
    }
}
