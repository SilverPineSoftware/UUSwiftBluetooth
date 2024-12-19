//
//  UUPeripheral.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 8/13/21.
//

import UIKit
import CoreBluetooth
import UUSwiftCore

// UUPeripheral is a convenience class that wraps a CBPeripheral and it's
// advertisement data into one object.
//
internal class UUCoreBluetoothPeripheral: UUPeripheral, UUPeripheralInternal
{
    private let centralManager: UUCentralManager
    private let dispatchQueue: DispatchQueue
    private let delegate = UUPeripheralDelegate()
    private let timerPool: UUTimerPool

    // Reference to the underlying CBPeripheral
    public var underlyingPeripheral: CBPeripheral

    private(set) public var advertisement: UUAdvertisementProtocol? = nil
    private(set) public var rssi: Int? = nil
    private(set) public var firstDiscoveryTime: Date
    
    public required init(
        centralManager: UUCentralManager,
        peripheral: CBPeripheral)
    {
        self.dispatchQueue = centralManager.dispatchQueue
        self.centralManager = centralManager
        self.underlyingPeripheral = peripheral
        self.underlyingPeripheral.delegate = delegate
        self.timerPool = UUTimerPool.getPool("UUPeripheral_\(peripheral.identifier)", queue: centralManager.dispatchQueue)
        self.firstDiscoveryTime = Date()
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
        
        if let val = advertisement?.localName, val.isEmpty == false
        {
            return val
        }
        
        return self.name
    }
    
    public var peripheralState: CBPeripheralState
    {
        return underlyingPeripheral.state
    }
    
    public var services: [CBService]?
    {
        return underlyingPeripheral.services
    }
    
    func update(advertisement: UUBluetoothAdvertisement)
    {
        self.advertisement = advertisement
        self.rssi = advertisement.rssi
    }
    
    func updateRssi(_ rssi: Int)
    {
        // Per CoreBluetooth documentation, a value of 127 indicates the RSSI
        // reading is not available
        /*if rssi != 127
        {
            self.rssi = rssi
            self.lastRssiUpdateTime = Date()
        }*/
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
        connected: @escaping UUPeripheralConnectedBlock,
        disconnected: @escaping UUPeripheralDisconnectedBlock)
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
            
            //UUDebugLog("Connected to \(peripheral.uuIdentifier) - \(peripheral.uuName)")
            
