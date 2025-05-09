//
//  SortingTests.swift
//  UUSwiftBluetoothTests
//
//  Created by Ryan DeVore on 5/8/25.
//

import XCTest
@testable import UUSwiftBluetooth

final class SortingTests: XCTestCase
{
    private let input: [UUPeripheral] =
    [
        MockPeripheral(
            identifier: UUID(uuidString: "BB06F68C-AC25-476C-AC6B-16DB517E2198")!,
            rssi: -50,
            name: "A",
            friendlyName: "A",
            firstDiscoveryTime: Date(timeIntervalSinceNow: -100)
        ),
            
         MockPeripheral(
            identifier: UUID(uuidString: "CE54002F-3C72-4189-8663-FAD905C6D6DF")!,
            rssi: -60,
            name: "C",
            friendlyName: "C",
            firstDiscoveryTime: Date(timeIntervalSinceNow: -200)),
            
        MockPeripheral(
            identifier: UUID(uuidString: "DE776C44-A550-4E83-A9EA-8D5892AF3814")!,
            rssi: -70,
            name: "B",
            friendlyName: "B",
            firstDiscoveryTime: Date(timeIntervalSinceNow: -500)),
        
        MockPeripheral(
            identifier: UUID(uuidString: "0BC865D0-8C7F-447D-AF32-D79D1EDBFEAF")!,
            rssi: -80,
            name: "D",
            friendlyName: "D",
            firstDiscoveryTime: Date(timeIntervalSinceNow: -10)),
    ]
    
    func test_rssi_sort_descending() throws
    {
        let comparator: UUPeripheralComparator = UUPeripheralRssiComparator(ascending: false)
        let sorted = input.sorted(by: comparator.compare)
        let sortedNames = sorted.map(\.name)
        XCTAssertEqual(sortedNames, ["A", "C", "B", "D"])
    }
    
    func test_rssi_sort_ascending() throws
    {
        let comparator: UUPeripheralComparator = UUPeripheralRssiComparator(ascending: true)
        let sorted = input.sorted(by: comparator.compare)
        let sortedNames = sorted.map(\.name)
        XCTAssertEqual(sortedNames, ["D", "B", "C", "A"])
    }
    
    func test_friendly_name_sort_descending() throws
    {
        let comparator: UUPeripheralComparator = UUPeripheralFriendlyNameComparator(ascending: false)
        let sorted = input.sorted(by: comparator.compare)
        let sortedNames = sorted.map(\.name)
        XCTAssertEqual(sortedNames, ["D", "C", "B", "A"])
    }
    
    func test_friendly_name_sort_ascending() throws
    {
        let comparator: UUPeripheralComparator = UUPeripheralFriendlyNameComparator(ascending: true)
        let sorted = input.sorted(by: comparator.compare)
        let sortedNames = sorted.map(\.name)
        XCTAssertEqual(sortedNames, ["A", "B", "C", "D"])
        
    }
    
    func test_discovery_time_sort_descending() throws
    {
        let comparator: UUPeripheralComparator = UUPeripheralFirstDiscoveryTimeComparator(ascending: false)
        let sorted = input.sorted(by: comparator.compare)
        let sortedNames = sorted.map(\.name)
        XCTAssertEqual(sortedNames, ["D", "A", "C", "B"])
    }
    
    func test_discovery_time_sort_ascending() throws
    {
        let comparator: UUPeripheralComparator = UUPeripheralFirstDiscoveryTimeComparator(ascending: true)
        let sorted = input.sorted(by: comparator.compare)
        let sortedNames = sorted.map(\.name)
        XCTAssertEqual(sortedNames, ["B", "C", "A", "D"])
    }
}
