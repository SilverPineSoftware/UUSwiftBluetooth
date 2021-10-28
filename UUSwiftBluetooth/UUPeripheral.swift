//
//  UUPeripheral.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 8/13/21.
//

import UIKit
import CoreBluetooth
import UUSwiftCore

public typealias UUPeripheralBlock = ((UUPeripheral)->())
public typealias UUPeripheralErrorBlock = ((UUPeripheral, Error?)->())
public typealias UUPeripheralCharacteristicErrorBlock = ((UUPeripheral, CBCharacteristic, Error?)->())
public typealias UUPeripheralDescriptorErrorBlock = ((UUPeripheral, CBDescriptor, Error?)->())
public typealias UUPeripheralIntegerErrorBlock = ((UUPeripheral, Int, Error?)->())
public typealias UUDiscoverServicesCompletionBlock = (([CBService]?, Error?)->())
public typealias UUDiscoverCharacteristicsCompletionBlock = (([CBCharacteristic]?, Error?)->())

// UUPeripheral is a convenience class that wraps a CBPeripheral and it's
// advertisement data into one object.
//
open class UUPeripheral
{
    public class Defaults
    {
        public static let connectTimeout: TimeInterval = 60.0
        public static let disconnectTimeout: TimeInterval = 10.0
        public static let operationTimeout: TimeInterval = 60.0
    }
    
    private let centralManager: UUCentralManager
    private let dispatchQueue: DispatchQueue
    private let delegate = UUPeripheralDelegate()
    
    // Reference to the underlying CBPeripheral
    public var underlyingPeripheral: CBPeripheral!
    {
        didSet
        {
            underlyingPeripheral.delegate = delegate
        }
    }
    
    // The most recent advertisement data
    var advertisementData: [String: Any] = [:]
    
    // Timestamp of when this peripheral was first seen
    private(set) public var firstAdvertisementTime: Date = Date()
    
    // Timestamp of when the last advertisement was seen
    private(set) public var lastAdvertisementTime: Date = Date()
    
    // Most recent signal strength
    private(set) public var rssi: Int = 0
    
    // Timestamp of when the RSSI was last updated
    private(set) public var lastRssiUpdateTime: Date = Date()
    
    public required init(_ dispatchQueue: DispatchQueue, _ centralManager: UUCentralManager, _ peripheral: CBPeripheral)
    {
        self.dispatchQueue = dispatchQueue
        self.centralManager = centralManager
        self.underlyingPeripheral = peripheral
        peripheral.delegate = delegate
    }
    
    // Passthrough properties to read values directly from CBPeripheral
    
    public var identifier: String
    {
        return underlyingPeripheral.identifier.uuidString
    }
    
    public var name: String
    {
        return underlyingPeripheral.name ?? ""
    }
    
    public var localName: String
    {
        return advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? ""
    }
    
    public var friendlyName: String
    {
        var result = localName
        if (result.isEmpty)
        {
            result = self.name
        }
        
        return result
    }
    
    public var peripheralState: CBPeripheralState
    {
        return underlyingPeripheral.state
    }
    
    public var services: [CBService]?
    {
        return underlyingPeripheral.services
    }
    
    // Returns value of CBAdvertisementDataIsConnectable from advertisement data.  Default
    // value is NO if value is not present. Per the CoreBluetooth documentation, this
    // value indicates if the peripheral is connectable "right now", which implies
    // it may change in the future.
    public var isConnectable: Bool
    {
        return advertisementData.uuGetBool(CBAdvertisementDataIsConnectable) ?? false
    }
    
    // Returns value of CBAdvertisementDataManufacturerDataKey from advertisement data.
    public var manufacturingData: Data?
    {
        return advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data
    }
    
    // Hook for derived classes to parse custom manufacturing data during object creation.
    open func parseManufacturingData()
    {
        
    }
    
    
    
    func updateFromScan(
        _ peripheral: CBPeripheral,
        _ updatedAdvertisement: [String:Any],
        _ rssi: Int)
    {
        underlyingPeripheral = peripheral
        advertisementData = updatedAdvertisement
        lastAdvertisementTime = Date()
        updateRssi(rssi)
        parseManufacturingData()
    }
    
