//
//  UUStream.swift
//  UUSwiftBluetooth
//
//  Created by Rhonda DeVore on 9/20/23.
//

import Foundation


public class UUStream
{
    private var underlyingStream:Stream
    
    init(_ stream: Stream)
    {
        self.underlyingStream = stream
    }
    /**
     Writes data to an output stream and returns number of bytes written
     */
    public func uuWriteData(_ data:Data?) -> Int?
    {
        guard let outputStream = self.underlyingStream as? OutputStream else
        {
            NSLog("Trying to write data to a stream that isn't an OutputStream, bailing!")
            return nil
        }
                
        guard let d = data, !d.isEmpty else
        {
            NSLog("Data is nil or empty, cannot write!")
            return nil
        }
        
        guard outputStream.hasSpaceAvailable else
        {
            NSLog("No space available! (try again later?)")
            return nil
        }

        
        return d.withUnsafeBytes({ (unsafeRawBufferPointer:UnsafeRawBufferPointer) -> Int in
            
            let pointer = unsafeRawBufferPointer.bindMemory(to: UInt8.self)
            
            if let baseAddress = pointer.baseAddress
            {
                return outputStream.write(baseAddress, maxLength: d.count)
            }
            else
            {
                return 0
            }
        })
    }
    
    /**
     Reads available data from input stream and retuns data and flag
     indicating if there is more data to read
     */
    public func uuReadData(_ bufferLength:Int) -> (dataRead:Data?, hasBytesAvailable:Bool)
    {
        guard let inputStream = self.underlyingStream as? InputStream else
        {
            NSLog("Trying to read data from a stream that isn't an InputStream, bailing!")
            return (nil, false)
        }
        
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferLength)
        
        defer
        {
            buffer.deallocate()
        }
        
        let rawBytesRead = inputStream.read(buffer, maxLength: bufferLength)
        
        var data = Data()
        
        data.append(buffer, count: rawBytesRead)
        
        return (data, inputStream.hasBytesAvailable)
    }
}
