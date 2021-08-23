//
//  UUCoreBluetooth.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 8/13/21.
//

import UIKit
import CoreBluetooth
import UUSwiftCore

// MARK:- Common Type Alias Definitions

public typealias UUCentralStateChangedBlock = ((CBManagerState)->())
public typealias UUPeripheralFoundBlock = ((CBPeripheral, [String:Any], Int)->())
public typealias UUPeripheralConnectedBlock = ((CBPeripheral)->())
public typealias UUPeripheralDisconnectedBlock = ((CBPeripheral, Error?)->())
public typealias UUWillRestoreStateBlock = (([String:Any])->())
public typealias UUPeripheralNameUpdatedBlock = ((CBPeripheral)->())
public typealias UUDidModifyServicesBlock = ((CBPeripheral, [CBService])->())
public typealias UUDidReadRssiBlock = ((CBPeripheral, NSNumber, Error?)->())
public typealias UUDiscoverServicesBlock = ((CBPeripheral, Error?)->())
public typealias UUDiscoverIncludedServicesBlock = ((CBPeripheral, CBService, Error?)->())
public typealias UUDiscoverCharacteristicsBlock = ((CBPeripheral, CBService, Error?)->())
public typealias UUDiscoverCharacteristicsForServiceUuidBlock = ((CBPeripheral, CBService?, Error?)->())
public typealias UUUpdateValueForCharacteristicsBlock = ((CBPeripheral, CBCharacteristic, Error?)->())
public typealias UUReadValueForCharacteristicsBlock = ((CBPeripheral, CBCharacteristic, Error?)->())
public typealias UUWriteValueForCharacteristicsBlock = ((CBPeripheral, CBCharacteristic, Error?)->())
public typealias UUSetNotifyValueForCharacteristicsBlock = ((CBPeripheral, CBCharacteristic, Error?)->())
public typealias UUDiscoverDescriptorsBlock = ((CBPeripheral, CBCharacteristic, Error?)->())
public typealias UUUpdateValueForDescriptorBlock = ((CBPeripheral, CBDescriptor, Error?)->())
public typealias UUReadValueForDescriptorBlock = ((CBPeripheral, CBDescriptor, Error?)->())
public typealias UUWriteValueForDescriptorBlock = ((CBPeripheral, CBDescriptor, Error?)->())
public typealias UUPeripheralBlock = ((UUPeripheral)->())
public typealias UUPeripheralErrorBlock = ((UUPeripheral, Error?)->())
public typealias UUPeripheralListBlock = (([UUPeripheral])->())

public typealias UUCBPeripheralBlock = ((CBPeripheral)->())



