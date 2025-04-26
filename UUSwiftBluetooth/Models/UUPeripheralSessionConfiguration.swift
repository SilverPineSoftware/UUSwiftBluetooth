//
//  UUPeripheralSessionConfiguration.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 4/24/25.
//

import Foundation
import CoreBluetooth

public struct UUPeripheralSessionConfiguration
{
    public var servicesToDiscover: [CBUUID]? = nil
    public var characteristicsToDiscover: [CBUUID:[CBUUID]?]? = nil
    
    public var connectTimeout: TimeInterval = UUCoreBluetooth.Defaults.connectTimeout
    public var disconnectTimeout: TimeInterval = UUCoreBluetooth.Defaults.disconnectTimeout
    public var serviceDiscoveryTimeout: TimeInterval = UUCoreBluetooth.Defaults.operationTimeout
    public var characteristicDiscoveryTimeout: TimeInterval = UUCoreBluetooth.Defaults.operationTimeout
    public var descriptorDiscoveryTimeout: TimeInterval = UUCoreBluetooth.Defaults.operationTimeout
    public var readTimeout: TimeInterval = UUCoreBluetooth.Defaults.operationTimeout
    public var writeTimeout: TimeInterval = UUCoreBluetooth.Defaults.operationTimeout
    
    public init(
        servicesToDiscover: [CBUUID]? = nil,
        characteristicsToDiscover: [CBUUID : [CBUUID]?]? = nil,
        connectTimeout: TimeInterval = UUCoreBluetooth.Defaults.connectTimeout,
        disconnectTimeout: TimeInterval = UUCoreBluetooth.Defaults.disconnectTimeout,
        serviceDiscoveryTimeout: TimeInterval = UUCoreBluetooth.Defaults.operationTimeout,
        characteristicDiscoveryTimeout: TimeInterval = UUCoreBluetooth.Defaults.operationTimeout,
        descriptorDiscoveryTimeout: TimeInterval = UUCoreBluetooth.Defaults.operationTimeout,
        readTimeout: TimeInterval = UUCoreBluetooth.Defaults.operationTimeout,
        writeTimeout: TimeInterval = UUCoreBluetooth.Defaults.operationTimeout)
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
