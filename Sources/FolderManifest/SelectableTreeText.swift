import AppKit
import SwiftUI

struct SelectableTreeText: NSViewRepresentable {
    let text: NSAttributedString
    let searchTitle: String
    let copyTitle: String
    let onSearch: (String) -> Void
    let onDoubleClick: () -> Void

    func makeNSView(context: Context) -> SelectableTreeTextView {
        let textView = SelectableTreeTextView()
        update(textView)
        return textView
    }

    func updateNSView(_ nsView: SelectableTreeTextView, context: Context) {
        update(nsView)
    }

    func sizeThatFits(
        _ proposal: ProposedViewSize,
        nsView: SelectableTreeTextView,
        context: Context
    ) -> CGSize? {
        nsView.intrinsicContentSize
    }

    private func update(_ textView: SelectableTreeTextView) {
        textView.searchTitle = searchTitle
        textView.copyTitle = copyTitle
        textView.onSearch = onSearch
        textView.onDoubleClick = onDoubleClick

        guard !textView.attributedString().isEqual(to: text) else { return }
        textView.textStorage?.setAttributedString(text)
        textView.invalidateIntrinsicContentSize()
    }
}

final class SelectableTreeTextView: NSTextView {
    var searchTitle = "Search"
    var copyTitle = "Copy"
    var onSearch: ((String) -> Void)?
    var onDoubleClick: (() -> Void)?
    private var ownedTextStorage: NSTextStorage?

    override init(frame frameRect: NSRect, textContainer container: NSTextContainer?) {
        let resolvedContainer: NSTextContainer
        let textStorage: NSTextStorage?
        if let container {
            resolvedContainer = container
            textStorage = nil
        } else {
            let storage = NSTextStorage()
            let layoutManager = NSLayoutManager()
            let newContainer = NSTextContainer(size: NSSize(width: 1_000_000, height: 1_000))
            storage.addLayoutManager(layoutManager)
            layoutManager.addTextContainer(newContainer)
            resolvedContainer = newContainer
            textStorage = storage
        }

        super.init(frame: frameRect, textContainer: resolvedContainer)
        ownedTextStorage = textStorage
        configure()
    }

    convenience init() {
        self.init(frame: .zero, textContainer: nil)
    }

    private func configure() {
        isEditable = false
        isSelectable = true
        drawsBackground = false
        isRichText = true
        importsGraphics = false
        textContainerInset = .zero
        textContainer?.lineFragmentPadding = 0
        textContainer?.lineBreakMode = .byClipping
        textContainer?.containerSize = NSSize(width: 1_000_000, height: 1_000)
        textContainer?.widthTracksTextView = false
        textContainer?.heightTracksTextView = false
        isHorizontallyResizable = true
        isVerticallyResizable = false
        setContentHuggingPriority(.required, for: .horizontal)
        setContentHuggingPriority(.required, for: .vertical)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: NSSize {
        let bounds = attributedString().boundingRect(
            with: NSSize(width: 1_000_000, height: 1_000),
            options: [.usesLineFragmentOrigin, .usesFontLeading]
        )
        return NSSize(width: ceil(bounds.width) + 1, height: ceil(bounds.height))
    }

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        if event.clickCount == 2 {
            onDoubleClick?()
        }
    }

    override func menu(for event: NSEvent) -> NSMenu? {
        guard selectedText != nil else { return super.menu(for: event) }

        let menu = NSMenu()
        let searchItem = NSMenuItem(
            title: searchTitle,
            action: #selector(searchSelectedText),
            keyEquivalent: ""
        )
        searchItem.image = NSImage(systemSymbolName: "magnifyingglass", accessibilityDescription: searchTitle)
        searchItem.target = self
        menu.addItem(searchItem)

        let copyItem = NSMenuItem(
            title: copyTitle,
            action: #selector(copySelectedText),
            keyEquivalent: ""
        )
        copyItem.image = NSImage(systemSymbolName: "doc.on.doc", accessibilityDescription: copyTitle)
        copyItem.target = self
        menu.addItem(copyItem)
        return menu
    }

    private var selectedText: String? {
        let range = selectedRange()
        guard range.length > 0, NSMaxRange(range) <= (string as NSString).length else { return nil }
        return (string as NSString).substring(with: range)
    }

    @objc private func searchSelectedText() {
        guard let selectedText else { return }
        onSearch?(selectedText)
    }

    @objc private func copySelectedText() {
        guard let selectedText else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(selectedText, forType: .string)
    }
}
