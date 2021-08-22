//
//  CBPeripheral+Extensions.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 8/13/21.
//

import UIKit
import CoreBluetooth
import UUSwiftCore

extension CBPeripheral
{
    var uuIdentifier: String
    {
        return identifier.uuidString
    }
    
    var uuName: String
    {
        return name ?? ""
    }
    
    private static var uuSharedDelegates: [String:UUPeripheralDelegate] = [:]
    private static let uuSharedDelegatesMutex = NSRecursiveLock()
        
        
    private static func uuDelegateForPeripheral(_ peripheral: CBPeripheral) -> UUPeripheralDelegate
    {
        defer { uuSharedDelegatesMutex.unlock() }
        uuSharedDelegatesMutex.lock()
        
        if let existing = uuSharedDelegates[peripheral.uuIdentifier]
        {
            return existing
        }
        
        let delegate = UUPeripheralDelegate(peripheral)
        uuAddDelegate(delegate)
        return delegate
    }
    
    private static func uuAddDelegate(_ delegate: UUPeripheralDelegate)
    {
        defer { uuSharedDelegatesMutex.unlock() }
        uuSharedDelegatesMutex.lock()
        
        uuSharedDelegates[delegate.peripheral.uuIdentifier] = delegate
    }
    
    private static func uuRemoveDelegate(_ delegate: UUPeripheralDelegate)
    {
        defer { uuSharedDelegatesMutex.unlock() }
        uuSharedDelegatesMutex.lock()
        
        uuSharedDelegates.removeValue(forKey: delegate.peripheral.uuIdentifier)
    }
    
    private var uuDelegate: UUPeripheralDelegate
    {
        return CBPeripheral.uuDelegateForPeripheral(self)
    }
    
    private enum TimerBucket: String
    {
        case connectWatchdogBucket
        case serviceDiscoveryWatchdogBucket
        case characteristicDiscoveryWatchdogBucket
        case includedServicesDiscoveryWatchdogBucket
        case descriptorDiscoveryWatchdogBucket
        case characteristicNotifyStateWatchdogBucket
        case readCharacteristicValueWatchdogBucket
        case writeCharacteristicValueWatchdogBucket
        case readDescriptorValueWatchdogBucket
        case writeDescriptorValueWatchdogBucket
        case readRssiWatchdogBucket
        case pollRssiBucket
        case disconnectWatchdogBucket

    }

    private func formatTimerId(_ bucket: TimerBucket) -> String
    {
        return "\(uuIdentifier)__\(bucket.rawValue)"
    }

    func uuConnectWatchdogTimerId() -> String
    {
        return formatTimerId(.connectWatchdogBucket)
    }

    func uuDisconnectWatchdogTimerId() -> String
    {
        return formatTimerId(.disconnectWatchdogBucket)
    }

    private func uuServiceDiscoveryWatchdogTimerId() -> String
    {
        return formatTimerId(.serviceDiscoveryWatchdogBucket)
    }

    private func uuCharacteristicDiscoveryWatchdogTimerId() -> String
    {
        return formatTimerId(.characteristicDiscoveryWatchdogBucket)
    }

    private func uuIncludedServicesDiscoveryWatchdogTimerId() -> String
    {
        return formatTimerId(.includedServicesDiscoveryWatchdogBucket)
    }

    private func uuDescriptorDiscoveryWatchdogTimerId() -> String
    {
        return formatTimerId(.descriptorDiscoveryWatchdogBucket)
    }

    private func uuCharacteristicNotifyStateWatchdogTimerId() -> String
    {
        return formatTimerId(.characteristicNotifyStateWatchdogBucket)
    }

    private func uuReadCharacteristicValueWatchdogTimerId() -> String
    {
        return formatTimerId(.readCharacteristicValueWatchdogBucket)
    }
    
    private func uuReadDescriptorValueWatchdogTimerId() -> String
    {
        return formatTimerId(.readDescriptorValueWatchdogBucket)
    }

