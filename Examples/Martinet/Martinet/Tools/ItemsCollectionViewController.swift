import UIKit

private let reuseIdentifier = "Cell"

open class ItemsCollectionViewController<Item, Cell: UICollectionViewCell>: UICollectionViewController {
    var items: [Item] = []
    var configure: (Cell, Item) -> Void = { _, _ in }
    var didSelect: (Item) -> Void = { _ in }
    let reuseIdentifier = "reuseIdentifier"

    public init(collectionViewLayout: UICollectionViewLayout, items: [Item], configure: @escaping (Cell, Item) -> Void) {
        self.configure = configure
        super.init(collectionViewLayout: collectionViewLayout)
        self.items = items
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func viewDidLoad() {
        super.viewDidLoad()

        // Register cell classes
        // self.collectionView!.register(Cell.self, forCellWithReuseIdentifier: reuseIdentifier)
        collectionView?.register(UINib(nibName: "AlbumCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: reuseIdentifier)
    }

    // MARK: UICollectionViewDataSource

    override open func numberOfSections(in _: UICollectionView) -> Int {
        1
    }

    override open func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        items.count
    }

    override open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! Cell

        // Configure the cell
        let item = items[indexPath.row]
        configure(cell, item)

        return cell
    }

    // MARK: UICollectionViewDelegate

    override open func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        didSelect(item)
    }
}
