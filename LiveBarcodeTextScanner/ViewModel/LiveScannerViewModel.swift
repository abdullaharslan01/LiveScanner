//
//  LiveScannerViewModel.swift
//  LiveBarcodeTextScanner
//
//  Created by abdullah on 06.07.2025.
//

import AVKit
import SwiftUI
import VisionKit

enum ScanType:String {
    case text, barcode
}

enum DataScannerAccessStatusType {
    case notDetermined
    case cameraAccessNotGranted
    case cameraNotAvaliable
    case scannerAvaliable
    case scannerNotAvaliable
}

@MainActor
@Observable
final class LiveScannerViewModel {
    var dataScannerAccessStatus: DataScannerAccessStatusType = .notDetermined
    var  recognizedItems: [RecognizedItem] = []
    var scanType: ScanType = .barcode
    var textContentType: DataScannerViewController.TextContentType?
    var recognizesMultipleItems = true

     var recognizedDataType: DataScannerViewController.RecognizedDataType {
        scanType == .barcode ? .barcode() : .text(textContentType: textContentType)
    }
    
    
    var headerText:String {
        if recognizedItems.isEmpty {
            return "Scanning \(scanType.rawValue)"
        } else {
            return "Recognized \(recognizedItems.count) item(s)"
        }
    }
    
    var dataScannerViewId: Int {
        var hasher = Hasher()
        hasher.combine(scanType)
        hasher.combine(recognizesMultipleItems)
        if let textContentType {
            hasher.combine(textContentType)
        }
        return hasher.finalize()
    }

    private var isScannerAvaliable: Bool {
        return DataScannerViewController.isAvailable && DataScannerViewController.isSupported
    }

    func requestDataScannerAccessStatus() async {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            dataScannerAccessStatus = .cameraNotAvaliable
            return
        }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            dataScannerAccessStatus = isScannerAvaliable ? .scannerAvaliable : .scannerNotAvaliable
        case .restricted, .denied:
            dataScannerAccessStatus = .cameraAccessNotGranted
        case .notDetermined:

            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if granted {
                dataScannerAccessStatus = isScannerAvaliable ? .scannerAvaliable : .scannerNotAvaliable
            } else {
                dataScannerAccessStatus = .cameraAccessNotGranted
            }
        @unknown default:
            break
        }
    }
}