    private func uuWriteCharacteristicValueWatchdogTimerId() -> String
    {
        return formatTimerId(.writeCharacteristicValueWatchdogBucket)
    }
    
    private func uuWriteDescriptorValueWatchdogTimerId() -> String
    {
        return formatTimerId(.writeDescriptorValueWatchdogBucket)
    }

    private func uuReadRssiWatchdogTimerId() -> String
    {
        return formatTimerId(.readRssiWatchdogBucket)
    }

    private func uuPollRssiTimerId() -> String
    {
        return formatTimerId(.pollRssiBucket)
    }

    func uuCancelAllTimers()
    {
        let list = UUTimer.listActiveTimers()
        for t in list
        {
            if (t.timerId.starts(with: uuIdentifier))
            {
                t.cancel()
            }
        }
    }
    
    func uuStartTimer(_ timerId: String, _ timeout: TimeInterval, _ block: @escaping UUCBPeripheralBlock)
    {
        NSLog("Starting timer \(timerId) with timeout: \(timeout)")
        UUCoreBluetooth.startWatchdogTimer(timerId, timeout: timeout, userInfo: self)
        { info in
            
            if let p = info as? CBPeripheral
            {
                block(p)
            }
        }
    }
    
    func uuCancelTimer(_ timerId: String)
    {
        UUTimer.cancelWatchdogTimer(timerId)
    }
    
    private var uuCanAttemptOperation: Error?
    {
        if (!UUCoreBluetooth.shared.uuIsPoweredOn)
        {
            return NSError.uuCoreBluetoothError(.centralNotReady)
        }
        
        if (self.state != .connected)
        {
            return NSError.uuCoreBluetoothError(.notConnected)
        }
        
        return nil
    }
    
    // Block based wrapper around CBPeripheral discoverServices, with an optional
    // timeout value.  A negative timeout value will disable the timeout.
    public func uuDiscoverServices(
        _ serviceUuidList: [CBUUID]?,
        _ timeout: TimeInterval,
        _ completion: @escaping UUDiscoverServicesBlock)
    {
        NSLog("Discovering services for \(uuIdentifier) - \(uuName), timeout: \(timeout), service list: \(String(describing: serviceUuidList))")
        
        let timerId = uuServiceDiscoveryWatchdogTimerId()
        
        let delegate = CBPeripheral.uuDelegateForPeripheral(self)
        self.delegate = delegate
        delegate.discoverServicesBlock =
        { peripheral, errOpt in
            
            let err = NSError.uuOperationCompleteError(errOpt as NSError?)
            
            NSLog("Service discovery finished for \(peripheral.uuIdentifier) - \(peripheral.uuName), error: \(String(describing: err)), services: \(String(describing: peripheral.services))")
            
            self.uuCancelTimer(timerId)
            completion(peripheral, err)
        }
        
        uuStartTimer(timerId, timeout)
        { peripheral in
            
            NSLog("Service discovery timeout for \(peripheral.uuIdentifier) - \(peripheral.uuName)")
            
            let err = NSError.uuCoreBluetoothError(.timeout)
            delegate.peripheral(peripheral, didDiscoverServices: err)
        }
        
        if let err = uuCanAttemptOperation
        {
            UUCoreBluetooth.dispatchQueue.async
            {
                delegate.peripheral(self, didDiscoverServices: err)
            }
            
            return
        }
        
        discoverServices(serviceUuidList)
    }

