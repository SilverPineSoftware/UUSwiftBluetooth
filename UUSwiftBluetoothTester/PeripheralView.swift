//
//  PeripheralView.swift
//  UUSwiftBluetoothTester
//
//  Created by Ryan DeVore on 9/9/21.
//

import SwiftUI
import CoreBluetooth
import UUSwiftBluetooth

class PeripheralViewModel: ObservableObject
{
    @Published var peripheral: UUPeripheral
    
    var serviceTapHandler: ((UUPeripheral, CBService)->()) = { _,_ in }
    
    init(_ peripheral: UUPeripheral)
    {
        self.peripheral = peripheral
    }
    
    func onConnect()
    {
        peripheral.connect(connected:
        { connectedPeripheral in
            
            DispatchQueue.main.async
            {
                self.peripheral = connectedPeripheral
            }
            
        }, disconnected:
        { disconnectedPeripheral, disconnectError in
            
            DispatchQueue.main.async
            {
                self.peripheral = disconnectedPeripheral
            }
        })
    }
    
    func onDisconnect()
    {
        peripheral.disconnect()
    }
    
    func onDiscoverServices()
    {
        peripheral.discoverServices
        { updatedPeripheral, errOpt in
            
            DispatchQueue.main.async
            {
                self.peripheral = updatedPeripheral
            }
        }
    }
    
    func onServiceTapped(_ service: CBService)
    {
        serviceTapHandler(peripheral, service)
    }
}

struct PeripheralView: View
{
    @ObservedObject var viewModel: PeripheralViewModel
    
    var body: some View
    {
        VStack(alignment: .leading)
        {
            ScrollView (.horizontal, showsIndicators: false)
            {
                 HStack
                 {
                    if (viewModel.peripheral.peripheralState != .connected)
                    {
                        Button("Connect", action: { viewModel.onConnect() })
                            .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))
                        
                    }
                    else
                    {
                        Button("Disconnect", action: { viewModel.onDisconnect() })
                            .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))
                        
                        Button("Discover Services", action: { viewModel.onDiscoverServices() })
                            .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))
                    }
                 }
            }
            
            ScrollView(.vertical, showsIndicators: false)
            {
                SectionHeaderView(label: "Info")
                LabelValueRowView(label: "ID:", value: viewModel.peripheral.identifier)
                LabelValueRowView(label: "Name:", value: viewModel.peripheral.friendlyName)
                LabelValueRowView(label: "State:", value: "\(UUCBPeripheralStateToString(viewModel.peripheral.peripheralState)) - (\(viewModel.peripheral.peripheralState.rawValue))")
                LabelValueRowView(label: "RSSI:", value: "\(viewModel.peripheral.rssi)")
                                 
                if let services = viewModel.peripheral.services, !services.isEmpty
                {
                    SectionHeaderView(label: "Services")
                    
                    ForEach(services, id: \.uuid)
                    { service in
                        
                        ServiceRowView(viewModel: ServiceRowViewModel(service)
                        { service in
                            viewModel.onServiceTapped(service)
                        })
                    }
                }
            }
        }
    }
}
