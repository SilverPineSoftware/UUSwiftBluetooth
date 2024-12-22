//
//  UUPeripheralDelegate.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 8/13/21.
//

import UIKit
import CoreBluetooth
import UUSwiftCore

fileprivate let LOG_TAG = "UUPeripheralDelegate"

typealias UUCBPeripheralBlock = ((CBPeripheral)->())
typealias UUCBPeripheralErrorBlock = ((CBPeripheral, Error?)->())
typealias UUCBPeripheralServiceErrorBlock = ((CBPeripheral, CBService, Error?)->())
typealias UUCBPeripheralCharacteristicErrorBlock = ((CBPeripheral, CBCharacteristic, Error?)->())
typealias UUCBPeripheralDescriptorErrorBlock = ((CBPeripheral, CBDescriptor, Error?)->())
typealias UUCBPeripheralIntErrorBlock = ((CBPeripheral, Int, Error?)->())
typealias UUCBPeripheralServiceListBlock = ((CBPeripheral, [CBService])->())

typealias UUCBL2CapChannelOpenedBlock = ((CBPeripheral, CBL2CAPChannel?, Error?)->())

class UUPeripheralDelegate: NSObject, CBPeripheralDelegate
{
    var peripheralNameUpdatedBlock: UUCBPeripheralBlock? = nil
    var didModifyServicesBlock: UUCBPeripheralServiceListBlock? = nil
    var didReadRssiBlock: UUCBPeripheralIntErrorBlock? = nil
    var discoverServicesBlock: UUCBPeripheralErrorBlock? = nil
    var discoverIncludedServicesBlock: UUCBPeripheralServiceErrorBlock? = nil
    var discoverCharacteristicsBlock: UUCBPeripheralServiceErrorBlock? = nil
    var updateValueForCharacteristicBlocks: [String:UUCBPeripheralCharacteristicErrorBlock] = [:]
    var readValueForCharacteristicBlocks: [String:UUCBPeripheralCharacteristicErrorBlock] = [:]
    var writeValueForCharacteristicBlocks: [String:UUCBPeripheralCharacteristicErrorBlock] = [:]
    var updateValueForDescriptorBlocks: [String:UUCBPeripheralDescriptorErrorBlock] = [:]
    var readValueForDescriptorBlocks: [String:UUCBPeripheralDescriptorErrorBlock] = [:]
    var writeValueForDescriptorBlocks: [String:UUCBPeripheralDescriptorErrorBlock] = [:]
    var setNotifyValueForCharacteristicBlock: UUCBPeripheralCharacteristicErrorBlock? = nil
    var discoverDescriptorsBlock: UUCBPeripheralCharacteristicErrorBlock? = nil
    var didOpenL2ChannelBlock: UUCBL2CapChannelOpenedBlock? = nil
    
    func clearBlocks()
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

    func registerUpdateHandler(_ handler: UUCBPeripheralCharacteristicErrorBlock?, _ characteristic: CBCharacteristic)
    {
        UULog.verbose(tag: LOG_TAG, message: "Adding Update Handler for \(characteristic.uuid.uuCommonName) - \(characteristic.uuid.uuidString)")
        updateValueForCharacteristicBlocks[characteristic.uuid.uuidString] = handler
    }

    func removeUpdateHandlerForCharacteristic(_ characteristic: CBCharacteristic)
    {
        UULog.verbose(tag: LOG_TAG, message: "Removing Update Handler for \(characteristic.uuid.uuCommonName) - \(characteristic.uuid.uuidString)")
        updateValueForCharacteristicBlocks.removeValue(forKey: characteristic.uuid.uuidString)
    }

    func registerReadHandler(_ handler: UUCBPeripheralCharacteristicErrorBlock?, _ characteristic: CBCharacteristic)
    {
        UULog.verbose(tag: LOG_TAG, message: "Adding Read Handler for \(characteristic.uuid.uuCommonName) - \(characteristic.uuid.uuidString)")
        readValueForCharacteristicBlocks[characteristic.uuid.uuidString] = handler
    }

    func removeReadHandler(_ characteristic: CBCharacteristic)
    {
        UULog.verbose(tag: LOG_TAG, message: "Removing Read Handler for \(characteristic.uuid.uuCommonName) - \(characteristic.uuid.uuidString)")
        readValueForCharacteristicBlocks.removeValue(forKey: characteristic.uuid.uuidString)
    }

    func registerWriteHandler(_ handler: UUCBPeripheralCharacteristicErrorBlock?, _ characteristic: CBCharacteristic)
    {
        writeValueForCharacteristicBlocks[characteristic.uuid.uuidString] = handler
    }

    func removeWriteHandler(_ characteristic: CBCharacteristic)
    {
        writeValueForCharacteristicBlocks.removeValue(forKey: characteristic.uuid.uuidString)
    }
    
    func registerUpdateHandler(_ handler: UUCBPeripheralDescriptorErrorBlock?, _ descriptor: CBDescriptor)
    {
        updateValueForDescriptorBlocks[descriptor.uuid.uuidString] = handler
    }

    func removeUpdateHandler(_ descriptor: CBDescriptor)
    {
        updateValueForDescriptorBlocks.removeValue(forKey: descriptor.uuid.uuidString)
    }

    func registerReadHandler(_ handler: UUCBPeripheralDescriptorErrorBlock?, _ descriptor: CBDescriptor)
    {
        readValueForDescriptorBlocks[descriptor.uuid.uuidString] = handler
    }

    func removeReadHandler(_ descriptor: CBDescriptor)
    {
        readValueForDescriptorBlocks.removeValue(forKey: descriptor.uuid.uuidString)
    }

    func registerWriteHandler(_ handler: UUCBPeripheralDescriptorErrorBlock?, _ descriptor: CBDescriptor)
    {
        writeValueForDescriptorBlocks[descriptor.uuid.uuidString] = handler
    }

    func removeWriteHandler(_ descriptor: CBDescriptor)
    {
        writeValueForDescriptorBlocks.removeValue(forKey: descriptor.uuid.uuidString)
    }
    
    func peripheralDidUpdateName(_ peripheral: CBPeripheral)
    {
        peripheralNameUpdatedBlock?(peripheral)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService])
    {
        didModifyServicesBlock?(peripheral, invalidatedServices)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?)
    {
        let block = didReadRssiBlock
        didReadRssiBlock = nil
        block?(peripheral, RSSI.intValue, error)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?)
    {
        let block = discoverServicesBlock
        discoverServicesBlock = nil
        block?(peripheral, error)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?)
    {
        let block = discoverIncludedServicesBlock
        discoverIncludedServicesBlock = nil
        block?(peripheral, service, error)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?)
    {
        let block = discoverCharacteristicsBlock
        discoverCharacteristicsBlock = nil
        block?(peripheral, service, error)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?)
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
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?)
    {
        if let writeBlock = writeValueForCharacteristicBlocks[characteristic.uuid.uuidString]
        {
            writeBlock(peripheral, characteristic, error)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?)
    {
        let block = setNotifyValueForCharacteristicBlock
        setNotifyValueForCharacteristicBlock = nil
        block?(peripheral, characteristic, error)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?)
    {
        let block = discoverDescriptorsBlock
        discoverDescriptorsBlock = nil
        block?(peripheral, characteristic, error)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?)
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
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?)
    {
        if let writeBlock = writeValueForDescriptorBlocks[descriptor.uuid.uuidString]
        {
            writeBlock(peripheral, descriptor, error)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didOpen channel: CBL2CAPChannel?, error: Error?)
    {
        didOpenL2ChannelBlock?(peripheral, channel, error)
    }
}
