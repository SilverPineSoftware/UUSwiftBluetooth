//
//  UUMockCBCentralManager.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 7/8/25.
//

#if DEBUG

import Foundation
import CoreBluetooth

///
/// Non Functional central manager for use in building out mocked objects for Swift UI previews
///
public class UUMockCBCentralManager: UUCBCentralManager
{
    public init()
    {
        
    }
    
    // MARK: UUCBCentralManager Implementation
    
    public var delegate: (any CBCentralManagerDelegate)?
    
    public var isScanning: Bool = false
    
    public static func supports(_ features: CBCentralManager.Feature) -> Bool
    {
        return false
    }
    
    public required init(delegate: (any CBCentralManagerDelegate)?, queue: dispatch_queue_t?, options: [String : Any]?)
    {
        self.delegate = delegate
    }
    
    public func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> [CBPeripheral]
    {
        return []
    }
    
    public func retrieveConnectedPeripherals(withServices serviceUUIDs: [CBUUID]) -> [CBPeripheral]
    {
        return []
    }
    
    public func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String : Any]?)
    {
        
    }
    
    public func stopScan()
    {
    }
    
    public func connect(_ peripheral: CBPeripheral, options: [String : Any]?)
    {
    }
    
    public func cancelPeripheralConnection(_ peripheral: CBPeripheral)
    {
    }
    
    public func registerForConnectionEvents(options: [CBConnectionEventMatchingOption : Any]?)
    {
    }
    
    public var state: CBManagerState = .poweredOn
    
    public var authorization: CBManagerAuthorization = .allowedAlways
    
    public static var authorization: CBManagerAuthorization = .allowedAlways
}

#endif
