//
//  UUPeripheralSessionConfiguration.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 4/24/25.
//

import Foundation
import CoreBluetooth

open class UUPeripheralSessionConfiguration
{
    public var servicesToDiscover: [CBUUID]? = nil
    public var characteristicsToDiscover: [CBUUID:[CBUUID]?]? = nil
    
    public var connectTimeout: TimeInterval = UUBluetooth.Defaults.connectTimeout
    public var disconnectTimeout: TimeInterval = UUBluetooth.Defaults.disconnectTimeout
    public var serviceDiscoveryTimeout: TimeInterval = UUBluetooth.Defaults.operationTimeout
    public var characteristicDiscoveryTimeout: TimeInterval = UUBluetooth.Defaults.operationTimeout
    public var descriptorDiscoveryTimeout: TimeInterval = UUBluetooth.Defaults.operationTimeout
    public var readTimeout: TimeInterval = UUBluetooth.Defaults.operationTimeout
    public var writeTimeout: TimeInterval = UUBluetooth.Defaults.operationTimeout
    
    public init(
        servicesToDiscover: [CBUUID]? = nil,
        characteristicsToDiscover: [CBUUID : [CBUUID]?]? = nil,
        connectTimeout: TimeInterval = UUBluetooth.Defaults.connectTimeout,
        disconnectTimeout: TimeInterval = UUBluetooth.Defaults.disconnectTimeout,
        serviceDiscoveryTimeout: TimeInterval = UUBluetooth.Defaults.operationTimeout,
        characteristicDiscoveryTimeout: TimeInterval = UUBluetooth.Defaults.operationTimeout,
        descriptorDiscoveryTimeout: TimeInterval = UUBluetooth.Defaults.operationTimeout,
        readTimeout: TimeInterval = UUBluetooth.Defaults.operationTimeout,
        writeTimeout: TimeInterval = UUBluetooth.Defaults.operationTimeout)
    {
        self.servicesToDiscover = servicesToDiscover
        self.characteristicsToDiscover = characteristicsToDiscover
        self.connectTimeout = connectTimeout
        self.disconnectTimeout = disconnectTimeout
        self.serviceDiscoveryTimeout = serviceDiscoveryTimeout
        self.characteristicDiscoveryTimeout = characteristicDiscoveryTimeout
        self.descriptorDiscoveryTimeout = descriptorDiscoveryTimeout
        self.readTimeout = readTimeout
        self.writeTimeout = writeTimeout
    }
}