    // Block based wrapper around CBPeripheral discoverCharacteristics:forService,
    // with an optional timeout value.  A negative timeout value will disable the timeout.
    public func uuDiscoverCharacteristics(
        _ characteristicUuidList: [CBUUID]?,
        _ service: CBService,
        _ timeout: TimeInterval,
        _ completion: @escaping UUDiscoverCharacteristicsBlock)
    {
        NSLog("Discovering characteristics for \(uuIdentifier) - \(uuName), timeout: \(timeout), service: \(service), characteristic list: \(String(describing: characteristicUuidList))")
        
        let timerId = uuCharacteristicDiscoveryWatchdogTimerId()
        
        let delegate = CBPeripheral.uuDelegateForPeripheral(self)
        self.delegate = delegate
        delegate.discoverCharacteristicsBlock =
        { peripheral, service, error in
            
            NSLog("Characteristic discovery finished for \(peripheral.uuIdentifier) - \(peripheral.uuName), service: \(service), error: \(String(describing: error)), characteristics: \(String(describing: service.characteristics))")
            
            self.uuCancelTimer(timerId)
            completion(peripheral, service, error)
        }
        
        uuStartTimer(timerId, timeout)
        { peripheral in
            
            NSLog("Characteristic discovery timeout for \(peripheral.uuIdentifier) - \(peripheral.uuName)")
            
            let err = NSError.uuCoreBluetoothError(.timeout)
            delegate.peripheral(peripheral, didDiscoverCharacteristicsFor: service, error: err)
        }
        
        if let err = uuCanAttemptOperation
        {
            UUCoreBluetooth.dispatchQueue.async
            {
                delegate.peripheral(self, didDiscoverCharacteristicsFor: service, error: err)
            }
            
            return
        }
        
        discoverCharacteristics(characteristicUuidList, for: service)
    }

    // Block based wrapper around CBPeripheral discoverIncludedServices:forService,
    // with an optional timeout value.  A negative timeout value will disable the timeout.
    public func uuDiscoverIncludedServices(
        _ serviceUuidList: [CBUUID]?,
        _ service: CBService,
        _ timeout: TimeInterval,
        _ completion: @escaping UUDiscoverIncludedServicesBlock)
    {
        NSLog("Discovering included services for \(uuIdentifier) - \(uuName), timeout: \(timeout), service: \(service), service list: \(String(describing: serviceUuidList))")
        
        let timerId = uuIncludedServicesDiscoveryWatchdogTimerId()
        
        let delegate = CBPeripheral.uuDelegateForPeripheral(self)
        self.delegate = delegate
        delegate.discoverIncludedServicesBlock =
        { peripheral, service, error in
            
            let err = NSError.uuOperationCompleteError(error as NSError?)
            
            NSLog("Included services discovery finished for \(peripheral.uuIdentifier) - \(peripheral.uuName), service: \(service), error: \(String(describing: err)), includedServices: \(String(describing: service.includedServices))")
            
            self.uuCancelTimer(timerId)
            completion(peripheral, service, error)
        }
        
        uuStartTimer(timerId, timeout)
        { peripheral in
            
            NSLog("Included services discovery timeout for \(peripheral.uuIdentifier) - \(peripheral.uuName)")
            
            let err = NSError.uuCoreBluetoothError(.timeout)
            delegate.peripheral(peripheral, didDiscoverIncludedServicesFor: service, error: err)
        }
        
        if let err = uuCanAttemptOperation
        {
            UUCoreBluetooth.dispatchQueue.async
            {
                delegate.peripheral(self, didDiscoverIncludedServicesFor: service, error: err)
            }
            
            return
        }
        
        discoverIncludedServices(serviceUuidList, for: service)
        
//        else if (service == nil)
//        {
//            dispatch_async(UUCoreBluetoothQueue(), ^
//            {
//                NSError* err = [NSError uuExpectNonNilParamError:@"service"];
//                [delegate peripheral:self didDiscoverCharacteristicsForService:service error:err];
//            });
//        }
    }
    
