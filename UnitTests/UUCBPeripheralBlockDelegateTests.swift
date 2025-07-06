//
//  UUCBPeripheralBlockDelegateTests.swift
//  UUSwiftBluetoothTests
//
//  Created by Ryan DeVore on 7/5/25.
//

import XCTest
import CoreBluetooth
@testable import UUSwiftBluetooth

final class UUCBPeripheralBlockDelegateTests: XCTestCase
{
    // MARK: Miscellaneous
    
    func testMakeMockCBPeripheral() throws
    {
        let mockPeripheral = try XCTUnwrap(uuMakeCBPeripheral())
        XCTAssertNotNil(mockPeripheral)
    }
    
    // MARK: peripheralDidUpdateName
    
    func test_peripheralDidUpdateName_success() throws
    {
        let exp = uuExpectationForMethod()
        
        let delegate = UUCBPeripheralBlockDelegate()
        
        var callbackResult: CBPeripheral? = nil
        
        delegate.peripheralNameUpdatedBlock =
        { peripheral in
            
            callbackResult = peripheral
            exp.fulfill()
        }
        
        let mockPeripheral = try XCTUnwrap(uuMakeCBPeripheral(name: "Before"))

        XCTAssertNotNil(delegate.peripheralNameUpdatedBlock)
        
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.1)
        {
            mockPeripheral.setValue("After", forKey: "name")
            delegate.peripheralDidUpdateName(mockPeripheral)
        }
        
        uuWaitForExpectations()
        
        XCTAssertNotNil(callbackResult)
        
        let result = try XCTUnwrap(callbackResult)
        XCTAssertEqual("After", result.name)
        
