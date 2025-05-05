import Cocoa

class WindowConfig {
    static let width: CGFloat = 659
    static let height: CGFloat = 800
    static let sidebarFixedWidth: CGFloat = 215
}

enum SidebarItem: String, CaseIterable {
    case shortcut = "Shortcut"
    case appearance = "Appearance"
}

func getIcon(for item: SidebarItem) -> NSImageView {
    var imageName: String
    switch item {
    case .shortcut:
        imageName = "shortcut-icon"
    case .appearance:
        imageName = "appearance-icon"
    }
    let image = NSImage(named: NSImage.Name(imageName)) ?? NSImage()
    let imageView = NSImageView(image: image)
    return imageView
}

protocol SidebarSelectionDelegate: AnyObject {
    func didSelectSidebarItem(_ item: SidebarItem)
}

class ShortcutView: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupView() {
        frame = NSRect(x: 0, y: 0, width: WindowConfig.width, height: WindowConfig.height)
        wantsLayer = true
        
        let textLabel = NSTextField(labelWithString: "Shortcut")
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textLabel)
        
        NSLayoutConstraint.activate([
            textLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            textLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
}

class AppearanceView: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupView() {
        frame = NSRect(x: 0, y: 0, width: WindowConfig.width, height: WindowConfig.height)
        wantsLayer = true
        
        let textLabel = NSTextField(labelWithString: "Appearance")
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textLabel)
        
        NSLayoutConstraint.activate([
            textLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            textLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
}

class SidebarViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    weak var delegate: SidebarSelectionDelegate?
    
    private let tableView = NSTableView()
    private let items = SidebarItem.allCases

    override func loadView() {
        self.view = NSView()

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Column"))
        tableView.addTableColumn(column)
        tableView.headerView = nil
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.rowHeight = 28
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        tableView.focusRingType = .none
        
        DispatchQueue.main.async {
            self.tableView.selectRowIndexes([0], byExtendingSelection: false)
        }

        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: 43),
        ])
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        return items.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let item = items[row]
        
        let textLabel = NSTextField(labelWithString: item.rawValue)
        textLabel.isBordered = false
        textLabel.drawsBackground = false
        
        let imageView = getIcon(for: items[row])
        
        let stackView = NSStackView(views: [imageView, textLabel])
        stackView.orientation = .horizontal
        stackView.spacing = 5
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.heightAnchor.constraint(equalToConstant: tableView.rowHeight).isActive = true
        
        return stackView
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let selectedIndex = tableView.selectedRow
        guard selectedIndex >= 0 else { return }
        delegate?.didSelectSidebarItem(items[selectedIndex])
    }
}

class DetailViewController: NSViewController {
    override func loadView() {
        self.view = ShortcutView()
    }
}

class AppearanceViewController: NSViewController {
    override func loadView() {
        self.view = AppearanceView()
    }
}

class MainSplitViewController: NSSplitViewController, SidebarSelectionDelegate {
    private var currentDetailVC: NSViewController?
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: WindowConfig.width, height: WindowConfig.height))
        super.loadView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let sidebarVC = SidebarViewController()
        sidebarVC.delegate = self

        let sidebarItem = NSSplitViewItem(sidebarWithViewController: sidebarVC)
        sidebarItem.minimumThickness = WindowConfig.sidebarFixedWidth
        sidebarItem.maximumThickness = WindowConfig.sidebarFixedWidth
        sidebarItem.canCollapse = false
        addSplitViewItem(sidebarItem)

        let initialDetailVC = viewController(for: .shortcut)
        let detailItem = NSSplitViewItem(viewController: initialDetailVC)
        addSplitViewItem(detailItem)
        currentDetailVC = initialDetailVC
    }

    func didSelectSidebarItem(_ item: SidebarItem) {
        let newVC = viewController(for: item)

        removeSplitViewItem(splitViewItems[1])
        let newDetailItem = NSSplitViewItem(viewController: newVC)
        addSplitViewItem(newDetailItem)
        currentDetailVC = newVC
    }

    private func viewController(for item: SidebarItem) -> NSViewController {
        switch item {
        case .shortcut:
            return DetailViewController()
        case .appearance:
            return AppearanceViewController()
        }
    }
}

var mainWindow: NSWindow?

func addPaddingToWindowButtons() {
    DispatchQueue.main.async {
        guard let window = mainWindow,
              let buttonContainer = window.standardWindowButton(.closeButton)?.superview else {
            return
        }
        
        var frame = buttonContainer.frame
        frame.origin.x += 12
        frame.origin.y -= 12
        buttonContainer.frame = frame
    }
}

func createMainWindow() {
    mainWindow = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: WindowConfig.width, height: WindowConfig.height),
        styleMask: [.titled, .closable, .fullSizeContentView],
        backing: .buffered, defer: false
    )
    mainWindow?.center()
    mainWindow?.contentViewController = MainSplitViewController()
    mainWindow?.titlebarAppearsTransparent = true
    
    addPaddingToWindowButtons()
    
    let _ = NSWindowController(window: mainWindow)
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        createMainWindow()
        
        mainWindow?.makeKeyAndOrderFront(nil)
    }
}

let app = Application.shared
let delegate = AppDelegate()
app.delegate = delegate

app.run()

#Preview {
    MainSplitViewController()
}