    func updateRssi(_ rssi: Int)
    {
        // Per CoreBluetooth documentation, a value of 127 indicates the RSSI
        // reading is not available
        if rssi != 127
        {
            self.rssi = rssi
            self.lastRssiUpdateTime = Date()
        }
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
       timeout: TimeInterval = Defaults.connectTimeout,
       connected: @escaping ()->(),
       disconnected: @escaping (Error?)->())
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
            
            //NSLog("Connected to \(peripheral.uuIdentifier) - \(peripheral.uuName)")
            
            self.cancelTimer(timerId)
            connected()
        };
        
        let disconnectedBlock: UUCBPeripheralErrorBlock =
        { p, error in
            
            //NSLog("Disconnected from \(peripheral.uuIdentifier) - \(peripheral.uuName), error: \(String(describing: error))")
            
            self.cancelAllTimers()
            
            disconnected(error)
        }
        
        centralManager.registerConnectionBlocks(self, connectedBlock, disconnectedBlock)
        
        startTimer(timerId, timeout)
        {
            
            NSLog("Connect timeout for \(self.debugName)")
             
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
        
        centralManager.connect(self, nil)
    }

    // Wrapper around CBCentralManager cancelPeripheralConnection.  After calling this
    // method, the disconnected block passed in at connect time will be invoked.
    public func disconnect(timeout: TimeInterval = Defaults.disconnectTimeout)
    {
        guard centralManager.isPoweredOn else
        {
            NSLog("Central is not powered on, cannot cancel a connection!")
            let err = NSError.uuCoreBluetoothError(.centralNotReady)
            centralManager.notifyDisconnect(self, err)
            return
        }
        
        let timerId = TimerId.disconnect
        
        NSLog("Starting disconnect timeout")
        startTimer(timerId, timeout)
        {
            NSLog("Disconnect timeout for \(self.debugName)")
            
            self.cancelTimer(timerId)
            self.centralManager.notifyDisconnect(self, NSError.uuCoreBluetoothError(.timeout))
            
            // Just in case the timeout fires and a real disconnect is needed, this is the last
            // ditch effort to close the connection
            self.centralManager.cancelPeripheralConnection(self)
        }
        
        
        NSLog("Cancelling peripheral connection for \(self.debugName)")
        centralManager.cancelPeripheralConnection(self)
    }
   
    // Block based wrapper around CBPeripheral discoverServices, with an optional
    // timeout value.  A negative timeout value will disable the timeout.
    public func discoverServices(
        _ serviceUUIDs: [CBUUID]? = nil,
        timeout: TimeInterval = Defaults.operationTimeout,
        completion: @escaping UUDiscoverServicesCompletionBlock)
    {
        NSLog("Discovering services for \(self.debugName), timeout: \(timeout), service list: \(String(describing: serviceUUIDs))")
        
        let timerId = TimerId.serviceDiscovery
        
        delegate.discoverServicesBlock =
        { peripheral, errOpt in
            
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
        _ characteristicUUIDs: [CBUUID]?,
        for service: CBService,
        timeout: TimeInterval = Defaults.operationTimeout,
        completion: @escaping UUDiscoverCharacteristicsCompletionBlock)
    {
        NSLog("Discovering characteristics for \(self.debugName), timeout: \(timeout), service: \(service), characteristic list: \(String(describing: characteristicUUIDs))")
        
        let timerId = TimerId.characteristicDiscovery
        
        delegate.discoverCharacteristicsBlock =
        { peripheral, service, error in
            
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
        _ includedServiceUUIDs: [CBUUID]?,
        for service: CBService,
        timeout: TimeInterval = Defaults.operationTimeout,
        completion: @escaping UUPeripheralErrorBlock)
    {
        NSLog("Discovering included services for \(self.debugName), timeout: \(timeout), service: \(service), service list: \(String(describing: includedServiceUUIDs))")
        
        let timerId = TimerId.includedServicesDiscovery
        
        delegate.discoverIncludedServicesBlock =
        { peripheral, service, error in
            
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
        timeout: TimeInterval = Defaults.operationTimeout,
        completion: @escaping UUPeripheralCharacteristicErrorBlock)
    {
        NSLog("Discovering descriptors for \(self.debugName), timeout: \(timeout), characteristic: \(characteristic)")
        
        let timerId = TimerId.descriptorDiscovery
        
        delegate.discoverDescriptorsBlock =
        { peripheral, characteristic, error in
            
            self.finishOperation(timerId, peripheral, characteristic, error, completion)
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
    
    // Block based wrapper around CBPeripheral setNotifyValue, with an optional
    // timeout value.  A negative timeout value will disable the timeout.
    public func setNotifyValue(
        _ enabled: Bool,
        for characteristic: CBCharacteristic,
        timeout: TimeInterval = Defaults.operationTimeout,
        notifyHandler: UUPeripheralCharacteristicErrorBlock?,
        completion: @escaping UUPeripheralCharacteristicErrorBlock)
    {
        NSLog("Set Notify State for \(self.debugName), enabled: \(enabled), timeout: \(timeout), characateristic: \(characteristic)")
        
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
        timeout: TimeInterval = Defaults.operationTimeout,
        completion: @escaping UUPeripheralCharacteristicErrorBlock)
    {
        NSLog("Read value for \(self.debugName), characteristic: \(characteristic), timeout: \(timeout)")
        
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
        timeout: TimeInterval = Defaults.operationTimeout,
        completion: @escaping UUPeripheralDescriptorErrorBlock)
    {
        NSLog("Read value for \(self.debugName), descriptor: \(descriptor), timeout: \(timeout)")
        
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
        _ data: Data,
        for characteristic: CBCharacteristic,
        timeout: TimeInterval = Defaults.operationTimeout,
        completion: @escaping UUPeripheralCharacteristicErrorBlock)
    {
        NSLog("Write value \(data.uuToHexString()), for \(self.debugName), characteristic: \(characteristic), timeout: \(timeout)")
        
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
        _ data: Data,
        for characteristic: CBCharacteristic,
        completion: @escaping UUPeripheralCharacteristicErrorBlock)
    {
        NSLog("Write value without response \(data.uuToHexString()), for \(self.debugName), characteristic: \(characteristic)")
        
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
        _ data: Data,
        for descriptor: CBDescriptor,
        timeout: TimeInterval = Defaults.operationTimeout,
        completion: @escaping UUPeripheralDescriptorErrorBlock)
    {
        NSLog("Write value \(data.uuToHexString()), for \(self.debugName), descriptor: \(descriptor), timeout: \(timeout)")
        
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
        timeout: TimeInterval = Defaults.operationTimeout,
        completion: @escaping UUPeripheralIntegerErrorBlock)
    {
        NSLog("Reading RSSI for \(self.debugName), timeout: \(timeout)")
        
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
        
        //discoverServices([serviceUuid], timeout: timeout)
        discoverServices(nil, timeout: timeout)
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
            
            //self.discoverCharacteristics(characteristics, for: foundService, timeout: remainingTimeout, completion: completion)
            self.discoverCharacteristics(nil, for: foundService, timeout: remainingTimeout, completion: completion)
        }
    }
    
    
    
    
    
    
    private func prepareToFinishOperation(
        _ timerBucket: TimerId,
        _ error: Error?) -> Error?
    {
        let err = NSError.uuOperationCompleteError(error as NSError?)
        
        NSLog("Finished \(timerBucket) for \(debugName), error: \(String(describing: err))")
        
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

    private func cancelAllTimers()
    {
        NSLog("Cancelling all timers")
        
        let list = UUTimer.listActiveTimers()
        for t in list
        {
            NSLog("Active timer: \(t.timerId)")
            
            if (t.timerId.starts(with: identifier))
            {
                NSLog("Cancelling Peripheral Timer: \(t.timerId)")
                t.cancel()
            }
        }
    }
    
    private func startTimer(_ timerBucket: TimerId, _ timeout: TimeInterval, _ block: @escaping ()->())
    {
        let timerId = formatTimerId(timerBucket)
        NSLog("Starting bucket timer \(timerId) with timeout: \(timeout)")
        
        UUTimer.startWatchdogTimer(timerId, timeout, nil, queue: dispatchQueue)
        { _ in
            
            block()
        }
    }
    
    private func cancelTimer(_ timerBucket: TimerId)
    {
        let timerId = formatTimerId(timerBucket)
        UUTimer.cancelWatchdogTimer(timerId)
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
    
}

