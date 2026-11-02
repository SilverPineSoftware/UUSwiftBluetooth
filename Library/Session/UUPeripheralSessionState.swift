//
//  UUPeripheralSessionState.swift
//  Library
//
//  Created by Ryan DeVore on 10/31/26.
//  Copyright © 2026 Silverpine Software, LLC. All rights reserved.
//

import Foundation

///
/// Describes the different states that a UUPeripheralSession can be in
///
public enum UUPeripheralSessionState: Int, CaseIterable, Codable
{
    /// The session has not started - ie. the peripheral is disconnected
    case notStarted = 0
    
    /// The session is attempting to make a BLE connection to the peripheral
    case connecting = 1
    
    /// The session is performing service discovery on the peripheral
    case serviceDiscovery = 2
    
    /// The session is performing characteristic discovery on the peripheral
    case characteristicDiscovery = 3
    
    /// The session is performing descriptor discovery on the peripheral
    case descriptorDiscovery = 4
    
    /// The session is waiting for any post connection work to be done by derived classes
    case finishSessionStart = 5
    
    /// The session is started and ready to be used.
    case started = 6
    
    /// The session is disconnecting
    case disconnecting = 7
    
    /// The session has ended
    case ended = 8
}
