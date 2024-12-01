//
//  ReadDeviceInfoOperation.swift
//  UUSwiftBluetoothTester
//
//  Created by Ryan DeVore on 12/6/21.
//

import UIKit
import CoreBluetooth
import UUSwiftBluetooth

/*
class ReadDeviceInfoResult
{
    var manufacturerName: String = ""
    var systemId: String = ""
}*/

class ReadDeviceInfoOperation: UUPeripheralOperation<Any>
{
    var manufacturerName: String = ""
    var systemId: String = ""
    
    override var servicesToDiscover: [CBUUID]?
    {
        return [ UUBluetoothConstants.Services.deviceInformation ]
    }
    
    override func characteristicsToDiscover(for service: CBUUID) -> [CBUUID]?
    {
        guard service == UUBluetoothConstants.Services.deviceInformation else
        {
            return nil
        }
        
        return [ UUBluetoothConstants.Characteristics.manufacturerNameString, UUBluetoothConstants.Characteristics.systemID ]
    }
    
    override func execute(_ completion: @escaping (Any, Error?) -> ())
    {
        readSystemId
        { systemIdResult in
            self.systemId = systemIdResult
            
            self.readManufacturerName
            { manufacturerNameResult in
                self.manufacturerName = manufacturerNameResult
                
                completion(0, nil)
            }
        }
    }

    private func readSystemId(_ completion: @escaping (String)->())
    {
        readUtf8(from: UUBluetoothConstants.Characteristics.systemID)
        { result in
            completion(result ?? "")
        }
    }
    
    private func readManufacturerName(_ completion: @escaping (String)->())
    {
        readUtf8(from: UUBluetoothConstants.Characteristics.manufacturerNameString)
        { result in
            completion(result ?? "")
        }
    }
}
