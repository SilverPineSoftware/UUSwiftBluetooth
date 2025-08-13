//
//  UUPeripheral.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 8/13/21.
//

import Foundation
import CoreBluetooth
import UUSwiftCore

fileprivate let LOG_TAG = "UUPeripheral"

// UUPeripheral is a convenience class that wraps a CBPeripheral and it's
// advertisement data into one object.
//
open class UUPeripheral
{
    private let centralManager: UUCentralManager
    private let dispatchQueue: DispatchQueue
    private let delegate = UUCBPeripheralBlockDelegate()
    private let timerPool: UUTimerPool

    // Reference to the underlying CBPeripheral
    public var underlyingPeripheral: UUCBPeripheral

    private(set) public var advertisement: UUAdvertisement
    private(set) public var rssi: Int
    private(set) public var firstDiscoveryTime: Date
    
    public var userInfo: Codable? = nil
    
    public init(
        centralManager: UUCentralManager,
        peripheral: UUCBPeripheral,
        advertisement: UUAdvertisement)
    {
        self.dispatchQueue = centralManager.dispatchQueue
        self.centralManager = centralManager
        self.underlyingPeripheral = peripheral
        self.underlyingPeripheral.delegate = delegate
        self.timerPool = UUTimerPool.getPool("UUPeripheral_\(peripheral.identifier)", queue: centralManager.dispatchQueue)
        self.advertisement = advertisement
        self.rssi = advertisement.rssi
        self.firstDiscoveryTime = advertisement.timestamp
    }
    
    // Passthrough properties to read values directly from CBPeripheral
    
    public var identifier: UUID
    {
        return underlyingPeripheral.identifier
    }
    
    public var name: String
    {
        return underlyingPeripheral.name ?? ""
    }
    
    public var friendlyName: String
    {
        if advertisement.localName.isEmpty == false
        {
            return advertisement.localName
        }
        
        return self.name
    }
    
    public var peripheralState: CBPeripheralState
    {
        return underlyingPeripheral.state
    }
    
    public var services: [UUCBService]?
    {
        return underlyingPeripheral.services
    }
    
    public func update(advertisement: UUAdvertisement)
    {
        self.advertisement = advertisement
        self.rssi = advertisement.rssi
    }
    
    func updateRssi(_ rssi: Int)
    {
        // TODO: Implement this
        
        // Per CoreBluetooth documentation, a value of 127 indicates the RSSI
        // reading is not available
        /*if rssi != 127
        {
            self.rssi = rssi
            self.lastRssiUpdateTime = Date()
        }*/
    }
    
    public func startTimer(name: String, timeout: TimeInterval, block: @escaping ()->())
    {
        let timerId = formatTimerId(name)
        UULog.debug(tag: LOG_TAG, message: "Starting bucket timer \(timerId) with timeout: \(timeout)")
        
        timerPool.start(identifier: timerId, timeout: timeout, userInfo: nil)
        { _ in
            block()
        }
    }
    
    public func cancelTimer(name: String)
    {
        let timerId = formatTimerId(name)
        timerPool.cancel(by: timerId)
    }
    
    public func maximumWriteValueLength(for writeType: CBCharacteristicWriteType) -> Int
    {
        return underlyingPeripheral.maximumWriteValueLength(for: writeType)
    }
    
