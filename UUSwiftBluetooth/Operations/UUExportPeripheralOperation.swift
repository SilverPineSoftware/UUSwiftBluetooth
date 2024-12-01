//
//  UUExportPeripheralOperation.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 11/25/24.
//

import UIKit
import CoreBluetooth

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
        print("Peripheral JSON: \(json)")
        
        completion(peripheralJson, nil)
    }
}
