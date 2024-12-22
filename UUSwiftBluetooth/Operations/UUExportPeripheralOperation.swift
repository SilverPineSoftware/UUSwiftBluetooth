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

public class UUExportPeripheralOperation: UUPeripheralOperation<UUPeripheralExport>
{
    public override func execute(_ completion: @escaping (UUPeripheralExport?, (any Error)?) -> ())
    {
        let services = self.discoveredServices.compactMap
        { service in
            var obj = UUServiceExport()
            obj.populate(from: service)
            return obj
        }
        
        var peripheralJson = UUPeripheralExport()
        peripheralJson.services = services
        
        let json = peripheralJson.uuToJsonString(true)
        UULog.debug(tag: LOG_TAG, message: "Peripheral JSON: \(json)")
        
        completion(peripheralJson, nil)
    }
}
