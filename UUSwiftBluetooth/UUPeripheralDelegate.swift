//
//  UUPeripheralDelegate.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 8/13/21.
//

import UIKit
import CoreBluetooth
import UUSwiftCore

typealias UUCBPeripheralBlock = ((CBPeripheral)->())
typealias UUCBPeripheralErrorBlock = ((CBPeripheral, Error?)->())
typealias UUCBPeripheralServiceErrorBlock = ((CBPeripheral, CBService, Error?)->())
typealias UUCBPeripheralCharacteristicErrorBlock = ((CBPeripheral, CBCharacteristic, Error?)->())
typealias UUCBPeripheralDescriptorErrorBlock = ((CBPeripheral, CBDescriptor, Error?)->())
typealias UUCBPeripheralIntErrorBlock = ((CBPeripheral, Int, Error?)->())
typealias UUCBPeripheralServiceListBlock = ((CBPeripheral, [CBService])->())

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

    func registerUpdateHandler(_ handler: UUCBPeripheralCharacteristicErrorBlock?, _ characteristic: CBCharacteristic)
    {
        updateValueForCharacteristicBlocks[characteristic.uuid.uuidString] = handler
    }

    func removeUpdateHandlerForCharacteristic(_ characteristic: CBCharacteristic)
    {
        updateValueForCharacteristicBlocks.removeValue(forKey: characteristic.uuid.uuidString)
    }

    func registerReadHandler(_ handler: UUCBPeripheralCharacteristicErrorBlock?, _ characteristic: CBCharacteristic)
    {
        readValueForCharacteristicBlocks[characteristic.uuid.uuidString] = handler
    }

    func removeReadHandler(_ characteristic: CBCharacteristic)
    {
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
            updateBlock(peripheral, characteristic, error)
        }
        
        if let readBlock = readValueForCharacteristicBlocks[key]
        {
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
}
