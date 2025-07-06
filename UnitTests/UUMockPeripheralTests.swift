
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

@testable import UUSwiftBluetooth

fileprivate let mockServiceUuid = CBUUID.uuCreate(from: "4A3F6F0E-093B-43FE-A717-09E074E42F22")!
fileprivate let mockCharacteristicUuid = CBUUID.uuCreate(from: "B5A3F393-F49B-461B-A1CE-076343E00E5F")!
fileprivate let mockDescriptorUuid = CBUUID.uuCreate(from: "2EC25CCE-D8AA-4DD6-8189-9FB87655BA1F")!

// E4746B35-667D-43B7-B629-988C1570EEB9
// 8601C5FB-966E-4D61-9E2A-11ECCBA9B27C
// DFAF5163-A083-4DC1-923F-66CD1BFACDA5
// 819752E6-DD05-4A14-8475-32EA033F1F9D

final class UUMockPeripheralTests: XCTestCase
{
    public override func setUpWithError() throws
    {
        let logger = UULogger.console
        logger.logLevel = .debug
        
        UULog.setLogger(logger)
    }
    
//    private func loadMockPeripheral() -> UUMockPeripheral?
//    {
//        let bundle = Bundle(for: Self.self)
//        
//        //guard let path = bundle.path(forResource: "atmotube_pro", ofType: "json") else
//        guard let path = bundle.path(forResource: "ti_sensor_tag", ofType: "json") else
//        {
//            NSLog("Unable to load file from bundle")
//            return nil
//        }
//        
//        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else
//        {
//            NSLog("Unable to create data from file")
//            return nil
//        }
//        
//        guard let peripheralData = try? JSONDecoder().decode(UUPeripheralRepresentation.self, from: data) else
//        {
//            NSLog("Unable to load JSON representation")
//            return nil
//        }
//        
//        let check = peripheralData.uuToJsonString()
//        UULog.debug(tag: "Import", message: check)
//        
//        return peripheralData.mockPeripheral
//    }
    
    
    private func setupMockPeripheral() throws -> UUMockPeripheral
    {
        let peripheral = UUMockPeripheral()
        
        let descriptor = CBMutableDescriptor(type: mockDescriptorUuid, value: Data())
        let characteristic = CBMutableCharacteristic(type: mockCharacteristicUuid, properties: [.read, .write], value: nil, permissions: [.readable, .writeable])
        characteristic.descriptors = [descriptor]
        
        let service = CBMutableService(type: mockServiceUuid, primary: true)
        service.characteristics = [characteristic]
        peripheral.mockServices = [service]
        
        return peripheral
    }
    
    func test_0001_connect_success() throws
    {
        let peripheral = try setupMockPeripheral()
        
        let connectExp = uuExpectationForMethod(tag: "connect")
        
        peripheral.connect(timeout: 10.0)
        {
            connectExp.fulfill()
        }
        disconnected:
        { disconnectError in
            XCTFail("Disconnect block not expected in this case")
        }
        
        wait(for: [connectExp], timeout: 20.0)
    }
    
    func test_0002_connect_error() throws
    {
        let peripheral = try setupMockPeripheral()
        
        let connectExp = uuExpectationForMethod(tag: "connect")
        var error: Error? = nil
        
        let domain = "mock"
        let code = 1
        peripheral.mockCallbackError = NSError(domain: domain, code: code)
        
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
        XCTAssertEqual(nsErr.domain, domain)
        XCTAssertEqual(nsErr.code, code)
    }
    
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
        
        peripheral.discoverCharacteristics(characteristicUUIDs: nil, for: peripheral.mockServices[0].uuid, timeout: 10.0)
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
    }
    
    func test_0007_discoverCharacteristics_success_none_found() throws
    {
        let peripheral = try setupMockPeripheral()
        
        let exp = uuExpectationForMethod()
        
        var charResult: [CBCharacteristic]? = nil
        var errorResult: Error? = nil
        
        let fakeService = CBMutableService(type: CBUUID(), primary: false)
        peripheral.discoverCharacteristics(characteristicUUIDs: nil, for: fakeService.uuid, timeout: 10.0)
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
    }
    
}
