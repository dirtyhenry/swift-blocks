import Blocks
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    enum Section: String, Identifiable, CaseIterable {
        case formPlayground = "Form Playground"
        case taskStateDemo = "TaskState"
        case fonts = "Fonts"
        case plainDateDemo = "PlainDate"
        case watchPairing = "Watch Pairing"
        #if os(iOS)
        case backgroundTasks = "Background Tasks"
        #endif
        case fileSystemExplorer = "File System"
        case ipAddressScanner = "IP Address"
        case mailAndCamera = "Mail & Camera"
        case loggingPlayground = "Logging"
        case slugifyPlayground = "Slugify"
        case transportDemo = "Transport"

        var id: String {
            rawValue
        }

        var systemImage: String {
            switch self {
            case .formPlayground: "list.bullet.rectangle"
            case .taskStateDemo: "button.horizontal"
            case .fonts: "textformat"
            case .plainDateDemo: "calendar"
            case .watchPairing: "applewatch"
            #if os(iOS)
            case .backgroundTasks: "moon.zzz"
            #endif
            case .fileSystemExplorer: "folder"
            case .ipAddressScanner: "network"
            case .mailAndCamera: "envelope"
            case .loggingPlayground: "doc.text.magnifyingglass"
            case .slugifyPlayground: "link"
            case .transportDemo: "arrow.up.arrow.down.circle"
            }
        }

        static let groups: [(title: String, sections: [Section])] = [
            ("Components", [.formPlayground, .taskStateDemo, .fonts, .plainDateDemo]),
            ("System", {
                var sections: [Section] = [.watchPairing]
                #if os(iOS)
                sections.append(.backgroundTasks)
                #endif
                sections += [.fileSystemExplorer, .ipAddressScanner, .mailAndCamera]
                return sections
            }()),
            ("Utilities", [.loggingPlayground, .slugifyPlayground, .transportDemo])
        ]
    }

    @State var isShowingCamera: Bool = false
    @State var isShowingComposer: Bool = false

    @State var selectedSectionId: Section.ID?

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedSectionId) {
                ForEach(Section.groups, id: \.title) { group in
                    SwiftUI.Section(group.title) {
                        ForEach(group.sections) { section in
                            Label(section.rawValue, systemImage: section.systemImage)
                        }
                    }
                }
            }
            .navigationTitle("Blocks")
            #if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            #endif
        } detail: {
            Group {
                if let selectedSectionId, let section = Section(rawValue: selectedSectionId) {
                    switch section {
                    case .mailAndCamera:
                        mailAndCameraView
                    case .fonts:
                        FontsView()
                    #if os(iOS)
                    case .backgroundTasks:
                        BackgroundTaskView()
                    #endif
                    case .fileSystemExplorer:
                        Button("Explore") {
                            explore()
                        }
                    case .ipAddressScanner:
                        IPAddressScannerView()
                    case .plainDateDemo:
                        PlainDateDemoView()
                    case .taskStateDemo:
                        TaskStateDemoView()
                    case .loggingPlayground:
                        LoggingPlaygroundView()
                    case .slugifyPlayground:
                        SlugifyView()
                    case .transportDemo:
                        TransportDemoView()
                    case .formPlayground:
                        FormPlaygroundView()
                    case .watchPairing:
                        WatchPairingDemoView()
                    }
                } else {
                    ContentUnavailableView("Select a Demo", systemImage: "square.grid.2x2")
                }
            }
            #if os(macOS)
            .scenePadding()
            #endif
        }
    }

    var mailAndCameraView: some View {
        Form {
            #if os(iOS) || os(tvOS)
            SwiftUI.Section("Camera") {
                Button("Take a Photo") {
                    isShowingCamera = true
                }.fullScreenCover(isPresented: $isShowingCamera) {
                    // In order to use this, `NSCameraUsageDescription` must be set.
                    ImagePickerView(sourceType: .camera, mediaTypes: [UTType.image.identifier])
                        .edgesIgnoringSafeArea(.all)
                }
            }
            #endif

            SwiftUI.Section("Mail") {
                #if canImport(MessageUI)
                if MailComposeView.canSendMail() {
                    Button("Compose In-App") {
                        isShowingComposer = true
                    }.fullScreenCover(isPresented: $isShowingComposer) {
                        MailComposeView()
                            .edgesIgnoringSafeArea(.all)
                    }
                } else {
                    Text("This device cannot send mail in-app.")
                        .foregroundStyle(.secondary)
                }
                #endif

                Link("Open a mailto: Link", destination: mailtoURL())
            }
        }
        .navigationTitle("Mail & Camera")
    }

    func mailtoURL() -> URL {
        var res = MailtoComponents()
        res.recipient = "foo@bar.tld"
        res.subject = "Test Subject"
        res.body = """
        Dear Mr. Doe,

        Wouldn't you agree this library is awesome?
        """

        guard let resultURL = res.url else {
            fatalError("Invalid mailto URL")
        }

        return resultURL
    }
}

#Preview {
    ContentView()
}