        XCTAssertNotNil(delegate.peripheralNameUpdatedBlock)
    }
    
    func test_peripheralDidUpdateName_notRegistered() throws
    {
        let exp = uuExpectationForMethod()
        exp.isInverted = true
        
        let delegate = UUCBPeripheralBlockDelegate()
        
        delegate.peripheralNameUpdatedBlock = nil
        
        let mockPeripheral = try XCTUnwrap(uuMakeCBPeripheral(name: "Before"))

        XCTAssertNil(delegate.peripheralNameUpdatedBlock)
        
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.1)
        {
            mockPeripheral.setValue("After", forKey: "name")
            delegate.peripheralDidUpdateName(mockPeripheral)
        }
        
        uuWaitForExpectations(0.2)
        
        XCTAssertNil(delegate.peripheralNameUpdatedBlock)
    }
    
    // MARK: didModifyServices
    
    func test_didModifyServices_success() throws
    {
        let exp = uuExpectationForMethod()
        
        let delegate = UUCBPeripheralBlockDelegate()
        
        var callbackResult: CBPeripheral? = nil
        
        delegate.didModifyServicesBlock =
        { peripheral, invalidatedServices in
            
            callbackResult = peripheral
            exp.fulfill()
        }
        
        let mockPeripheral = try XCTUnwrap(uuMakeCBPeripheral())

        XCTAssertNotNil(delegate.didModifyServicesBlock)
        
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.1)
        {
            delegate.peripheral(mockPeripheral, didModifyServices: [])
        }
        
        uuWaitForExpectations()
        
        XCTAssertNotNil(callbackResult)
        
        XCTAssertNotNil(delegate.didModifyServicesBlock)
    }
    
    func test_didModifyServices_notRegistered() throws
    {
        let exp = uuExpectationForMethod()
        exp.isInverted = true
        
        let delegate = UUCBPeripheralBlockDelegate()
        
        delegate.didModifyServicesBlock = nil
        
        let mockPeripheral = try XCTUnwrap(uuMakeCBPeripheral(name: "Before"))

        XCTAssertNil(delegate.didModifyServicesBlock)
        
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.1)
        {
            delegate.peripheral(mockPeripheral, didModifyServices: [])
        }
        
        uuWaitForExpectations(0.2)
        
        XCTAssertNil(delegate.didModifyServicesBlock)
    }
    
    // MARK: didDiscoverServices
    
    func test_didDiscoverServices_success() throws
    {
        let exp = uuExpectationForMethod()
        
        let delegate = UUCBPeripheralBlockDelegate()
        
        var callbackResult: [CBService]? = nil
        var callbackError: Error? = nil
        
        delegate.discoverServicesBlock =
        { services, err in
            
            callbackResult = services
            callbackError = err
            exp.fulfill()
        }
        
        let mockService = CBMutableService(type: CBUUID(), primary: true)
        
        let mockPeripheral = try XCTUnwrap(uuMakeCBPeripheral(services: [mockService]))

        XCTAssertNotNil(delegate.discoverServicesBlock)
        
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.1)
        {
            delegate.peripheral(mockPeripheral, didDiscoverServices: nil)
        }
        
        uuWaitForExpectations()
        
        XCTAssertNil(callbackError)
        XCTAssertNotNil(callbackResult)
        
        let result = try XCTUnwrap(callbackResult)
        XCTAssertEqual(1, result.count)
        
        XCTAssertNil(delegate.discoverServicesBlock)
    }
    
    func test_didDiscoverServices_error() throws
    {
        let exp = uuExpectationForMethod()
        
        let delegate = UUCBPeripheralBlockDelegate()
        
        var callbackResult: [CBService]? = nil
        var callbackError: Error? = nil
        
        delegate.discoverServicesBlock =
        { services, err in
            
            callbackResult = services
            callbackError = err
            exp.fulfill()
        }
        
        let mockPeripheral = try XCTUnwrap(uuMakeCBPeripheral())
        
        XCTAssertNotNil(delegate.discoverServicesBlock)
        
        let inputError = NSError(domain: "test", code: 1, userInfo: nil)

        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.1)
        {
            delegate.peripheral(mockPeripheral, didDiscoverServices: inputError)
        }
        
        uuWaitForExpectations()
        
        XCTAssertNotNil(callbackError)
        XCTAssertNil(callbackResult)
        
        let result = try XCTUnwrap(callbackError) as NSError
        XCTAssertEqual(inputError.domain, result.domain)
        XCTAssertEqual(inputError.code, result.code)
        
        XCTAssertNil(delegate.discoverServicesBlock)
    }
    
    func test_didDiscoverServices_notRegistered() throws
    {
        let exp = uuExpectationForMethod()
        exp.isInverted = true
        
        let delegate = UUCBPeripheralBlockDelegate()
        
        delegate.discoverServicesBlock = nil
        
        let mockPeripheral = try XCTUnwrap(uuMakeCBPeripheral())
        
        XCTAssertNil(delegate.discoverServicesBlock)
        
        let inputError = NSError(domain: "test", code: 1, userInfo: nil)

        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.1)
        {
            delegate.peripheral(mockPeripheral, didDiscoverServices: inputError)
        }
        
        uuWaitForExpectations(0.2)
        
        XCTAssertNil(delegate.discoverServicesBlock)
    }
    
    
    
    // MARK: didReadRSSI
    
    func test_didReadRSSI_success() throws
    {
        let exp = uuExpectationForMethod()
        
        let delegate = UUCBPeripheralBlockDelegate()
        
        var callbackResult: Int? = nil
        var callbackError: Error? = nil
        
        delegate.didReadRssiBlock =
        { rssi, err in
            
            callbackResult = rssi
            callbackError = err
            exp.fulfill()
        }
        
        let mockPeripheral = try XCTUnwrap(uuMakeCBPeripheral())

        XCTAssertNotNil(delegate.didReadRssiBlock)
        
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.1)
        {
            delegate.peripheral(mockPeripheral, didReadRSSI: NSNumber(integerLiteral: -20), error: nil)
        }
        
        uuWaitForExpectations()
        
        XCTAssertNil(callbackError)
        XCTAssertNotNil(callbackResult)
        
        let result = try XCTUnwrap(callbackResult)
        XCTAssertEqual(-20, result)
        
        XCTAssertNil(delegate.didReadRssiBlock)
    }
    
    func test_didReadRSSI_error() throws
    {
        let exp = uuExpectationForMethod()
        
        let delegate = UUCBPeripheralBlockDelegate()
        
        var callbackResult: Int? = nil
        var callbackError: Error? = nil
        
        delegate.didReadRssiBlock =
        { rssi, err in
            
            callbackResult = rssi
            callbackError = err
            exp.fulfill()
        }
        
        let mockPeripheral = try XCTUnwrap(uuMakeCBPeripheral())
        
        XCTAssertNotNil(delegate.didReadRssiBlock)
        
        let inputError = NSError(domain: "test", code: 1, userInfo: nil)

        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.1)
        {
            delegate.peripheral(mockPeripheral, didReadRSSI: NSNumber(integerLiteral: 55), error: inputError)
        }
        
        uuWaitForExpectations()
        
        XCTAssertNotNil(callbackError)
        XCTAssertNotNil(callbackResult)
        
        let result = try XCTUnwrap(callbackError) as NSError
        XCTAssertEqual(inputError.domain, result.domain)
        XCTAssertEqual(inputError.code, result.code)
        
        let result2 = try XCTUnwrap(callbackResult)
        XCTAssertEqual(55, result2)
        
        XCTAssertNil(delegate.didReadRssiBlock)
    }
    
    func test_didReadRssiBlock_notRegistered() throws
    {
        let exp = uuExpectationForMethod()
        exp.isInverted = true
        
        let delegate = UUCBPeripheralBlockDelegate()
        
        delegate.didReadRssiBlock = nil
        
        let mockPeripheral = try XCTUnwrap(uuMakeCBPeripheral())
        
        XCTAssertNil(delegate.didReadRssiBlock)
        
        let inputError = NSError(domain: "test", code: 1, userInfo: nil)

        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.1)
        {
            delegate.peripheral(mockPeripheral, didReadRSSI: NSNumber(integerLiteral: -20), error: inputError)
        }
        
        uuWaitForExpectations(0.2)
        
        XCTAssertNil(delegate.didReadRssiBlock)
    }
        
    // MARK: didDiscoverIncludedServices
    
    func test_didDiscoverIncludedServices_success() throws
    {
        let exp = uuExpectationForMethod()
        
        let delegate = UUCBPeripheralBlockDelegate()
        
        var callbackResult: [CBService]? = nil
        var callbackError: Error? = nil
        
        delegate.discoverIncludedServicesBlock =
        { services, err in
            
            callbackResult = services
            callbackError = err
            exp.fulfill()
        }
        
        let mockService = CBMutableService(type: CBUUID(), primary: true)
        mockService.includedServices = [CBMutableService(type: CBUUID(), primary: true), CBMutableService(type: CBUUID(), primary: false)]
        let mockPeripheral = try XCTUnwrap(uuMakeCBPeripheral(services: [mockService]))

        XCTAssertNotNil(delegate.discoverIncludedServicesBlock)
        
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.1)
        {
            delegate.peripheral(mockPeripheral, didDiscoverIncludedServicesFor: mockService, error: nil)
        }
        
        uuWaitForExpectations()
        
        XCTAssertNil(callbackError)
        XCTAssertNotNil(callbackResult)
        
        let result = try XCTUnwrap(callbackResult)
        XCTAssertEqual(2, result.count)
        
        XCTAssertNil(delegate.discoverIncludedServicesBlock)
    }
    
    func test_didDiscoverIncludedServices_error() throws
    {
        let exp = uuExpectationForMethod()
        
        let delegate = UUCBPeripheralBlockDelegate()
        
        var callbackResult: [CBService]? = nil
        var callbackError: Error? = nil
        
        delegate.discoverIncludedServicesBlock =
        { services, err in
            
            callbackResult = services
            callbackError = err
            exp.fulfill()
        }
        
        let mockService = CBMutableService(type: CBUUID(), primary: true)
        let mockPeripheral = try XCTUnwrap(uuMakeCBPeripheral())
        
        XCTAssertNotNil(delegate.discoverIncludedServicesBlock)
        
        let inputError = NSError(domain: "test", code: 1, userInfo: nil)

        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.1)
        {
            delegate.peripheral(mockPeripheral, didDiscoverIncludedServicesFor: mockService, error: inputError)
        }
        
        uuWaitForExpectations()
        
        XCTAssertNotNil(callbackError)
        XCTAssertNil(callbackResult)
        
        let result = try XCTUnwrap(callbackError) as NSError
        XCTAssertEqual(inputError.domain, result.domain)
        XCTAssertEqual(inputError.code, result.code)
        
        XCTAssertNil(delegate.discoverIncludedServicesBlock)
    }
    
    func test_didDiscoverIncludedServices_notRegistered() throws
    {
        let exp = uuExpectationForMethod()
        exp.isInverted = true
        
        let delegate = UUCBPeripheralBlockDelegate()
        
        delegate.discoverIncludedServicesBlock = nil
        
        let mockService = CBMutableService(type: CBUUID(), primary: true)
        let mockPeripheral = try XCTUnwrap(uuMakeCBPeripheral())
        
        XCTAssertNil(delegate.discoverIncludedServicesBlock)
        
        let inputError = NSError(domain: "test", code: 1, userInfo: nil)

        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.1)
        {
            delegate.peripheral(mockPeripheral, didDiscoverIncludedServicesFor: mockService, error: inputError)
        }
        
        uuWaitForExpectations(0.2)
        
        XCTAssertNil(delegate.discoverIncludedServicesBlock)
    }

    // MARK: didDiscoverCharacteristics
    
    func test_didDiscoverCharacteristics_success() throws
    {
        let exp = uuExpectationForMethod()
        
        let delegate = UUCBPeripheralBlockDelegate()
        
        var callbackResult: [CBCharacteristic]? = nil
        var callbackError: Error? = nil
        
        delegate.discoverCharacteristicsBlock =
        { characteristics, err in
            
            callbackResult = characteristics
            callbackError = err
            exp.fulfill()
        }
        
        let mockService = CBMutableService(type: CBUUID(), primary: true)
        mockService.characteristics = [
            CBMutableCharacteristic(type: CBUUID(), properties: [.read, .write], value: nil, permissions: [.readable, .writeable]),
            CBMutableCharacteristic(type: CBUUID(), properties: [.write], value: nil, permissions: [.writeable]),
            CBMutableCharacteristic(type: CBUUID(), properties: [.writeWithoutResponse, .notify], value: nil, permissions: [.writeable]),
        ]
        
        let mockPeripheral = try XCTUnwrap(uuMakeCBPeripheral(services: [mockService]))

        XCTAssertNotNil(delegate.discoverCharacteristicsBlock)
        
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.1)
        {
            delegate.peripheral(mockPeripheral, didDiscoverCharacteristicsFor: mockService, error: nil)
        }
        
        uuWaitForExpectations()
        
        XCTAssertNil(callbackError)
        XCTAssertNotNil(callbackResult)
        
        let result = try XCTUnwrap(callbackResult)
        XCTAssertEqual(3, result.count)
        
        XCTAssertNil(delegate.discoverCharacteristicsBlock)
    }
    
    func test_didDiscoverCharacteristics_error() throws
    {
        let exp = uuExpectationForMethod()
        
        let delegate = UUCBPeripheralBlockDelegate()
        
        var callbackResult: [CBCharacteristic]? = nil
        var callbackError: Error? = nil
        
        delegate.discoverCharacteristicsBlock =
        { services, err in
            
            callbackResult = services
            callbackError = err
            exp.fulfill()
        }
        
        let mockService = CBMutableService(type: CBUUID(), primary: true)
        let mockPeripheral = try XCTUnwrap(uuMakeCBPeripheral())
        
        XCTAssertNotNil(delegate.discoverCharacteristicsBlock)
        
        let inputError = NSError(domain: "test", code: 1, userInfo: nil)

        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.1)
        {
            delegate.peripheral(mockPeripheral, didDiscoverCharacteristicsFor: mockService, error: inputError)
        }
        
        uuWaitForExpectations()
        
        XCTAssertNotNil(callbackError)
        XCTAssertNil(callbackResult)
        
        let result = try XCTUnwrap(callbackError) as NSError
        XCTAssertEqual(inputError.domain, result.domain)
        XCTAssertEqual(inputError.code, result.code)
        
        XCTAssertNil(delegate.discoverCharacteristicsBlock)
    }
    
    func test_didDiscoverCharacteristics_notRegistered() throws
    {
        let exp = uuExpectationForMethod()
        exp.isInverted = true
        
        let delegate = UUCBPeripheralBlockDelegate()
        
        delegate.discoverCharacteristicsBlock = nil
        
        let mockService = CBMutableService(type: CBUUID(), primary: true)
        let mockPeripheral = try XCTUnwrap(uuMakeCBPeripheral())
        
        XCTAssertNil(delegate.discoverCharacteristicsBlock)
        
        let inputError = NSError(domain: "test", code: 1, userInfo: nil)

        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.1)
        {
            delegate.peripheral(mockPeripheral, didDiscoverCharacteristicsFor: mockService, error: inputError)
        }
        
        uuWaitForExpectations(0.2)
        
        XCTAssertNil(delegate.discoverCharacteristicsBlock)
    }
    
    // MARK: didDiscoverDescriptors
    
    func test_didDiscoverDescriptors_success() throws
    {
        let exp = uuExpectationForMethod()
        
        let delegate = UUCBPeripheralBlockDelegate()
        
        var callbackResult: [CBDescriptor]? = nil
        var callbackError: Error? = nil
        
        delegate.discoverDescriptorsBlock =
        { descriptors, err in
            
            callbackResult = descriptors
            callbackError = err
            exp.fulfill()
        }
        
        let mockCharacteristic = CBMutableCharacteristic(type: CBUUID(), properties: [.read, .write], value: nil, permissions: [.readable, .writeable])
        mockCharacteristic.descriptors = [
            CBMutableDescriptor(type: CBUUID(), value: nil),
            CBMutableDescriptor(type: CBUUID(), value: "Hello"),
        ]
        
        let mockPeripheral = try XCTUnwrap(uuMakeCBPeripheral())

        XCTAssertNotNil(delegate.discoverDescriptorsBlock)
        
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.1)
        {
            delegate.peripheral(mockPeripheral, didDiscoverDescriptorsFor: mockCharacteristic, error: nil)
        }
        
        uuWaitForExpectations()
        
        XCTAssertNil(callbackError)
        XCTAssertNotNil(callbackResult)
        
        let result = try XCTUnwrap(callbackResult)
        XCTAssertEqual(2, result.count)
        
        XCTAssertNil(delegate.discoverDescriptorsBlock)
    }
    
    func test_didDiscoverDescriptors_error() throws
    {
        let exp = uuExpectationForMethod()
        
        let delegate = UUCBPeripheralBlockDelegate()
        
        var callbackResult: [CBDescriptor]? = nil
        var callbackError: Error? = nil
        
        delegate.discoverDescriptorsBlock =
        { descriptors, err in
            
            callbackResult = descriptors
            callbackError = err
            exp.fulfill()
        }
        
        let mockCharacteristic = CBMutableCharacteristic(type: CBUUID(), properties: [.read, .write], value: nil, permissions: [.readable, .writeable])
        let mockPeripheral = try XCTUnwrap(uuMakeCBPeripheral())
        
        XCTAssertNotNil(delegate.discoverDescriptorsBlock)
        
        let inputError = NSError(domain: "test", code: 1, userInfo: nil)

        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.1)
        {
            delegate.peripheral(mockPeripheral, didDiscoverDescriptorsFor: mockCharacteristic, error: inputError)
        }
        
        uuWaitForExpectations()
        
        XCTAssertNotNil(callbackError)
        XCTAssertNil(callbackResult)
        
        let result = try XCTUnwrap(callbackError) as NSError
        XCTAssertEqual(inputError.domain, result.domain)
        XCTAssertEqual(inputError.code, result.code)
        
        XCTAssertNil(delegate.discoverDescriptorsBlock)
    }
    
    func test_didDiscoverDescriptors_notRegistered() throws
    {
        let exp = uuExpectationForMethod()
        exp.isInverted = true
        
        let delegate = UUCBPeripheralBlockDelegate()
        
        delegate.discoverDescriptorsBlock = nil
        
        let mockCharacteristic = CBMutableCharacteristic(type: CBUUID(), properties: [.read, .write], value: nil, permissions: [.readable, .writeable])
        let mockPeripheral = try XCTUnwrap(uuMakeCBPeripheral())
        
        XCTAssertNil(delegate.discoverDescriptorsBlock)
        
        let inputError = NSError(domain: "test", code: 1, userInfo: nil)

        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.1)
        {
            delegate.peripheral(mockPeripheral, didDiscoverDescriptorsFor: mockCharacteristic, error: inputError)
        }
        
        uuWaitForExpectations(0.2)
        
        XCTAssertNil(delegate.discoverDescriptorsBlock)
    }
    
    // MARK: didUpdateNotificationState
    
    func test_didUpdateNotificationState_success() throws
    {
        let exp = uuExpectationForMethod()
        
        let delegate = UUCBPeripheralBlockDelegate()
        
        var callbackError: Error? = nil
        
        delegate.setNotifyValueForCharacteristicBlock =
        { err in
            
            callbackError = err
            exp.fulfill()
        }
        
        let mockCharacteristic = CBMutableCharacteristic(type: CBUUID(), properties: [.read, .write], value: nil, permissions: [.readable, .writeable])
        let mockPeripheral = try XCTUnwrap(uuMakeCBPeripheral())

        XCTAssertNotNil(delegate.setNotifyValueForCharacteristicBlock)
        
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.1)
        {
            delegate.peripheral(mockPeripheral, didUpdateNotificationStateFor: mockCharacteristic, error: nil)
        }
        
        uuWaitForExpectations()
        
        XCTAssertNil(callbackError)
        
        XCTAssertNil(delegate.setNotifyValueForCharacteristicBlock)
    }
    
    func test_didUpdateNotificationState_error() throws
    {
        let exp = uuExpectationForMethod()
        
        let delegate = UUCBPeripheralBlockDelegate()
        
        var callbackError: Error? = nil
        
        delegate.setNotifyValueForCharacteristicBlock =
        { err in
            
            callbackError = err
            exp.fulfill()
        }
        
        let mockCharacteristic = CBMutableCharacteristic(type: CBUUID(), properties: [.read, .write], value: nil, permissions: [.readable, .writeable])
        let mockPeripheral = try XCTUnwrap(uuMakeCBPeripheral())
        
        XCTAssertNotNil(delegate.setNotifyValueForCharacteristicBlock)
        
        let inputError = NSError(domain: "test", code: 1, userInfo: nil)

        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.1)
        {
            delegate.peripheral(mockPeripheral, didUpdateNotificationStateFor: mockCharacteristic, error: inputError)
        }
        
        uuWaitForExpectations()
        
        XCTAssertNotNil(callbackError)
        
        let result = try XCTUnwrap(callbackError) as NSError
        XCTAssertEqual(inputError.domain, result.domain)
        XCTAssertEqual(inputError.code, result.code)
        
        XCTAssertNil(delegate.setNotifyValueForCharacteristicBlock)
    }
    
    func test_didUpdateNotificationState_notRegistered() throws
    {
        let exp = uuExpectationForMethod()
        exp.isInverted = true
        
        let delegate = UUCBPeripheralBlockDelegate()
        
        delegate.setNotifyValueForCharacteristicBlock = nil
        
        let mockCharacteristic = CBMutableCharacteristic(type: CBUUID(), properties: [.read, .write], value: nil, permissions: [.readable, .writeable])
        let mockPeripheral = try XCTUnwrap(uuMakeCBPeripheral())
        
        XCTAssertNil(delegate.setNotifyValueForCharacteristicBlock)
        
        let inputError = NSError(domain: "test", code: 1, userInfo: nil)

        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.1)
        {
            delegate.peripheral(mockPeripheral, didUpdateNotificationStateFor: mockCharacteristic, error: inputError)
        }
        
        uuWaitForExpectations(0.2)
        
        XCTAssertNil(delegate.setNotifyValueForCharacteristicBlock)
    }
    
    // MARK: didUpdateValueForCharacteristicRead
    
    func test_didUpdateValueForCharacteristicRead_success() throws
    {
        let exp = uuExpectationForMethod(tag: "read")
        let updateExp = uuExpectationForMethod(tag: "update")
        updateExp.isInverted = true
        
        let delegate = UUCBPeripheralBlockDelegate()
        let mockCharacteristic = CBMutableCharacteristic(type: CBUUID(), properties: [.read, .write], value: "ABCD".uuToHexData()!, permissions: [.readable, .writeable])
        let mockPeripheral = try XCTUnwrap(uuMakeCBPeripheral())
        
        var callbackResult: Data? = nil
        var callbackError: Error? = nil
        
        delegate.registerReadHandler(for: mockCharacteristic)
        { data, err in
            callbackResult = data
            callbackError = err
            exp.fulfill()
        }
        
        XCTAssertNotNil(delegate.readValueForCharacteristicBlocks[mockCharacteristic.uuid.uuidString])
        XCTAssertNil(delegate.updateValueForCharacteristicBlocks[mockCharacteristic.uuid.uuidString])
        
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.1)
        {
            delegate.peripheral(mockPeripheral, didUpdateValueFor: mockCharacteristic, error: nil)
        }
        
        uuWaitForExpectations(0.2)
        
        XCTAssertNotNil(callbackResult)
        XCTAssertNil(callbackError)
        
        let result = try XCTUnwrap(callbackResult)
        XCTAssertEqual("ABCD".uuToHexData()!, result)
        
        XCTAssertNil(delegate.readValueForCharacteristicBlocks[mockCharacteristic.uuid.uuidString])
        XCTAssertNil(delegate.updateValueForCharacteristicBlocks[mockCharacteristic.uuid.uuidString])
    }
    
    func test_didUpdateValueForCharacteristicRead_error() throws
    {
        let exp = uuExpectationForMethod(tag: "read")
        let updateExp = uuExpectationForMethod(tag: "update")
        updateExp.isInverted = true
        
        let delegate = UUCBPeripheralBlockDelegate()
        let mockCharacteristic = CBMutableCharacteristic(type: CBUUID(), properties: [.read, .write], value: nil, permissions: [.readable, .writeable])
        let mockPeripheral = try XCTUnwrap(uuMakeCBPeripheral())
        
        var callbackResult: Data? = nil
        var callbackError: Error? = nil
        
        delegate.registerReadHandler(for: mockCharacteristic)
        { data, err in
            callbackResult = data
            callbackError = err
            exp.fulfill()
        }
        
        XCTAssertNotNil(delegate.readValueForCharacteristicBlocks[mockCharacteristic.uuid.uuidString])
        
        let inputError = NSError(domain: "test", code: 1, userInfo: nil)

        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.1)
        {
            delegate.peripheral(mockPeripheral, didUpdateValueFor: mockCharacteristic, error: inputError)
        }
        
        uuWaitForExpectations(0.2)
        
        XCTAssertNil(callbackResult)
        XCTAssertNotNil(callbackError)
        
        let result = try XCTUnwrap(callbackError) as NSError
        XCTAssertEqual(inputError.domain, result.domain)
        XCTAssertEqual(inputError.code, result.code)
        
        XCTAssertNil(delegate.readValueForCharacteristicBlocks[mockCharacteristic.uuid.uuidString])
    }
    
    func test_didUpdateValueForCharacteristicRead_notRegistered() throws
    {
        let exp = uuExpectationForMethod(tag: "read")
        exp.isInverted = true
        
        let updateExp = uuExpectationForMethod(tag: "update")
        updateExp.isInverted = true
        
        let delegate = UUCBPeripheralBlockDelegate()
        let mockCharacteristic = CBMutableCharacteristic(type: CBUUID(), properties: [.read, .write], value: nil, permissions: [.readable, .writeable])
        let mockPeripheral = try XCTUnwrap(uuMakeCBPeripheral())
        
        delegate.registerReadHandler(for: mockCharacteristic, handler: nil)
        
        XCTAssertNil(delegate.readValueForCharacteristicBlocks[mockCharacteristic.uuid.uuidString])
        
        let inputError = NSError(domain: "test", code: 1, userInfo: nil)

        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.1)
        {
            delegate.peripheral(mockPeripheral, didUpdateValueFor: mockCharacteristic, error: inputError)
        }
        
        uuWaitForExpectations(0.2)
        
        XCTAssertNil(delegate.readValueForCharacteristicBlocks[mockCharacteristic.uuid.uuidString])
    }
    

    
    
}
