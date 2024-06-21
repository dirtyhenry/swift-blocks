import Blocks
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    enum Section: String, Identifiable, CaseIterable {
        case taskStateDemo = "TaskState demo"
        case misc = "Misc"
        case fonts = "Fonts"
        #if os(iOS)
        case bg = "Background test"
        #endif
        case fileSystemExplorer = "FileSystem Explorer"
        case plainDateDemo = "PlainDate demo"
        case loggingPlayground = "Logging Playground"

        var id: String {
            rawValue
        }
    }

    @ObservedObject var model: WatchState

    @State var isShowingCamera: Bool = false
    @State var isShowingComposer: Bool = false

    @State var selectedSectionId: Section.ID?

    init(model: WatchState) {
        self.model = model
    }

    var body: some View {
        NavigationSplitView {
            Text("🧱 Welcome to Blocks!")
            List(Section.allCases, selection: $selectedSectionId) { section in
                Text(section.id)
            }
            #if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                #endif
                ToolbarItem {
                    Button("Hey") {
                        print("Hey")
                    }
                }
            }
        } detail: {
            if let selectedSectionId, let section = Section(rawValue: selectedSectionId) {
                switch section {
                case .misc:
                    VStack {
                        Text("Is a watch paired with this iPhone?")
                        Text(model.state.rawValue)
                        Spacer().frame(height: 16)
                        #if os(iOS) || os(tvOS)
                        Button("Photo", role: nil) {
                            isShowingCamera = true
                        }.fullScreenCover(isPresented: $isShowingCamera) {
                            // In order to use this, `NSCameraUsageDescription` must be set.
                            ImagePickerView(sourceType: .camera, mediaTypes: [UTType.image.identifier])
                                .edgesIgnoringSafeArea(.all)
                        }
                        Spacer().frame(height: 16)
                        #endif

                        #if canImport(MessageUI)
                        if MailComposeView.canSendMail() {
                            Button("Mail", role: nil) {
                                isShowingComposer = true
                            }.fullScreenCover(isPresented: $isShowingComposer) {
                                MailComposeView()
                                    .edgesIgnoringSafeArea(.all)
                            }
                        } else {
                            Text("Can not send mail in-app.")
                        }
                        #endif

                        Link("Alternative mailto", destination: mailtoURL())
                    }
                    .padding()
                case .fonts:
                    FontsView()
                #if os(iOS)
                case .bg:
                    BackgroundTaskView()
                #endif
                case .fileSystemExplorer:
                    Button("Explore") {
                        explore()
                    }
                case .plainDateDemo:
                    PlainDateDemoView()
                case .taskStateDemo:
                    TaskStateDemoView()
                case .loggingPlayground:
                    LoggingPlaygroundView()
                }
            } else {
                Text("Select a section")
            }
        }
        .onAppear {
            model.start()
        }
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(model: WatchState())
    }
}
