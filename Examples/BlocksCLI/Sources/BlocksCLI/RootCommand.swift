import ArgumentParser

@main
struct BlocksCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Blocks CLI Tool.",
        version: "0.3.0",
        subcommands: Self.allSubcommands
    )

    private static var allSubcommands: [ParsableCommand.Type] {
        var commands: [ParsableCommand.Type] = [
            CurlLikeCommand.self,
            GenerateTestCommand.self,
            ReadBarcodeCommand.self,
            GenerateBarcodeCommand.self,
            ReadPasswordCommand.self,
            PrintColorsCommand.self,
            LintCopyCommand.self,
            ListDevicesCommand.self,
            ListIPAddressesCommand.self,
            MergeTranslationsCommand.self,
            SlugifyCommand.self
        ]
        #if canImport(FoundationModels)
        commands.append(AICommand.self)
        #endif
        return commands
    }
}
