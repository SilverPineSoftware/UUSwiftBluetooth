//
//  UUCBManager.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 7/4/25.
//

import Foundation
import CoreBluetooth

public protocol UUCBManager
{

    /**
     *  @property state
     *
     *  @discussion The current state of the manager, initially set to <code>CBManagerStateUnknown</code>.
     *                Updates are provided by required delegate method {@link managerDidUpdateState:}.
     *
     */
    var state: CBManagerState { get }

    /**
     *  @property authorization
     *
     *  @discussion The current authorization of the manager, initially set to <code>CBManagerAuthorizationNotDetermined</code>.
     *                Updates are provided by required delegate method {@link managerDidUpdateState:}.
     *  @seealso    state
     */
    //@available(iOS, introduced: 13.0, deprecated: 13.1)
    var authorization: CBManagerAuthorization { get }

    /**
     *  @property authorization
     *
     *  @discussion The current authorization of the manager, initially set to <code>CBManagerAuthorizationNotDetermined</code>.
     *              You can check this in your implementation of required delegate method {@link managerDidUpdateState:}. You can also use it to check authorization status before allocating CBManager.
     *  @seealso    state
     */
    //@available(iOS 13.1, *)
    static var authorization: CBManagerAuthorization { get }
}