    public var timeSinceLastUpdate: TimeInterval
    {
        return Date.timeIntervalSinceReferenceDate - advertisement.timestamp.timeIntervalSinceReferenceDate
    }
    
    
    // Block based wrapper around CBCentralManager connectPeripheral:options with a
    // timeout value.  If a negative timeout is passed there will be no timeout used.
    // The connected block is only invoked upon successfully connection.  The
    // disconnected block is invoked in the case of a connection failure, timeout
    // or disconnection.
    //
    // Each block will only be invoked at most one time.  After a successful
    // connection, the disconnect block will be called back when the peripheral
    // is disconnected from the phone side, or if the remote device disconnects
    // from the phone
    public func connect(
        timeout: TimeInterval = UUCoreBluetooth.Defaults.connectTimeout,
        connected: @escaping UUVoidBlock,
        disconnected: @escaping UUErrorBlock)
    {
        guard centralManager.isPoweredOn else
        {
            let err = NSError.uuCoreBluetoothError(.centralNotReady)
            disconnected(err)
            return
        }
        
        let timerId = TimerId.connect
        
        let connectedBlock: UUCBPeripheralBlock =
        { p in
            
            self.cancelTimer(timerId)
            connected()
        }
        
        let disconnectedBlock: UUCBPeripheralErrorBlock =
        { p, error in
            
            self.cleanupAfterDisconnect()
            
            disconnected(error)
        }
        
        let identifier = underlyingPeripheral.identifier
        
        centralManager.registerConnectionBlocks(identifier, connectedBlock, disconnectedBlock)
        
        startTimer(timerId, timeout)
        {
            
            UULog.debug(tag: LOG_TAG, message: "Connect timeout for \(self.debugName)")
            
            self.centralManager.removeConnectionBlocks(identifier)
            
            // Issue the disconnect but disconnect any delegate's.  In the case of
            // CBCentralManager being off or reset when this happens, immediately
            // calling the disconnected block ensures there is not an infinite
            // timeout situation.
            self.centralManager.cancelPeripheralConnection(identifier)
            
            let err = NSError.uuCoreBluetoothError(.timeout)
            self.cancelTimer(timerId)
            disconnected(err)
        }
        
        //var options: [String: Any] = [:]
        /*if #available(iOS 17.0, *) {
            options[CBConnectPeripheralOptionEnableAutoReconnect] = true
        } else {
            // Fallback on earlier versions
        }*/
        
        centralManager.connect(identifier, nil)
    }
    
    // Wrapper around CBCentralManager cancelPeripheralConnection.  After calling this
    // method, the disconnected block passed in at connect time will be invoked.
    public func disconnect(timeout: TimeInterval = UUCoreBluetooth.Defaults.disconnectTimeout)
    {
        let identifier = underlyingPeripheral.identifier
        
        guard centralManager.isPoweredOn else
        {
            UULog.debug(tag: LOG_TAG, message: "Central is not powered on, cannot cancel a connection!")
            let err = NSError.uuCoreBluetoothError(.centralNotReady)
            centralManager.notifyDisconnect(identifier, err)
            return
        }
        
        let timerId = TimerId.disconnect
        
        UULog.debug(tag: LOG_TAG, message: "Starting disconnect timeout")
        startTimer(timerId, timeout)
        {
            UULog.debug(tag: LOG_TAG, message: "Disconnect timeout for \(self.debugName)")
            
            self.cancelTimer(timerId)
            self.centralManager.notifyDisconnect(identifier, NSError.uuCoreBluetoothError(.timeout))
            
            // Just in case the timeout fires and a real disconnect is needed, this is the last
            // ditch effort to close the connection
            self.centralManager.cancelPeripheralConnection(identifier)
        }
        
        
        UULog.debug(tag: LOG_TAG, message: "Cancelling peripheral connection for \(self.debugName)")
        centralManager.cancelPeripheralConnection(identifier)
    }
    
    // Block based wrapper around CBPeripheral discoverServices, with an optional
    // timeout value.  A negative timeout value will disable the timeout.
    public func discoverServices(
        serviceUUIDs: [CBUUID]? = nil,
        timeout: TimeInterval = UUCoreBluetooth.Defaults.operationTimeout,
        completion: @escaping UUListErrorBlock<UUCBService>)
    {
        UULog.debug(tag: LOG_TAG, message: "Discovering services for \(self.debugName), timeout: \(timeout), service list: \(String(describing: serviceUUIDs))")
        
        let timerId = TimerId.serviceDiscovery
        
        delegate.discoverServicesBlock =
        { services, errOpt in
            
            self.finishOperation(timerId, services, errOpt, completion)
        }
        
        if let err = canAttemptOperation
        {
            endServiceDiscovery(err)
            return
        }
        
        startTimer(timerId, timeout)
        {
            let err = NSError.uuCoreBluetoothError(.timeout)
            self.endServiceDiscovery(err)
        }
        
        underlyingPeripheral.discoverServices(serviceUUIDs)
    }
    
    private func endServiceDiscovery(_ error: Error?)
    {
        dispatchQueue.async
        {
            self.delegate.handleServicesDiscovered(self.underlyingPeripheral, error)
        }
    }
    
