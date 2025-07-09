
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

public extension XCTestCase
{
    func uuTestWaitForNotification(_ name: Notification.Name, _ timeout: TimeInterval = 30.0)
    {
        let exp = expectation(forNotification: name, object: nil)
        
        _ = XCTWaiter.wait(for: [exp], timeout: timeout)
    }
    
}
open class UUPeripheralTests: XCTestCase
{
    public override func setUpWithError() throws
    {
        let logger = UULogger.console
        logger.logLevel = .debug
        
        UULog.setLogger(logger)
    }
    
    open func acquireTestPeripheral() throws -> UUPeripheral
    {
        fatalError("Derived classes must implement acquireTestPeripheral()")
    }
    
    func doTest_0001_sessionConnect() throws
    {
        UUTestSetTitle("test_0001_connect_success")
        
        UUTestAddLine("Acquiring test peripheral")
        let peripheral = try acquireTestPeripheral()
        
        let connectExp = uuExpectationForMethod(tag: "connect")
        let disconnectExp = uuExpectationForMethod(tag: "disconnect")
        
        var disconnectError: Error? = nil
        
        peripheral.connect(timeout: 10.0)
        {
            connectExp.fulfill()
        }
        disconnected:
        { disconnectErrorResult in
            disconnectError = disconnectErrorResult
            disconnectExp.fulfill()
        }
        
        wait(for: [connectExp], timeout: 30)
        
        peripheral.disconnect(timeout: 10.0)
        
        wait(for: [disconnectExp], timeout: 30)
        
        XCTAssertNil(disconnectError)
    }
    
    func doTest_0002_connect_device_offline() throws
    {
        UUTestSetTitle("test_0002_device_offline")
        
        UUTestAddLine("Acquiring test peripheral")
        let peripheral = try acquireTestPeripheral()
        
        let connectExp = uuExpectationForMethod(tag: "connect")
        var error: Error? = nil
        
        UUTestAddLine("Turn off test device!")
        
        let deviceOffNotification = "deviceTurnedOff"
        UUTestSetButtonTitle("Click when device is off", deviceOffNotification)
        uuTestWaitForNotification(.uuTestButtonClickedNotification)
        
        peripheral.connect(timeout: 10.0)
        {
            XCTFail("Connect block not expected in this case")
        }
        disconnected:
        { disconnectError in
            error = disconnectError
            connectExp.fulfill()
        }
        
        wait(for: [connectExp], timeout: 20.0)
        
        XCTAssertNotNil(error)
        
        let nsErrorOpt = (error as? NSError)
        let nsErr = try XCTUnwrap(nsErrorOpt)
        XCTAssertEqual(nsErr.domain, kUUCoreBluetoothErrorDomain)
        XCTAssertEqual(nsErr.code, UUCoreBluetoothErrorCode.timeout.rawValue)
    }
    
