//
//  Mocks.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 7/5/25.
//

import Foundation
import CoreBluetooth

func uuMakeCBPeripheral(
    uuid: UUID? = nil,
    name: String? = nil,
    services: [CBMutableService]? = nil) -> CBPeripheral?
{
    let peripheralClass = NSClassFromString("CBPeripheral") as? NSObject.Type
    guard let peripheral = peripheralClass?.init() as? CBPeripheral else
    {
        return nil
    }

    peripheral.addObserver(peripheral, forKeyPath: "delegate", options: [], context: nil)
    
    // Use KVC to set some properties
    
    if let uuid = uuid
    {
        peripheral.setValue(uuid, forKey: "identifier")
    }
    
    if let name = name
    {
        peripheral.setValue(name, forKey: "name")
    }
    
    if let services = services
    {
        peripheral.setValue(services, forKey: "services")
    }
    
    return peripheral
}
