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




/*
func UUCoreBluetoothQueue() -> DispatchQueue
{
    DispatchQueue(label: "UUCoreBluetoothQueue", qos: .userInitiated, attributes: [], target: <#T##DispatchQueue?#>)
//    static dispatch_queue_t theSharedCoreBluetoothQueue = nil;
//    static dispatch_once_t onceToken;
//
//    dispatch_once (&onceToken, ^
//    {
//        dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, 0);
//        theSharedCoreBluetoothQueue = dispatch_queue_create(kUUCoreBluetoothQueueName, attr);
//    });
//
//    return theSharedCoreBluetoothQueue;
    
    
}*/

//static sharedBackgroundQueue = DispatchQueue(l


public class UUCoreBluetooth
{
    static var dispatchQueue = DispatchQueue(label: "UUCoreBluetoothQueue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .inherit, target: nil)

    
//    private static var internalShared: UUCoreBluetooth? = nil
//
//    public static var shared: UUCoreBluetooth
//    {
//        if (internalShared == nil)
//        {
//            internalShared = UUCoreBluetooth()
//        }
//
//        return internalShared!
//    }
    /*
    
    // UUCoreBluetooth provides a small set of convenience wrappers around the
    // CoreBluetooth block based extensions defined above.  Additionally, all of
    // the UUCoreBluetooth methods operate on the UUPeripheral wrapper object
    // instead of CBPeripheral directly.
    @interface UUCoreBluetooth : NSObject

    // Singleton instance
    + (nonnull instancetype) sharedInstance;

    // Sets a static dictionary that is passed into the CBCentralManager init method
    //
    // NOTE: Once sharedInstance  has been called, the set method has no effect.
    //
    // Use these to prepare UUCoreBluetooth for state restoration/preservation
    + (void) setSharedInstanceInitOptions:(nullable NSDictionary<NSString*, id>*)options;

    // Reference to the underlying central
    @property (nonnull, nonatomic, strong, readonly) CBCentralManager* centralManager;

    // Returns current CBCentralManager.state value
    - (CBManagerState) centralState;

    // Register a listener for central state changes
    - (void) registerForCentralStateChanges:(nullable UUCentralStateChangedBlock)block;

    // Initiates a CoreBluetooth scan for nearby peripherals
    //
    // serviceUUIDs - list of service's to scan for.
    //
    // allowDuplicates controls how the CBCentralManagerScanOptionAllowDuplicatesKey
    // scanning option is initialized.
    //
    // peripheralClass allows callers to pass in their custom UUPeripheral derived
    // class so that peripheral objects returned from scan are already thier
    // custom object.  If nil, UUPeripheral is used.
    //
    // filters - An array of UUPeripheralFilter objects to narrow down which
    // objects are returned in the peripheralFoundBlock.  The peripheral filtering
    // logic is an AND algorithm, meaning that a peripheral is only returned if it
    // passes ALL filters.
    //
    // peripheralFoundBlock - block used to notify callers of new peripherals
    //
    - (void) startScanForServices:(nullable NSArray<CBUUID *> *)serviceUUIDs
                  allowDuplicates:(BOOL)allowDuplicates
                  peripheralClass:(nullable Class)peripheralClass
                          filters:(nullable NSArray< NSObject<UUPeripheralFilter>* >*)filters
          peripheralFoundCallback:(nonnull UUPeripheralBlock)peripheralFoundBlock
         willRestoreStateCallback:(nonnull UUWillRestoreStateBlock)willRestoreStateBlock;

    // Stop an ongoing scan
    - (void) stopScanning;

    // Flag indicating if UUCoreBluetooth is currently scanning.  This does NOT map
    // directly to the CBCentralManager.isScanning flag.  This flag is used internally
    // to resume scanning if the central manager has to go through a restart.
    @property (assign, readonly) BOOL isScanning;

    // Convenience wrapper around CBCentralManager uuConnectPeripheral that uses nil
    // for the connect options
    - (void) connectPeripheral:(nonnull UUPeripheral*)peripheral
                       timeout:(NSTimeInterval)timeout
             disconnectTimeout:(NSTimeInterval)disconnectTimeout
                     connected:(nonnull UUPeripheralBlock)connected
                  disconnected:(nonnull UUPeripheralErrorBlock)disconnected;

    // Convenience wrapper around CBCentralManager uuDisconnectPeripheral
    - (void) disconnectPeripheral:(nonnull UUPeripheral*)peripheral timeout:(NSTimeInterval)timeout;

    // Begins polling RSSI for a peripheral.  When the RSSI is successfully
    // retrieved, the peripheralFoundBlock is called.  This method is useful to
    // perform a crude 'ranging' logic when already connected to a peripheral
    - (void) startRssiPolling:(nonnull UUPeripheral*)peripheral
                     interval:(NSTimeInterval)interval
            peripheralUpdated:(nonnull UUPeripheralBlock)peripheralUpdated;

    // Stop RSSI polling for a peripheral
    - (void) stopRssiPolling:(nonnull UUPeripheral*)peripheral;

    // Returns a flag indicating if RSSI polling is active
    - (BOOL) isPollingForRssi:(nonnull UUPeripheral*)peripheral;

    // Cancels any existing timer with this ID, and kicks off a new timer
    // on the UUCoreBluetooth queue. If the timeout value is negative, the
    // new timer will not be started.
    + (void) startWatchdogTimer:(nonnull NSString*)timerId
                        timeout:(NSTimeInterval)timeout
                       userInfo:(nullable id)userInfo
                          block:(nonnull void (^)(id _Nullable userInfo))block;

    + (void) cancelWatchdogTimer:(nonnull NSString*)timerId;

    // Flag indicating if background state restoration identifier was used to initialize core bluetooth
    @property (assign, readonly) BOOL isConfiguredForStateRestoration;

    @end
    */
    
    
    private var delegate: UUCentralManagerDelegate
    private var centralManager: CBCentralManager
    
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
    
    private static var theSharedInstance: UUCoreBluetooth? = nil
    private static var theSharedInstanceOptions: [String:Any]? = nil
    
    
    public static var shared: UUCoreBluetooth
    {
        if (theSharedInstance == nil)
        {
            let opts = theSharedInstanceOptions ?? defaultOptions()
            theSharedInstance = UUCoreBluetooth(opts)
        }
        
        return theSharedInstance!
    }
    
    public static func setSharedInstanceInitOptions(_ options: [String:Any]?)
    {
        theSharedInstanceOptions = options
        
        if (theSharedInstance != nil)
        {
            let existingRestoreId = theSharedInstance?.options?.uuSafeGetString(CBCentralManagerOptionRestoreIdentifierKey) ?? ""
            let incomingRestoreId = theSharedInstanceOptions?.uuSafeGetString(CBCentralManagerOptionRestoreIdentifierKey) ?? ""
            if (existingRestoreId != incomingRestoreId)
            {
                NSLog("UUCoreBluetooth init options have changed! Setting theSharedInstance to nil");
                theSharedInstance = nil
            }
        }
    }
    
    private static func defaultOptions() -> [String:Any]
    {
        var md: [String:Any] = [:]
        md[CBCentralManagerOptionShowPowerAlertKey] = false
        return md
    }
    
    required init(_ opts: [String:Any]?)
    {
        NSLog("Initializing UUCoreBluetooth with options: \(String(describing: opts))")
        
        options = opts
        isConfiguredForStateRestoration = (options?.uuSafeGetString(CBCentralManagerOptionRestoreIdentifierKey) != nil)
        delegate = isConfiguredForStateRestoration ? UUCentralManagerRestoringDelegate() : UUCentralManagerDelegate()
        centralManager = CBCentralManager(delegate: delegate, queue: UUCoreBluetooth.dispatchQueue, options: options)
        delegate.centralStateChangedBlock = handleCentralStateChanged
    }
    
    public var centralState: CBManagerState
    {
        return centralManager.state
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
                centralManager.uuNotifyDisconnect(p.underlyingPeripheral, nil)
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
            
//
//        __weak typeof(self) weakSelf = self;
//        self.peripheralFoundBlock = ^(CBPeripheral * _Nonnull peripheral, NSDictionary<NSString *,id> * _Nullable advertisementData, NSNumber * _Nonnull rssi)
//        {
//            UUPeripheral* uuPeripheral = [weakSelf updatedPeripheralFromScan:peripheral advertisementData:advertisementData rssi:rssi];
//
//            UUCoreBluetoothLog(@"Updated peripheral after scan. peripheral: %@, rssi: %@, advertisement: %@",
//                               uuPeripheral.peripheral, uuPeripheral.rssi, uuPeripheral.advertisementData);
//
//            if ([weakSelf shouldDiscoverPeripheral:uuPeripheral])
//            {
//                peripheralFoundBlock(uuPeripheral);
//            }
//        };
//
        
        resumeScanning()
    }

    private func resumeScanning()
    {
        centralManager.uuScanForPeripherals(scanUuidList, scanOptions, handlePeripheralFound, handleWillRestoreState)
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
        centralManager.uuStopScan()
    }
    
    

     /*
     
    - (void) connectPeripheral:(nonnull UUPeripheral*)peripheral
                       timeout:(NSTimeInterval)timeout
             disconnectTimeout:(NSTimeInterval)disconnectTimeout
                     connected:(nonnull UUPeripheralBlock)connected
                  disconnected:(nonnull UUPeripheralErrorBlock)disconnected
    {
        [self.centralManager uuConnectPeripheral:peripheral.peripheral
                                         options:nil
                                         timeout:timeout
                               disconnectTimeout:disconnectTimeout
                                       connected:^(CBPeripheral * _Nonnull peripheral)
        {
            UUPeripheral* uuPeripheral = [self updatedPeripheralFromCbPeripheral:peripheral];
            connected(uuPeripheral);
            
        }
        disconnected:^(CBPeripheral * _Nonnull peripheral, NSError * _Nullable error)
        {
            [peripheral uuCancelAllTimers];
            
            UUPeripheral* uuPeripheral = [self updatedPeripheralFromCbPeripheral:peripheral];
            disconnected(uuPeripheral, error);
        }];
    }

    - (void) disconnectPeripheral:(nonnull UUPeripheral*)peripheral timeout:(NSTimeInterval)timeout;
    {
        [self.centralManager uuDisconnectPeripheral:peripheral.peripheral timeout:timeout];
    }

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
        
        var uuPeripheral = peripherals[peripheral.uuIdentifier]
        if (uuPeripheral == nil)
        {
            uuPeripheral = UUPeripheral(peripheral)
            
            //let f = peripheralClass?.self.ini
        }
        return UUPeripheral(peripheral)
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


public extension UUCoreBluetooth
{
    static var isBluetoothPoweredOn: Bool
    {
        // TODO: this method
        return false
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




extension UUCoreBluetooth // Timers
{
    static func startWatchdogTimer(_ timerId: String, timeout: TimeInterval, userInfo: Any?, block: UUWatchdogTimerBlock?)
    {
        UUTimer.startWatchdogTimer(timerId, timeout, userInfo, queue: dispatchQueue, block)
    }
}