    // Block based wrapper around CBPeripheral discoverCharacteristics:forService,
    // with an optional timeout value.  A negative timeout value will disable the timeout.
    public func discoverCharacteristics(
        characteristicUUIDs: [CBUUID]?,
        for service: UUCBService,
        timeout: TimeInterval,
        completion: @escaping UUListErrorBlock<UUCBCharacteristic>)
    {
        UULog.debug(tag: LOG_TAG, message: "Discovering characteristics for \(self.debugName), timeout: \(timeout), service: \(service), characteristic list: \(String(describing: characteristicUUIDs))")
        
        let timerId = TimerId.characteristicDiscovery
        
        delegate.discoverCharacteristicsBlock =
        { characteristics, error in
            
            self.finishOperation(timerId, characteristics, error, completion)
        }
        
        if let err = canAttemptOperation
        {
            endCharacteristicDiscovery(service, err)
            return
        }
        
        startTimer(timerId, timeout)
        {
            let err = NSError.uuCoreBluetoothError(.timeout)
            self.endCharacteristicDiscovery(service, err)
        }
        
        if let err = underlyingPeripheral.discoverCharacteristics(characteristicUUIDs, service)
        {
            endCharacteristicDiscovery(service, err)
            return
        }
        // else, wait for delegate to invoke callback block, or timeout to happen
    }
    
    private func endCharacteristicDiscovery(_ service: UUCBService, _ error: Error?)
    {
        dispatchQueue.async
        {
            self.delegate.handleDiscoverCharacteristics(self.underlyingPeripheral, service, error)
        }
    }
    
    // Block based wrapper around CBPeripheral discoverIncludedServices:forService,
    // with an optional timeout value.  A negative timeout value will disable the timeout.
    public func discoverIncludedServices(
        includedServiceUUIDs: [CBUUID]?,
        for service: UUCBService,
        timeout: TimeInterval,
        completion: @escaping UUListErrorBlock<UUCBService>)
    {
        UULog.debug(tag: LOG_TAG, message: "Discovering included services for \(self.debugName), timeout: \(timeout), service: \(service), service list: \(String(describing: includedServiceUUIDs))")
        
        let timerId = TimerId.includedServicesDiscovery
        
        delegate.discoverIncludedServicesBlock =
        { services, error in
            
            self.finishOperation(timerId, services, error, completion)
        }
        
        if let err = canAttemptOperation
        {
            endDiscoverIncludedServices(service, err)
            return
        }
        
        startTimer(timerId, timeout)
        {
            let err = NSError.uuCoreBluetoothError(.timeout)
            self.endDiscoverIncludedServices(service, err)
        }
        
        if let err = underlyingPeripheral.discoverIncludedServices(includedServiceUUIDs, service)
        {
            endDiscoverIncludedServices(service, err)
            return
        }
        // else, wait for delegate to invoke callback block, or timeout to happen
    }
    
    private func endDiscoverIncludedServices(_ service: UUCBService, _ error: Error?)
    {
        dispatchQueue.async
        {
            self.delegate.handleDiscoverIncludedServices(self.underlyingPeripheral, service, error)
        }
    }
    
    // Block based wrapper around CBPeripheral discoverDescriptorsForCharacteristic,
    // with an optional timeout value.  A negative timeout value will disable the timeout.
    public func discoverDescriptors(
        for characteristic: UUCBCharacteristic,
        timeout: TimeInterval,
        completion: @escaping UUListErrorBlock<UUCBDescriptor>)
    {
        UULog.debug(tag: LOG_TAG, message: "Discovering descriptors for \(self.debugName), timeout: \(timeout), characteristic: \(characteristic)")
        
        let timerId = TimerId.descriptorDiscovery
        
        delegate.discoverDescriptorsBlock =
        { descriptors, error in
            
            self.finishOperation(timerId, descriptors, error, completion)
        }
        
        if let err = canAttemptOperation
        {
            endDescriptorDiscovery(characteristic, err)
            return
        }
        
        startTimer(timerId, timeout)
        {
            let err = NSError.uuCoreBluetoothError(.timeout)
            self.endDescriptorDiscovery(characteristic, err)
        }
        
        if let err = underlyingPeripheral.discoverDescriptors(characteristic)
        {
            endDescriptorDiscovery(characteristic, err)
            return
        }
        // else, wait for delegate to invoke callback block, or timeout to happen
    }
    
