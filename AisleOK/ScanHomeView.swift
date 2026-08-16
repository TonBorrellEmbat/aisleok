import AVFoundation
import SwiftUI

struct ScanHomeView: View {
    @EnvironmentObject private var model: AppModel
    @State private var cameraAuthorized = CameraAvailability.canShowLiveCamera

    var body: some View {
        VStack(spacing: 16) {
            cameraWell
            Text("Point at a barcode.")
                .font(.body)
                .foregroundStyle(.secondary)
            if let message = model.scanMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AisleOKColor.canvas.ignoresSafeArea())
        .navigationTitle("AisleOK")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    model.openSettings()
                } label: {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("Settings")
            }
            ToolbarItem(placement: .bottomBar) {
                Button {
                    model.openLabelOCR()
                } label: {
                    Label("Photo of label", systemImage: "camera")
                }
            }
            ToolbarItem(placement: .bottomBar) {
                Button {
                    model.openProduceSearch()
                } label: {
                    Label("Search produce", systemImage: "magnifyingglass")
                }
            }
        }
        .task {
            await requestCamera()
        }
    }

    private var cameraWell: some View {
        ZStack {
            if cameraAuthorized {
                BarcodeScannerView { code in
                    model.handleBarcode(code)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "barcode.viewfinder")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("Camera is off. Search produce still works.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.secondary, lineWidth: 2)
                .padding(28)
                .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
        )
        .padding(.top, 8)
    }

    private func requestCamera() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            cameraAuthorized = CameraAvailability.canShowLiveCamera
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            cameraAuthorized = granted && CameraAvailability.canShowLiveCamera
        default:
            cameraAuthorized = false
        }
    }
}
