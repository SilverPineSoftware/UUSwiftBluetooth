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
            NSLog("\n\n\n\n\(String(data: data, encoding: .utf8) ?? "null")\n\n\n\n")
            
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
                    UUDebugLog("Error saving sniff results: %@", String(describing: err))
                }
            }
        }
    }
}
