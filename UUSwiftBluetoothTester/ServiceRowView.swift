//
//  ServiceRowView.swift
//  UUSwiftBluetoothTester
//
//  Created by Ryan DeVore on 9/9/21.
//

import SwiftUI
import CoreBluetooth
import UUSwiftCore
import UUSwiftBluetooth

class ServiceRowViewModel: ObservableObject
{
    @Published var service: CBService
    var tapHandler: ((CBService)->())?
    @Published var showDivider: Bool
    
    required init(_ service: CBService, tapHandler: ((CBService)->())? = nil, showDivider: Bool = true)
    {
        self.service = service
        self.tapHandler = tapHandler
        self.showDivider = showDivider
    }
    
    func onTap()
    {
        UUDebugLog("Tapped on service: \(service.uuid.uuidString)")
        tapHandler?(service)
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
            
            if (viewModel.showDivider)
            {
                Rectangle()
                    .fill(Color.black)
                    .frame(width: nil, height: 1, alignment: .leading)
            }
        }
        .onTapGesture(perform: viewModel.onTap)
    }
}
