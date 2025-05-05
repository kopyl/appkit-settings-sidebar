import Cocoa

class WindowConfig {
    static let width: CGFloat = 659
    static let height: CGFloat = 800
    static let sidebarFixedWidth: CGFloat = 215
}

enum SidebarItem: String, CaseIterable {
    case shortcut = "Shortcut"
    case appearance = "Appearance"
    
    var icon: NSImageView {
        let imageName = "\(self.rawValue)-icon"
        let image = NSImage(named: NSImage.Name(imageName)) ?? NSImage()
        return NSImageView(image: image)
    }
    
    var viewController: NSViewController {
        switch self {
        case .shortcut:
            return ShortcutViewController()
        case .appearance:
            return AppearanceViewController()
        }
    }
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
        let textLabel = NSTextField(labelWithString: items[row].rawValue)
        let imageView = items[row].icon
        
        let stackView = NSStackView(views: [imageView, textLabel])
        stackView.spacing = 5
        stackView.heightAnchor.constraint(equalToConstant: tableView.rowHeight).isActive = true
        
        return stackView
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let selectedIndex = tableView.selectedRow
        guard selectedIndex >= 0 else { return }
        delegate?.didSelectSidebarItem(items[selectedIndex])
    }
}

class ShortcutViewController: NSViewController {
    override func loadView() {
        self.view = ShortcutView()
    }
}

class AppearanceViewController: NSViewController {
    override func loadView() {
        self.view = AppearanceView()
    }
}

class SplitViewController: NSSplitViewController, SidebarSelectionDelegate {
    
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
        
        let detailItem = NSSplitViewItem(viewController: SidebarItem.shortcut.viewController)
        addSplitViewItem(detailItem)
    }

    func didSelectSidebarItem(_ item: SidebarItem) {
        removeSplitViewItem(splitViewItems[1])
        let newDetailItem = NSSplitViewItem(viewController: item.viewController)
        addSplitViewItem(newDetailItem)
    }
}

var mainWindow: NSWindow?

func addPaddingToWindowButtons(leading: CGFloat, top: CGFloat) {
    DispatchQueue.main.async {
        guard let window = mainWindow,
              let buttonContainer = window.standardWindowButton(.closeButton)?.superview else {
            return
        }
        
        var frame = buttonContainer.frame
        frame.origin.x += leading
        frame.origin.y -= top
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
    mainWindow?.contentViewController = SplitViewController()
    mainWindow?.titlebarAppearsTransparent = true
    
    addPaddingToWindowButtons(leading: 12, top: 12)
    
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
    SplitViewController()
}
