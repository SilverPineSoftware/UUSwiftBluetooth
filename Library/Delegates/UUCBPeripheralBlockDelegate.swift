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
    public var l2CapChannelOpenedBlock: UUObjectErrorBlock<UUCBL2CAPChannel>? = nil
    
    internal var discoverIncludedServicesBlocks: [String:UUListErrorBlock<CBService>] = [:]
    internal var discoverCharacteristicsBlocks: [String:UUListErrorBlock<CBCharacteristic>] = [:]
    internal var discoverDescriptorsBlocks: [String:UUListErrorBlock<CBDescriptor>] = [:]
    internal var setNotifyValueForCharacteristicBlocks: [String:UUErrorBlock] = [:]
    internal var updateValueForCharacteristicBlocks: [String:UUObjectErrorBlock<Data>] = [:]
    internal var readValueForCharacteristicBlocks: [String:UUObjectErrorBlock<Data>] = [:]
    internal var writeValueForCharacteristicBlocks: [String:UUErrorBlock] = [:]
    internal var readValueForDescriptorBlocks: [String:UUObjectErrorBlock<Any>] = [:]
    internal var writeValueForDescriptorBlocks: [String:UUErrorBlock] = [:]
    
    // ////////////////////////////////////////////////////////////////////////////////////////////
    // MARK: Public methods
    // ////////////////////////////////////////////////////////////////////////////////////////////
    
    public func clearBlocks()
    {
        peripheralNameUpdatedBlock = nil
        didModifyServicesBlock = nil
        didReadRssiBlock = nil
        discoverServicesBlock = nil
        l2CapChannelOpenedBlock = nil
        
        discoverIncludedServicesBlocks.removeAll()
        discoverCharacteristicsBlocks.removeAll()
        discoverDescriptorsBlocks.removeAll()
        setNotifyValueForCharacteristicBlocks.removeAll()
        updateValueForCharacteristicBlocks.removeAll()
        readValueForCharacteristicBlocks.removeAll()
        writeValueForCharacteristicBlocks.removeAll()
        readValueForDescriptorBlocks.removeAll()
        writeValueForDescriptorBlocks.removeAll()
    }

    /// Detaches pending one-shot completions and removes persistent subscriptions.
    /// Invoke the returned work only after cancelling the disconnected connection's timers.
    /// Detaching first allows completions to reenter the peripheral without losing new handlers.
    internal func takePendingCompletions(error: Error) -> () -> Void
    {
        let rssi = didReadRssiBlock
        let services = discoverServicesBlock
        let channel = l2CapChannelOpenedBlock
        let characteristicReads = Array(readValueForCharacteristicBlocks.values)
        let characteristicWrites = Array(writeValueForCharacteristicBlocks.values)
        let descriptorReads = Array(readValueForDescriptorBlocks.values)
        let descriptorWrites = Array(writeValueForDescriptorBlocks.values)

        let pendingIncludedServices = Array(discoverIncludedServicesBlocks.values)
        let pendingCharacteristics = Array(discoverCharacteristicsBlocks.values)
        let pendingDescriptors = Array(discoverDescriptorsBlocks.values)
        let pendingNotifyStates = Array(setNotifyValueForCharacteristicBlocks.values)
        clearBlocks()

        return {
            rssi?(nil, error)
            services?(nil, error)
            pendingIncludedServices.forEach { $0(nil, error) }
            pendingCharacteristics.forEach { $0(nil, error) }
            pendingDescriptors.forEach { $0(nil, error) }
            pendingNotifyStates.forEach { $0(error) }
            channel?(nil, error)
            characteristicReads.forEach { $0(nil, error) }
            characteristicWrites.forEach { $0(error) }
            descriptorReads.forEach { $0(nil, error) }
            descriptorWrites.forEach { $0(error) }
        }
    }
    
    public func logBlocks()
    {
        UULog.debug(tag: LOG_TAG, message: "peripheralNameUpdatedBlock: \(String(describing: peripheralNameUpdatedBlock))")
        UULog.debug(tag: LOG_TAG, message: "didModifyServicesBlock: \(String(describing: didModifyServicesBlock))")
        UULog.debug(tag: LOG_TAG, message: "didReadRssiBlock: \(String(describing: didReadRssiBlock))")
        UULog.debug(tag: LOG_TAG, message: "discoverServicesBlock: \(String(describing: discoverServicesBlock))")
        UULog.debug(tag: LOG_TAG, message: "discoverIncludedServicesBlocks: \(String(describing: discoverIncludedServicesBlocks))")
        UULog.debug(tag: LOG_TAG, message: "discoverCharacteristicsBlocks: \(String(describing: discoverCharacteristicsBlocks))")
        UULog.debug(tag: LOG_TAG, message: "updateValueForCharacteristicBlocks: \(String(describing: updateValueForCharacteristicBlocks))")
        UULog.debug(tag: LOG_TAG, message: "readValueForCharacteristicBlocks: \(String(describing: readValueForCharacteristicBlocks))")
        UULog.debug(tag: LOG_TAG, message: "writeValueForCharacteristicBlocks: \(String(describing: writeValueForCharacteristicBlocks))")
        UULog.debug(tag: LOG_TAG, message: "readValueForDescriptorBlocks: \(String(describing: readValueForDescriptorBlocks))")
        UULog.debug(tag: LOG_TAG, message: "writeValueForDescriptorBlocks: \(String(describing: writeValueForDescriptorBlocks))")
        UULog.debug(tag: LOG_TAG, message: "setNotifyValueForCharacteristicBlocks: \(String(describing: setNotifyValueForCharacteristicBlocks))")
        UULog.debug(tag: LOG_TAG, message: "discoverDescriptorsBlocks: \(String(describing: discoverDescriptorsBlocks))")
        UULog.debug(tag: LOG_TAG, message: "l2CapChannelOpenedBlock: \(String(describing: l2CapChannelOpenedBlock))")
    }

    public func registerCharacteristicUpdateHandler(
        _ characteristic: CBUUID,
        _ handler: UUObjectErrorBlock<Data>?)
    {
        UULog.verbose(tag: LOG_TAG, message: "Adding Update Handler for \(characteristic.uuCommonName) - \(characteristic.uuidString)")
        updateValueForCharacteristicBlocks[characteristic.uuidString] = handler
    }

    public func removeUpdateHandlerForCharacteristic(_ characteristic: CBUUID)
    {
        UULog.verbose(tag: LOG_TAG, message: "Removing Update Handler for \(characteristic.uuCommonName) - \(characteristic.uuidString)")
        updateValueForCharacteristicBlocks.removeValue(forKey: characteristic.uuidString)
    }

    public func registerCharacteristicReadHandler(
        _ characteristic: CBUUID,
        _ handler: UUObjectErrorBlock<Data>?)
    {
        UULog.verbose(tag: LOG_TAG, message: "Adding Read Handler for \(characteristic.uuCommonName) - \(characteristic.uuidString)")
        readValueForCharacteristicBlocks[characteristic.uuidString] = handler
    }

    public func removeCharacteristicReadHandler(_ characteristic: CBUUID)
    {
        UULog.verbose(tag: LOG_TAG, message: "Removing Read Handler for \(characteristic.uuCommonName) - \(characteristic.uuidString)")
        readValueForCharacteristicBlocks.removeValue(forKey: characteristic.uuidString)
    }

    public func registerCharacteristicWriteHandler(
        _ characteristic: CBUUID,
        _ handler: UUErrorBlock?)
    {
        writeValueForCharacteristicBlocks[characteristic.uuidString] = handler
    }

    public func removeCharacteristicWriteHandler(_ characteristic: CBUUID)
    {
        writeValueForCharacteristicBlocks.removeValue(forKey: characteristic.uuidString)
    }

    public func registerDescriptorReadHandler(
        _ descriptor: CBUUID,
        _ handler: UUObjectErrorBlock<Any>?)
    {
        readValueForDescriptorBlocks[descriptor.uuidString] = handler
    }

    public func removeDescriptorReadHandler(_ descriptor: CBUUID)
    {
        readValueForDescriptorBlocks.removeValue(forKey: descriptor.uuidString)
    }

    public func registerDescriptorWriteHandler(
        _ descriptor: CBUUID,
        _ handler: UUErrorBlock?)
    {
        writeValueForDescriptorBlocks[descriptor.uuidString] = handler
    }

    public func removeDescriptorWriteHandler(_ descriptor: CBUUID)
    {
        writeValueForDescriptorBlocks.removeValue(forKey: descriptor.uuidString)
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
        handleRssiRead(peripheral, RSSI, error)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?)
    {
        handleServicesDiscovered(peripheral, error)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?)
    {
        handleDiscoverIncludedServices(peripheral, service, error)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?)
    {
        handleDiscoverCharacteristics(peripheral, service, error)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?)
    {
        handleCharacteristicValueUpdated(peripheral, characteristic, error)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?)
    {
        handleCharacteristicValueWritten(peripheral, characteristic, error)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?)
    {
        handleDidUpdateNotificationState(peripheral, characteristic, error)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?)
    {
        handleDescriptorDiscovery(peripheral, characteristic, error)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?)
    {
        handleDescriptorValueUpdated(peripheral, descriptor, error)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?)
    {
        handleDescriptorValueWritten(peripheral, descriptor, error)
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
        handleL2CapChannelOpened(peripheral, channel, error)
    }
    
    
    
    // MARK: Handlers
    
    /*public func handlePeripheralNameUpdated(_ peripheral: UUCBPeripheral)
    {
        // Don't clear this one because it's an async event not invoked in direct response to a method call.
        peripheralNameUpdatedBlock?(peripheral)
    }
    
    public func handlePeripheralServicesUpdated(_ peripheral: UUCBPeripheral, _ invalidatedServices: [UUCBService])
    {
        // Don't clear this one because it's an async event not invoked in direct response to a method call.
        didModifyServicesBlock?(peripheral, invalidatedServices)
    }*/
    
    public func handleRssiRead(_ peripheral: UUCBPeripheral, _ rssi: NSNumber, _ error: Error?)
    {
        let block = didReadRssiBlock
        didReadRssiBlock = nil
        block?(rssi.intValue, error)
    }
    
    public func handleServicesDiscovered(_ peripheral: UUCBPeripheral, _ error: Error?)
    {
        let block = discoverServicesBlock
        discoverServicesBlock = nil
        block?(peripheral.services, error)
    }
    
    public func handleDiscoverIncludedServices(_ peripheral: UUCBPeripheral, _ service: UUCBService, _ error: Error?)
    {
        let block = discoverIncludedServicesBlocks.removeValue(forKey: service.uuid.uuidString)
        
        let updatedService = peripheral.services?.first { $0.uuid == service.uuid }
        
        block?(updatedService?.includedServices, error)
    }
    
    public func handleDiscoverCharacteristics(_ peripheral: UUCBPeripheral, _ service: UUCBService, _ error: Error?)
    {
        let block = discoverCharacteristicsBlocks.removeValue(forKey: service.uuid.uuidString)
        block?(service.characteristics, error)
    }
    
    public func handleCharacteristicValueUpdated(_ peripheral: UUCBPeripheral, _ characteristic: UUCBCharacteristic, _ error: Error?)
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
            removeCharacteristicReadHandler(characteristic.uuid)
            readBlock(characteristic.value, error)
        }
    }
    
    public func handleCharacteristicValueWritten(_ peripheral: UUCBPeripheral, _ characteristic: UUCBCharacteristic, _ error: Error?)
    {
        if let writeBlock = writeValueForCharacteristicBlocks[characteristic.uuid.uuidString]
        {
            removeCharacteristicWriteHandler(characteristic.uuid)
            writeBlock(error)
        }
    }
    
    public func handleDidUpdateNotificationState(_ peripheral: UUCBPeripheral, _ characteristic: UUCBCharacteristic, _ error: Error?)
    {
        let block = setNotifyValueForCharacteristicBlocks.removeValue(forKey: characteristic.uuid.uuidString)
        block?(error)
    }
    
    public func handleDescriptorDiscovery(_ peripheral: UUCBPeripheral, _ characteristic: UUCBCharacteristic, _ error: Error?)
    {
        let block = discoverDescriptorsBlocks.removeValue(forKey: characteristic.uuid.uuidString)
        block?(characteristic.descriptors, error)
    }
    
    public func handleDescriptorValueUpdated(_ peripheral: UUCBPeripheral, _ descriptor: UUCBDescriptor, _ error: Error?)
    {
        if let readBlock = readValueForDescriptorBlocks[descriptor.uuid.uuidString]
        {
            removeDescriptorReadHandler(descriptor.uuid)
            readBlock(descriptor.value, error)
        }
    }
    
    public func handleDescriptorValueWritten(_ peripheral: UUCBPeripheral, _ descriptor: UUCBDescriptor, _ error: Error?)
    {
        if let writeBlock = writeValueForDescriptorBlocks[descriptor.uuid.uuidString]
        {
            removeDescriptorWriteHandler(descriptor.uuid)
            writeBlock(error)
        }
    }
    
    public func handleL2CapChannelOpened(_ peripheral: UUCBPeripheral, _ channel: UUCBL2CAPChannel?, _ error: Error?)
    {
        let block = l2CapChannelOpenedBlock
        l2CapChannelOpenedBlock = nil
        block?(channel, error)
    }
}
