//
//  UUCBL2CAPChannel.swift
//  UUSwiftBluetooth
//
//  Created by Ryan DeVore on 7/8/25.
//

import Foundation
import CoreBluetooth

public protocol UUCBL2CAPChannel
{

    /**
     *  @property peer
     *
     *  @discussion The peer connected to the channel
     */
    //open var peer: CBPeer! { get }

    /**
     *  @property inputStream
     *
     *  @discussion An NSStream used for reading data from the remote peer
     */
    var inputStream: InputStream! { get }

    /**
     *  @property outputStream
     *
     *  @discussion An NSStream used for writing data to the peer
     */
    var outputStream: OutputStream! { get }

    /**
     *  @property PSM
     *
     *  @discussion The PSM (Protocol/Service Multiplexer) of the channel
     */
    var psm: CBL2CAPPSM { get }
}

extension CBL2CAPChannel: UUCBL2CAPChannel
{
    
}
