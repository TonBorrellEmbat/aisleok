import SwiftUI

struct LabelOCRView: View {
    @EnvironmentObject private var model: AppModel
    @State private var isRecognizing = false
    @State private var typedFallback = ""

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                if CameraAvailability.hasVideoDevice {
                    OCRCameraView { image in
                        Task { await recognize(image) }
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "camera")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("Camera is off. Type an ingredient list instead.")
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

            if CameraAvailability.hasVideoDevice {
                Button {
                    NotificationCenter.default.post(name: .aisleokCaptureOCR, object: nil)
                } label: {
                    Label("Capture label", systemImage: "camera")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AisleOKColor.paprika)
                .controlSize(.large)
                .disabled(isRecognizing)
            } else {
                TextField("Paste ingredients", text: $typedFallback, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(4...8)
                Button("Score this list") {
                    model.handleOCR(text: typedFallback, fallbackName: "Label")
                }
                .buttonStyle(.borderedProminent)
                .tint(AisleOKColor.paprika)
                .disabled(typedFallback.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if isRecognizing {
                ProgressView("Reading the label…")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .background(AisleOKColor.canvas.ignoresSafeArea())
        .navigationTitle("Photo of label")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func recognize(_ image: UIImage) async {
        isRecognizing = true
        let text = await LabelOCR.recognize(image)
        isRecognizing = false
        model.handleOCR(text: text, fallbackName: "Label")
    }
}

extension Notification.Name {
    static let aisleokCaptureOCR = Notification.Name("aisleok.captureOCR")
}
