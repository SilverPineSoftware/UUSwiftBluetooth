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
open class UUPeripheral
{
    private var centralManager: UUCentralManager!
    private var dispatchQueue: DispatchQueue!
    
    
    
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
        //centralManager = UUCentralManager.shared.centralManager
        //dispatchQueue = DispatchQueue.uuBluetooth

        underlyingPeripheral = peripheral
        
        //delegate = UUPeripheralDelegate()//centralManager, peripheral, dispatchQueue)
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
        return advertisementData.uuSafeGetBool(CBAdvertisementDataIsConnectable) ?? false
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
    
    
    
    
    
    
    
    
    
    
    /*
    public func connect(
        _ timeout: TimeInterval,
        _ disconnectTimeout: TimeInterval,
        _ connected: @escaping UUPeripheralBlock,
        _ disconnected: @escaping UUPeripheralErrorBlock)
    {
        centralManager.uuConnectPeripheral(underlyingPeripheral, nil, timeout, disconnectTimeout,
        { connectedPeripheral in
            
            //let uuPeripheral = self.updatedPeripheralFromCbPeripheral(connectedPeripheral)
            //connected(uuPeripheral)
            self.underlyingPeripheral = connectedPeripheral
            connected(self)
        },
        { disconnectedPeripheral, disconnectError in
            
            //disconnectedPeripheral.uuCancelAllTimers()
            
            //let uuPeripheral = self.updatedPeripheralFromCbPeripheral(disconnectedPeripheral)
            //connected(uuPeripheral)
            
            self.cancelAllTimers()
            
            self.underlyingPeripheral = disconnectedPeripheral
            disconnected(self, disconnectError)
        })
    }
    
    public func disconnect(_ timeout: TimeInterval)
    {
        centralManager.uuDisconnectPeripheral(underlyingPeripheral, timeout)
        //centralManager.uuDisconnectPeripheral(peripheral.underlyingPeripheral, timeout)
    }*/
    
    
    
    
    
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
       //_ peripheral: CBPeripheral,
       //_ options: [String:Any]?,
       _ timeout: TimeInterval,
       _ disconnectTimeout: TimeInterval,
       _ connected: @escaping UUPeripheralBlock,
       _ disconnected: @escaping UUPeripheralErrorBlock)
    {
        centralManager.connectPeripheral(self, timeout, disconnectTimeout, connected, disconnected)
        
        /*
       //NSLog("Connecting to \(peripheral.uuIdentifier) - \(peripheral.uuName), timeout: \(timeout)")
       
        guard centralManager.uuIsPoweredOn else
       {
           let err = NSError.uuCoreBluetoothError(.centralNotReady)
           disconnected(self, err)
           return
       }
       
       let timerId = uuConnectWatchdogTimerId()
       
        let delegate = centralManager.delegate as? UUCentralManagerDelegate// uuCentralManagerDelegate
       
       let connectedBlock: UUPeripheralConnectedBlock =
       { peripheral in
           
           NSLog("Connected to \(peripheral.uuIdentifier) - \(peripheral.uuName)")
           
            self.cancelTimer(timerId)
            connected(self)
       };
       
       let disconnectedBlock: UUPeripheralDisconnectedBlock =
       { peripheral, error in
           
           NSLog("Disconnected from \(peripheral.uuIdentifier) - \(peripheral.uuName), error: \(String(describing: error))")
           
            self.cancelTimer(timerId)
           disconnected(self, error)
       }
       
       delegate?.connectBlocks[identifier] = connectedBlock
       delegate?.disconnectBlocks[identifier] = disconnectedBlock
       
       startTimer(timerId, timeout)
       { peripheral in
           
           NSLog("Connect timeout for \(peripheral.uuIdentifier) - \(peripheral.uuName)")
            
           delegate?.connectBlocks.removeValue(forKey: peripheral.uuIdentifier)
           delegate?.disconnectBlocks.removeValue(forKey: peripheral.uuIdentifier)
            
            // Issue the disconnect but disconnect any delegate's.  In the case of
            // CBCentralManager being off or reset when this happens, immediately
            // calling the disconnected block ensures there is not an infinite
            // timeout situation.
           self.disconnect(disconnectTimeout)
            
           let err = NSError.uuCoreBluetoothError(.timeout)
            self.cancelTimer(timerId)
           disconnected(self, err)
       }
       
        centralManager.connect(underlyingPeripheral, options: nil)
       //connect(peripheral, options: options)
        */
    }

    // Wrapper around CBCentralManager cancelPeripheralConnection.  After calling this
    // method, the disconnected block passed in at connect time will be invoked.
   public func disconnect(_ timeout: TimeInterval)
   {
        centralManager.disconnectPeripheral(self, timeout)
    /*
       //NSLog("Cancelling connection to peripheral \(peripheral.uuIdentifier) - \(peripheral.uuName), timeout: \(timeout)")
       
        guard centralManager.uuIsPoweredOn else
       {
            NSLog("Central is not powered on, cannot cancel a connection!")
            let err = NSError.uuCoreBluetoothError(.centralNotReady)
            notifyDisconnect(err)
            return
       }
       
       let timerId = uuDisconnectWatchdogTimerId()
       
       startTimer(timerId, timeout)
       { peripheral in
           
           NSLog("Disconnect timeout for \(peripheral.uuIdentifier) - \(peripheral.uuName)")
           
            self.cancelTimer(timerId)
           self.notifyDisconnect(NSError.uuCoreBluetoothError(.timeout))
           
           // Just in case the timeout fires and a real disconnect is needed, this is the last
           // ditch effort to close the connection
            self.centralManager.cancelPeripheralConnection(peripheral)
       }
       
        centralManager.cancelPeripheralConnection(underlyingPeripheral)*/
   }
   
    /*
   private func notifyDisconnect(_ error: Error?)
   {
       let delegate = centralManager.delegate as? UUCentralManagerDelegate// uuCentralManagerDelegate
       
       let key = identifier// peripheral.uuIdentifier
       let disconnectBlock = delegate?.disconnectBlocks[key]
       delegate?.disconnectBlocks.removeValue(forKey: key)
       delegate?.connectBlocks.removeValue(forKey: key)
       
       if let block = disconnectBlock
       {
           block(underlyingPeripheral, error)
       }
       else
       {
           NSLog("No delegate to notify disconnected")
       }
   }*/
    
    
    
    
    // Block based wrapper around CBPeripheral discoverServices, with an optional
    // timeout value.  A negative timeout value will disable the timeout.
    public func discoverServices(
        _ serviceUuidList: [CBUUID]?,
        _ timeout: TimeInterval,
        _ completion: @escaping UUDiscoverServicesBlock)
    {
        NSLog("Discovering services for \(self.debugName), timeout: \(timeout), service list: \(String(describing: serviceUuidList))")
        
        let timerId = uuServiceDiscoveryWatchdogTimerId()
        
        //let delegate = self.delegate //CBPeripheral.uuDelegateForPeripheral(self)
        //self.delegate = delegate
        //underlyingPeripheral.delegate = delegate
        delegate.discoverServicesBlock =
        { peripheral, errOpt in
            
            let err = NSError.uuOperationCompleteError(errOpt as NSError?)
            
            NSLog("Service discovery finished for \(self.debugName), error: \(String(describing: err)), services: \(String(describing: peripheral.services))")
            
            self.cancelTimer(timerId)
            completion(peripheral, err)
        }
        
        startTimer(timerId, timeout)
        { peripheral in
            
            NSLog("Service discovery timeout for \(self.debugName)")
            
            let err = NSError.uuCoreBluetoothError(.timeout)
            self.delegate.peripheral(peripheral, didDiscoverServices: err)
        }
        
        if let err = canAttemptOperation
        {
            DispatchQueue.uuBluetooth.async
            {
                self.delegate.peripheral(self.underlyingPeripheral, didDiscoverServices: err)
            }
            
            return
        }
        
        underlyingPeripheral.discoverServices(serviceUuidList)
    }
    
    
    
    
    // Block based wrapper around CBPeripheral discoverCharacteristics:forService,
    // with an optional timeout value.  A negative timeout value will disable the timeout.
    public func discoverCharacteristics(
        _ characteristicUuidList: [CBUUID]?,
        _ service: CBService,
        _ timeout: TimeInterval,
        _ completion: @escaping UUDiscoverCharacteristicsBlock)
    {
        NSLog("Discovering characteristics for \(self.debugName), timeout: \(timeout), service: \(service), characteristic list: \(String(describing: characteristicUuidList))")
        
        let timerId = uuCharacteristicDiscoveryWatchdogTimerId()
        
        //let delegate = CBPeripheral.uuDelegateForPeripheral(self)
        //self.delegate = delegate
        delegate.discoverCharacteristicsBlock =
        { peripheral, service, error in
            
            NSLog("Characteristic discovery finished for \(self.debugName), service: \(service), error: \(String(describing: error)), characteristics: \(String(describing: service.characteristics))")
            
            self.cancelTimer(timerId)
            completion(peripheral, service, error)
        }
        
        startTimer(timerId, timeout)
        { peripheral in
            
            NSLog("Characteristic discovery timeout for \(self.debugName)")
            
            let err = NSError.uuCoreBluetoothError(.timeout)
            self.delegate.peripheral(peripheral, didDiscoverCharacteristicsFor: service, error: err)
        }
        
        if let err = canAttemptOperation
        {
            dispatchQueue.async
            {
                self.delegate.peripheral(self.underlyingPeripheral, didDiscoverCharacteristicsFor: service, error: err)
            }
            
            return
        }
        
        underlyingPeripheral.discoverCharacteristics(characteristicUuidList, for: service)
    }

    // Block based wrapper around CBPeripheral discoverIncludedServices:forService,
    // with an optional timeout value.  A negative timeout value will disable the timeout.
    public func discoverIncludedServices(
        _ serviceUuidList: [CBUUID]?,
        _ service: CBService,
        _ timeout: TimeInterval,
        _ completion: @escaping UUDiscoverIncludedServicesBlock)
    {
        NSLog("Discovering included services for \(self.debugName), timeout: \(timeout), service: \(service), service list: \(String(describing: serviceUuidList))")
        
        let timerId = uuIncludedServicesDiscoveryWatchdogTimerId()
        
        //let delegate = CBPeripheral.uuDelegateForPeripheral(self)
        //self.delegate = delegate
        delegate.discoverIncludedServicesBlock =
        { peripheral, service, error in
            
            let err = NSError.uuOperationCompleteError(error as NSError?)
            
            NSLog("Included services discovery finished for \(self.debugName), service: \(service), error: \(String(describing: err)), includedServices: \(String(describing: service.includedServices))")
            
            self.cancelTimer(timerId)
            completion(peripheral, service, error)
        }
        
        startTimer(timerId, timeout)
        { peripheral in
            
            NSLog("Included services discovery timeout for \(self.debugName)")
            
            let err = NSError.uuCoreBluetoothError(.timeout)
            self.delegate.peripheral(peripheral, didDiscoverIncludedServicesFor: service, error: err)
        }
        
        if let err = canAttemptOperation
        {
            dispatchQueue.async
            {
                self.delegate.peripheral(self.underlyingPeripheral, didDiscoverIncludedServicesFor: service, error: err)
            }
            
            return
        }
        
        underlyingPeripheral.discoverIncludedServices(serviceUuidList, for: service)
        
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
    public func discoverDescriptorsForCharacteristic(
        _ characteristic: CBCharacteristic,
        _ timeout: TimeInterval,
        _ completion: @escaping UUDiscoverDescriptorsBlock)
    {
        NSLog("Discovering descriptors for \(self.debugName), timeout: \(timeout), characteristic: \(characteristic)")
        
        let timerId = uuDescriptorDiscoveryWatchdogTimerId()
        
        //let delegate = CBPeripheral.uuDelegateForPeripheral(self)
        //self.delegate = delegate
        delegate.discoverDescriptorsBlock =
        { peripheral, characteristic, error in
            
            let err = NSError.uuOperationCompleteError(error as NSError?)
            
            NSLog("Descriptor discovery finished for \(self.debugName), characteristic: \(characteristic), error: \(String(describing: err)), descriptors: \(String(describing: characteristic.descriptors))")
            
            self.cancelTimer(timerId)
            completion(peripheral, characteristic, error)
        }
        
        startTimer(timerId, timeout)
        { peripheral in
            
            NSLog("Descriptor discovery timeout for \(self.debugName)")
            
            let err = NSError.uuCoreBluetoothError(.timeout)
            self.delegate.peripheral(peripheral, didDiscoverDescriptorsFor: characteristic, error: err)
        }
        
        if let err = canAttemptOperation
        {
            dispatchQueue.async
            {
                self.delegate.peripheral(self.underlyingPeripheral, didDiscoverDescriptorsFor: characteristic, error: err)
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
        
        
        underlyingPeripheral.discoverDescriptors(for: characteristic)
    }
    
    // Block based wrapper around CBPeripheral setNotifyValue, with an optional
    // timeout value.  A negative timeout value will disable the timeout.
    public func setNotifyValue(
        _ enabled: Bool,
        _ characteristic: CBCharacteristic,
        _ timeout: TimeInterval,
        _ notifyHandler: UUUpdateValueForCharacteristicsBlock?,
        _ completion: @escaping UUSetNotifyValueForCharacteristicsBlock)
    {
        NSLog("Set Notify State for \(self.debugName), enabled: \(enabled), timeout: \(timeout), characateristic: \(characteristic)")
        
        let timerId = uuCharacteristicNotifyStateWatchdogTimerId()
        
        //let delegate = CBPeripheral.uuDelegateForPeripheral(self)
        //self.delegate = delegate
        delegate.setNotifyValueForCharacteristicBlock =
        { peripheral, characteristic, error in
            
            let err = NSError.uuOperationCompleteError(error as NSError?)
            
            NSLog("Set Notify State finished for \(self.debugName), characteristic: \(characteristic), error: \(String(describing: err))")
            
            self.cancelTimer(timerId)
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
        
        startTimer(timerId, timeout)
        { peripheral in
            
            NSLog("Set Notify State timeout for \(self.debugName)")
            
            let err = NSError.uuCoreBluetoothError(.timeout)
            self.delegate.peripheral(peripheral, didUpdateNotificationStateFor: characteristic, error: err)
        }
        
        if let err = canAttemptOperation
        {
            dispatchQueue.async
            {
                self.delegate.peripheral(self.underlyingPeripheral, didUpdateNotificationStateFor: characteristic, error: err)
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
        
        underlyingPeripheral.setNotifyValue(enabled, for: characteristic)
    }

    // Block based wrapper around CBPeripheral readValue:forCharacteristic, with an
    // optional timeout value.  A negative timeout value will disable the timeout.
    public func readValueForCharacteristic(
        _ characteristic: CBCharacteristic,
        _ timeout: TimeInterval,
        _ completion: @escaping UUReadValueForCharacteristicsBlock)
    {
        NSLog("Read value for \(self.debugName), characteristic: \(characteristic), timeout: \(timeout)")
        
        let timerId = uuReadCharacteristicValueWatchdogTimerId()
        
        //let delegate = Self.uuDelegateForPeripheral(self)
        //self.delegate = delegate
        
        delegate.registerReadHandler(
        { peripheral, characteristic, error in
            
            let err = NSError.uuOperationCompleteError(error as NSError?)
            
            NSLog("Read value finished for \(self.debugName), characteristic: \(characteristic), error: \(String(describing: err))")
            
            self.cancelTimer(timerId)
            self.delegate.removeReadHandler(characteristic)
            completion(peripheral, characteristic, err)
            
        }, characteristic)
        
        startTimer(timerId, timeout)
        { peripheral in
            
            NSLog("Read value timeout for \(self.debugName)")
            
            let err = NSError.uuCoreBluetoothError(.timeout)
            self.delegate.peripheral(peripheral, didUpdateValueFor: characteristic, error: err)
        }
        
        if let err = canAttemptOperation
        {
            dispatchQueue.async
            {
                self.delegate.peripheral(self.underlyingPeripheral, didUpdateValueFor: characteristic, error: err)
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
        
        underlyingPeripheral.readValue(for: characteristic)
    }
    
    // Block based wrapper around CBPeripheral readValue:forCharacteristic, with an
    // optional timeout value.  A negative timeout value will disable the timeout.
    public func readValueForDescriptor(
        _ descriptor: CBDescriptor,
        _ timeout: TimeInterval,
        _ completion: @escaping UUReadValueForDescriptorBlock)
    {
        NSLog("Read value for \(self.debugName), descriptor: \(descriptor), timeout: \(timeout)")
        
        let timerId = uuReadDescriptorValueWatchdogTimerId()
        
        //let delegate = Self.uuDelegateForPeripheral(self)
        //self.delegate = delegate
        
        delegate.registerReadHandler(
        { peripheral, descriptor, error in
            
            let err = NSError.uuOperationCompleteError(error as NSError?)
            
            NSLog("Read value finished for \(self.debugName), descriptor: \(descriptor), error: \(String(describing: err))")
            
            self.cancelTimer(timerId)
            self.delegate.removeReadHandler(descriptor)
            completion(peripheral, descriptor, err)
            
        }, descriptor)
        
        startTimer(timerId, timeout)
        { peripheral in
            
            NSLog("Read descriptor timeout for \(self.debugName)")
            
            let err = NSError.uuCoreBluetoothError(.timeout)
            self.delegate.peripheral(peripheral, didUpdateValueFor: descriptor, error: err)
        }
        
        if let err = canAttemptOperation
        {
            dispatchQueue.async
            {
                self.delegate.peripheral(self.underlyingPeripheral, didUpdateValueFor: descriptor, error: err)
            }
            
            return
        }
        
        underlyingPeripheral.readValue(for: descriptor)
    }
    
    // Block based wrapper around CBPeripheral writeValue:forCharacteristic:type with type
    // CBCharacteristicWriteWithResponse, with an optional timeout value.  A negative
    // timeout value will disable the timeout.
    public func writeValue(
        _ data: Data,
        _ characteristic: CBCharacteristic,
        _ timeout: TimeInterval,
        _ completion: @escaping UUWriteValueForCharacteristicsBlock)
    {
        NSLog("Write value \(data.uuToHexString()), for \(self.debugName), characteristic: \(characteristic), timeout: \(timeout)")
        
        let timerId = uuWriteCharacteristicValueWatchdogTimerId()
        
        //let delegate = Self.uuDelegateForPeripheral(self)
        //self.delegate = delegate
        
        delegate.registerWriteHandler(
        { peripheral, characteristic, error in
        
            let err = NSError.uuOperationCompleteError(error as NSError?)
            
            NSLog("Write value finished for \(self.debugName), characteristic: \(characteristic), error: \(String(describing: err))")
            
            self.cancelTimer(timerId)
            self.delegate.removeWriteHandler(characteristic)
            completion(peripheral, characteristic, err)
            
        }, characteristic)
        
        startTimer(timerId, timeout)
        { peripheral in
            
            NSLog("Write value timeout for \(self.debugName)")
            
            let err = NSError.uuCoreBluetoothError(.timeout)
            self.delegate.peripheral(peripheral, didWriteValueFor: characteristic, error: err)
        }
        
        if let err = canAttemptOperation
        {
            dispatchQueue.async
            {
                self.delegate.peripheral(self.underlyingPeripheral, didWriteValueFor: characteristic, error: err)
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
        
        underlyingPeripheral.writeValue(data, for: characteristic, type: .withResponse)
    }

    // Block based wrapper around CBPeripheral writeValue:forCharacteristic:type with type
    // CBCharacteristicWriteWithoutResponse.  Block callback is invoked after sending.
    // Per CoreBluetooth documentation, there is no garauntee of delivery.
    public func writeValueWithoutResponse(
        _ data: Data,
        _ characteristic: CBCharacteristic,
        _ completion: @escaping UUWriteValueForCharacteristicsBlock)
    {
        NSLog("Write value without response \(data.uuToHexString()), for \(self.debugName), characteristic: \(characteristic)")
        
        if let err = canAttemptOperation
        {
            dispatchQueue.async
            {
                completion(self.underlyingPeripheral, characteristic, err)
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
        _ descriptor: CBDescriptor,
        _ timeout: TimeInterval,
        _ completion: @escaping UUWriteValueForDescriptorBlock)
    {
        NSLog("Write value \(data.uuToHexString()), for \(self.debugName), descriptor: \(descriptor), timeout: \(timeout)")
        
        let timerId = uuWriteDescriptorValueWatchdogTimerId()
        
        //let delegate = Self.uuDelegateForPeripheral(self)
        //self.delegate = delegate
        
        delegate.registerWriteHandler(
        { peripheral, descriptor, error in
        
            let err = NSError.uuOperationCompleteError(error as NSError?)
            
            NSLog("Write value finished for \(self.debugName), descriptor: \(descriptor), error: \(String(describing: err))")
            
            self.cancelTimer(timerId)
            self.delegate.removeWriteHandler(descriptor)
            completion(peripheral, descriptor, err)
            
        }, descriptor)
        
        startTimer(timerId, timeout)
        { peripheral in
            
            NSLog("Write descriptor value timeout for \(self.debugName)")
            
            let err = NSError.uuCoreBluetoothError(.timeout)
            self.delegate.peripheral(peripheral, didWriteValueFor: descriptor, error: err)
        }
        
        if let err = canAttemptOperation
        {
            dispatchQueue.async
            {
                self.delegate.peripheral(self.underlyingPeripheral, didWriteValueFor: descriptor, error: err)
            }
            
            return
        }
        
        underlyingPeripheral.writeValue(data, for: descriptor)
    }
    
    // TODO: Read/Write descriptors
    
    // Block based wrapper around CBPeripheral readRssi, with an optional
    // timeout value.  A negative timeout value will disable the timeout.
    public func readRssi(
        _ timeout: TimeInterval,
        _ completion: @escaping UUDidReadRssiBlock)
    {
        NSLog("Reading RSSI for \(self.debugName), timeout: \(timeout)")
        
        let timerId = uuReadRssiWatchdogTimerId()
        
        //let delegate = Self.uuDelegateForPeripheral(self)
        //self.delegate = delegate
        
        delegate.didReadRssiBlock =
        { peripheral, rssi, error in
            
            let err = NSError.uuOperationCompleteError(error as NSError?)
            
            NSLog("Read RSSI finished for \(self.debugName), rssi: \(rssi), error: \(String(describing: err))")
            
            self.cancelTimer(timerId)
            completion(peripheral, rssi, error)
        }
        
        startTimer(timerId, timeout)
        { peripheral in
            
            NSLog("Read RSSI timeout for \(self.debugName)")
            
            let err = NSError.uuCoreBluetoothError(.timeout)
            self.delegate.peripheral(peripheral, didReadRSSI: NSNumber(127), error: err)
        }
        
        if let err = canAttemptOperation
        {
            dispatchQueue.async
            {
                self.delegate.peripheral(self.underlyingPeripheral, didReadRSSI: NSNumber(127), error: err)
            }
            
            return
        }
        
        underlyingPeripheral.readRSSI()
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
        
        discoverServices([serviceUuid], timeout)
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
                
                self.discoverCharacteristics(characteristicUuidList, foundService, remainingTimeout, completion)
            }
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    // MARK:- Timers
    
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
        return "\(identifier)__\(bucket.rawValue)"
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
    
    private func cancelAllTimers()
    {
        let list = UUTimer.listActiveTimers()
        for t in list
        {
            if (t.timerId.starts(with: identifier))
            {
                t.cancel()
            }
        }
    }
    
    func startTimer(_ timerId: String, _ timeout: TimeInterval, _ block: @escaping UUCBPeripheralBlock)
    {
        NSLog("Starting timer \(timerId) with timeout: \(timeout)")
        
        UUTimer.startWatchdogTimer(timerId, timeout, underlyingPeripheral, queue: dispatchQueue)
        { info in
            
            if let p = info as? CBPeripheral
            {
                block(p)
            }
        }
    }
    
    func cancelTimer(_ timerId: String)
    {
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