    private func endDescriptorDiscovery(_ characteristic: UUCBCharacteristic, _ error: Error?)
    {
        dispatchQueue.async
        {
            self.delegate.handleDescriptorDiscovery(self.underlyingPeripheral, characteristic, error)
        }
    }
    
    
    private func discoverNextCharacteristics(
        _ services: [UUCBService], timeout: TimeInterval, completion: @escaping UUErrorBlock)
    {
        var tmpServices = services
        
        guard let nextService = tmpServices.popLast() else
        {
            completion(nil)
            return
        }
        
        discoverCharacteristics(characteristicUUIDs: nil, for: nextService, timeout: timeout)
        { _, error in
            
            if let err = error
            {
                completion(err)
                return
            }
            
            self.discoverNextCharacteristics(tmpServices, timeout: timeout, completion: completion)
        }
    }
    
    public func discoverAllServicesAndCharacteristics(
        timeout: TimeInterval = UUCoreBluetooth.Defaults.operationTimeout,
        completion: @escaping UUErrorBlock)
    {
        connect(timeout: timeout)
        {
            self.discoverServices
            { services, discoverServicesError in
                
                if let err = discoverServicesError
                {
                    completion(err)
                    return
                }
                
                guard let actualServices = services else
                {
                    completion(nil)
                    return
                }
                
                self.discoverNextCharacteristics(actualServices, timeout: timeout)
                { error in
                    
                    self.disconnect()
                }
            }
        }
        disconnected:
        { disconnectError in
            
            completion(disconnectError)
        }
    }
    
    
    // Block based wrapper around CBPeripheral setNotifyValue, with an optional
    // timeout value.  A negative timeout value will disable the timeout.
    public func setNotifyValue(
        enabled: Bool,
        for characteristic: UUCBCharacteristic,
        timeout: TimeInterval = UUCoreBluetooth.Defaults.operationTimeout,
        notifyHandler: UUObjectErrorBlock<Data>?,
        completion: @escaping UUErrorBlock)
    {
        UULog.debug(tag: LOG_TAG, message: "Set Notify State for \(self.debugName), enabled: \(enabled), timeout: \(timeout), characateristic: \(characteristic)")
        
        let timerId = TimerId.characteristicNotifyState
        
        delegate.setNotifyValueForCharacteristicBlock =
        { error in
            
            self.finishOperation(timerId, error, completion)
        }
        
        if (enabled)
        {
            delegate.registerCharacteristicUpdateHandler(characteristic.uuid, notifyHandler)
        }
        else
        {
            delegate.removeUpdateHandlerForCharacteristic(characteristic.uuid)
        }
        
        if let err = canAttemptOperation
        {
            self.endSetNotify(characteristic, err)
            return
        }
        
        startTimer(timerId, timeout)
        {
            let err = NSError.uuCoreBluetoothError(.timeout)
            self.endSetNotify(characteristic, err)
        }
        
        if let err = underlyingPeripheral.setNotifyValue(enabled, for: characteristic)
        {
            self.endSetNotify(characteristic, err)
            return
        }
        // else, wait for delegate to invoke callback block, or timeout to happen
    }
    
    private func endSetNotify(_ characteristic: UUCBCharacteristic, _ error: Error?)
    {
        dispatchQueue.async
        {
            self.delegate.handleDidUpdateNotificationState(self.underlyingPeripheral, characteristic, error)
        }
    }
    
    // Block based wrapper around CBPeripheral readValue:forCharacteristic, with an
    // optional timeout value.  A negative timeout value will disable the timeout.
    public func readValue(
        for characteristic: UUCBCharacteristic,
        timeout: TimeInterval,
        completion: @escaping UUObjectErrorBlock<Data>)
    {
        UULog.debug(tag: LOG_TAG, message: "Read value for \(self.debugName), characteristic: \(characteristic), timeout: \(timeout)")
        
        let timerId = TimerId.readCharacteristic
        
        delegate.registerCharacteristicReadHandler(characteristic.uuid)
        { data, error in
            
            self.finishOperation(timerId, data, error, completion)
        }
        
        startTimer(timerId, timeout)
        {
            let err = NSError.uuCoreBluetoothError(.timeout)
            self.endReadValue(characteristic, err)
        }
        
        if let err = canAttemptOperation
        {
            endReadValue(characteristic, err)
            return
        }
        
        if let err = underlyingPeripheral.readValue(characteristic)
        {
            endReadValue(characteristic, err)
            return
        }
        // else, wait for delegate to invoke callback block, or timeout to happen
    }
    
