//
//  UUL2CapChannel.swift
//  UUSwiftBluetooth
//
//  Created by Rhonda DeVore on 9/21/23.
//

import Foundation
import CoreBluetooth

public class UUL2CapChannel:NSObject
{
    public var delegate:UUStreamDelegate? = nil
    
    /**
     Initializes the channel.
     
     _NOTE:_ Does NOT open the streams!
     */
    public init(_ channel: CBL2CAPChannel, delegate:UUStreamDelegate?)
    {
        self.underlyingChannel = channel
        self.delegate = delegate
    }
    
    /**
     Opens both input and output streams
     */
    public func openStreams()
    {
        self.underlyingChannel.inputStream.delegate = self.delegate
        self.underlyingChannel.outputStream.delegate = self.delegate
        
        self.underlyingChannel.inputStream.schedule(in: RunLoop.main, forMode: .default)
        self.underlyingChannel.outputStream.schedule(in: RunLoop.main, forMode: .default)
        
        self.underlyingChannel.inputStream.open()
        self.underlyingChannel.outputStream.open()
    }
    
    /**
     Closes both input and output streams
     */
    public func closeStreams()
    {
        self.underlyingChannel.inputStream.close()
        self.underlyingChannel.outputStream.close()
        
        self.underlyingChannel.inputStream.remove(from: RunLoop.main, forMode: .default)
        self.underlyingChannel.outputStream.remove(from: RunLoop.main, forMode: .default)
        
        self.underlyingChannel.inputStream.delegate = nil
        self.underlyingChannel.outputStream.delegate = nil
    }
    
    /**
     Sends data
     */
    public func sendData(_ data:Data, _ completion: @escaping ((Error?) -> Void) )
    {
        if (self.bytesToSend == nil)
        {
            self.bytesToSend = Data()
        }
        
        self.bytesToSend?.append(data)
        
        self.internalSend()
    }
    


    private let underlyingChannel:CBL2CAPChannel
    private var bytesToSend:Data? = nil
    
    private func internalSend()
    {
        
        guard let outputStream = self.underlyingChannel.outputStream else
        {
            NSLog("Cannot perform internal send data, no output stream")
            return
        }
        
        let stream = UUStream(outputStream)
        
        let numberOfBytesSent = stream.uuWriteData(self.bytesToSend)
        
        if let bytesSent = numberOfBytesSent
        {
            self.delegate?.bytesSentCallback?(bytesSent)
        }
        
        if let bytesSent = numberOfBytesSent, (bytesSent < (self.bytesToSend?.count ?? 0))
        {
            self.bytesToSend = bytesToSend?.advanced(by: bytesSent)
        }
        else
        {
            self.bytesToSend?.removeAll()
        }
    }
}
