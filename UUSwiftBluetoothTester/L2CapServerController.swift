//
//  L2CapServerController.swift
//  UUSwiftBluetoothTester
//
//  Created by Rhonda DeVore on 9/15/23.
//

import UIKit
import CoreBluetooth
import UUSwiftBluetooth
import UUSwiftCore

class L2CapServerController:L2CapController
{
    let server:UUL2CapServer = UUL2CapServer(uuid: CBUUID(string: "E3AAE22C-8E52-47E3-9E03-629C62C542B9"))
    
    
    var command:UUL2CapCommand? = nil
    
    
    override func buildMenu() -> UIMenu?
    {
        let start = UIAction(title: "Start", handler: { _ in self.listen() })
        let stop = UIAction(title: "Stop", handler: { _ in self.stop() })

        return UIMenu(title: "Server Actions", image: nil, identifier: nil, options: [], children: [start, stop])
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.title = "L2Cap Server"
        
        self.initialOutputline = "Tap Start to Begin"
        self.clearOutput()
        
        self.server.didReceiveDataCallback =
        { receivedBytes in
            
            guard let data = receivedBytes else
            {
                self.addOutputLine("Hit data recieved callback but didn't get any data...weird!")
                return
            }
            
            
            if (self.command == nil)
            {
                self.addOutputLine("Starting recieve!")
                self.command = UUL2CapCommand.fromData(data)
            }
            
            self.command?.appendBytes(data)
            
            if let cmd = self.command, cmd.haveReceivedAllData()
            {
                self.processCommand(cmd)
            }
            
        }
    }
    
    func processCommand(_ command:UUL2CapCommand)
    {
        self.addOutputLine("Recieved \(command.data.count) bytes!")
        
        switch command.commandId
        {
        case .echo:
            self.addOutputLine("Received full echo command!")
            self.addOutputLine("Raw Bytes:\n\(command.data.uuToHexString())\n")
            self.sendCommand(.echo, command.data)

        case .sendImage:
            self.addOutputLine("Received full send image command!")
            if let img = UIImage(data: command.data)
            {
                self.addImageLine(image: img)
            }
            else
            {
                self.addOutputLine("Couldn't parse image!")
            }
            
            self.sendCommand(.ackImage, Data("ABCD".uuToHexData() ?? NSData()))
            
        default:
            self.addOutputLine("Received command with unhandled id!")
        }
        
        self.command = nil
    }
    
    
    func sendCommand(_ commandId:UUL2CapCommand.Id, _ data:Data)
    {
        let command = UUL2CapCommand(commandId: commandId, totalExpectedBytes: data.count)
        command.appendBytes(data)
        
        self.server.sendData(command.toData())
        { bytesSent in
            self.addOutputLine("Echo back sent!")
        }
    }
    
    
    func listen()
    {
        self.server.start(secure: false)
        { psm, error in
            
            self.addOutputLine("Did start UUL2CapServer with psm \(psm ?? 0). Error: \(self.errorDescription(error))")

        }
    }
    
    func stop()
    {
        self.server.stop()
        self.addOutputLine("Stopped UUL2CapServer")
    }
}
