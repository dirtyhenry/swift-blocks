import ArgumentParser
import Blocks
import Cocoa
import CoreImage.CIFilterBuiltins
import Foundation
import Vision

struct GenerateBarcodeCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "gen-barcode",
        abstract: "Create a barcode from a text input."
    )

    @Argument(help: "Message to encode.")
    var input: String

    @Option(help: "Symbology to use.")
    var symbology: SupportedSymbology = .qr

    @Option(help: "Scaling factor.")
    var scalingFactor: Int = 4

    @Option(help: "Output filename.")
    var outputFilename: String = "output.png"

    @Flag var verbose = false

    mutating func run() throws {
        guard let image = try image(for: input, as: symbology),
              let imageData = ciImageAsPNG(scale(image: image, by: CGFloat(scalingFactor))),
              FileManager.default.createFile(atPath: outputFilename, contents: imageData)
        else {
            throw SimpleMessageError(message: "Could not generate a code from input")
        }
    }

    // MARK: - Code Generation

    func image(for inputMessage: String, as symbology: SupportedSymbology) throws -> CIImage? {
        switch symbology {
        case .aztec:
            return aztecCode(inputMessage: inputMessage)
        case .qr:
            return qrCode(inputMessage: inputMessage)
        }
    }

    func aztecCode(inputMessage: String) -> CIImage? {
        guard let message = inputMessage.data(using: .ascii) else {
            return nil
        }

        let generator = CIFilter.aztecCodeGenerator()
        generator.correctionLevel = 5
        generator.compactStyle = 0
        generator.message = message
        generator.layers = 5
        return generator.outputImage
    }

    func qrCode(inputMessage: String) -> CIImage? {
        guard let message = inputMessage.data(using: .ascii) else {
            return nil
        }

        let generator = CIFilter.qrCodeGenerator()
        generator.message = message
        generator.correctionLevel = "H"
        return generator.outputImage
    }

    // MARK: - Image tooling

    func scale(image: CIImage, by scaleFactor: CGFloat) -> CIImage {
        let transform = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
        return image.transformed(by: transform)
    }

    func ciImageAsPNG(_ ciImage: CIImage) -> Data? {
        guard let cgImage = CIContext().createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        return cgImageAsPNG(cgImage)
    }

    func cgImageAsPNG(_ cgImage: CGImage) -> Data? {
        // Step 1: Convert CGImage to NSImage
        let image = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))

        // Step 2: Convert NSImage to PNG Data using NSBitmapImageRep
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:])
        else {
            return nil
        }

        return pngData
    }

    enum SupportedSymbology: String, ExpressibleByArgument, CaseIterable {
        case qr
        case aztec
    }
}