            self.cancelTimer(timerId)
            connected()
        };
        
        let disconnectedBlock: UUCBPeripheralErrorBlock =
        { p, error in
            
            //UUDebugLog("Disconnected from \(peripheral.uuIdentifier) - \(peripheral.uuName), error: \(String(describing: error))")
            
            self.cleanupAfterDisconnect()
            
            disconnected(error)
        }
        
        centralManager.registerConnectionBlocks(self, connectedBlock, disconnectedBlock)
        
        startTimer(timerId, timeout)
        {
            
            UUDebugLog("Connect timeout for \(self.debugName)")
            
            self.centralManager.removeConnectionBlocks(self)
            
            // Issue the disconnect but disconnect any delegate's.  In the case of
            // CBCentralManager being off or reset when this happens, immediately
            // calling the disconnected block ensures there is not an infinite
            // timeout situation.
            self.centralManager.cancelPeripheralConnection(self)
            
            let err = NSError.uuCoreBluetoothError(.timeout)
            self.cancelTimer(timerId)
            disconnected(err)
        }
        
        var options: [String: Any] = [:]
        /*if #available(iOS 17.0, *) {
            options[CBConnectPeripheralOptionEnableAutoReconnect] = true
        } else {
            // Fallback on earlier versions
        }*/
        
        centralManager.connect(self, options)
    }
    
    // Wrapper around CBCentralManager cancelPeripheralConnection.  After calling this
    // method, the disconnected block passed in at connect time will be invoked.
    public func disconnect(timeout: TimeInterval = UUCoreBluetooth.Defaults.disconnectTimeout)
    {
        guard centralManager.isPoweredOn else
        {
            UUDebugLog("Central is not powered on, cannot cancel a connection!")
            let err = NSError.uuCoreBluetoothError(.centralNotReady)
            centralManager.notifyDisconnect(self, err)
            return
        }
        
        let timerId = TimerId.disconnect
        
        UUDebugLog("Starting disconnect timeout")
        startTimer(timerId, timeout)
        {
            UUDebugLog("Disconnect timeout for \(self.debugName)")
            
            self.cancelTimer(timerId)
            self.centralManager.notifyDisconnect(self, NSError.uuCoreBluetoothError(.timeout))
            
            // Just in case the timeout fires and a real disconnect is needed, this is the last
            // ditch effort to close the connection
            self.centralManager.cancelPeripheralConnection(self)
        }
        
        
        UUDebugLog("Cancelling peripheral connection for \(self.debugName)")
        centralManager.cancelPeripheralConnection(self)
    }
    
    // Block based wrapper around CBPeripheral discoverServices, with an optional
    // timeout value.  A negative timeout value will disable the timeout.
    public func discoverServices(
        serviceUUIDs: [CBUUID]? = nil,
        timeout: TimeInterval = UUCoreBluetooth.Defaults.operationTimeout,
        completion: @escaping UUDiscoverServicesCompletionBlock)
    {
        UUDebugLog("Discovering services for \(self.debugName), timeout: \(timeout), service list: \(String(describing: serviceUUIDs))")
        
        let timerId = TimerId.serviceDiscovery
        
        delegate.discoverServicesBlock =
        { peripheral, errOpt in
            
            self.underlyingPeripheral = peripheral
            self.finishDiscoverServices(timerId, errOpt, completion)
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
            self.delegate.peripheral(self.underlyingPeripheral, didDiscoverServices: error)
        }
    }
    
    // Block based wrapper around CBPeripheral discoverCharacteristics:forService,
    // with an optional timeout value.  A negative timeout value will disable the timeout.
    public func discoverCharacteristics(
        characteristicUUIDs: [CBUUID]?,
        for service: CBService,
        timeout: TimeInterval = UUCoreBluetooth.Defaults.operationTimeout,
        completion: @escaping UUDiscoverCharacteristicsCompletionBlock)
    {
        UUDebugLog("Discovering characteristics for \(self.debugName), timeout: \(timeout), service: \(service), characteristic list: \(String(describing: characteristicUUIDs))")
        
        let timerId = TimerId.characteristicDiscovery
        
        delegate.discoverCharacteristicsBlock =
        { peripheral, service, error in
            
            self.underlyingPeripheral = peripheral
            self.finishDiscoverCharacteristics(timerId, error, service, completion)
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
        
        underlyingPeripheral.discoverCharacteristics(characteristicUUIDs, for: service)
    }
    
    private func endCharacteristicDiscovery(_ service: CBService, _ error: Error?)
    {
        dispatchQueue.async
        {
            self.delegate.peripheral(self.underlyingPeripheral, didDiscoverCharacteristicsFor: service, error: error)
        }
    }
    
    // Block based wrapper around CBPeripheral discoverIncludedServices:forService,
    // with an optional timeout value.  A negative timeout value will disable the timeout.
    public func discoverIncludedServices(
        includedServiceUUIDs: [CBUUID]?,
        for service: CBService,
        timeout: TimeInterval = UUCoreBluetooth.Defaults.operationTimeout,
        completion: @escaping UUPeripheralErrorBlock)
    {
        UUDebugLog("Discovering included services for \(self.debugName), timeout: \(timeout), service: \(service), service list: \(String(describing: includedServiceUUIDs))")
        
        let timerId = TimerId.includedServicesDiscovery
        
        delegate.discoverIncludedServicesBlock =
        { peripheral, service, error in
            
            self.underlyingPeripheral = peripheral
            self.finishOperation(timerId, peripheral, error, completion)
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
        
        underlyingPeripheral.discoverIncludedServices(includedServiceUUIDs, for: service)
    }
    
    private func endDiscoverIncludedServices(_ service: CBService, _ error: Error?)
    {
        dispatchQueue.async
        {
            self.delegate.peripheral(self.underlyingPeripheral, didDiscoverIncludedServicesFor: service, error: error)
        }
    }
    
    // Block based wrapper around CBPeripheral discoverDescriptorsForCharacteristic,
    // with an optional timeout value.  A negative timeout value will disable the timeout.
    public func discoverDescriptorsForCharacteristic(
        for characteristic: CBCharacteristic,
        timeout: TimeInterval = UUCoreBluetooth.Defaults.operationTimeout,
        completion: @escaping UUDiscoverDescriptorsCompletionBlock)
    {
        UUDebugLog("Discovering descriptors for \(self.debugName), timeout: \(timeout), characteristic: \(characteristic)")
        
        let timerId = TimerId.descriptorDiscovery
        
        delegate.discoverDescriptorsBlock =
        { peripheral, characteristic, error in
            
            self.underlyingPeripheral = peripheral
            self.finishDiscoverDescriptors(timerId, error, characteristic, completion)
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
        
        underlyingPeripheral.discoverDescriptors(for: characteristic)
    }
    
    private func endDescriptorDiscovery(_ characteristic: CBCharacteristic, _ error: Error?)
    {
        dispatchQueue.async
        {
            self.delegate.peripheral(self.underlyingPeripheral, didDiscoverDescriptorsFor: characteristic, error: error)
        }
    }
    
    
    private func discoverNextCharacteristics(
        _ services: [CBService], timeout: TimeInterval, completion: @escaping UUPeripheralErrorBlock)
    {
        var tmpServices = services
        
        guard let nextService = tmpServices.popLast() else
        {
            completion(self, nil)
            return
        }
        
        discover(characteristics: nil, for: nextService.uuid, timeout: timeout) { _, error in
            
            if let err = error
            {
                completion(self, err)
                return
            }
            
            self.discoverNextCharacteristics(tmpServices, timeout: timeout, completion: completion)
        }
    }
    
    public func discoverAllServicesAndCharacteristics(
        timeout: TimeInterval = UUCoreBluetooth.Defaults.operationTimeout,
        completion: @escaping UUPeripheralErrorBlock)
    {
        connect(timeout: timeout)
        {
            self.discoverServices
            { services, discoverServicesError in
                
                if let err = discoverServicesError
                {
                    completion(self, err)
                    return
                }
                
                guard let actualServices = services else
                {
                    completion(self, nil)
                    return
                }
                
                self.discoverNextCharacteristics(actualServices, timeout: timeout)
                { _, error in
                    
                    self.disconnect()
                }
            }
        }
        disconnected:
        { disconnectError in
            
            completion(self, disconnectError)
        }
    }
    
    
    // Block based wrapper around CBPeripheral setNotifyValue, with an optional
    // timeout value.  A negative timeout value will disable the timeout.
    public func setNotifyValue(
        enabled: Bool,
        for characteristic: CBCharacteristic,
        timeout: TimeInterval = UUCoreBluetooth.Defaults.operationTimeout,
        notifyHandler: UUPeripheralCharacteristicErrorBlock?,
        completion: @escaping UUPeripheralCharacteristicErrorBlock)
    {
        UUDebugLog("Set Notify State for \(self.debugName), enabled: \(enabled), timeout: \(timeout), characateristic: \(characteristic)")
        
        let timerId = TimerId.characteristicNotifyState
        
        delegate.setNotifyValueForCharacteristicBlock =
        { peripheral, characteristic, error in
            
            self.finishOperation(timerId, peripheral, characteristic, error, completion)
        };
        
        if (enabled)
        {
            let handler: UUCBPeripheralCharacteristicErrorBlock =
            { p, characteristic, error in
                notifyHandler?(self, characteristic, error)
            }
            
            delegate.registerUpdateHandler(handler, characteristic)
        }
        else
        {
            delegate.removeUpdateHandlerForCharacteristic(characteristic)
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
        
        underlyingPeripheral.setNotifyValue(enabled, for: characteristic)
    }
    
    private func endSetNotify(_ characteristic: CBCharacteristic, _ error: Error?)
    {
        dispatchQueue.async
        {
            self.delegate.peripheral(self.underlyingPeripheral, didUpdateNotificationStateFor: characteristic, error: error)
        }
    }
    
    // Block based wrapper around CBPeripheral readValue:forCharacteristic, with an
    // optional timeout value.  A negative timeout value will disable the timeout.
    public func readValue(
        for characteristic: CBCharacteristic,
        timeout: TimeInterval = UUCoreBluetooth.Defaults.operationTimeout,
        completion: @escaping UUPeripheralCharacteristicErrorBlock)
    {
        UUDebugLog("Read value for \(self.debugName), characteristic: \(characteristic), timeout: \(timeout)")
        
        let timerId = TimerId.readCharacteristic
        
        delegate.registerReadHandler(
            { peripheral, characteristic, error in
                
                let err = self.prepareToFinishOperation(timerId, error)
                
                self.delegate.removeReadHandler(characteristic)
                completion(self, characteristic, err)
                
            }, characteristic)
        
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
        
        underlyingPeripheral.readValue(for: characteristic)
    }
    
    private func endReadValue(_ characteristic: CBCharacteristic, _ error: Error?)
    {
        dispatchQueue.async
        {
            self.delegate.peripheral(self.underlyingPeripheral, didUpdateValueFor: characteristic, error: error)
        }
    }
    
    // Block based wrapper around CBPeripheral readValue:forCharacteristic, with an
    // optional timeout value.  A negative timeout value will disable the timeout.
    public func readValue(
        for descriptor: CBDescriptor,
        timeout: TimeInterval = UUCoreBluetooth.Defaults.operationTimeout,
        completion: @escaping UUPeripheralDescriptorErrorBlock)
    {
        UUDebugLog("Read value for \(self.debugName), descriptor: \(descriptor), timeout: \(timeout)")
        
        let timerId = TimerId.readDescriptor
        
        delegate.registerReadHandler(
            { peripheral, descriptor, error in
                
                let err = self.prepareToFinishOperation(timerId, error)
                self.delegate.removeReadHandler(descriptor)
                completion(self, descriptor, err)
                
            }, descriptor)
        
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
        
        underlyingPeripheral.readValue(for: descriptor)
    }
    
    private func endReadDescriptor(_ descriptor: CBDescriptor, _ error: Error?)
    {
        dispatchQueue.async
        {
            self.delegate.peripheral(self.underlyingPeripheral, didUpdateValueFor: descriptor, error: error)
        }
    }
    
    // Block based wrapper around CBPeripheral writeValue:forCharacteristic:type with type
    // CBCharacteristicWriteWithResponse, with an optional timeout value.  A negative
    // timeout value will disable the timeout.
    public func writeValue(
        data: Data,
        for characteristic: CBCharacteristic,
        timeout: TimeInterval = UUCoreBluetooth.Defaults.operationTimeout,
        completion: @escaping UUPeripheralCharacteristicErrorBlock)
    {
        UUDebugLog("Write value \(data.uuToHexString()), for \(self.debugName), characteristic: \(characteristic), timeout: \(timeout)")
        
        let timerId = TimerId.writeCharacteristic
        
        delegate.registerWriteHandler(
            { peripheral, characteristic, error in
                
                let err = self.prepareToFinishOperation(timerId, error)
                self.delegate.removeWriteHandler(characteristic)
                completion(self, characteristic, err)
                
            }, characteristic)
        
        if let err = canAttemptOperation
        {
            endWriteValue(characteristic, err)
            return
        }
        
        startTimer(timerId, timeout)
        {
            let err = NSError.uuCoreBluetoothError(.timeout)
            self.delegate.peripheral(self.underlyingPeripheral, didWriteValueFor: characteristic, error: err)
        }
        
        underlyingPeripheral.writeValue(data, for: characteristic, type: .withResponse)
    }
    
    private func endWriteValue(_ characteristic: CBCharacteristic, _ error: Error?)
    {
        dispatchQueue.async
        {
            self.delegate.peripheral(self.underlyingPeripheral, didWriteValueFor: characteristic, error: error)
        }
    }
    
    // Block based wrapper around CBPeripheral writeValue:forCharacteristic:type with type
    // CBCharacteristicWriteWithoutResponse.  Block callback is invoked after sending.
    // Per CoreBluetooth documentation, there is no garauntee of delivery.
    public func writeValueWithoutResponse(
        data: Data,
        for characteristic: CBCharacteristic,
        completion: @escaping UUPeripheralCharacteristicErrorBlock)
    {
        UUDebugLog("Write value without response \(data.uuToHexString()), for \(self.debugName), characteristic: \(characteristic)")
        
        if let err = canAttemptOperation
        {
            dispatchQueue.async
            {
                completion(self, characteristic, err)
            }
            
            return
        }
        
        underlyingPeripheral.writeValue(data, for: characteristic, type: .withoutResponse)
    }
    
    // Block based wrapper around CBPeripheral writeValue:forDesctiptor with type
    // CBCharacteristicWriteWithResponse, with an optional timeout value.  A negative
    // timeout value will disable the timeout.
    public func writeValue(
        data: Data,
        for descriptor: CBDescriptor,
        timeout: TimeInterval = UUCoreBluetooth.Defaults.operationTimeout,
        completion: @escaping UUPeripheralDescriptorErrorBlock)
    {
        UUDebugLog("Write value \(data.uuToHexString()), for \(self.debugName), descriptor: \(descriptor), timeout: \(timeout)")
        
        let timerId = TimerId.writeDescriptor
        
        delegate.registerWriteHandler(
            { peripheral, descriptor, error in
                
                let err = self.prepareToFinishOperation(timerId, error)
                
                self.delegate.removeWriteHandler(descriptor)
                completion(self, descriptor, err)
                
            }, descriptor)
        
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
        
        underlyingPeripheral.writeValue(data, for: descriptor)
    }
    
    private func endWriteValue(_ descriptor: CBDescriptor, _ error: Error?)
    {
        dispatchQueue.async
        {
            self.delegate.peripheral(self.underlyingPeripheral, didWriteValueFor: descriptor, error: error)
        }
    }
    
    // Block based wrapper around CBPeripheral readRssi, with an optional
    // timeout value.  A negative timeout value will disable the timeout.
    public func readRSSI(
        timeout: TimeInterval = UUCoreBluetooth.Defaults.operationTimeout,
        completion: @escaping UUPeripheralIntegerErrorBlock)
    {
        UUDebugLog("Reading RSSI for \(self.debugName), timeout: \(timeout)")
        
        let timerId = TimerId.readRssi
        
        delegate.didReadRssiBlock =
        { peripheral, rssi, error in
            
            let err = self.prepareToFinishOperation(timerId, error)
            completion(self, rssi, err)
        }
        
        if let err = canAttemptOperation
        {
            endReadRssi(err)
            return
        }
        
        startTimer(timerId, timeout)
        {
            let err = NSError.uuCoreBluetoothError(.timeout)
            self.endReadRssi(err)
        }
        
        underlyingPeripheral.readRSSI()
    }
    
    private func endReadRssi(_ error: Error?)
    {
        dispatchQueue.async
        {
            self.delegate.peripheral(self.underlyingPeripheral, didReadRSSI: NSNumber(127), error: error)
        }
    }
    
    // Convenience wrapper to perform both service and characteristic discovery at
    // one time.  This method is useful when you know both service and characteristic
    // UUID's ahead of time.
    public func discover(
        characteristics: [CBUUID]?,
        for serviceUuid: CBUUID,
        timeout: TimeInterval,
        completion: @escaping UUDiscoverCharacteristicsCompletionBlock)
    {
        let start = Date().timeIntervalSinceReferenceDate
        
        discoverServices(serviceUUIDs: [serviceUuid], timeout: timeout)
        { discoveredServices, err in
            
            if let error = err
            {
                completion(nil, error)
                return
            }
            
            guard let foundService = discoveredServices?.filter({ $0.uuid.uuidString == serviceUuid.uuidString }).first else
            {
                // QUESTION: Should this emit a 'service not found error'
                completion(nil, err)
                return
            }
            
            let duration = Date().timeIntervalSinceReferenceDate - start
            let remainingTimeout = timeout - duration
            
            self.discoverCharacteristics(characteristicUUIDs: characteristics, for: foundService, timeout: remainingTimeout, completion: completion)
        }
    }
    
    
    
    
    
    
    private func prepareToFinishOperation(
        _ timerBucket: TimerId,
        _ error: Error?) -> Error?
    {
        let err = NSError.uuOperationCompleteError(error as NSError?)
        
        UUDebugLog("Finished \(timerBucket) for \(debugName), error: \(String(describing: err))")
        
        cancelTimer(timerBucket)
        return err
    }
    
    private func finishOperation(
        _ timerBucket: TimerId,
        _ peripheral: CBPeripheral,
        _ error: Error?,
        _ completion: @escaping UUPeripheralErrorBlock)
    {
        let err = prepareToFinishOperation(timerBucket, error)
        completion(self, err)
    }
    
    private func finishOperation(
        _ timerBucket: TimerId,
        _ peripheral: CBPeripheral,
        _ characteristic: CBCharacteristic,
        _ error: Error?,
        _ completion: @escaping UUPeripheralCharacteristicErrorBlock)
    {
        let err = prepareToFinishOperation(timerBucket, error)
        completion(self, characteristic, err)
    }
    
    private func finishDiscoverServices(
        _ timerBucket: TimerId,
        _ error: Error?,
        _ completion: @escaping UUDiscoverServicesCompletionBlock)
    {
        let err = prepareToFinishOperation(timerBucket, error)
        completion(self.services, err)
    }
    
    private func finishDiscoverCharacteristics(
        _ timerBucket: TimerId,
        _ error: Error?,
        _ service: CBService,
        _ completion: @escaping UUDiscoverCharacteristicsCompletionBlock)
    {
        let err = prepareToFinishOperation(timerBucket, error)
        completion(service.characteristics, err)
    }
    
    private func finishDiscoverDescriptors(
        _ timerBucket: TimerId,
        _ error: Error?,
        _ characteristic: CBCharacteristic,
        _ completion: @escaping UUDiscoverDescriptorsCompletionBlock)
    {
        let err = prepareToFinishOperation(timerBucket, error)
        completion(characteristic.descriptors, err)
    }
    
    
    
    
    
    // MARK:- Timers
    
    
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
    }
    
    private func formatTimerId(_ bucket: TimerId) -> String
    {
        return "\(identifier)__\(bucket.rawValue)"
    }
    
    private func cleanupAfterDisconnect()
    {
        UUDebugLog("Cancelling all timers")
        timerPool.cancelAllTimers()
        
        UUDebugLog("Clearing all delegate callbacks")
        delegate.clearBlocks()
    }
    
    private func startTimer(_ timerBucket: TimerId, _ timeout: TimeInterval, _ block: @escaping ()->())
    {
        let timerId = formatTimerId(timerBucket)
        UUDebugLog("Starting bucket timer \(timerId) with timeout: \(timeout)")
        
        timerPool.start(identifier: timerId, timeout: timeout, userInfo: nil)
        { _ in
            block()
        }
    }
    
    private func cancelTimer(_ timerBucket: TimerId)
    {
        let timerId = formatTimerId(timerBucket)
        timerPool.cancel(by: timerId)
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
    
    
    func openL2CAPChannel(psm: CBL2CAPPSM)
    {
        self.underlyingPeripheral.openL2CAPChannel(psm)
    }
    
    func setDidOpenL2ChannelCallback(callback:((CBPeripheral, CBL2CAPChannel?, Error?) -> Void)?)
    {
        self.delegate.didOpenL2ChannelBlock = callback
    }    
}