    // Block based wrapper around CBPeripheral discoverDescriptorsForCharacteristic,
    // with an optional timeout value.  A negative timeout value will disable the timeout.
    public func uuDiscoverDescriptorsForCharacteristic(
        _ characteristic: CBCharacteristic,
        _ timeout: TimeInterval,
        _ completion: @escaping UUDiscoverDescriptorsBlock)
    {
        NSLog("Discovering descriptors for \(uuIdentifier) - \(uuName), timeout: \(timeout), characteristic: \(characteristic)")
        
        let timerId = uuDescriptorDiscoveryWatchdogTimerId()
        
        let delegate = CBPeripheral.uuDelegateForPeripheral(self)
        self.delegate = delegate
        delegate.discoverDescriptorsBlock =
        { peripheral, characteristic, error in
            
            let err = NSError.uuOperationCompleteError(error as NSError?)
            
            NSLog("Descriptor discovery finished for \(peripheral.uuIdentifier) - \(peripheral.uuName), characteristic: \(characteristic), error: \(String(describing: err)), descriptors: \(String(describing: characteristic.descriptors))")
            
            self.uuCancelTimer(timerId)
            completion(peripheral, characteristic, error)
        }
        
        uuStartTimer(timerId, timeout)
        { peripheral in
            
            NSLog("Descriptor discovery timeout for \(peripheral.uuIdentifier) - \(peripheral.uuName)")
            
            let err = NSError.uuCoreBluetoothError(.timeout)
            delegate.peripheral(peripheral, didDiscoverDescriptorsFor: characteristic, error: err)
        }
        
        if let err = uuCanAttemptOperation
        {
            UUCoreBluetooth.dispatchQueue.async
            {
                delegate.peripheral(self, didDiscoverDescriptorsFor: characteristic, error: err)
            }
            
            return
        }
        
//        else if (characteristic == nil)
//        {
//            dispatch_async(UUCoreBluetoothQueue(), ^
//            {
//                NSError* err = [NSError uuExpectNonNilParamError:@"characteristic"];
//                [delegate peripheral:self didDiscoverDescriptorsForCharacteristic:characteristic error:err];
//            });
//        }
        
        
        discoverDescriptors(for: characteristic)
    }
    
    // Block based wrapper around CBPeripheral setNotifyValue, with an optional
    // timeout value.  A negative timeout value will disable the timeout.
    public func uuSetNotifyValue(
        _ enabled: Bool,
        _ characteristic: CBCharacteristic,
        _ timeout: TimeInterval,
        _ notifyHandler: UUUpdateValueForCharacteristicsBlock?,
        _ completion: @escaping UUSetNotifyValueForCharacteristicsBlock)
    {
        NSLog("Set Notify State for \(uuIdentifier) - \(uuName), enabled: \(enabled), timeout: \(timeout), characateristic: \(characteristic)")
        
        let timerId = uuCharacteristicNotifyStateWatchdogTimerId()
        
        let delegate = CBPeripheral.uuDelegateForPeripheral(self)
        self.delegate = delegate
        delegate.setNotifyValueForCharacteristicBlock =
        { peripheral, characteristic, error in
            
            let err = NSError.uuOperationCompleteError(error as NSError?)
            
            NSLog("Set Notify State finished for \(peripheral.uuIdentifier) - \(peripheral.uuName), characteristic: \(characteristic), error: \(String(describing: err))")
            
            self.uuCancelTimer(timerId)
            completion(peripheral, characteristic, err)
        };
        
        if (enabled)
        {
            delegate.registerUpdateHandler(notifyHandler, characteristic)
        }
        else
        {
            delegate.removeUpdateHandlerForCharacteristic(characteristic)
        }
        
        uuStartTimer(timerId, timeout)
        { peripheral in
            
            NSLog("Set Notify State timeout for \(peripheral.uuIdentifier) - \(peripheral.uuName)")
            
            let err = NSError.uuCoreBluetoothError(.timeout)
            delegate.peripheral(peripheral, didUpdateNotificationStateFor: characteristic, error: err)
        }
        
        if let err = uuCanAttemptOperation
        {
            UUCoreBluetooth.dispatchQueue.async
            {
                delegate.peripheral(self, didUpdateNotificationStateFor: characteristic, error: err)
            }
            
            return
        }
        
//        else if (characteristic == nil)
//        {
//            dispatch_async(UUCoreBluetoothQueue(), ^
//            {
//                NSError* err = [NSError uuExpectNonNilParamError:@"characteristic"];
//                [delegate peripheral:self didUpdateNotificationStateForCharacteristic:characteristic error:err];
//            });
//        }
        
        setNotifyValue(enabled, for: characteristic)
    }

