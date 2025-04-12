//
//  UUExportPeripheralOperation.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 11/25/24.
//

import UIKit
import CoreBluetooth
import UUSwiftCore

fileprivate let LOG_TAG = "UUExportPeripheralOperation"

public class UUExportPeripheralOperation: UUPeripheralOperation<UUPeripheralRepresentation>
{
    public override func execute(_ completion: @escaping (UUPeripheralRepresentation?, (any Error)?) -> ())
    {
        let services = session.discoveredServices.compactMap
        { service in
            let obj = UUServiceRepresentation(from: service)
            return obj
        }
        
        let peripheralJson = UUPeripheralRepresentation()
        peripheralJson.services = services
        
        let encoder = JSONEncoder()
        let jsonData = try? encoder.encode(peripheralJson)
        let jsonString = jsonData?.uuToJsonString(true)
        UULog.debug(tag: LOG_TAG, message: "Peripheral JSON: \(String(describing: jsonString))")
        
        completion(peripheralJson, nil)
    }
}
