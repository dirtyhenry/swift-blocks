import ArgumentParser
import Blocks
import CoreImage
import Vision

struct ReadBarcodeCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "read-barcode",
        abstract: "Extract the textual payload from a barcode."
    )

    @Argument(help: "Path to the barcode file.")
    var inputPath: String

    mutating func run() throws {
        let fileURL = URL(fileURLWithPath: inputPath)
        do {
            print("🚦 Start Detection")
            let barcodeDescriptions = try detectBarcodes(in: fileURL)
            print("🎉 Success (count: \(barcodeDescriptions.count))")

            for item in barcodeDescriptions {
                print(item.description)
                print(item.humanDescription)
            }
        } catch {
            print("💥 Failure: \(error.localizedDescription)")
        }
    }

    func detectBarcodes(in fileURL: URL) throws -> [VNBarcodeObservation] {
        let imageRequestHandler = VNImageRequestHandler(url: fileURL, orientation: .up, options: [:])
        let request = VNDetectBarcodesRequest()
        try imageRequestHandler.perform([request])
        return request.results ?? []
    }
}

extension VNBarcodeObservation {
    var humanDescription: String {
        switch barcodeDescriptor {
        case let aztecCodeDescritor as CIAztecCodeDescriptor:
            let props = [
                "symbology": symbology.rawValue,
                "payload": payloadStringValue ?? "n/a",
                "isCompact": aztecCodeDescritor.isCompact.description,
                "layerCount": aztecCodeDescritor.layerCount.description,
                "dataCodewordCount": aztecCodeDescritor.dataCodewordCount.description
            ]
            return JSON.stringify(props)
        case let qrCodeDescriptor as CIQRCodeDescriptor:
            let props = [
                "symbology": symbology.rawValue,
                "payload": payloadStringValue ?? "n/a",
                "symbolVersion": qrCodeDescriptor.symbolVersion.description,
                "maskPattern": qrCodeDescriptor.maskPattern.description,
                "errorCorrectionLevel.rawValue": qrCodeDescriptor.errorCorrectionLevel.rawValue.description
            ]
            return JSON.stringify(props)
        default:
            return "Unsupported human description for this barcode descriptor."
        }
    }
}