    // Block based wrapper around CBPeripheral readValue:forCharacteristic, with an
    // optional timeout value.  A negative timeout value will disable the timeout.
    public func uuReadValueForCharacteristic(
        _ characteristic: CBCharacteristic,
        _ timeout: TimeInterval,
        _ completion: @escaping UUReadValueForCharacteristicsBlock)
    {
        NSLog("Read value for \(uuIdentifier) - \(uuName), characteristic: \(characteristic), timeout: \(timeout)")
        
        let timerId = uuReadCharacteristicValueWatchdogTimerId()
        
        let delegate = Self.uuDelegateForPeripheral(self)
        self.delegate = delegate
        
        delegate.registerReadHandler(
        { peripheral, characteristic, error in
            
            let err = NSError.uuOperationCompleteError(error as NSError?)
            
            NSLog("Read value finished for \(peripheral.uuIdentifier) - \(peripheral.uuName), characteristic: \(characteristic), error: \(String(describing: err))")
            
            self.uuCancelTimer(timerId)
            delegate.removeReadHandler(characteristic)
            completion(peripheral, characteristic, err)
            
        }, characteristic)
        
        uuStartTimer(timerId, timeout)
        { peripheral in
            
            NSLog("Read value timeout for \(peripheral.uuIdentifier) - \(peripheral.uuName)")
            
            let err = NSError.uuCoreBluetoothError(.timeout)
            delegate.peripheral(peripheral, didUpdateValueFor: characteristic, error: err)
        }
        
        if let err = uuCanAttemptOperation
        {
            UUCoreBluetooth.dispatchQueue.async
            {
                delegate.peripheral(self, didUpdateValueFor: characteristic, error: err)
            }
            
            return
        }
        
//        else if (characteristic == nil)
//        {
//            dispatch_async(UUCoreBluetoothQueue(), ^
//            {
//                NSError* err = [NSError uuExpectNonNilParamError:@"characteristic"];
//                [delegate peripheral:self didUpdateValueForCharacteristic:characteristic error:err];
//            });
//        }
        
        readValue(for: characteristic)
    }
    
    // Block based wrapper around CBPeripheral readValue:forCharacteristic, with an
    // optional timeout value.  A negative timeout value will disable the timeout.
    public func uuReadValueForDescriptor(
        _ descriptor: CBDescriptor,
        _ timeout: TimeInterval,
        _ completion: @escaping UUReadValueForDescriptorBlock)
    {
        NSLog("Read value for \(uuIdentifier) - \(uuName), descriptor: \(descriptor), timeout: \(timeout)")
        
        let timerId = uuReadDescriptorValueWatchdogTimerId()
        
        let delegate = Self.uuDelegateForPeripheral(self)
        self.delegate = delegate
        
        delegate.registerReadHandler(
        { peripheral, descriptor, error in
            
            let err = NSError.uuOperationCompleteError(error as NSError?)
            
            NSLog("Read value finished for \(peripheral.uuIdentifier) - \(peripheral.uuName), descriptor: \(descriptor), error: \(String(describing: err))")
            
            self.uuCancelTimer(timerId)
            delegate.removeReadHandler(descriptor)
            completion(peripheral, descriptor, err)
            
        }, descriptor)
        
        uuStartTimer(timerId, timeout)
        { peripheral in
            
            NSLog("Read descriptor timeout for \(peripheral.uuIdentifier) - \(peripheral.uuName)")
            
            let err = NSError.uuCoreBluetoothError(.timeout)
            delegate.peripheral(peripheral, didUpdateValueFor: descriptor, error: err)
        }
        
        if let err = uuCanAttemptOperation
        {
            UUCoreBluetooth.dispatchQueue.async
            {
                delegate.peripheral(self, didUpdateValueFor: descriptor, error: err)
            }
            
            return
        }
        
        readValue(for: descriptor)
    }
    
