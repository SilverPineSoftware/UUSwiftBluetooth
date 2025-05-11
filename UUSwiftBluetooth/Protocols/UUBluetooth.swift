//
//  Untitled.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 5/10/25.
//

public class UUBluetooth
{
    private init() {}
    
    private static var provider: UUBluetoothProvider = UUDefaultProvider()
    
    public static func setProvider(_ provider: UUBluetoothProvider)
    {
        UUBluetooth.provider = provider
    }
    
    public static var scanner: UUPeripheralScanner
    {
        return provider.scanner
    }
    
    public static func createSession(peripheral: UUPeripheral) -> UUPeripheralSession
    {
        return provider.createSession(peripheral: peripheral)
    }
}
