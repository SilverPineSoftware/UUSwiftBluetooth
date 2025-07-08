
//
//  UUMockPeripheralTests.swift
//  UUSwiftBluetoothTests
//
//  Created by Ryan DeVore on 7/1/25.
//

import XCTest
import UUSwiftTestCore
import UUSwiftCore
import CoreBluetooth
import UUSwiftTestCoreUX

@testable import UUSwiftBluetooth

final class UULivePeripheralTests: UUPeripheralTests
{
    override func acquireTestPeripheral() throws -> (any UUPeripheral)
    {
        //let peripheralName = "CC2650 SensorTag"
        let peripheralName = "Code Ninja Mac"
        let scanner = UUBluetooth.scanner
        let peripheralOpt = scanForPeripheral(scanner: scanner, timeout: 10.0, filter: UUPeripheralNameFilter(peripheralName))
        let peripheral = try XCTUnwrap(peripheralOpt)
        return peripheral
    }
    
    func test_0001_sessionConnect() throws
    {
        try super.doTest_0001_sessionConnect()
    }
    
    func test_0002_sessionConnect() throws
    {
        try super.doTest_0002_connect_device_offline()
    }
}
