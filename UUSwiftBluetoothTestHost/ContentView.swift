//
//  ContentView.swift
//  UUSwiftBluetoothTestHost
//
//  Created by Ryan DeVore on 6/22/24.
//

import SwiftUI

struct ContentView: View 
{
    /*init()
    {
        //NotificationCenter.default.post(name: Notification.Name(rawValue: "SaveFile"), object: data)
        NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: "SaveFile"), object: nil, queue: nil)
        { notification in
            NSLog("Handled notification!")
            
            if let data = notification.object as? Data
            {
                let av = UIActivityViewController(activityItems: [data], applicationActivities: nil)
                UIApplication.shared.windows.first?.rootViewController?.present(av, animated: true, completion: nil)
            }
        }
    }*/
    
    var body: some View {
        VStack {
//            Image(systemName: "globe")
//                .imageScale(.large)
//                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
