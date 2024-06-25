import UIKit

enum DemoMenuItem: String {
    case StereogumTopAlbums2016Table = "Stereogum Top Albums 2016 (table)"
    case StereogumTopAlbums2016Collection = "Stereogum Top Albums 2016 (collection)"
    case DemoAsyncDownloads = "Demo Async Downloads"
}

class AppRoute: NSObject {
    let navigationController: UINavigationController
    let storyboard: UIStoryboard
    var alertController: AppDomainStatusBarController?

    init(window: UIWindow) {
        navigationController = window.rootViewController as! UINavigationController
        storyboard = UIStoryboard(name: "Main", bundle: nil)
        super.init()
        pushMenuViewController()

        alertController = AppDomainStatusBarController(window: window)
        alertController?.setup()
    }

    func pushMenuViewController() {
        let items: [DemoMenuItem] = [
            .StereogumTopAlbums2016Table,
            .StereogumTopAlbums2016Collection,
            .DemoAsyncDownloads
        ]

        let rootViewController = ItemsTableViewController(items: items, configure: { cell, item in
            cell.textLabel?.text = item.rawValue
        })
        rootViewController.title = "Martinet's Menu"
        rootViewController.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Toggle Alert", style: .plain, target: self, action: #selector(toggleAlertView(sender:)))

        rootViewController.didSelect = { menuItem in
            switch menuItem {
            case .StereogumTopAlbums2016Table:
                let stereogumTop = StereogumTop2016Presenter()
                if let stereogumVC = stereogumTop.tableViewController {
                    self.navigationController.modalPresentationStyle = .overCurrentContext
                    self.navigationController.pushViewController(stereogumVC, animated: true)
                }

            case .StereogumTopAlbums2016Collection:
                let stereogumTop = StereogumTop2016Presenter()
                if let stereogumVC = stereogumTop.collectionViewController {
                    self.navigationController.modalPresentationStyle = .overCurrentContext
                    self.navigationController.pushViewController(stereogumVC, animated: true)
                }

            case .DemoAsyncDownloads:
                let demoAsyncDownloads = DemoAsyncDownloadsPresenter()
                if let demoAyncDownloadsVC = demoAsyncDownloads.viewController {
                    self.navigationController.pushViewController(demoAyncDownloadsVC, animated: true)
                }
            }
        }

        navigationController.pushViewController(rootViewController, animated: false)
    }

    @objc func toggleAlertView(sender: Any) {
        alertController?.toggleAlertView(sender: sender)
    }
}
