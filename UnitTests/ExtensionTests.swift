//
//  UUSwiftBluetoothTests.swift
//  UUSwiftBluetoothTests
//
//  Created by Ryan DeVore on 6/22/24.
//

import XCTest
import UUSwiftCore
@testable import UUSwiftBluetooth
import UUSwiftTestCore
import CoreBluetooth

final class CBUUID_Ext_Tests: XCTestCase
{
    func test_0001_nil()
    {
        let input: String? = nil
        let cbuuid = CBUUID.uuCreate(from: input)
        XCTAssertNil(cbuuid)
    }
    
    func test_0002_empty()
    {
        let input = ""
        let cbuuid = CBUUID.uuCreate(from: input)
        XCTAssertNil(cbuuid)
    }
    
    func test_0003_bogusInputs()
    {
        let input = "Bogus UUID String"
        let cbuuid = CBUUID.uuCreate(from: input)
        XCTAssertNil(cbuuid)
    }
    
    func test_0004_goodShortCode()
    {
        let input = "ABCD"
        let cbuuid = CBUUID.uuCreate(from: input)
        XCTAssertNotNil(cbuuid)
    }
    
    func test_0005_goodFullGuid()
    {
        let input = "190EBAE6-4A3D-49AA-B1DF-F151171B03EF"
        let cbuuid = CBUUID.uuCreate(from: input)
        XCTAssertNotNil(cbuuid)
    }
}
