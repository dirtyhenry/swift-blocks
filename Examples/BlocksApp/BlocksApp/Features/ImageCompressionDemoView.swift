import Blocks
import SwiftUI
import UniformTypeIdentifiers

struct ImageCompressionDemoView: View {
    let readme: LocalizedStringKey = """
    This demo shows `ImageResizer`, `ImageCompressor` and `DocumentDetector` from the Imaging module.

    Select an image and a preset. Then compress the image and examine the result.
    """

    enum PresetOption: String, CaseIterable, Identifiable {
        case highQuality = "High Quality"
        case balanced = "Balanced"
        case compact = "Compact"

        var id: String {
            rawValue
        }

        var preset: CompressionPreset {
            switch self {
            case .highQuality: .highQuality
            case .balanced: .balanced
            case .compact: .compact
            }
        }
    }

    @State private var sourceImage: CGImage?
    @State private var sourceInfo: String = ""
    @State private var compressedData: Data?
    @State private var selectedPreset: PresetOption = .balanced
    @State private var detectDocument: Bool = false
    @State private var isProcessing: Bool = false
    @State private var resultInfo: String = ""
    @State private var errorMessage: String?
    @State private var isShowingFilePicker: Bool = false
    @State private var isShowingSavePanel: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(alignment: .leading) {
                    Text(readme)
                }.frame(maxWidth: .infinity, alignment: .leading)

                Divider()

                // Source image section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Source Image").font(.headline)
                    HStack(spacing: 12) {
                        Button("Generate Sample") {
                            sourceImage = Self.makeSampleImage()
                            sourceInfo = "\(sourceImage?.width ?? 0)×\(sourceImage?.height ?? 0) (generated)"
                            resetResult()
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Open File…") {
                            isShowingFilePicker = true
                        }
                        .buttonStyle(.bordered)
                    }

                    if !sourceInfo.isEmpty {
                        Text(sourceInfo)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let sourceImage {
                        imagePreview(sourceImage, label: "Source: \(sourceImage.width)×\(sourceImage.height)")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()

                // Configuration section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Configuration").font(.headline)
                    Picker("Preset", selection: $selectedPreset) {
                        ForEach(PresetOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)

                    let config = selectedPreset.preset.configuration
                    Text("Target: \(config.targetByteSize / 1000) KB, Max: \(config.maxWidth ?? 0)px")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Toggle("Detect & crop document", isOn: $detectDocument)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()

                // Actions
                HStack(spacing: 12) {
                    Button(action: compress) {
                        if isProcessing {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Text("Compress")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(sourceImage == nil || isProcessing)

                    if compressedData != nil {
                        Button("Save Compressed…") {
                            isShowingSavePanel = true
                        }
                        .buttonStyle(.bordered)
                    }
                }

                // Result section
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                if !resultInfo.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Result").font(.headline)
                        Text(resultInfo)
                            .font(.system(.caption, design: .monospaced))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let compressedData, let compressedImage = CGImage.from(jpegData: compressedData) {
                    imagePreview(
                        compressedImage,
                        label: "Compressed: \(compressedImage.width)×\(compressedImage.height)"
                    )
                }

                if sourceImage != nil {
                    Divider()
                    Button("Reset", role: .destructive) {
                        resetAll()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
        .navigationTitle("Image Compression")
        .fileImporter(
            isPresented: $isShowingFilePicker,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .fileExporter(
            isPresented: $isShowingSavePanel,
            document: JPEGDocument(data: compressedData),
            contentType: .jpeg,
            defaultFilename: "compressed.jpg"
        ) { result in
            if case let .failure(error) = result {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func imagePreview(_ cgImage: CGImage, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            #if os(macOS)
            let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
            Image(nsImage: nsImage)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 200)
            #else
            Image(uiImage: UIImage(cgImage: cgImage))
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 200)
            #endif
        }
    }

    private func resetResult() {
        compressedData = nil
        resultInfo = ""
        errorMessage = nil
    }

    private func resetAll() {
        sourceImage = nil
        sourceInfo = ""
        selectedPreset = .balanced
        detectDocument = false
        resetResult()
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        resetResult()
        switch result {
        case let .success(urls):
            guard let url = urls.first else { return }
            do {
                // On iOS, the file is outside of the sandbox of the app.
                let isAccessing = url.startAccessingSecurityScopedResource()
                defer {
                    if isAccessing {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
                let data = try Data(contentsOf: url)
                let source = try ImageSource(data: data)
                sourceImage = source.cgImage
                let fileSize = ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file)
                sourceInfo = "\(source.width)×\(source.height), \(fileSize) — \(url.lastPathComponent)"
            } catch {
                errorMessage = error.localizedDescription
            }
        case let .failure(error):
            errorMessage = error.localizedDescription
        }
    }

    private func compress() {
        guard let sourceImage else { return }
        isProcessing = true
        errorMessage = nil
        resultInfo = ""
        compressedData = nil

        let detectDocument = detectDocument
        let config = selectedPreset.preset.configuration

        Task {
            do {
                var source = ImageSource(cgImage: sourceImage)

                if detectDocument {
                    if let detection = try await DocumentDetector.detectDocument(in: source) {
                        source = detection.image
                        let confidence = String(format: "%.0f%%", detection.confidence * 100)
                        resultInfo += "Document detected (confidence: \(confidence))\n"
                    } else {
                        resultInfo += "No document detected, using original\n"
                    }
                }

                // The compression is synchronous and slow: keep it off the main actor.
                let input = source
                let result = try await Task.detached {
                    try ImageCompressor.compress(input, configuration: config)
                }.value

                compressedData = result.data
                resultInfo += """
                Quality: \(String(format: "%.0f%%", result.quality * 100))
                Size: \(result.byteSize / 1000) KB
                Resized: \(result.didResize ? "yes" : "no")
                """
            } catch {
                errorMessage = error.localizedDescription
            }
            isProcessing = false
        }
    }
}

extension ImageCompressionDemoView {
    static func makeSampleImage() -> CGImage? {
        let width = 3000
        let height = 2000
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        // Sky gradient background
        for row in 0 ..< height {
            let progress = CGFloat(row) / CGFloat(height)
            context.setFillColor(
                red: 0.3 + progress * 0.4,
                green: 0.5 + progress * 0.3,
                blue: 0.9 - progress * 0.3,
                alpha: 1
            )
            context.fill(CGRect(x: 0, y: row, width: width, height: 1))
        }

        // White "document" rectangle in center
        let docRect = CGRect(x: 400, y: 200, width: 2200, height: 1600)
        context.setFillColor(red: 1, green: 1, blue: 1, alpha: 1)
        context.fill(docRect)

        // Text-like lines on the document
        context.setFillColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        for line in 0 ..< 12 {
            let lineWidth = line % 3 == 2 ? 1200 : 1800
            context.fill(CGRect(x: 600, y: 350 + line * 100, width: lineWidth, height: 12))
        }

        return context.makeImage()
    }
}

struct JPEGDocument: FileDocument {
    static var readableContentTypes: [UTType] {
        [.jpeg]
    }

    let data: Data?

    init(data: Data?) {
        self.data = data
    }

    init(configuration _: ReadConfiguration) throws {
        data = nil
    }

    func fileWrapper(configuration _: WriteConfiguration) throws -> FileWrapper {
        guard let data else {
            throw CocoaError(.fileWriteUnknown)
        }
        return FileWrapper(regularFileWithContents: data)
    }
}

private extension CGImage {
    static func from(jpegData data: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }
}

#Preview {
    NavigationStack {
        ImageCompressionDemoView()
    }
}
