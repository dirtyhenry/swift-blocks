import ArgumentParser

@main
struct BlocksCLI: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "Blocks CLI Tool.",
        version: "0.1.0",
        subcommands: [
            CurlLikeCommand.self,
            GenerateTestCommand.self,
            ReadBarcodeCommand.self,
            ReadPasswordCommand.self,
            PrintColorsCommand.self,
            LintCopyCommand.self,
            ListDevicesCommand.self
        ]
    )
}
