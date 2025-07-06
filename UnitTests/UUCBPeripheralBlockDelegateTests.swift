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
    func testMakeMockCBPeripheral() throws
    {
        let mockPeripheral = try XCTUnwrap(uuMakeCBPeripheral())
        XCTAssertNotNil(mockPeripheral)
    }
    
    func testDiscoverServicesHandler_success() throws
    {
        let exp = uuExpectationForMethod()
        
        let delegate = UUCBPeripheralBlockDelegate()
        
        var callbackResult: [CBService]? = nil
        var callbackError: Error? = nil
        
        delegate.registerDiscoverServicesHandler
        { services, err in
            
            callbackResult = services
            callbackError = err
            exp.fulfill()
        }
        
        let mockService = CBMutableService(type: CBUUID(), primary: true)
        
        let mockPeripheral = try XCTUnwrap(uuMakeCBPeripheral(services: [mockService]))

        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.1)
        {
            delegate.peripheral(mockPeripheral, didDiscoverServices: nil)
        }
        
        uuWaitForExpectations()
        
        XCTAssertNil(callbackError)
        XCTAssertNotNil(callbackResult)
        
        let result = try XCTUnwrap(callbackResult)
        XCTAssertEqual(1, result.count)
    }
    
    func testDiscoverServicesHandler_error() throws
    {
        let exp = uuExpectationForMethod()
        
        let delegate = UUCBPeripheralBlockDelegate()
        
        var callbackResult: [CBService]? = nil
        var callbackError: Error? = nil
        
        delegate.registerDiscoverServicesHandler
        { services, err in
            
            callbackResult = services
            callbackError = err
            exp.fulfill()
        }
        
        let mockPeripheral = try XCTUnwrap(uuMakeCBPeripheral())
        
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
    }
    
    
    

    
    
    
    
    /*
    func testClearBlocksRemovesAllHandlers()
    {
        // Register a couple of handlers
        var didCallNameHandler = false
        delegate.registerNameUpdateHandler { _ in didCallNameHandler = true }

        var didCallDiscoverServices = false
        delegate.registerDiscoverServicesHandler { _, _ in didCallDiscoverServices = true }

        // Clear everything
        delegate.clearBlocks()

        // Invoke both callbacks
        delegate.peripheralDidUpdateName(fakePeripheral)
        delegate.peripheral(fakePeripheral, didDiscoverServices: nil)

        XCTAssertFalse(didCallNameHandler)
        XCTAssertFalse(didCallDiscoverServices)
    }

    func testNameUpdateHandler()
    {
        let exp = expectation(description: "name update")
        delegate.registerNameUpdateHandler { p in
            XCTAssert(p === self.fakePeripheral)
            exp.fulfill()
        }
        delegate.peripheralDidUpdateName(fakePeripheral)
        wait(for: [exp], timeout: 0.1)
    }

    func testDidModifyServicesHandler()
    {
        let exp = expectation(description: "modify services")
        let dummyServices = [CBMutableService(type: CBUUID(string: "A"))]
        delegate.didModifyServicesBlock = nil
        delegate.registerDiscoverServicesHandler(nil) // just to ensure no leakage

        // use the public didModifyServicesBlock via clearBlocks test above;
        // actually we need register a custom block... it's private, so test via discoverServicesBlock
        // Instead use registerDiscoverIncludedServicesHandler to test didDiscoverIncludedServicesFor:
        delegate.registerDiscoverIncludedServicesHandler { p, s, e in
            XCTAssert(p === self.fakePeripheral)
            XCTAssert(s.uuid == dummyServices[0].uuid)
            XCTAssertNil(e)
            exp.fulfill()
        }
        delegate.peripheral(fakePeripheral, didDiscoverIncludedServicesFor: dummyServices[0], error: nil)
        wait(for: [exp], timeout: 0.1)
    }

    func testReadRSSIHandler() {
        let exp = expectation(description: "read RSSI")
        delegate.registerReadRssiaHandler { p, rssi, err in
            XCTAssert(p === self.fakePeripheral)
            XCTAssertEqual(rssi, 42)
            XCTAssertNil(err)
            exp.fulfill()
        }
        delegate.peripheral(fakePeripheral, didReadRSSI: 42 as NSNumber, error: nil)
        wait(for: [exp], timeout: 0.1)
    }

    func testDiscoverServicesHandler() {
        let exp = expectation(description: "discover services")
        delegate.registerDiscoverServicesHandler { p, err in
            XCTAssert(p === self.fakePeripheral)
            XCTAssertNil(err)
            exp.fulfill()
        }
        delegate.peripheral(fakePeripheral, didDiscoverServices: nil)
        wait(for: [exp], timeout: 0.1)
    }

    func testDiscoverCharacteristicsHandler() {
        let exp = expectation(description: "discover characteristics")
        let svc = CBMutableService(type: CBUUID(string: "B"))
        delegate.registerDiscoverCharacteristicsHandler { p, service, err in
            XCTAssert(p === self.fakePeripheral)
            XCTAssert(service.uuid == svc.uuid)
            XCTAssertNil(err)
            exp.fulfill()
        }
        delegate.peripheral(fakePeripheral, didDiscoverCharacteristicsFor: svc, error: nil)
        wait(for: [exp], timeout: 0.1)
    }

    func testUpdateAndReadValueForCharacteristic() {
        let svc = CBMutableService(type: CBUUID(string: "C"))
        let char = CBMutableCharacteristic(
            type: CBUUID(string: "C1"),
            properties: [.read, .notify],
            value: nil,
            permissions: [.readable]
        )
        svc.characteristics = [char]

        let updateExp = expectation(description: "update value")
        delegate.registerUpdateHandler({ p, characteristic, err in
            XCTAssert(p === self.fakePeripheral)
            XCTAssert(characteristic.uuid == char.uuid)
            XCTAssertNil(err)
            updateExp.fulfill()
        }, char)

        let readExp = expectation(description: "read value")
        delegate.registerReadHandler({ p, characteristic, err in
            XCTAssert(p === self.fakePeripheral)
            XCTAssert(characteristic.uuid == char.uuid)
            XCTAssertNil(err)
            readExp.fulfill()
        }, char)

        delegate.peripheral(fakePeripheral, didUpdateValueFor: char, error: nil)
        wait(for: [updateExp, readExp], timeout: 0.1)
    }

    func testWriteValueForCharacteristic() {
        let char = CBMutableCharacteristic(
            type: CBUUID(string: "D1"),
            properties: [], value: nil, permissions: []
        )
        let exp = expectation(description: "write characteristic")
        delegate.registerWriteHandler({ p, characteristic, err in
            XCTAssert(p === self.fakePeripheral)
            XCTAssert(characteristic.uuid == char.uuid)
            XCTAssertNil(err)
            exp.fulfill()
        }, char)
        delegate.peripheral(fakePeripheral, didWriteValueFor: char, error: nil)
        wait(for: [exp], timeout: 0.1)
    }

    func testNotifyStateChangeForCharacteristic() {
        let char = CBMutableCharacteristic(
            type: CBUUID(string: "E1"),
            properties: [], value: nil, permissions: []
        )
        let exp = expectation(description: "notify state")
        delegate.registerSetNotifyValueHandler { p, characteristic, err in
            XCTAssert(p === self.fakePeripheral)
            XCTAssert(characteristic.uuid == char.uuid)
            XCTAssertNil(err)
            exp.fulfill()
        }
        delegate.peripheral(fakePeripheral, didUpdateNotificationStateFor: char, error: nil)
        wait(for: [exp], timeout: 0.1)
    }

    func testDiscoverDescriptorsForCharacteristic() {
        let char = CBMutableCharacteristic(
            type: CBUUID(string: "F1"),
            properties: [], value: nil, permissions: []
        )
        let exp = expectation(description: "discover descriptors")
        delegate.registerDiscoverDescriptorsHandler { p, characteristic, err in
            XCTAssert(p === self.fakePeripheral)
            XCTAssert(characteristic.uuid == char.uuid)
            XCTAssertNil(err)
            exp.fulfill()
        }
        delegate.peripheral(fakePeripheral, didDiscoverDescriptorsFor: char, error: nil)
        wait(for: [exp], timeout: 0.1)
    }

    func testUpdateAndReadValueForDescriptor() {
        let descriptor = CBMutableDescriptor(
            type: CBUUID(string: "G1"),
            value: "X" as NSString
        )
        let updateExp = expectation(description: "update descriptor")
        delegate.registerUpdateHandler({ p, desc, err in
            XCTAssert(p === self.fakePeripheral)
            XCTAssert(desc.uuid == descriptor.uuid)
            XCTAssertNil(err)
            updateExp.fulfill()
        }, descriptor)

        let readExp = expectation(description: "read descriptor")
        delegate.registerReadHandler({ p, desc, err in
            XCTAssert(p === self.fakePeripheral)
            XCTAssert(desc.uuid == descriptor.uuid)
            XCTAssertNil(err)
            readExp.fulfill()
        }, descriptor)

        delegate.peripheral(fakePeripheral, didUpdateValueFor: descriptor, error: nil)
        wait(for: [updateExp, readExp], timeout: 0.1)
    }

    func testWriteValueForDescriptor() {
        let descriptor = CBMutableDescriptor(
            type: CBUUID(string: "H1"),
            value: "Y" as NSString
        )
        let exp = expectation(description: "write descriptor")
        delegate.registerWriteHandler({ p, desc, err in
            XCTAssert(p === self.fakePeripheral)
            XCTAssert(desc.uuid == descriptor.uuid)
            XCTAssertNil(err)
            exp.fulfill()
        }, descriptor)
        delegate.peripheral(fakePeripheral, didWriteValueFor: descriptor, error: nil)
        wait(for: [exp], timeout: 0.1)
    }

    func testDidOpenL2CAPChannel() {
        let exp = expectation(description: "open L2CAP")
        let channel: CBL2CAPChannel? = nil
        delegate.registerDidOpenL2CAPChannelHandler { p, ch, err in
            XCTAssert(p === self.fakePeripheral)
            XCTAssert(ch === channel)
            XCTAssertNil(err)
            exp.fulfill()
        }
        delegate.peripheral(fakePeripheral, didOpen: channel, error: nil)
        wait(for: [exp], timeout: 0.1)
    }

    func testLogBlocksDoesNotCrash() {
        // just exercise logBlocks
        delegate.logBlocks()
    }*/
}


//private class MockCBPeripheral: CBPeripheral {
//  override var identifier: UUID { UUID() }
//  override var name: String?   { "Mock" }
//}



//class MockCBPeripheralImplementation: CBPeripheral {
//    let identifier: UUID
//    let name: String?
//    let state: CBPeripheralState
//
//    init(identifier: UUID, name: String?, state: CBPeripheralState) {
//        self.identifier = identifier
//        self.name = name
//        self.state = state
//    }
//    // ... Implement other methods and properties
//}
