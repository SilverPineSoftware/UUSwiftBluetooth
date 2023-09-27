//
//  L2CapServerController.swift
//  UUSwiftBluetoothTester
//
//  Created by Rhonda DeVore on 9/15/23.
//

import UIKit
import CoreBluetooth
import UUSwiftBluetooth

class L2CapServerController:L2CapController
{
    let server:UUL2CapServer = UUL2CapServer(uuid: CBUUID(string: "E3AAE22C-8E52-47E3-9E03-629C62C542B9"))
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.title = "L2Cap Server"
        
        self.configureLeftButton("Start", listen)
        self.configureRightButton("Stop", stop)
        
        self.initialOutputline = "Tap Start to Begin"
        self.clearOutput()
        
        self.server.didReceiveDataCallback =
        { data in 
         
            if let rec = data
            {
                self.addOutputLine("Recieved \(rec.count) bytes. Raw Bytes:\n\(rec.uuToHexString())\n")
            }
            else
            {
                self.addOutputLine("Received nil bytes!")
            }
            
        }
    }
    
    func listen()
    {
        self.server.start(secure: true)
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