    private func endReadValue(_ characteristic: UUCBCharacteristic, _ error: Error?)
    {
        dispatchQueue.async
        {
            self.delegate.handleCharacteristicValueUpdated(self.underlyingPeripheral, characteristic, error)
        }
    }
    
    // Block based wrapper around CBPeripheral readValue:forCharacteristic, with an
    // optional timeout value.  A negative timeout value will disable the timeout.
    public func readValue(
        for descriptor: UUCBDescriptor,
        timeout: TimeInterval = UUCoreBluetooth.Defaults.operationTimeout,
        completion: @escaping UUObjectErrorBlock<Any>)
    {
        UULog.debug(tag: LOG_TAG, message: "Read value for \(self.debugName), descriptor: \(descriptor), timeout: \(timeout)")
        
        let timerId = TimerId.readDescriptor
        
        delegate.registerDescriptorReadHandler(descriptor.uuid)
        { data, error in
            
            self.finishOperation(timerId, data, error, completion)
        }
        
        if let err = canAttemptOperation
        {
            endReadDescriptor(descriptor, err)
            return
        }
        
        startTimer(timerId, timeout)
        {
            let err = NSError.uuCoreBluetoothError(.timeout)
            self.endReadDescriptor(descriptor, err)
        }
        
        if let err = underlyingPeripheral.readValue(descriptor)
        {
            endReadDescriptor(descriptor, err)
            return
        }
        // else, wait for delegate to invoke callback block, or timeout to happen
    }
    
    private func endReadDescriptor(_ descriptor: UUCBDescriptor, _ error: Error?)
    {
        dispatchQueue.async
        {
            self.delegate.handleDescriptorValueUpdated(self.underlyingPeripheral, descriptor, error)
        }
    }
    
    // Block based wrapper around CBPeripheral writeValue:forCharacteristic:type with type
    // CBCharacteristicWriteWithResponse, with an optional timeout value.  A negative
    // timeout value will disable the timeout.
    public func writeValue(
        data: Data,
        for characteristic: UUCBCharacteristic,
        timeout: TimeInterval = UUCoreBluetooth.Defaults.operationTimeout,
        completion: @escaping UUErrorBlock)
    {
        UULog.debug(tag: LOG_TAG, message: "Write value \(data.uuToHexString()), for \(self.debugName), characteristic: \(characteristic), timeout: \(timeout)")
        
        let timerId = TimerId.writeCharacteristic
        
        delegate.registerCharacteristicWriteHandler(characteristic.uuid)
        { error in
            
            self.finishOperation(timerId, error, completion)
        }
        
        if let err = canAttemptOperation
        {
            endWriteValue(characteristic, err)
            return
        }
        
        startTimer(timerId, timeout)
        {
            let err = NSError.uuCoreBluetoothError(.timeout)
            self.endWriteValue(characteristic, err)
        }
        
        if let err = underlyingPeripheral.writeCharacteristicValue(data, characteristic, .withResponse)
        {
            endWriteValue(characteristic, err)
            return
        }
        // else, wait for delegate to invoke callback block, or timeout to happen
    }
    
    private func endWriteValue(_ characteristic: UUCBCharacteristic, _ error: Error?)
    {
        dispatchQueue.async
        {
            self.delegate.handleCharacteristicValueWritten(self.underlyingPeripheral, characteristic, error)
        }
    }
    
    // Block based wrapper around CBPeripheral writeValue:forCharacteristic:type with type
    // CBCharacteristicWriteWithoutResponse.  Block callback is invoked after sending.
    // Per CoreBluetooth documentation, there is no garauntee of delivery.
    public func writeValueWithoutResponse(
        data: Data,
        for characteristic: UUCBCharacteristic,
        completion: @escaping UUErrorBlock)
    {
        UULog.debug(tag: LOG_TAG, message: "Write value without response \(data.uuToHexString()), for \(self.debugName), characteristic: \(characteristic)")
        
        if let err = canAttemptOperation
        {
            dispatchQueue.async
            {
                completion(err)
            }
            
            return
        }
        
        if let err = underlyingPeripheral.writeCharacteristicValue(data, characteristic, .withoutResponse)
        {
            dispatchQueue.async
            {
                completion(err)
            }
            
            return
        }
        
        // Immediately invoke the completion callback because write without response will not trigger a delegate callback
        dispatchQueue.async
        {
            completion(nil)
        }
    }
    
