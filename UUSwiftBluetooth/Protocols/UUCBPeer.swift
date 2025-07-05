//
//  UUCBPeer.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 7/4/25.
//

import Foundation
import CoreBluetooth

/// Protocol wrapping public interface of CBPeer
public protocol UUCBPeer
{
    /**
     *  @property identifier
     *
     *  @discussion The unique, persistent identifier associated with the peer.
     */
    //@available(iOS 7.0, *)
    var identifier: UUID { get }
}
