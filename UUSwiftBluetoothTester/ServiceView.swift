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
    @Published var peripheral: any UUPeripheral
    @Published var service: CBService
    
    init(_ peripheral: any UUPeripheral, _ service: CBService)
    {
        self.peripheral = peripheral
        self.service = service
    }
    
    func onConnect()
    {
        peripheral.connect(timeout: 20.0, connected:
        {
            DispatchQueue.main.async
            {
                self.objectWillChange.send()
            }
            
        }, disconnected:
        { disconnectError in
            
            DispatchQueue.main.async
            {
                self.objectWillChange.send()
            }
        })
    }
    
    func onDiscoverCharacteristics()
    {
        peripheral.discoverCharacteristics(characteristicUUIDs: nil, for: service, timeout: 20.0)
        { characteristics, errOpt in
            
            NSLog("Characteristic discovery complete, found \(characteristics?.count ?? 0) characteristics")
            
            characteristics?.forEach(
            { characteristic in
                NSLog("Found Characteristic: \(characteristic.uuid) - \(characteristic.uuid.uuCommonName)")
            })
            
            NSLog("Characteristic discovery complete")
            
            DispatchQueue.main.async
            {
                self.objectWillChange.send()
            }
        }
    }
    
    func onDiscoverIncludedServices()
    {
        peripheral.discoverIncludedServices(includedServiceUUIDs: nil, for: service, timeout: 20.0)
        { updatedPeripheral, errOpt in
            
            DispatchQueue.main.async
            {
                self.objectWillChange.send()
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
