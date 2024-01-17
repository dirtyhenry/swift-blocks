import Blocks
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    enum Section: String, Identifiable, CaseIterable {
        case misc = "Misc"
        case fonts = "Fonts"
        case bg = "Background test"
        case fileSystemExplorer = "FileSystem Explorer"
        case plainDateDemo = "PlainDate demo"
        case taskStateDemo = "TaskState demo"

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
        } detail: {
            if let selectedSectionId,
               let section = Section(rawValue: selectedSectionId) {
                switch section {
                case .misc:
                    VStack {
                        Text("Is a watch paired with this iPhone?")
                        Text(model.state.rawValue)
                        Spacer().frame(height: 16)
                        Button("Photo", role: nil) {
                            isShowingCamera = true
                        }.fullScreenCover(isPresented: $isShowingCamera) {
                            // In order to use this, `NSCameraUsageDescription` must be set.
                            ImagePickerView(sourceType: .camera, mediaTypes: [UTType.image.identifier])
                                .edgesIgnoringSafeArea(.all)
                        }
                        Spacer().frame(height: 16)

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

                        Link("Alternative mailto", destination: mailtoURL())
                    }
                    .padding()
                case .fonts:
                    FontsView()
                case .bg:
                    BackgroundTaskView()
                case .fileSystemExplorer:
                    Button("Explore") {
                        explore()
                    }
                case .plainDateDemo:
                    PlainDateDemoView()
                case .taskStateDemo:
                    TaskStateDemoView()
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
