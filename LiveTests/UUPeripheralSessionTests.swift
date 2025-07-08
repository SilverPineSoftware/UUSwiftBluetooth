//
//  UUPeripheralSessionTests.swift
//  UUSwiftBluetoothTests
//
//  Created by Ryan DeVore on 5/4/25.
//

import XCTest
import UUSwiftCore
@testable import UUSwiftBluetooth
import UUSwiftTestCore
import UUSwiftTestCoreUX
import CoreBluetooth

final class UUPeripheralSessionTests: XCTestCase
{
    override func setUpWithError() throws
    {
        let logger = UULogger.console
        logger.logLevel = .debug
        
        UULog.setLogger(logger)
        
        TiSensorTag.addSpecNames()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws
    {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_0001_sessionConnect() throws
    {
        UUTestSetTitle("Peripheral Session Test")
        
        let startExp = uuExpectationForMethod(tag: "session_start")
        let endExp = uuExpectationForMethod(tag: "session_end")
        
        UUTestAddLine("Scanning for peripheral")
        let peripheralName = "Code Ninja Mac"
        //var scanner = UUBluetooth.scanner
        //let peripheralOpt = await scanner.scanForPeripheral(timeout: 10, filter: UUPeripheralNameFilter(peripheralName))
        let peripheral = try scanForPeripheral(name: peripheralName)
        
        UUTestAddLine("Found peripheral")
        //let session = UUCoreBluetoothPeripheralSession(peripheral: peripheral)
        //let session = TiSensorTagCoreBluetoothSession(peripheral: peripheral)
        let session = TestPeripheralSessionImplementation(peripheral: peripheral)
        
        session.started =
        { s in
            UUTestAddLine("Session Started")
            startExp.fulfill()
        }
        
        session.ended =
        { s, err in
            UUTestAddLine("session ended, err: \(String(describing: err))")
            endExp.fulfill()
        }
        
        UUTestAddLine("Starting session")
        session.start()
        
        wait(for: [startExp], timeout: 30.0)
        
        UUTestAddLine("Waiting a while...")
        uuTestWait(10.0)
        
        UUTestAddLine("Ending session")
        session.end(error: nil)
        
        wait(for: [endExp], timeout: 30.0)
        
        UUTestAddLine("Test done")
    }
    
    func test_0002_discoverServices() throws
    {
        UUTestSetTitle("Peripheral Session Test")
        
        let startExp = uuExpectationForMethod(tag: "session_start")
        let endExp = uuExpectationForMethod(tag: "session_end")
        
        UUTestAddLine("Scanning for peripheral")
        let peripheralName = "Code Ninja Mac"
//        var scanner = UUBluetooth.scanner
//        let peripheralOpt = await scanner.scanForPeripheral(timeout: 10, filter: UUPeripheralNameFilter(peripheralName))
//        let peripheral = try XCTUnwrap(peripheralOpt)
        let peripheral = try scanForPeripheral(name: peripheralName)
        
        UUTestAddLine("Found peripheral")
        //let session = UUCoreBluetoothPeripheralSession(peripheral: peripheral)
        //let session = TiSensorTagCoreBluetoothSession(peripheral: peripheral)
        let session = TestPeripheralSessionImplementation(peripheral: peripheral)
        
        session.started =
        { s in
            UUTestAddLine("Session Started")
            startExp.fulfill()
        }
        
        session.ended =
        { s, err in
            UUTestAddLine("session ended, err: \(String(describing: err))")
            endExp.fulfill()
        }
        
        UUTestAddLine("Starting session")
        session.start()
        
        wait(for: [startExp], timeout: 30.0)
        
        UUTestAddLine("Waiting a while...")
        uuTestWait(10.0)
        
        UUTestAddLine("Ending session")
        session.end(error: nil)
        
        wait(for: [endExp], timeout: 30.0)
        
        UUTestAddLine("Test done")
    }

}



fileprivate protocol TestPeripheralSession
{
    func readManufacturerName(_ completion: @escaping UUObjectErrorBlock<String>)
    func readModelNumber(_ completion: @escaping UUObjectErrorBlock<String>)
}

fileprivate class TestPeripheralSessionImplementation: UUPeripheralSession, TestPeripheralSession
{
    public required init(peripheral: UUPeripheral)
    {
        super.init(peripheral: peripheral)
        
        configuration.servicesToDiscover = [ UUCoreBluetooth.Constants.Services.deviceInformation ]
        configuration.characteristicsToDiscover =
        [
            UUCoreBluetooth.Constants.Services.deviceInformation:
            [
                UUCoreBluetooth.Constants.Characteristics.manufacturerNameString,
                UUCoreBluetooth.Constants.Characteristics.modelNumberString
        ]   ]
    }
    
    public var manufacturerName: String? = nil
    public var modelNumber: String? = nil
    
    public override func finishSessionStart(_ completion: @escaping () -> Void)
    {
        readManufacturerName
        { deviceNameOpt, deviceNameErrOpt in
            self.manufacturerName = deviceNameOpt
            NSLog("Manufacturer Name: \(String(describing: deviceNameOpt))")
            
            self.readModelNumber
            { modelNumberOpt, modelNumberErrOpt in
            
                self.modelNumber = modelNumberOpt
                NSLog("Model Number: \(String(describing: modelNumberOpt))")
                
                completion()
            }
        }
    }
    
    func readManufacturerName(_ completion: @escaping UUObjectErrorBlock<String>)
    {
        readUtf8(from: UUCoreBluetooth.Constants.Characteristics.manufacturerNameString)
        { session, stringOpt, errorOpt in
            completion(stringOpt, errorOpt)
        }
    }
    
    func readModelNumber(_ completion: @escaping UUObjectErrorBlock<String>)
    {
        readUtf8(from: UUCoreBluetooth.Constants.Characteristics.modelNumberString)
        { session, stringOpt, errorOpt in
            completion(stringOpt, errorOpt)
        }
    }
}

