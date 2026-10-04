//
//  Untitled.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 5/10/25.
//

public class UUBluetooth
{
    private init() {}
    
    private static var provider: UUBluetoothProvider = UUCoreBluetoothProvider()
    
    public static func setProvider(_ provider: UUBluetoothProvider)
    {
        UUBluetooth.provider = provider
    }
    
    public static func initialize(config: UUBluetoothConfig)
    {
        provider.initialize(config: config)
    }
    
    public static var centralManager: UUCentralManager
    {
        return provider.centralManager
    }
    
    public static var scanner: UUPeripheralScanner
    {
        return provider.scanner
    }
    
    public static var monitor: UUManagerStateMonitor
    {
        return provider.managerStateMonitor
    }
}