    // Block based wrapper around CBPeripheral writeValue:forDesctiptor with type
    // CBCharacteristicWriteWithResponse, with an optional timeout value.  A negative
    // timeout value will disable the timeout.
    public func writeValue(
        data: Data,
        for descriptor: UUCBDescriptor,
        timeout: TimeInterval = UUCoreBluetooth.Defaults.operationTimeout,
        completion: @escaping UUErrorBlock)
    {
        UULog.debug(tag: LOG_TAG, message: "Write value \(data.uuToHexString()), for \(self.debugName), descriptor: \(descriptor), timeout: \(timeout)")
        
        let timerId = TimerId.writeDescriptor
        
        delegate.registerDescriptorWriteHandler(descriptor.uuid)
        { error in
            
            self.finishOperation(timerId, error, completion)
        }
        
        if let err = canAttemptOperation
        {
            endWriteValue(descriptor, err)
            return
        }
        
        startTimer(timerId, timeout)
        {
            let err = NSError.uuCoreBluetoothError(.timeout)
            self.endWriteValue(descriptor, err)
        }
        
        if let err = underlyingPeripheral.writeDescriptorValue(data, descriptor)
        {
            endWriteValue(descriptor, err)
            return
        }
        // else, wait for delegate to invoke callback block, or timeout to happen
    }
    
    private func endWriteValue(_ descriptor: UUCBDescriptor, _ error: Error?)
    {
        dispatchQueue.async
        {
            self.delegate.handleDescriptorValueWritten(self.underlyingPeripheral, descriptor, error)
        }
    }
    
    // Block based wrapper around CBPeripheral readRssi, with an optional
    // timeout value.  A negative timeout value will disable the timeout.
    public func readRSSI(
        timeout: TimeInterval = UUCoreBluetooth.Defaults.operationTimeout,
        completion: @escaping UUObjectErrorBlock<Int>)
    {
        UULog.debug(tag: LOG_TAG, message: "Reading RSSI for \(self.debugName), timeout: \(timeout)")
        
        let timerId = TimerId.readRssi
        
        delegate.didReadRssiBlock =
        { rssi, error in
            
            self.finishOperation(timerId, rssi, error, completion)
        }
        
        if let err = canAttemptOperation
        {
            endReadRssi(UUCoreBluetooth.Constants.noRssi, err)
            return
        }
        
        startTimer(timerId, timeout)
        {
            let err = NSError.uuCoreBluetoothError(.timeout)
            self.endReadRssi(UUCoreBluetooth.Constants.noRssi, err)
        }
        
        underlyingPeripheral.readRSSI()
        
        // wait for delegate to invoke callback block, or timeout to happen
    }
    
    private func endReadRssi(_ rssi: Int, _ error: Error?)
    {
        dispatchQueue.async
        {
            self.delegate.handleRssiRead(self.underlyingPeripheral, NSNumber(integerLiteral: rssi), error)
        }
    }
    
//    // Convenience wrapper to perform both service and characteristic discovery at
//    // one time.  This method is useful when you know both service and characteristic
//    // UUID's ahead of time.
//    public func discover(
//        characteristics: [CBUUID]?,
//        for serviceUuid: CBUUID,
//        timeout: TimeInterval,
//        completion: @escaping UUDiscoverCharacteristicsCompletionBlock)
//    {
//        let start = Date().timeIntervalSinceReferenceDate
//
//        discoverServices(serviceUUIDs: [serviceUuid], timeout: timeout)
//        { discoveredServices, err in
//
//            if let error = err
//            {
//                completion(nil, error)
//                return
//            }
//
//            guard let foundService = discoveredServices?.filter({ $0.uuid.uuidString == serviceUuid.uuidString }).first else
//            {
//                // QUESTION: Should this emit a 'service not found error'
//                completion(nil, err)
//                return
//            }
//
//            let duration = Date().timeIntervalSinceReferenceDate - start
//            let remainingTimeout = timeout - duration
//
//            self.discoverCharacteristics(characteristicUUIDs: characteristics, for: foundService, timeout: remainingTimeout, completion: completion)
//        }
//    }
    
    
    public func openL2CAPChannel(
        psm: CBL2CAPPSM,
        timeout: TimeInterval,
        completion: @escaping UUObjectErrorBlock<UUCBL2CAPChannel>)
    {
        UULog.debug(tag: LOG_TAG, message: "Opening L2Cap channel for \(self.debugName), psm: \(psm),  timeout: \(timeout)")
        
        let timerId = TimerId.openL2CapChannel
        
        delegate.l2CapChannelOpenedBlock =
        { channel, error in
            
            self.finishOperation(timerId, channel, error, completion)
        }
        
        if let err = canAttemptOperation
        {
            endOpenL2CapChannel(nil, err)
            return
        }
        
        startTimer(timerId, timeout)
        {
            let err = NSError.uuCoreBluetoothError(.timeout)
            self.endOpenL2CapChannel(nil, err)
        }
        
        underlyingPeripheral.openL2CAPChannel(psm)
        
        // wait for delegate to invoke callback block, or timeout to happen
        
    }
    
