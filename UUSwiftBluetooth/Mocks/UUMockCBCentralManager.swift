//
//  UUMockCBCentralManager.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 7/8/25.
//

import Foundation
import CoreBluetooth

public class UUMockCBCentralManager: UUCBCentralManager
{
    private var backingCentral: CBCentralManager
    
    public var mockDispatchQueue: DispatchQueue = DispatchQueue(label: "UUMockCBCentralManager_DispatchQueue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .inherit, target: nil)
    ///
    /// Mock result
    ///
    public var mockCallbackError: Error? = nil
    
    ///
    /// Number of seconds each api call will delay before returning an async result
    ///
    public var mockCallbackTime: TimeInterval = 0.01
    
    public var mockPeripherals: [CBPeripheral] = []
    
    
    public var delegate: (any CBCentralManagerDelegate)?
    
    public var isScanning: Bool = false
    
    public static func supports(_ features: CBCentralManager.Feature) -> Bool
    {
        return true
    }
    
    public required init(delegate: (any CBCentralManagerDelegate)?, queue: dispatch_queue_t?, options: [String : Any]?)
    {
        backingCentral = CBCentralManager(delegate: delegate, queue: queue, options: options)
        self.delegate = delegate
    }
    
    
    public func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> [CBPeripheral]
    {
        return mockPeripherals.filter { identifiers.contains($0.identifier) }
    }
    
    public func retrieveConnectedPeripherals(withServices serviceUUIDs: [CBUUID]) -> [CBPeripheral]
    {
        return mockPeripherals.filter
        { p in
            
            return (p.services?.count(where: { serviceUUIDs.contains($0.uuid) }) ?? 0 > 0)
        }
    }
    
    public func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String : Any]?)
    {
        
    }
    
    public func stopScan()
    {
    }
    
    public func connect(_ peripheral: CBPeripheral, options: [String : Any]?)
    {
        peripheral.setValue(NSNumber(integerLiteral: CBPeripheralState.connecting.rawValue), forKey: "state")
        
        dispatch
        {
            if let err = self.mockCallbackError
            {
                self.delegate?.centralManager?(self.backingCentral, didFailToConnect: peripheral, error: err)
            }
            else
            {
                peripheral.setValue(NSNumber(integerLiteral: CBPeripheralState.connected.rawValue), forKey: "state")
                
                self.delegate?.centralManager?(self.backingCentral, didConnect: peripheral)
            }
        }
    }
    
    public func cancelPeripheralConnection(_ peripheral: CBPeripheral)
    {
        peripheral.setValue(NSNumber(integerLiteral: CBPeripheralState.disconnecting.rawValue), forKey: "state")
        
        dispatch
        {
            peripheral.setValue(NSNumber(integerLiteral: CBPeripheralState.disconnected.rawValue), forKey: "state")
            self.delegate?.centralManager?(self.backingCentral, didDisconnectPeripheral: peripheral, error: self.mockCallbackError)
        }
    }
    
    public func registerForConnectionEvents(options: [CBConnectionEventMatchingOption : Any]?)
    {
    }
    
    public var state: CBManagerState = .poweredOn
    
    public var authorization: CBManagerAuthorization = .allowedAlways
    
    public static var authorization: CBManagerAuthorization = .allowedAlways
    
    
    
    private func dispatch(_ block: @escaping ()->Void)
    {
        mockDispatchQueue.asyncAfter(deadline: .now() + .milliseconds(Int(self.mockCallbackTime * 1000.0)), execute: block)
    }
}
