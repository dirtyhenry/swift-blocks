import Blocks
import SwiftUI

struct IPAddressScannerView: View {
    @State private var addresses: [String] = []
    @State private var scanState: TaskState = .notStarted
    @State private var copiedAddress: String?

    private let pasteboard = Pasteboard()

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header section
                VStack(spacing: 16) {
                    Image(systemName: "network")
                        .font(.system(size: 64))
                        .foregroundStyle(.green.gradient)

                    Text("IP Address Scanner")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Find all private IPv4 addresses on this device")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                #if os(iOS)
                .padding(.top, 20)
                #else
                .padding(.top, 30)
                #endif

                // Scan button
                TaskStateButton(
                    "Start Scanning",
                    runningTitleKey: "Scanning...",
                    systemImage: "magnifyingglass",
                    action: scanAddresses,
                    disabledWhenCompleted: false,
                    state: scanState
                )
                .buttonStyle(.borderedProminent)
                .tint(.green)

                // Results section
                if scanState == .completed {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Found Addresses (\(addresses.count))", systemImage: "list.bullet")
                            .font(.headline)
                            .foregroundStyle(.primary)

                        if addresses.isEmpty {
                            Text("No private IPv4 addresses found")
                                .foregroundStyle(.secondary)
                                .italic()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 20)
                        } else {
                            VStack(spacing: 8) {
                                ForEach(addresses, id: \.self) { address in
                                    addressRow(address)
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(.regularMaterial, in: .rect(cornerRadius: 16))
                }

                Spacer(minLength: 20)
            }
            #if os(iOS)
            .padding(.horizontal, 20)
            #else
            .padding(.horizontal, 40)
            #endif
        }
        .navigationTitle("IP Scanner")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    @ViewBuilder
    private func addressRow(_ address: String) -> some View {
        HStack {
            Text(address)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)

            Spacer()

            Button(action: { copyAddress(address) }) {
                Image(systemName: copiedAddress == address ? "checkmark" : "doc.on.clipboard")
                    .font(.body)
                    .foregroundStyle(copiedAddress == address ? .green : .blue)
                    .animation(.spring(response: 0.3), value: copiedAddress)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(.green.opacity(0.1), in: .rect(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.green.opacity(0.3), lineWidth: 1)
        )
    }

    private func scanAddresses() {
        scanState = .running
        Task {
            try? await Task.sleep(for: .milliseconds(300))
            await MainActor.run {
                addresses = getPrivateIPv4Addresses()
                scanState = .completed
            }
        }
    }

    private func copyAddress(_ address: String) {
        pasteboard.copy(text: address)
        copiedAddress = address

        Task {
            try? await Task.sleep(for: .seconds(2))
            await MainActor.run {
                if copiedAddress == address {
                    copiedAddress = nil
                }
            }
        }
    }
}

#Preview {
    IPAddressScannerView()
}