    // Block based wrapper around CBPeripheral writeValue:forCharacteristic:type with type
    // CBCharacteristicWriteWithResponse, with an optional timeout value.  A negative
    // timeout value will disable the timeout.
    public func uuWriteValue(
        _ data: Data,
        _ characteristic: CBCharacteristic,
        _ timeout: TimeInterval,
        _ completion: @escaping UUWriteValueForCharacteristicsBlock)
    {
        NSLog("Write value \(data.uuToHexString()), for \(uuIdentifier) - \(uuName), characteristic: \(characteristic), timeout: \(timeout)")
        
        let timerId = uuWriteCharacteristicValueWatchdogTimerId()
        
        let delegate = Self.uuDelegateForPeripheral(self)
        self.delegate = delegate
        
        delegate.registerWriteHandler(
        { peripheral, characteristic, error in
        
            let err = NSError.uuOperationCompleteError(error as NSError?)
            
            NSLog("Write value finished for \(peripheral.uuIdentifier) - \(peripheral.uuName), characteristic: \(characteristic), error: \(String(describing: err))")
            
            self.uuCancelTimer(timerId)
            delegate.removeWriteHandler(characteristic)
            completion(peripheral, characteristic, err)
            
        }, characteristic)
        
        uuStartTimer(timerId, timeout)
        { peripheral in
            
            NSLog("Write value timeout for \(peripheral.uuIdentifier) - \(peripheral.uuName)")
            
            let err = NSError.uuCoreBluetoothError(.timeout)
            delegate.peripheral(peripheral, didWriteValueFor: characteristic, error: err)
        }
        
        if let err = uuCanAttemptOperation
        {
            UUCoreBluetooth.dispatchQueue.async
            {
                delegate.peripheral(self, didWriteValueFor: characteristic, error: err)
            }
            
            return
        }
        
//        else if (characteristic == nil)
//        {
//            dispatch_async(UUCoreBluetoothQueue(), ^
//            {
//                NSError* err = [NSError uuExpectNonNilParamError:@"characteristic"];
//                [delegate peripheral:self didWriteValueForCharacteristic:characteristic error:err];
//            });
//        }
        
        writeValue(data, for: characteristic, type: .withResponse)
    }

    // Block based wrapper around CBPeripheral writeValue:forCharacteristic:type with type
    // CBCharacteristicWriteWithoutResponse.  Block callback is invoked after sending.
    // Per CoreBluetooth documentation, there is no garauntee of delivery.
    public func uuWriteValueWithoutResponse(
        _ data: Data,
        _ characteristic: CBCharacteristic,
        _ completion: @escaping UUWriteValueForCharacteristicsBlock)
    {
        NSLog("Write value without response \(data.uuToHexString()), for \(uuIdentifier) - \(uuName), characteristic: \(characteristic)")
        
        if let err = uuCanAttemptOperation
        {
            UUCoreBluetooth.dispatchQueue.async
            {
                completion(self, characteristic, err)
            }
            
            return
        }
        
        writeValue(data, for: characteristic, type: .withoutResponse)
    }
    
