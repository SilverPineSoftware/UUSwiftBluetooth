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

fileprivate func OperationConfig() -> UUPeripheralSessionConfiguration
{
    return UUPeripheralSessionConfiguration(
        servicesToDiscover: [ UUBluetooth.Constants.Services.deviceInformation ],
        characteristicsToDiscover:
        [
            UUBluetooth.Constants.Services.deviceInformation :
                [
                    UUBluetooth.Constants.Characteristics.manufacturerNameString,
                    UUBluetooth.Constants.Characteristics.systemID
                ]
        ])
}

class ReadDeviceInfoOperation: UUPeripheralOperation<Any>
{
    var manufacturerName: String = ""
    var systemId: String = ""
    
    
    public init(_ peripheral: UUPeripheral)
    {
        super.init(peripheral, centralManager: UUBluetooth.shared.centralManager, configuration: OperationConfig())
    }
    
    /*
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
    
    override init(_ peripheral: any UUPeripheral)
    {
        super.init(peripheral)
    }*/
    
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
        session.readUtf8(from: UUBluetooth.Constants.Characteristics.systemID)
        { session, result, error in
            completion(result ?? "")
        }
    }
    
    private func readManufacturerName(_ completion: @escaping (String)->())
    {
        session.readUtf8(from: UUBluetooth.Constants.Characteristics.manufacturerNameString)
        { session, result, error in
            completion(result ?? "")
        }
    }
}