public class UUCentralManager
{
    private var dispatchQueue = DispatchQueue(label: "UUCentralManagerQueue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .inherit, target: nil)
    
    private var delegate: UUCentralManagerDelegate
    var centralManager: CBCentralManager
    
    private var peripherals: [String: UUPeripheral] = [:]
    private var peripheralsMutex = NSRecursiveLock()
    
    private var scanUuidList: [CBUUID]? = nil
    private var peripheralClass: AnyClass? = nil
    private var scanOptions: [String:Any]? = nil
    private var scanFilters: [UUPeripheralFilter]? = nil
    private(set) public var isScanning: Bool = false
    private var isConfiguredForStateRestoration: Bool = false
    
    private var peripheralFoundBlock: UUPeripheralBlock? = nil
    private var centralStateChangedBlock: UUCentralStateChangedBlock? = nil
    private var rssiPollingBlocks: [String:UUPeripheralBlock] = [:]
    private var willRestoreStateBlock: UUWillRestoreStateBlock? = nil
    private var options: [String:Any]? = nil
    
    
    public static var shared: UUCentralManager
    {
        return UUCentralManagerFactory.sharedCentralManager
    }
    
    required init(_ opts: [String:Any]?)
    {
        NSLog("Initializing UUCoreBluetooth with options: \(String(describing: opts))")
        
        options = opts
        isConfiguredForStateRestoration = (options?.uuSafeGetString(CBCentralManagerOptionRestoreIdentifierKey) != nil)
        delegate = isConfiguredForStateRestoration ? UUCentralManagerRestoringDelegate() : UUCentralManagerDelegate()
        centralManager = CBCentralManager(delegate: delegate, queue: dispatchQueue, options: options)
        delegate.centralStateChangedBlock = handleCentralStateChanged
    }
    
    public var centralState: CBManagerState
    {
        return centralManager.state
    }
    
    // Returns a flag indicating whether the central state is powered on or not.
    public var isPoweredOn: Bool
    {
        return centralManager.state == .poweredOn
    }
    
    public func registerForCentralStateChanges(_ block: UUCentralStateChangedBlock?)
    {
        centralStateChangedBlock = block
    }
    
    
    
    // PRIVATE
    
    private func handleCentralStateChanged(_ state: CBManagerState)
    {
        peripherals.values.forEach
        { p in
            
            NSLog("Peripheral \(p.identifier)-\(p.name), state is \(UUCBPeripheralStateToString(p.peripheralState)) (\(p.peripheralState) when central state changed to \(UUCBManagerStateToString(state)) (\(state)")
            
            if (state != .poweredOn)
            {
                // TODO: How to do this one
                //centralManager.uuNotifyDisconnect(p.underlyingPeripheral, nil)
            }
        }
        
        switch (state)
        {
            case .poweredOn:
                handleCentralStatePoweredOn()
                
            case .resetting:
                handleCentralReset()
                
            default:
                break
        }
        
        centralStateChangedBlock?(state)
    }
    
    private func handleCentralStatePoweredOn()
    {
        if isScanning
        {
            resumeScanning()
        }
    }
    
    private func handleCentralReset()
    {
        NSLog("Central is resetting")
    }
    
    public func startScan(
        serviceUuids: [CBUUID]?,
        allowDuplicates: Bool,
        peripheralClass: AnyClass?,
        filters: [UUPeripheralFilter]?,
        peripheralFoundCallback: @escaping UUPeripheralBlock,
        willRestoreCallback: @escaping UUWillRestoreStateBlock)
    {
        var opts: [String:Any] = [:]
        opts[CBCentralManagerScanOptionAllowDuplicatesKey] = allowDuplicates
        
        self.peripheralClass = peripheralClass
        if (self.peripheralClass == nil)
        {
            self.peripheralClass = UUPeripheral.self
        }
        
        scanUuidList = serviceUuids
        scanOptions = opts
        scanFilters = filters
        isScanning = true
        willRestoreStateBlock = willRestoreCallback
        peripheralFoundBlock = peripheralFoundCallback
        
        delegate.peripheralFoundBlock = handlePeripheralFound
       
        resumeScanning()
    }

    private func resumeScanning()
    {
        centralManager.scanForPeripherals(withServices: scanUuidList, options: scanOptions)
    }
    
    private func handlePeripheralFound(_ peripheral: CBPeripheral, _ advertisementData: [String:Any], _ rssi: Int)
    {
        let uuPeripheral = updatedPeripheralFromScan(peripheral, advertisementData, rssi)
        
        NSLog("Updated peripheral after scan. peripheral: \(String(describing: uuPeripheral.underlyingPeripheral)), rssi: \(uuPeripheral.rssi), advertisement: \(uuPeripheral.advertisementData)")
        
        if (shouldDiscoverPeripheral(uuPeripheral))
        {
            peripheralFoundBlock?(uuPeripheral)
        }
    }
    
    private func handleWillRestoreState(_ options: [String:Any])
    {
        willRestoreStateBlock?(options)
    }
    
    private func shouldDiscoverPeripheral(_ peripheral: UUPeripheral) -> Bool
    {
        guard let filters = scanFilters else
        {
            return true
        }
        
        for f in filters
        {
            if (!f.shouldDiscover(peripheral))
            {
                return false
            }
        }
        
        return true
    }
    
    public func stopScan()
    {
        isScanning = false
        peripheralFoundBlock = nil
        centralManager.stopScan()
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    /*
    public func connectPeripheral(
        _ peripheral: UUPeripheral,
        _ timeout: TimeInterval,
        _ disconnectTimeout: TimeInterval,
        _ connected: @escaping UUPeripheralBlock,
        _ disconnected: @escaping UUPeripheralErrorBlock)
    {
        centralManager.uuConnectPeripheral(peripheral.underlyingPeripheral, nil, timeout, disconnectTimeout,
        { connectedPeripheral in
            
            let uuPeripheral = self.updatedPeripheralFromCbPeripheral(connectedPeripheral)
            connected(uuPeripheral)
        },
        { disconnectedPeripheral, disconnectError in
            
            disconnectedPeripheral.uuCancelAllTimers()
            
            let uuPeripheral = self.updatedPeripheralFromCbPeripheral(disconnectedPeripheral)
            connected(uuPeripheral)
        })
    }
    
    public func disconnectPeripheral(_ peripheral: UUPeripheral, _ timeout: TimeInterval)
    {
        centralManager.uuDisconnectPeripheral(peripheral.underlyingPeripheral, timeout)
    }
*/
    
    
    
    
    
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
    public func connectPeripheral(
       _ peripheral: UUPeripheral,
       //_ options: [String:Any]?,
       _ timeout: TimeInterval,
       _ disconnectTimeout: TimeInterval,
       _ connected: @escaping UUPeripheralBlock,
       _ disconnected: @escaping UUPeripheralErrorBlock)
    {
       //NSLog("Connecting to \(peripheral.uuIdentifier) - \(peripheral.uuName), timeout: \(timeout)")
       
       guard isPoweredOn else
       {
           let err = NSError.uuCoreBluetoothError(.centralNotReady)
           disconnected(peripheral, err)
           return
       }
       
       let timerId = peripheral.uuConnectWatchdogTimerId()
       
       //let delegate = uuCentralManagerDelegate
       
       let connectedBlock: UUPeripheralConnectedBlock =
       { p in
           
           //NSLog("Connected to \(peripheral.uuIdentifier) - \(peripheral.uuName)")
           
           peripheral.cancelTimer(timerId)
           connected(peripheral)
       };
       
       let disconnectedBlock: UUPeripheralDisconnectedBlock =
       { p, error in
           
           //NSLog("Disconnected from \(peripheral.uuIdentifier) - \(peripheral.uuName), error: \(String(describing: error))")
           
           peripheral.cancelTimer(timerId)
           disconnected(peripheral, error)
       }
       
        let key = peripheral.identifier
       delegate.connectBlocks[key] = connectedBlock
       delegate.disconnectBlocks[key] = disconnectedBlock
       
       peripheral.startTimer(timerId, timeout)
       { p in
           
           //NSLog("Connect timeout for \(peripheral.uuIdentifier) - \(peripheral.uuName)")
            
            self.delegate.connectBlocks.removeValue(forKey: key)
            self.delegate.disconnectBlocks.removeValue(forKey: key)
            
            // Issue the disconnect but disconnect any delegate's.  In the case of
            // CBCentralManager being off or reset when this happens, immediately
            // calling the disconnected block ensures there is not an infinite
            // timeout situation.
           self.disconnectPeripheral(peripheral, disconnectTimeout)
            
           let err = NSError.uuCoreBluetoothError(.timeout)
           peripheral.cancelTimer(timerId)
           disconnected(peripheral, err)
       }
       
        //connect(peripheral.underlyingPeripheral, options: nil)
        centralManager.connect(peripheral.underlyingPeripheral, options: nil)
    }

    // Wrapper around CBCentralManager cancelPeripheralConnection.  After calling this
    // method, the disconnected block passed in at connect time will be invoked.
   public func disconnectPeripheral(
       _ peripheral: UUPeripheral,
       _ timeout: TimeInterval)
   {
       //NSLog("Cancelling connection to peripheral \(peripheral.uuIdentifier) - \(peripheral.uuName), timeout: \(timeout)")
       
       guard isPoweredOn else
       {
           NSLog("Central is not powered on, cannot cancel a connection!")
           let err = NSError.uuCoreBluetoothError(.centralNotReady)
        notifyDisconnect(peripheral.underlyingPeripheral, err)
           return
       }
       
       let timerId = peripheral.uuDisconnectWatchdogTimerId()
       
       peripheral.startTimer(timerId, timeout)
       { p in
           
           //NSLog("Disconnect timeout for \(peripheral.uuIdentifier) - \(peripheral.uuName)")
           
           peripheral.cancelTimer(timerId)
           self.notifyDisconnect(p, NSError.uuCoreBluetoothError(.timeout))
           
           // Just in case the timeout fires and a real disconnect is needed, this is the last
           // ditch effort to close the connection
        self.centralManager.cancelPeripheralConnection(p)
       }
       
    centralManager.cancelPeripheralConnection(peripheral.underlyingPeripheral)
   }
   
   private func notifyDisconnect(_ peripheral: CBPeripheral, _ error: Error?)
   {
       //let delegate =  uuCentralManagerDelegate
       
       let key = peripheral.uuIdentifier
       let disconnectBlock = delegate.disconnectBlocks[key]
       delegate.disconnectBlocks.removeValue(forKey: key)
       delegate.connectBlocks.removeValue(forKey: key)
       
       if let block = disconnectBlock
       {
           block(peripheral, error)
       }
       else
       {
           NSLog("No delegate to notify disconnected")
       }
   }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    /*
    // Begins polling RSSI for a peripheral.  When the RSSI is successfully
    // retrieved, the peripheralFoundBlock is called.  This method is useful to
    // perform a crude 'ranging' logic when already connected to a peripheral
    - (void) startRssiPolling:(nonnull UUPeripheral*)peripheral
                     interval:(NSTimeInterval)interval
            peripheralUpdated:(nonnull UUPeripheralBlock)peripheralUpdated
    {
        [self.rssiPollingBlocks uuSafeSetValue:peripheralUpdated forKey:peripheral.identifier];
        
        NSString* timerId = [peripheral.peripheral uuPollRssiTimerId];
        [UUCoreBluetooth cancelWatchdogTimer:timerId];
        
        [peripheral.peripheral uuReadRssi:kUUCoreBluetoothTimeoutDisabled
                               completion:^(CBPeripheral * _Nonnull cbPeripheral, NSNumber * _Nonnull rssi, NSError * _Nullable error)
        {
            UUCoreBluetoothLog(@"RSSI Updated for %@-%@, %@, error: %@", cbPeripheral.uuIdentifier, cbPeripheral.name, rssi, error);
            
            UUPeripheralBlock block = [self.rssiPollingBlocks uuSafeGet:cbPeripheral.uuIdentifier];

            if (!error)
            {
                UUPeripheral* peripheral = [self updatedPeripheralFromRssiRead:cbPeripheral rssi:rssi];
                
                if (block)
                {
                    block(peripheral);
                }
            }
            else
            {
                UUCoreBluetoothLog(@"Error while reading RSSI: %@", error);
            }
            
            if (block)
            {
                [UUCoreBluetooth startWatchdogTimer:timerId
                                            timeout:interval
                                           userInfo:peripheral
                                              block:^(id  _Nullable userInfo)
                 {
                     UUPeripheral* peripheral = userInfo;
                     UUCoreBluetoothLog(@"RSSI Polling timer %@ - %@", peripheral.identifier, peripheral.name);
                     
                     UUPeripheralBlock block = [self.rssiPollingBlocks uuSafeGet:peripheral.identifier];
                     if (!block)
                     {
                         UUCoreBluetoothLog(@"Peripheral %@-%@ not polling anymore", peripheral.identifier, peripheral.name);
                     }
                     else if (peripheral.peripheralState == CBPeripheralStateConnected)
                     {
                         [self startRssiPolling:peripheral interval:interval peripheralUpdated:peripheralUpdated];
                     }
                     else
                     {
                         UUCoreBluetoothLog(@"Peripheral %@-%@ is not connected anymore, cannot poll for RSSI", peripheral.identifier, peripheral.name);
                     }
                 }];
            }
            
        }];
    }

    - (void) stopRssiPolling:(nonnull UUPeripheral*)peripheral
    {
        [self.rssiPollingBlocks uuSafeRemove:peripheral.identifier];
    }

    - (BOOL) isPollingForRssi:(nonnull UUPeripheral*)peripheral
    {
        return ([self.rssiPollingBlocks uuSafeGet:peripheral.identifier] != nil);
    }

     */
    
    
    private func findPeripheralFromCbPeripheral(_ peripheral: CBPeripheral) -> UUPeripheral
    {
        defer { peripheralsMutex.unlock() }
        peripheralsMutex.lock()
        
        var uuPeripheral = peripherals[peripheral.identifier.uuidString]
        if (uuPeripheral == nil)
        {
            uuPeripheral = UUPeripheral(dispatchQueue, self, peripheral)
            
            //let f = peripheralClass?.self.ini
        }
        
        return uuPeripheral!
    }
    
    private func updatedPeripheralFromCbPeripheral(_ peripheral: CBPeripheral) -> UUPeripheral
    {
        let uuPeripheral = findPeripheralFromCbPeripheral(peripheral)
        uuPeripheral.underlyingPeripheral = peripheral
        updatePeripheral(uuPeripheral)
        return uuPeripheral
    }
    
    private func updatedPeripheralFromScan(
        _ peripheral: CBPeripheral,
        _ advertisementData: [String:Any],
        _ rssi: Int) -> UUPeripheral
    {
        let uuPeripheral = findPeripheralFromCbPeripheral(peripheral)
        uuPeripheral.updateFromScan(peripheral, advertisementData, rssi)
        updatePeripheral(uuPeripheral)
        return uuPeripheral
    }

    /*
    - (nonnull UUPeripheral*) updatedPeripheralFromRssiRead:(nonnull CBPeripheral*)peripheral
                                                       rssi:(nullable NSNumber*)rssi
    {
        UUPeripheral* uuPeripheral = [self findPeripheralFromCbPeripheral:peripheral];
        
        NSNumber* oldRssi = uuPeripheral.rssi;
        #pragma unused(oldRssi)
        
        [uuPeripheral updateRssi:rssi];
        
        UUCoreBluetoothLog(@"peripheralRssiChanged, %@ - %@, from: %@ to %@", uuPeripheral.identifier, uuPeripheral.name, oldRssi, rssi);
        
        [self updatePeripheral:uuPeripheral];
        
        return uuPeripheral;
    }*/

    private func updatePeripheral(_ peripheral: UUPeripheral)
    {
        defer { peripheralsMutex.unlock() }
        peripheralsMutex.lock()
        
        peripherals[peripheral.identifier] = peripheral
    }
    
    private func removePeripheral(_ peripheral: UUPeripheral)
    {
        defer { peripheralsMutex.unlock() }
        peripheralsMutex.lock()
        
        peripherals.removeValue(forKey: peripheral.identifier)
    }
}

// MARK:- Global Helper functions

public func UUCBManagerStateToString(_ state: CBManagerState) -> String
{
    switch (state)
    {
        case .unknown:
            return "Unknown"
            
        case .resetting:
            return "Resetting"
            
        case .unsupported:
            return "Unsupported"
            
        case .unauthorized:
            return "Unauthorized"
            
        case .poweredOff:
            return "PoweredOff"
            
        case .poweredOn:
            return "PoweredOn"
            
        default:
            return "CBManagerState-\(state)"
    }
}

public func UUCBPeripheralStateToString(_ state: CBPeripheralState) -> String
{
    switch (state)
    {
        case .disconnected:
            return "Disconnected"
            
        case .connecting:
            return "Connecting"
            
        case .connected:
            return "Connected"
            
        case .disconnecting:
            return "Disconnecting"
            
        default:
            return "CBPeripheralState-\(state)"
    }
}

func UUIsCBCharacteristicPropertySet(_ props: CBCharacteristicProperties, _ check: CBCharacteristicProperties) -> Bool
{
    return props.contains(check)
}

public func UUCBCharacteristicPropertiesToString(_ props: CBCharacteristicProperties) -> String
{
    var parts: [String] = []
    
    if (UUIsCBCharacteristicPropertySet(props, .broadcast))
    {
        parts.append("Broadcast")
    }
    
    if (UUIsCBCharacteristicPropertySet(props, .read))
    {
        parts.append("Read")
    }
    
    if (UUIsCBCharacteristicPropertySet(props, .writeWithoutResponse))
    {
        parts.append("WriteWithoutResponse")
    }
    
    if (UUIsCBCharacteristicPropertySet(props, .write))
    {
        parts.append("Write")
    }
    
    if (UUIsCBCharacteristicPropertySet(props, .notify))
    {
        parts.append("Notify")
    }
    
    if (UUIsCBCharacteristicPropertySet(props, .indicate))
    {
        parts.append("Indicate")
    }
    
    if (UUIsCBCharacteristicPropertySet(props, .authenticatedSignedWrites))
    {
        parts.append("AuthenticatedSignedWrites")
    }
    
    if (UUIsCBCharacteristicPropertySet(props, .extendedProperties))
    {
        parts.append("ExtendedProperties")
    }
    if (UUIsCBCharacteristicPropertySet(props, .notifyEncryptionRequired))
    {
        parts.append("NotifyEncryptionRequired")
    }
    
    if (UUIsCBCharacteristicPropertySet(props, .indicateEncryptionRequired))
    {
        parts.append("IndicateEncryptionRequired")
    }
    
    return parts.joined(separator: ", ")
}



/*
extension UUCentralManager // Timers
{
    static func startWatchdogTimer(_ timerId: String, timeout: TimeInterval, userInfo: Any?, block: UUWatchdogTimerBlock?)
    {
        UUTimer.startWatchdogTimer(timerId, timeout, userInfo, queue: dispatchQueue, block)
    }
}*/