    private func endOpenL2CapChannel(_ channel: UUCBL2CAPChannel?, _ error: Error?)
    {
        dispatchQueue.async
        {
            self.delegate.handleL2CapChannelOpened(self.underlyingPeripheral, channel, error)
        }
    }
    
    
    
    
    
    private func prepareToFinishOperation(
        _ timerBucket: TimerId,
        _ error: Error?) -> Error?
    {
        let err = NSError.uuOperationCompleteError(error as NSError?)
        
        UULog.debug(tag: LOG_TAG, message: "Finished \(timerBucket) for \(debugName), error: \(String(describing: err))")
        
        cancelTimer(timerBucket)
        return err
    }
    
    private func finishOperation(
        _ timerBucket: TimerId,
        _ error: Error?,
        _ completion: @escaping UUErrorBlock)
    {
        let err = prepareToFinishOperation(timerBucket, error)
        completion(err)
    }
    
    private func finishOperation<T>(
        _ timerBucket: TimerId,
        _ result: T?,
        _ error: Error?,
        _ completion: @escaping UUObjectErrorBlock<T>)
    {
        let err = prepareToFinishOperation(timerBucket, error)
        completion(result, err)
    }
    
    private func finishOperation<T>(
        _ timerBucket: TimerId,
        _ result: [T]?,
        _ error: Error?,
        _ completion: @escaping UUListErrorBlock<T>)
    {
        let err = prepareToFinishOperation(timerBucket, error)
        completion(result, err)
    }
    
    
    // MARK: Timers
    
    
    private enum TimerId: String
    {
        case connect
        case disconnect
        case serviceDiscovery
        case characteristicDiscovery
        case includedServicesDiscovery
        case descriptorDiscovery
        case characteristicNotifyState
        case readCharacteristic
        case writeCharacteristic
        case readDescriptor
        case writeDescriptor
        case readRssi
        case pollRssi
        case openL2CapChannel
    }
    
    private func formatTimerId(_ name: String) -> String
    {
        return "\(identifier)__\(name)"
    }
    
    private func cleanupAfterDisconnect()
    {
        UULog.debug(tag: LOG_TAG, message: "Cancelling all timers")
        timerPool.cancelAllTimers()
        
        UULog.debug(tag: LOG_TAG, message: "Clearing all delegate callbacks")
        delegate.clearBlocks()
    }
    
    private func startTimer(_ timerBucket: TimerId, _ timeout: TimeInterval, _ block: @escaping ()->())
    {
        startTimer(name: timerBucket.rawValue, timeout: timeout, block: block)
    }
    
    private func cancelTimer(_ timerBucket: TimerId)
    {
        cancelTimer(name: timerBucket.rawValue)
    }
    
    private var canAttemptOperation: Error?
    {
        if (!centralManager.isPoweredOn)
        {
            return NSError.uuCoreBluetoothError(.centralNotReady)
        }
        
        if (underlyingPeripheral.state != .connected)
        {
            return NSError.uuCoreBluetoothError(.notConnected)
        }
        
        return nil
    }
    
    
    
    private var debugName: String
    {
        return "\(identifier) - \(name)"
    }
    
    
    public func logBlocks()
    {
        delegate.logBlocks()
    }
}

