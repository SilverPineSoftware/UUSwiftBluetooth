//
//  ServiceView.swift
//  UUSwiftBluetoothTester
//
//  Created by Ryan DeVore on 9/9/21.
//

import SwiftUI
import CoreBluetooth
import UUSwiftBluetooth

class ServiceViewModel: ObservableObject
{
    @Published var peripheral: UUPeripheral
    @Published var service: CBService
    
    init(_ peripheral: UUPeripheral, _ service: CBService)
    {
        self.peripheral = peripheral
        self.service = service
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
    
    func onDiscoverCharacteristics()
    {
        peripheral.discoverCharacteristics(nil, for: service)
        { updatedPeripheral, errOpt in
            
            DispatchQueue.main.async
            {
                self.peripheral = updatedPeripheral
                
                if let updatedService = updatedPeripheral.services?.filter({ $0.uuid.uuidString == self.service.uuid.uuidString }).first
                {
                    self.service = updatedService
                }
            }
        }
    }
    
    func onDiscoverIncludedServices()
    {
        peripheral.discoverIncludedServices(nil, for: service)
        { updatedPeripheral, errOpt in
            
            DispatchQueue.main.async
            {
                self.peripheral = updatedPeripheral
                
                if let updatedService = updatedPeripheral.services?.filter({ $0.uuid.uuidString == self.service.uuid.uuidString }).first
                {
                    self.service = updatedService
                }
            }
        }
    }
}

struct ServiceView: View
{
    @ObservedObject var viewModel: ServiceViewModel
    
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
                        Button("Discover Chars", action: { viewModel.onDiscoverCharacteristics() })
                            .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))
                        
                        Button("Discover Included Services", action: { viewModel.onDiscoverIncludedServices() })
                            .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))
                    }
                 }
            }
            
            ScrollView(.vertical, showsIndicators: false)
            {
                SectionHeaderView(label: "Info")
                ServiceRowView(viewModel: ServiceRowViewModel(viewModel.service, showDivider: false))
                
                SectionHeaderView(label: "Characteristics")
                
                if let characteristics = viewModel.service.characteristics, !characteristics.isEmpty
                {
                    ForEach(characteristics.indices, id: \.self)
                    { i in
                        
                        CharacteristicRowView(viewModel: CharacteristicRowViewModel(viewModel.peripheral, characteristics[i], showDivider: (i < (characteristics.count-1))))
                    }
                }
                
                SectionHeaderView(label: "Included Services")
                
                if let services = viewModel.service.includedServices, !services.isEmpty
                {
                    ForEach(services.indices, id: \.self)
                    { i in
                        
                        ServiceRowView(viewModel: ServiceRowViewModel(services[i], showDivider: (i < (services.count-1))))
                    }
                }
            }
        }
    }
}
