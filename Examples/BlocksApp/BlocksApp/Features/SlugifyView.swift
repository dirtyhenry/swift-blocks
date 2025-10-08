import Blocks
import OSLog
import SwiftUI

struct SlugifyView: View {
    private let logger = Logger(subsystem: "net.mickf.BlocksDemoApp", category: "Slugify")

    @State private var input: String = ""
    @State private var slug: String = "".slugify()
    @State private var showingCopyConfirmation = false

    private let pasteboard = Pasteboard()

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header section with icon
                VStack(spacing: 16) {
                    Image(systemName: "link.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.blue.gradient)

                    Text("URL Slugify")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Transform text into clean, URL-friendly slugs")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                #if os(iOS)
                .padding(.top, 20)
                #else
                .padding(.top, 30)
                #endif

                // Input and output cards
                VStack(spacing: 24) {
                    // Input card
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Input Text", systemImage: "keyboard")
                            .font(.headline)
                            .foregroundStyle(.primary)

                        TextField("Type your text here...", text: $input, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                        #if os(iOS)
                            .lineLimit(3 ... 6)
                        #else
                            .lineLimit(2 ... 8)
                        #endif
                            .disableAutocorrection(true)
                    }
                    .padding(20)
                    .background(.regularMaterial, in: .rect(cornerRadius: 16))

                    // Arrow indicator
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                        .opacity(input.isEmpty ? 0.3 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: input.isEmpty)

                    // Output card
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Generated Slug", systemImage: "link")
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Group {
                            if slug.isEmpty {
                                Text("Your slug will appear here")
                                    .foregroundStyle(.tertiary)
                                    .italic()
                            } else {
                                Text(slug)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundStyle(.primary)
                                    .textSelection(.enabled)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(slug.isEmpty ? .clear : .blue.opacity(0.1), in: .rect(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(slug.isEmpty ? .clear : .blue.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding(20)
                    .background(.regularMaterial, in: .rect(cornerRadius: 16))
                }

                // Action button
                Button(action: copySlug) {
                    HStack {
                        Image(systemName: showingCopyConfirmation ? "checkmark" : "doc.on.clipboard")
                            .font(.title3)
                        Text(showingCopyConfirmation ? "Copied!" : "Copy Slug")
                            .font(.headline)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(slug.isEmpty ? .gray : .blue, in: .capsule)
                    .animation(.spring(response: 0.3), value: showingCopyConfirmation)
                }
                .disabled(slug.isEmpty)
                .buttonStyle(.plain)

                Spacer(minLength: 20)
            }
            #if os(iOS)
            .padding(.horizontal, 20)
            #else
            .padding(.horizontal, 40)
            #endif
        }
        .navigationTitle("Slugify")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
            .onChange(of: input) { _, newValue in
                slug = newValue.slugify()
            }
    }

    private func copySlug() {
        pasteboard.copy(text: slug)
        showingCopyConfirmation = true

        // Reset the confirmation after a delay
        Task {
            try await Task.sleep(for: .seconds(2))
            await MainActor.run {
                showingCopyConfirmation = false
            }
        }
    }
}

#Preview {
    SlugifyView()
}