    // Block based wrapper around CBPeripheral writeValue:forDesctiptor with type
    // CBCharacteristicWriteWithResponse, with an optional timeout value.  A negative
    // timeout value will disable the timeout.
    public func uuWriteValue(
        _ data: Data,
        _ descriptor: CBDescriptor,
        _ timeout: TimeInterval,
        _ completion: @escaping UUWriteValueForDescriptorBlock)
    {
        NSLog("Write value \(data.uuToHexString()), for \(uuIdentifier) - \(uuName), descriptor: \(descriptor), timeout: \(timeout)")
        
        let timerId = uuWriteDescriptorValueWatchdogTimerId()
        
        let delegate = Self.uuDelegateForPeripheral(self)
        self.delegate = delegate
        
        delegate.registerWriteHandler(
        { peripheral, descriptor, error in
        
            let err = NSError.uuOperationCompleteError(error as NSError?)
            
            NSLog("Write value finished for \(peripheral.uuIdentifier) - \(peripheral.uuName), descriptor: \(descriptor), error: \(String(describing: err))")
            
            self.uuCancelTimer(timerId)
            delegate.removeWriteHandler(descriptor)
            completion(peripheral, descriptor, err)
            
        }, descriptor)
        
        uuStartTimer(timerId, timeout)
        { peripheral in
            
            NSLog("Write descriptor value timeout for \(peripheral.uuIdentifier) - \(peripheral.uuName)")
            
            let err = NSError.uuCoreBluetoothError(.timeout)
            delegate.peripheral(peripheral, didWriteValueFor: descriptor, error: err)
        }
        
        if let err = uuCanAttemptOperation
        {
            UUCoreBluetooth.dispatchQueue.async
            {
                delegate.peripheral(self, didWriteValueFor: descriptor, error: err)
            }
            
            return
        }
        
        writeValue(data, for: descriptor)
    }
    
    // TODO: Read/Write descriptors
    
    // Block based wrapper around CBPeripheral readRssi, with an optional
    // timeout value.  A negative timeout value will disable the timeout.
    public func uuReadRssi(
        _ timeout: TimeInterval,
        _ completion: @escaping UUDidReadRssiBlock)
    {
        NSLog("Reading RSSI for \(uuIdentifier) - \(uuName), timeout: \(timeout)")
        
        let timerId = uuReadRssiWatchdogTimerId()
        
        let delegate = Self.uuDelegateForPeripheral(self)
        self.delegate = delegate
        delegate.didReadRssiBlock =
        { peripheral, rssi, error in
            
            let err = NSError.uuOperationCompleteError(error as NSError?)
            
            NSLog("Read RSSI finished for \(peripheral.uuIdentifier) - \(peripheral.uuName), rssi: \(rssi), error: \(String(describing: err))")
            
            self.uuCancelTimer(timerId)
            completion(peripheral, rssi, error)
        }
        
        uuStartTimer(timerId, timeout)
        { peripheral in
            
            NSLog("Read RSSI timeout for \(peripheral.uuIdentifier) - \(peripheral.uuName)")
            
            let err = NSError.uuCoreBluetoothError(.timeout)
            delegate.peripheral(peripheral, didReadRSSI: NSNumber(127), error: err)
        }
        
        if let err = uuCanAttemptOperation
        {
            UUCoreBluetooth.dispatchQueue.async
            {
                delegate.peripheral(self, didReadRSSI: NSNumber(127), error: err)
            }
            
            return
        }
        
        readRSSI()
    }
    
    // Convenience wrapper to perform both service and characteristic discovery at
    // one time.  This method is useful when you know both service and characteristic
    // UUID's ahead of time.
    public func uuDiscoverCharactertistics(
        _ characteristicUuidList: [CBUUID]?,
        _ serviceUuid: CBUUID,
        _ timeout: TimeInterval,
        _ completion: @escaping UUDiscoverCharacteristicsForServiceUuidBlock)
    {
        
        let start = Date().timeIntervalSinceReferenceDate
        
        uuDiscoverServices([serviceUuid], timeout)
        { peripheral, error in
         
            if (error != nil)
            {
                completion(peripheral, nil, error);
            }
            else
            {
                guard let foundService = peripheral.services?.filter({ $0.uuid.uuidString == serviceUuid.uuidString }).first else
                {
                    completion(peripheral, nil, nil)
                    return
                }
                
                let duration = Date().timeIntervalSinceReferenceDate - start
                let remainingTimeout = timeout - duration
                
                self.uuDiscoverCharacteristics(characteristicUuidList, foundService, remainingTimeout, completion)
            }
        }
    }
}
