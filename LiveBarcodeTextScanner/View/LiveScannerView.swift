//
//  LiveScannerView.swift
//  LiveBarcodeTextScanner
//
//  Created by abdullah on 06.07.2025.
//

import SwiftUI
import VisionKit

struct LiveScannerView: View {
    private let textContentTypes: [(title: String, textContentType: DataScannerViewController.TextContentType?)] = [
        ("ALL", .none),
        ("URL", .URL),
        ("Phone", .telephoneNumber),
        ("Email", .emailAddress),
        ("Address", .fullStreetAddress)
    ]

    @State var vm = LiveScannerViewModel()
    var body: some View {
        ZStack {
            switch vm.dataScannerAccessStatus {
            case .scannerAvaliable:
                mainView
            case .cameraNotAvaliable:
                Text("Your device doesn't have a camera")
            case .scannerNotAvaliable:
                Text("Your device doesn't have suppor for scanning barcode with this app")
            case .cameraAccessNotGranted:
                Text("Please provide access to the camera in settings")
            case .notDetermined:
                Text("Requesting camera access")
            }
        }.task {
            await vm.requestDataScannerAccessStatus()
        }
    }

    private var mainView: some View {
        DataScannerView(recognizedItems: $vm.recognizedItems, recognizeDataType: vm.recognizedDataType, recognizedMultipleItems: vm.recognizesMultipleItems)
            .background(Color.gray.opacity(0.3))
            .ignoresSafeArea()
            .id(vm.dataScannerViewId)
            .onChange(of: vm.scanType) { _, _ in
                vm.recognizedItems = []

            }.onChange(of: vm.textContentType) { _, _ in
                vm.recognizedItems = []
            }
            .onChange(of: vm.recognizesMultipleItems) { _, _ in
                vm.recognizedItems = []
            }.sheet(isPresented: .constant(true)) {
                bottomContainerView
                    .background(.ultraThinMaterial)
                    .presentationDetents([.medium, .fraction(0.25)])
                    .presentationDragIndicator(.visible)
                    .interactiveDismissDisabled()
                    .onAppear {
                        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                              let controller = windowScene.windows.first?.rootViewController?.presentedViewController else { return }
                        controller.view.backgroundColor = .clear
                    }
            }
    }

    private var headerView: some View {
        VStack {
            HStack {
                Picker("Scan Type", selection: $vm.scanType) {
                    Text("Barcode").tag(ScanType.barcode)
                    Text("Text").tag(ScanType.text)
                }.pickerStyle(.segmented)

                Toggle("Scan multiple", isOn: $vm.recognizesMultipleItems)
            }.padding(.top)

            if vm.scanType == .text {
                Picker("Text content type", selection: $vm.textContentType) {
                    ForEach(textContentTypes, id: \.self.textContentType) { option in
                        Text(option.title).tag(option.textContentType)
                    }
                }.pickerStyle(.segmented)
            }

            Text(vm.headerText).padding(.top)
        }.padding(.horizontal)
    }

    private var bottomContainerView: some View {
        VStack {
            headerView
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(vm.recognizedItems) { item in
                        switch item {
                        case .barcode(let barcode):
                            Text(barcode.payloadStringValue ?? "Unknown")
                        case .text(let text):
                            Text(text.transcript)
                        @unknown default:
                            Text("Unknown")
                        }
                    }
                }.padding(.horizontal)
            }
        }
    }
}

#Preview {
    LiveScannerView()
        .environment(LiveScannerViewModel())
}
