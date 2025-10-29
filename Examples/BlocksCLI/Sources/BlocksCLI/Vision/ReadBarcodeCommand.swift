import ArgumentParser
import Blocks
import CoreImage
import Foundation
import UniformTypeIdentifiers
import Vision

/// A command-line tool for extracting textual payloads from barcode images.
///
/// This command uses Vision framework to detect and decode various barcode types
/// including QR codes, Aztec codes, Data Matrix codes, and more. It supports
/// both verbose output with detailed barcode information and JSON formatting.
struct ReadBarcodeCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "read-barcode",
        abstract: "Extract the textual payload from a barcode."
    )

    @Argument(help: "Path to the barcode file.")
    var inputPath: String

    @Flag(name: .shortAndLong, help: "Enable verbose output with detailed barcode information.")
    var verbose = false

    @Flag(name: .shortAndLong, help: "Output results in JSON format.")
    var json = false

    mutating func run() throws {
        let fileURL = URL(fileURLWithPath: inputPath)

        // Validate file exists and is a file (not a directory)
        try validateFileExists(at: inputPath)

        do {
            if verbose {
                print("🚦 Starting barcode detection for: \(inputPath)")
            }

            let barcodeDescriptions = try detectBarcodes(in: fileURL)

            if barcodeDescriptions.isEmpty {
                print("No barcodes found.")
                return
            }

            if verbose {
                print("🎉 Successfully detected \(barcodeDescriptions.count) barcode(s)")
            }

            if json {
                let jsonOutput = barcodeDescriptions.map(\.jsonRepresentation)
                if let jsonData = try? JSONSerialization.data(withJSONObject: jsonOutput, options: .prettyPrinted),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    print(jsonString)
                }
            } else {
                for (index, barcode) in barcodeDescriptions.enumerated() {
                    if barcodeDescriptions.count > 1 {
                        print("\n--- Barcode \(index + 1) ---")
                    }

                    if verbose {
                        print("Type: \(barcode.symbology.rawValue)")
                        print("Payload: \(barcode.payloadStringValue ?? "Unable to decode")")
                        print("Confidence: \(String(format: "%.2f", barcode.confidence))")
                        let bounds = barcode.boundingBox
                        print("Location: x=\(String(format: "%.0f", bounds.origin.x)), y=\(String(format: "%.0f", bounds.origin.y))")
                        print("Details: \(barcode.humanDescription)")
                    } else {
                        print(barcode.payloadStringValue ?? "Unable to decode payload")
                    }
                }
            }
        } catch let error as ValidationError {
            Self.exit(withError: error)
        } catch {
            print("💥 Detection failed: \(error.localizedDescription)")
            Self.exit(withError: ExitCode.failure)
        }
    }

    func detectBarcodes(in fileURL: URL) throws -> [VNBarcodeObservation] {
        let imageRequestHandler = VNImageRequestHandler(
            url: fileURL, orientation: .up, options: [:]
        )
        let request = VNDetectBarcodesRequest()
        try imageRequestHandler.perform([request])
        return request.results ?? []
    }
}

/// Extension providing additional functionality for Vision framework barcode observations.
extension VNBarcodeObservation {
    /// A dictionary representation of the barcode observation suitable for JSON serialization.
    ///
    /// This computed property creates a structured representation including:
    /// - Basic information: symbology, payload, confidence
    /// - Geometric information: bounding box coordinates
    /// - Type-specific details: varies based on barcode type (QR, Aztec, Data Matrix)
    ///
    /// - Returns: A dictionary containing all relevant barcode information
    var jsonRepresentation: [String: Any] {
        var result: [String: Any] = [
            "symbology": symbology.rawValue,
            "payload": payloadStringValue ?? NSNull(),
            "confidence": confidence
        ]

        // Add bounds information
        result["bounds"] = [
            "x": boundingBox.origin.x,
            "y": boundingBox.origin.y,
            "width": boundingBox.size.width,
            "height": boundingBox.size.height
        ]

        // Add descriptor-specific information
        switch barcodeDescriptor {
        case let aztecDescriptor as CIAztecCodeDescriptor:
            result["details"] = [
                "isCompact": aztecDescriptor.isCompact,
                "layerCount": aztecDescriptor.layerCount,
                "dataCodewordCount": aztecDescriptor.dataCodewordCount
            ]
        case let qrDescriptor as CIQRCodeDescriptor:
            result["details"] = [
                "symbolVersion": qrDescriptor.symbolVersion,
                "maskPattern": qrDescriptor.maskPattern,
                "errorCorrectionLevel": qrDescriptor.errorCorrectionLevel.rawValue
            ]
        case let dataMatrixDescriptor as CIDataMatrixCodeDescriptor:
            result["details"] = [
                "rowCount": dataMatrixDescriptor.rowCount,
                "columnCount": dataMatrixDescriptor.columnCount,
                "eccVersion": dataMatrixDescriptor.eccVersion.rawValue
            ]
        default:
            break
        }

        return result
    }

    /// A human-readable string description of the barcode observation.
    ///
    /// This computed property generates a formatted string containing detailed
    /// information about the barcode, including type-specific properties.
    /// The format varies based on the barcode symbology:
    ///
    /// - Aztec codes: includes compact flag, layer count, and data codeword count
    /// - QR codes: includes symbol version, mask pattern, and error correction level
    /// - Data Matrix codes: includes row/column counts and ECC version
    /// - Other types: includes basic symbology and payload information
    ///
    /// - Returns: A JSON-formatted string with barcode details
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
                "errorCorrectionLevel.rawValue": qrCodeDescriptor.errorCorrectionLevel.rawValue
                    .description
            ]
            return JSON.stringify(props)
        case let dataMatrixCodeDescriptor as CIDataMatrixCodeDescriptor:
            let props = [
                "symbology": symbology.rawValue,
                "payload": payloadStringValue ?? "n/a",
                "rowCount": dataMatrixCodeDescriptor.rowCount.description,
                "columnCount": dataMatrixCodeDescriptor.columnCount.description,
                "errorCorrectedPayload": dataMatrixCodeDescriptor.errorCorrectedPayload.description,
                "eccVersion.rawValue": dataMatrixCodeDescriptor.eccVersion.rawValue.description
            ]
            return JSON.stringify(props)
        default:
            let props = [
                "symbology": symbology.rawValue,
                "payload": payloadStringValue ?? "n/a"
            ]
            return JSON.stringify(props)
        }
    }
}

/// Validates that a file exists at the given path and is not a directory
/// - Parameter path: The file path to validate
/// - Throws: `ValidationError` if the file doesn't exist or is a directory
private func validateFileExists(at path: String) throws {
    var isDirectory: ObjCBool = false
    guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) else {
        throw ValidationError("File does not exist: \(path)")
    }

    guard !isDirectory.boolValue else {
        throw ValidationError("Path is a directory, not a file: \(path)")
    }
}
