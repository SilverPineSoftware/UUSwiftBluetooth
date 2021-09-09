//
//  ServiceRowView.swift
//  UUSwiftBluetoothTester
//
//  Created by Ryan DeVore on 9/9/21.
//

import SwiftUI
import CoreBluetooth
import UUSwiftBluetooth

class ServiceRowViewModel: ObservableObject
{
    @Published var service: CBService
    
    init(_ service: CBService)
    {
        self.service = service
    }
    
    func onTap()
    {
        NSLog("Tapped on service: \(service.uuid.uuidString)")
    }
    
}

struct ServiceRowView: View
{
    @ObservedObject var viewModel: ServiceRowViewModel
    
    var body: some View
    {
        VStack
        {
            LabelValueRowView(label: "UUID:", value: viewModel.service.uuid.uuidString)
            LabelValueRowView(label: "Name:", value: viewModel.service.uuid.uuCommonName)
            LabelValueRowView(label: "IsPrimary:", value: "\(viewModel.service.isPrimary ? "Yes" : "No")")
            
            Rectangle()
                .fill(Color.black)
                .frame(width: nil, height: 1, alignment: .leading)
        }
        .onTapGesture(perform: viewModel.onTap)
    }
}
