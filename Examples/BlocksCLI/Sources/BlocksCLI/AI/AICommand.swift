#if canImport(FoundationModels)
import ArgumentParser
import Blocks
import Foundation
import FoundationModels

/// Rewrites product copy through the on-device foundation model.
///
/// Requires macOS 26 or later and an Apple Intelligence-eligible device.
struct AICommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "ai-demo",
        abstract: "Edit product copy with AI."
    )

    @Argument(help: "The copy to edit.")
    var input: String

    @Flag(name: .shortAndLong, help: "Print the full model response instead of just the rewritten copy.")
    var verbose = false

    mutating func run() async throws {
        if #available(macOS 26.0, *) {
            let editor = ProductCopyEditor()
            let response = try await editor.edit(copy: input)

            if verbose {
                print(response)
            } else {
                print(response.content)
            }
        } else {
            throw SimpleMessageError(message: "macOS 26 required.")
        }
    }
}

/// Sends a single editing prompt to the system language model.
@available(macOS 26.0, *)
struct ProductCopyEditor {
    private var model = SystemLanguageModel.default

    func edit(copy: String) async throws -> LanguageModelSession.Response<String> {
        switch model.availability {
        case .available:
            break
        case .unavailable(.deviceNotEligible):
            throw SimpleMessageError(message: "Device not eligible")
        case .unavailable(.appleIntelligenceNotEnabled):
            throw SimpleMessageError(message: "Apple Intelligence not enabled")
        case .unavailable(.modelNotReady):
            throw SimpleMessageError(message: "Model not ready")
        case let .unavailable(other):
            throw SimpleMessageError(message: "Other reason: \(other)")
        }

        let instructions = """
        You are an expert product copy editor.

        Your task is to rewrite the provided text so it is clear, human, concise, and aligned with modern product copywriting best practices.

        Requirements:

        * Follow the principles from “Talking to Humans” by Giff Constable:
            * prioritize clarity over cleverness
            * sound natural and conversational
            * avoid marketing fluff, buzzwords, and exaggerated claims
            * focus on what users actually care about
            * write in plain English
        * Use inclusive language:
            * never assume gender
            * avoid gendered terms unless explicitly provided
            * use singular “they/them” when needed
        * Use US English spelling and vocabulary:
            * use “color” instead of “colour”
            * use “elevator” instead of “lift”
            * use “eggplant” instead of “aubergine”
            * use “apartment” instead of “flat”
            * use “favorite” instead of “favourite”
            * generally prefer standard American English wording
        * Maintain a professional but approachable tone:
            * remove profanity, insults, or aggressive wording
            * keep the language direct and plain
            * do not sound corporate or robotic
        * Preserve the original meaning and intent.
        * Keep the copy concise unless expansion improves clarity.
        * Do not add unsupported claims or marketing promises.
        * If the text is already good, make only minimal edits.

        Return only the improved version.
        """

        let session = LanguageModelSession(instructions: instructions)
        return try await session.respond(to: copy)
    }
}
#endif