    /*
    func test_0003_disconnect_after_connect() throws
    {
        let peripheral = try setupMockPeripheral()
        
        let connectExp = uuExpectationForMethod(tag: "connect")
        let disconnectExp = uuExpectationForMethod(tag: "disconnect")
        
        var error: Error? = nil
        
        peripheral.connect(timeout: 10.0)
        {
            connectExp.fulfill()
        }
        disconnected:
        { disconnectError in
            error = disconnectError
            disconnectExp.fulfill()
        }
        
        wait(for: [connectExp], timeout: 20.0)
        
        let domain = "mock"
        let code = 1
        peripheral.mockCallbackError = NSError(domain: domain, code: code)
        peripheral.disconnect(timeout: 10.0)
        
        wait(for: [disconnectExp], timeout: 20.0)
        
        XCTAssertNotNil(error)
        
        let nsErrorOpt = (error as? NSError)
        let nsErr = try XCTUnwrap(nsErrorOpt)
        XCTAssertEqual(nsErr.domain, domain)
        XCTAssertEqual(nsErr.code, code)
    }
    
    func test_0004_discoverServices_success() throws
    {
        let peripheral = try setupMockPeripheral()
        
        let exp = uuExpectationForMethod()
        
        var servicesResult: [CBService]? = nil
        var errorResult: Error? = nil
        
        peripheral.discoverServices(serviceUUIDs: nil, timeout: 10.0)
        { operationResult, operationError in
            servicesResult = operationResult
            errorResult = operationError
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 20.0)
        
        XCTAssertNil(errorResult)
        XCTAssertNotNil(servicesResult)
        let services = try XCTUnwrap(servicesResult)
        XCTAssertEqual(1, services.count)
        
        let svc = try XCTUnwrap(services.first)
        XCTAssertEqual(mockServiceUuid, svc.uuid)
        XCTAssertNil(svc.characteristics)
    }
    
    func test_0005_discoverServices_error() throws
    {
        let peripheral = try setupMockPeripheral()
        
        let exp = uuExpectationForMethod()
        
        var servicesResult: [CBService]? = nil
        var errorResult: Error? = nil
        
        let domain = "mock"
        let code = 1
        peripheral.mockCallbackError = NSError(domain: domain, code: code)
        
        peripheral.discoverServices(serviceUUIDs: nil, timeout: 10.0)
        { operationResult, operationError in
            servicesResult = operationResult
            errorResult = operationError
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 20.0)
        
        let nsErrorOpt = (errorResult as? NSError)
        let nsErr = try XCTUnwrap(nsErrorOpt)
        XCTAssertEqual(nsErr.domain, domain)
        XCTAssertEqual(nsErr.code, code)
        
        XCTAssertNil(servicesResult)
    }
    
    func test_0006_discoverCharacteristics_success() throws
    {
        let peripheral = try setupMockPeripheral()
        
        let exp = uuExpectationForMethod()
        
        var charResult: [CBCharacteristic]? = nil
        var errorResult: Error? = nil
        
        peripheral.discoverCharacteristics(characteristicUUIDs: nil, for: peripheral.mockServices[0], timeout: 10.0)
        { operationResult, operationError in
            charResult = operationResult
            errorResult = operationError
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 20.0)
        
        XCTAssertNil(errorResult)
        XCTAssertNotNil(charResult)
        let chars = try XCTUnwrap(charResult)
        XCTAssertEqual(1, chars.count)
        
        let char = try XCTUnwrap(chars.first)
        XCTAssertEqual(mockCharacteristicUuid, char.uuid)
        XCTAssertNil(char.descriptors)
    }*/
    
    /*
    func test_0007_discoverCharacteristics_success_none_found() throws
    {
        let peripheral = try setupMockPeripheral()
        
        let exp = uuExpectationForMethod()
        
        var charResult: [CBCharacteristic]? = nil
        var errorResult: Error? = nil
        
        let fakeService = CBMutableService(type: CBUUID(), primary: false)
        peripheral.discoverCharacteristics(characteristicUUIDs: nil, for: fakeService, timeout: 10.0)
        { operationResult, operationError in
            charResult = operationResult
            errorResult = operationError
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 20.0)
        
        XCTAssertNil(errorResult)
        XCTAssertNotNil(charResult)
        let chars = try XCTUnwrap(charResult)
        XCTAssertEqual(0, chars.count)
    }*/
    
    
    
    
    
    /*
    func test_0009_sessionConnect_discoverServices() async throws
    {
        UUTestSetTitle("test_0001_sessionConnect")
        
        
        UUTestAddLine("Scanning for peripheral")
        var scanner = UUBluetooth.scanner
        let peripheralOpt = await scanner.scanForPeripheral(timeout: 10, filter: UUPeripheralNameFilter("CC2650 SensorTag"))
        let peripheral = try XCTUnwrap(peripheralOpt)
        
        let connectExp = uuExpectationForMethod(tag: "connect")
        let disconnectExp = uuExpectationForMethod(tag: "disconnect")
        
        //var error: Error? = nil
        
        peripheral.connect(timeout: 10.0)
        {
            connectExp.fulfill()
        }
        disconnected:
        { disconnectError in
            //error = disconnectError
            disconnectExp.fulfill()
        }
        
        await fulfillment(of: [connectExp], timeout: 30)
        
        
        let discoverServicesExp = uuExpectationForMethod(tag: "discoverServices")
        peripheral.discoverServices(serviceUUIDs: [CBUUID()], timeout: 10.0)
        { operationResult, operationError in
            discoverServicesExp.fulfill()
        }
        
        await fulfillment(of: [discoverServicesExp], timeout: 30)
        
        
//        let domain = "mock"
//        let code = 1
//        peripheral.mockCallbackError = NSError(domain: domain, code: code)
        peripheral.disconnect(timeout: 10.0)
        
        await fulfillment(of: [disconnectExp], timeout: 30)
        
//        XCTAssertNotNil(error)
//
//        let nsErrorOpt = (error as? NSError)
//        let nsErr = try XCTUnwrap(nsErrorOpt)
//        XCTAssertEqual(nsErr.domain, domain)
//        XCTAssertEqual(nsErr.code, code)
    }*/
}
