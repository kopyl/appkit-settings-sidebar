import Cocoa

class WindowConfig {
    static let width: CGFloat = 659
    static let height: CGFloat = 800
    static let sidebarFixedWidth: CGFloat = 215
}

enum SidebarItem: String, CaseIterable {
    case home = "Home"
    case settings = "Settings"
}

protocol SidebarSelectionDelegate: AnyObject {
    func didSelectSidebarItem(_ item: SidebarItem)
}

class MainWindowView: NSView {
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
        
        let textLabel = NSTextField(labelWithString: "Main")
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textLabel)
        
        NSLayoutConstraint.activate([
            textLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            textLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
}

class SettingsView: NSView {
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
        
        let textLabel = NSTextField(labelWithString: "Settings")
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
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        tableView.focusRingType = .none

        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: 50),
        ])
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        return items.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let item = items[row]
        let cell = NSTextField(labelWithString: item.rawValue)
        cell.isBordered = false
        cell.drawsBackground = false
        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        let selectedIndex = tableView.selectedRow
        guard selectedIndex >= 0 else { return }
        delegate?.didSelectSidebarItem(items[selectedIndex])
    }
}

class DetailViewController: NSViewController {
    override func loadView() {
        self.view = MainWindowView()
    }
}

class SettingsViewController: NSViewController {
    override func loadView() {
        self.view = SettingsView()
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

        let initialDetailVC = viewController(for: .home)
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
        case .home:
            return DetailViewController()
        case .settings:
            return SettingsViewController()
        }
    }
}

var mainWindow: NSWindow?

let titlebarAccessory = NSTitlebarAccessoryViewController()
titlebarAccessory.layoutAttribute = .top

let customTitlebarView = NSView()
customTitlebarView.translatesAutoresizingMaskIntoConstraints = false

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
        styleMask: [.titled, .closable, .fullSizeContentView, .unifiedTitleAndToolbar],
        backing: .buffered, defer: false
    )
    mainWindow?.center()
    mainWindow?.titleVisibility = .hidden
    
    mainWindow?.contentViewController = MainSplitViewController()
    
    mainWindow?.titlebarAppearsTransparent = true
    
    mainWindow?.addTitlebarAccessoryViewController(titlebarAccessory)
    mainWindow?.titlebarSeparatorStyle = .none
    
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
