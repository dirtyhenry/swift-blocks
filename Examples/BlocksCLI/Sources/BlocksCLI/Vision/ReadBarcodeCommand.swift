import ArgumentParser
import Blocks
import Vision

struct ReadBarcodeCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "barcode",
        abstract: "Extracts the textual payload from a barcode."
    )

    @Argument(help: "Path to the barcode file.")
    var inputPath: String

    mutating func run() throws {
        let fileURL = URL(fileURLWithPath: inputPath)
        do {
            print("🚦 Start Detection")
            let barcodeDescriptions = try detectBarcodes(in: fileURL)
            print("🎉 Success (count: \(barcodeDescriptions.count))")

            barcodeDescriptions.forEach { item in
                print("[\(item.payload ?? "n/a")] — \(item.symbology.rawValue.description)")
            }

        } catch {
            print("💥 Failure")
        }
    }

    func detectBarcodes(in fileURL: URL) throws -> [BarcodeDescription] {
        let imageRequestHandler = VNImageRequestHandler(url: fileURL, orientation: .up, options: [:])
        let request = VNDetectBarcodesRequest()
        try imageRequestHandler.perform([request])

        guard let observations = request.results else {
            return []
        }

        return observations.map { BarcodeDescription(payload: $0.payloadStringValue, symbology: $0.symbology) }
    }

    struct BarcodeDescription {
        let payload: String?
        let symbology: VNBarcodeSymbology
    }
}
