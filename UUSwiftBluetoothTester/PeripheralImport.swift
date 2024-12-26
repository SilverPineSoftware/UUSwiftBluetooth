//
//  PeripheralImport.swift
//  UUSwiftBluetoothTester
//
//  Created by Ryan DeVore on 12/24/24.
//

import UIKit
import UniformTypeIdentifiers
import UUSwiftCore
import UUSwiftBluetooth

extension ViewController: UIDocumentPickerDelegate
{
    func showPickerForPeripheralImport()
    {
        let supportedTypes:[UTType]  = [UTType.data]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes)
        picker.delegate = self
        picker.modalPresentationStyle = .overFullScreen
        self.present(picker, animated: true)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL])
    {
        guard let url = urls.first else { return }
                
        if (url.startAccessingSecurityScopedResource())
        {
            do
            {
                let contents = try Data(contentsOf: url)
                
                let decoder = JSONDecoder()
                let peripheralData = try decoder.decode(UUPeripheralModel.self, from: contents)
                
                let check = peripheralData.uuToJsonString()
                UULog.debug(tag: "Import", message: check)
                
                peripheralData.registerCommonNames()
                
                url.stopAccessingSecurityScopedResource()
            }
            catch
            {
                url.stopAccessingSecurityScopedResource()
            }
            
        }
    }
}
