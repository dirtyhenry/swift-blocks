import UIKit

class LargerItemsTableViewController: ItemsTableViewController<String, UITableViewCell> {
    override func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        100
    }
}

class DemoAsyncDownloadsPresenter {
    var viewController: LargerItemsTableViewController?

    var items = [
        "5",
        "10",
        "15",
        "20",
        "25",
        "30",
        "35",
        "40",
        "45",
        "50",
        "55",
        "60",
        "65",
        "70",
        "75",
        "80",
        "85",
        "90",
        "95",
        "100",
        "105",
        "110",
        "115",
        "120",
        "125",
        "130",
        "135",
        "140",
        "145",
        "150",
        "155",
        "160",
        "165",
        "170",
        "175",
        "180",
        "185",
        "190",
        "195",
        "200"
    ]

    init() {
        viewController = LargerItemsTableViewController(items: items, configure: { cell, item in
            if let myURL = URL(string: "https://placehold.it/\(item)x100") {
                cell.layer.setValue(myURL, forKey: "myURL")
                cell.textLabel?.text = myURL.absoluteString
                let hueVal = Double(item) ?? 200.0
                let hueValFloat = CGFloat(hueVal / 200.0)
                cell.backgroundColor = UIColor(hue: hueValFloat, saturation: 0.7, brightness: 0.7, alpha: 1.0)
                cell.imageView?.image = nil // Comment to activate "blinking"

                // Download image from URL asynchronously
                URLSession.shared.dataTask(with: myURL) { data, _, error in
                    guard let fetchedData = data, error == nil else {
                        debugPrint("Error")
                        return
                    }
                    DispatchQueue.main.async { () in
                        let myCachedURL = cell.layer.value(forKey: "myURL") as? URL

                        if myCachedURL == myURL { // If cell url still matches downloaded image url, set to imageView. Otherwise discard (or cache)
                            cell.imageView?.image = UIImage(data: fetchedData)
                            cell.setNeedsLayout()
                        } else {
                            debugPrint("\(myCachedURL) != \(myURL)")
                        }
                    }
                }.resume()
            }
        })
    }
}
