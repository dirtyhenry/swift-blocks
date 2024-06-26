import UIKit

class StereogumTop2016Presenter {
    struct TopAlbum {
        var rank: Int
        var artistName: String
        var albumName: String
        var labelName: String
    }

    var albums: [TopAlbum] = []
    var tableViewController: ItemsTableViewController<TopAlbum, UITableViewCell>?
    var collectionViewController: ItemsCollectionViewController<TopAlbum, AlbumCollectionViewCell>?

    init() {
        loadAlbums()

        tableViewController = ItemsTableViewController(items: albums, configure: { cell, album in
            cell.textLabel?.text = "\(album.rank). \(album.artistName)"
        })
        tableViewController?.title = "Stereogum Top Albums 2016"

        let collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.scrollDirection = .vertical
        let halfScreenWidth = UIScreen.main.applicationFrame.size.width / 2.0
        collectionViewLayout.itemSize = CGSize(width: halfScreenWidth, height: halfScreenWidth)
        collectionViewLayout.minimumLineSpacing = 0.0
        collectionViewLayout.minimumInteritemSpacing = 0.0

        collectionViewController = ItemsCollectionViewController(collectionViewLayout: collectionViewLayout, items: albums, configure: { cell, album in
            cell.artistLabel.text = album.artistName
            cell.rankLabel.text = String(album.rank)
        })
    }

    func loadAlbums() {
        var result: [TopAlbum] = []

        do {
            if let url = Bundle.main.url(forResource: "2016-stereogum-best-albums", withExtension: "json") {
                let jsonData = try Data(contentsOf: url)
                let jsonResult = try JSONSerialization.jsonObject(with: jsonData)
                let jsonAlbums = jsonResult as! [[String: Any]]
                for jsonAlbum in jsonAlbums {
                    let albumName = jsonAlbum["Album Title"] as! String
                    let artistName = jsonAlbum["Artist"] as! String
                    let labelName = jsonAlbum["Label"] as! String
                    let rank = jsonAlbum["Rank"] as! Int

                    result.append(TopAlbum(rank: rank, artistName: artistName, albumName: albumName, labelName: labelName))
                }
            }
        } catch {
            debugPrint("JSON parsing failed")
        }

        albums = result
    }
}
