//
//  UUStreamDelegate.swift
//  UUSwiftBluetooth
//
//  Created by Rhonda DeVore on 9/21/23.
//

import Foundation

public class UUStreamDelegate: NSObject, StreamDelegate
{
    public var bytesReceivedCallback:((Data?) -> Void)? = nil
    public var bytesSentCallback:((Int) -> Void)? = nil
    
    private func readAvailableData(_ stream:UUStream)
    {
        let readReturn = stream.uuReadData(1024)
        
        if let data = readReturn.dataRead
        {
            DispatchQueue.main.async
            {
                self.bytesReceivedCallback?(data)
            }
        }
        
        if (readReturn.hasBytesAvailable)
        {
            //Keep Reading if there is more data!
            self.readAvailableData(stream)
        }
    }
    
    
    public func stream(_ stream: Stream, handle eventCode: Stream.Event)
    {
        switch eventCode
        {
        case Stream.Event.openCompleted:
            NSLog("Stream Opened: \(stream.debugDescription)")

        case Stream.Event.endEncountered:
            NSLog("Stream End Encountered: \(stream.debugDescription)")

        case Stream.Event.hasBytesAvailable:
            NSLog("Stream HasBytesAvailable: \(stream.debugDescription)")
            self.readAvailableData(UUStream(stream))

        case Stream.Event.hasSpaceAvailable:
            NSLog("Stream Has Space Available: \(stream.debugDescription)")

        case Stream.Event.errorOccurred:
            NSLog("Stream Error Occurred: \(stream.debugDescription)")

        default:
            NSLog("Unhandled Stream event code: \(eventCode)")
        }
    }
}
