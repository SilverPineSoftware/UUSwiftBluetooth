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


final class UUSwiftBluetoothTests: XCTestCase 
{
    private let sniffer = UUBluetoothSniffer()

    func test_bleSniffer() throws
    {
        let exp = uuExpectationForMethod()
        
        let services: [CBUUID] = []
        
        sniffer.start(services: services)
        
        let timeout: TimeInterval = 20.0
        
        let t = UUTimer(identifier: "BleSnifferTimerId", interval: timeout, userInfo: nil, shouldRepeat: false, pool: UUTimerPool.shared)
        { t in
            
            exp.fulfill()
        }

        t.start()
        
        
        uuWaitForExpectations(timeout + 30.0)
        
        let result = sniffer.stop()
        
        result.print()
        
        let fileContents = result.toCsvBytes()
        
        if let data = fileContents
        {
            print("\n\n\n\n\(String(data: data, encoding: .utf8) ?? "null")\n\n\n\n")
            
            //NotificationCenter.default.post(name: Notification.Name(rawValue: "SaveFile"), object: data)

            let fm = FileManager.default
            if let folder = fm.urls(for: .documentDirectory, in: .userDomainMask).last
            {
                let timestamp = Date().uuFormat("yyyy_MM_dd_HH_mm_ss")
                let file = folder.appendingPathComponent("sniff_results_ios\(timestamp).csv")
                
                do
                {
                    try data.write(to: file)
                }
                catch (let err)
                {
                    print("Error saving sniff results: %@", String(describing: err))
                }
            }
        }
    }
    
    func testIntSorting()
    {
        let input: [Int?] = [5, nil, 8, 3, 19, 4]
        
        //let sorted = input.sorted(using: OptionalIntComparator())
        let sortedBy = input.sorted(by: { lhs, rhs in
            return (lhs ?? Int.max) < (rhs ?? Int.max)
        })
        
        print("sorted by: \(sortedBy)")
        
        //let sortedUsing = input.sorted(using: OptionalIntComparator())
        
        //print("sorted using: \(sortedUsing)")
    }
    
    func testBadCBUUID()
    {
        let input = "Bogus UUID String"
        let cbuuid = CBUUID.uuCreate(from: input)
        XCTAssertNil(cbuuid)
        //let cbuuid = CBUUID(string: input)
        
    }
    
    func testJsonExport()
    {
        let attribute = UUAttributeRepresentation()
        attribute.uuid = "2902"
        attribute.name = "Client Characteristic Configuration"

        let encoder = JSONEncoder()
        if let jsonData = try? encoder.encode(attribute),
        let jsonString = String(data: jsonData, encoding: .utf8)
        {
              NSLog(jsonString)
        }
        
        encoder.outputFormatting = [.prettyPrinted]
        if let jsonData = try? encoder.encode(attribute),
        let jsonString = String(data: jsonData, encoding: .utf8)
        {
              NSLog(jsonString)
        }
        
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let jsonData = try? encoder.encode(attribute),
        let jsonString = String(data: jsonData, encoding: .utf8)
        {
              NSLog(jsonString)
        }
        
        let chr = UUCharacteristicRepresentation()
        chr.uuid = "2902"
        chr.name = "Client Characteristic Configuration"
        chr.descriptors = [
            UUDescriptorRepresentation(uuid: "2903", name: "Unit Test")
        ]

        encoder.outputFormatting = []
        if let jsonData = try? encoder.encode(chr),
        let jsonString = String(data: jsonData, encoding: .utf8)
        {
              NSLog(jsonString)
        }
        
        encoder.outputFormatting = [.prettyPrinted]
        if let jsonData = try? encoder.encode(chr),
        let jsonString = String(data: jsonData, encoding: .utf8)
        {
              NSLog(jsonString)
        }
        
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let jsonData = try? encoder.encode(chr),
        let jsonString = String(data: jsonData, encoding: .utf8)
        {
              NSLog(jsonString)
        }
        
        // Example output:
        // {
        //    "uuid": "2902",
        //    "name": "Client Characteristic Configuration"
        // }
    }
}
