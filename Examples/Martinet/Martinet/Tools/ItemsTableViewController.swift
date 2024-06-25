import UIKit

open class ItemsTableViewController<Item, Cell: UITableViewCell>: UITableViewController {
    var items: [Item] = []
    let reuseIdentifier = "reuseIdentifier"
    let configure: (Cell, Item) -> Void
    public var didSelect: (Item) -> Void = { _ in }

    public init(items: [Item], configure: @escaping (Cell, Item) -> Void) {
        self.configure = configure
        super.init(style: .plain)
        self.items = items
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(Cell.self, forCellReuseIdentifier: reuseIdentifier)
    }

    // MARK: - Table view data source

    override open func numberOfSections(in _: UITableView) -> Int {
        1
    }

    override open func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        items.count
    }

    override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! Cell
        let item = items[indexPath.row]
        configure(cell, item)
        return cell
    }

    override open func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        didSelect(item)
    }
}
