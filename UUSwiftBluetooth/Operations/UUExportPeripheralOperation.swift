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

public class UUExportPeripheralOperation: UUPeripheralOperation<UUPeripheralModel>
{
    public override func execute(_ completion: @escaping (UUPeripheralModel?, (any Error)?) -> ())
    {
        let services = self.discoveredServices.compactMap
        { service in
            var obj = UUServiceModel()
            obj.populate(from: service)
            return obj
        }
        
        var peripheralJson = UUPeripheralModel()
        peripheralJson.services = services
        
        let json = peripheralJson.uuToJsonString(true)
        UULog.debug(tag: LOG_TAG, message: "Peripheral JSON: \(json)")
        
        completion(peripheralJson, nil)
    }
}
