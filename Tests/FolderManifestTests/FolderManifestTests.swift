import Foundation
import XCTest
@testable import FolderManifest

final class FolderManifestTests: XCTestCase {
    @MainActor
    func testSelectableTreeTextViewHasVisibleSizeAfterReceivingText() {
        let textView = SelectableTreeTextView()
        textView.textStorage?.setAttributedString(NSAttributedString(string: "└── report.pdf"))
        textView.invalidateIntrinsicContentSize()

        XCTAssertTrue(textView.isSelectable)
        XCTAssertFalse(textView.isEditable)
        XCTAssertFalse(textView.drawsBackground)
        XCTAssertGreaterThan(textView.intrinsicContentSize.width, 1)
        XCTAssertGreaterThan(textView.intrinsicContentSize.height, 1)
    }

    func testAllSupportedLanguagesProvideLocalizedInterfaceText() {
        XCTAssertEqual(AppLanguage.allCases.count, 9)
        XCTAssertEqual(Set(AppLanguage.allCases.map(\.displayName)).count, 9)

        for language in AppLanguage.allCases {
            let strings = AppStrings(language: language)
            XCTAssertFalse(strings.settings.isEmpty)
            XCTAssertFalse(strings.showMainWindow.isEmpty)
            XCTAssertFalse(strings.recentlyOpened.isEmpty)
            XCTAssertFalse(strings.noRecentFolders.isEmpty)
            XCTAssertFalse(strings.pinnedCountPrefix.isEmpty)
            XCTAssertFalse(strings.pinFolder.isEmpty)
            XCTAssertFalse(strings.unpinFolder.isEmpty)
            XCTAssertFalse(strings.pinnedLimitReached.isEmpty)
            XCTAssertFalse(strings.movePinnedUp.isEmpty)
            XCTAssertFalse(strings.movePinnedDown.isEmpty)
            XCTAssertFalse(strings.selectFolder.isEmpty)
            XCTAssertFalse(strings.searchPlaceholder.isEmpty)
            XCTAssertFalse(strings.search.isEmpty)
            XCTAssertFalse(strings.previous.isEmpty)
            XCTAssertFalse(strings.next.isEmpty)
            XCTAssertFalse(strings.scanFinished.isEmpty)
            XCTAssertFalse(strings.discoveredItems(1).isEmpty)
            XCTAssertFalse(strings.totalDiscoveredItems(1).isEmpty)
            XCTAssertFalse(strings.matchPosition(1, total: 2).isEmpty)
            XCTAssertFalse(strings.exportPanelTitle.isEmpty)
        }
    }

    @MainActor
    func testRecentFolderStorePersistsSnapshotsAndKeepsMostRecentFirst() throws {
        let storageURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("RecentFolders.plist")
        defer { try? FileManager.default.removeItem(at: storageURL.deletingLastPathComponent()) }

        let firstURL = URL(fileURLWithPath: "/tmp/first", isDirectory: true)
        let secondURL = URL(fileURLWithPath: "/tmp/second", isDirectory: true)
        let firstSnapshot = testSnapshot(rootName: "first")
        let secondSnapshot = testSnapshot(rootName: "second")
        let store = RecentFolderStore(storageURL: storageURL)

        store.record(url: firstURL, snapshot: firstSnapshot, options: ScanOptions())
        store.record(url: secondURL, snapshot: secondSnapshot, options: ScanOptions())

        XCTAssertEqual(store.entries.map(\.name), ["second", "first"])
        XCTAssertEqual(store.entries[1].snapshot, firstSnapshot)

        let reloadedStore = RecentFolderStore(storageURL: storageURL)
        XCTAssertEqual(reloadedStore.entries.map(\.name), ["second", "first"])
        XCTAssertEqual(reloadedStore.entries[0].snapshot, secondSnapshot)

        reloadedStore.touch(reloadedStore.entries[1])
        XCTAssertEqual(reloadedStore.entries.map(\.name), ["first", "second"])
    }

    @MainActor
    func testPinnedRecentFoldersStayAboveNewAndCanBeReordered() {
        let storageURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("RecentFolders.plist")
        defer { try? FileManager.default.removeItem(at: storageURL.deletingLastPathComponent()) }
        let store = RecentFolderStore(storageURL: storageURL)

        for name in ["first", "second", "third"] {
            store.record(
                url: URL(fileURLWithPath: "/tmp/\(name)", isDirectory: true),
                snapshot: testSnapshot(rootName: name),
                options: ScanOptions()
            )
        }

        let firstPath = store.entries.first { $0.name == "first" }!.path
        let secondPath = store.entries.first { $0.name == "second" }!.path
        store.togglePin(path: firstPath)
        store.togglePin(path: secondPath)
        store.record(
            url: URL(fileURLWithPath: "/tmp/fourth", isDirectory: true),
            snapshot: testSnapshot(rootName: "fourth"),
            options: ScanOptions()
        )

        XCTAssertEqual(store.entries.map(\.name), ["first", "second", "fourth", "third"])
        XCTAssertEqual(store.entries.map(\.isPinned), [true, true, false, false])
        XCTAssertTrue(store.canMovePinned(path: secondPath, by: -1))

        store.movePinned(path: secondPath, by: -1)
        XCTAssertEqual(store.entries.map(\.name), ["second", "first", "fourth", "third"])

        store.touch(store.entries.last!)
        XCTAssertEqual(store.entries.map(\.name), ["second", "first", "third", "fourth"])
    }

    @MainActor
    func testRecentFolderStoreKeepsTwentyFiveUnpinnedFolders() {
        let storageURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("RecentFolders.plist")
        defer { try? FileManager.default.removeItem(at: storageURL.deletingLastPathComponent()) }
        let store = RecentFolderStore(storageURL: storageURL)

        for index in 1...30 {
            let name = "folder-\(index)"
            store.record(
                url: URL(fileURLWithPath: "/tmp/\(name)", isDirectory: true),
                snapshot: testSnapshot(rootName: name),
                options: ScanOptions()
            )
        }

        XCTAssertEqual(store.entries.count, 25)
        XCTAssertEqual(store.entries.first?.name, "folder-30")
        XCTAssertEqual(store.entries.last?.name, "folder-6")
    }

    @MainActor
    func testPinnedFolderLimitIsTwentyFiveAndUnpinRestoresPinning() {
        let storageURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("RecentFolders.plist")
        defer { try? FileManager.default.removeItem(at: storageURL.deletingLastPathComponent()) }
        let store = RecentFolderStore(storageURL: storageURL)

        for index in 1...25 {
            let name = "pinned-\(index)"
            store.record(
                url: URL(fileURLWithPath: "/tmp/\(name)", isDirectory: true),
                snapshot: testSnapshot(rootName: name),
                options: ScanOptions()
            )
            let path = store.entries.first { $0.name == name }!.path
            store.togglePin(path: path)
        }

        store.record(
            url: URL(fileURLWithPath: "/tmp/candidate", isDirectory: true),
            snapshot: testSnapshot(rootName: "candidate"),
            options: ScanOptions()
        )
        let candidatePath = store.entries.first { $0.name == "candidate" }!.path

        XCTAssertEqual(store.pinnedFolderCount, 25)
        XCTAssertFalse(store.canTogglePin(path: candidatePath))
        store.togglePin(path: candidatePath)
        XCTAssertFalse(store.entries.first { $0.path == candidatePath }!.isPinned)

        let pinnedPath = store.entries.first { $0.isPinned }!.path
        store.togglePin(path: pinnedPath)
        XCTAssertEqual(store.pinnedFolderCount, 24)
        XCTAssertTrue(store.canTogglePin(path: candidatePath))
        store.togglePin(path: candidatePath)
        XCTAssertEqual(store.pinnedFolderCount, 25)
        XCTAssertTrue(store.entries.first { $0.path == candidatePath }!.isPinned)
    }

    private func testSnapshot(rootName: String) -> ManifestSnapshot {
        ManifestSnapshot(
            root: ManifestNode(
                id: rootName,
                name: rootName,
                isDirectory: true,
                size: 0,
                modifiedDate: nil,
                children: []
            ),
            skippedCount: 0
        )
    }

    @MainActor
    func testLanguageSelectionPersists() {
        let suiteName = "FolderManifestTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settings = LanguageSettings(defaults: defaults)
        settings.language = .portugueseBrazil

        XCTAssertEqual(LanguageSettings(defaults: defaults).language, .portugueseBrazil)
    }

    func testScannerBuildsTreeAndSkipsHiddenFiles() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let subfolder = root.appendingPathComponent("资料")
        try FileManager.default.createDirectory(at: subfolder, withIntermediateDirectories: true)
        try Data("hello".utf8).write(to: root.appendingPathComponent("说明.txt"))
        try Data("secret".utf8).write(to: root.appendingPathComponent(".secret"))
        try Data("pdf".utf8).write(to: subfolder.appendingPathComponent("课程.pdf"))
        defer { try? FileManager.default.removeItem(at: root) }

        let progress = ScanProgressRecorder()
        let snapshot = try FolderScanner().scan(url: root, options: ScanOptions()) {
            progress.record($0)
        }

        XCTAssertEqual(snapshot.fileCount, 2)
        XCTAssertEqual(snapshot.folderCount, 1)
        XCTAssertFalse(snapshot.root.children.contains { $0.name == ".secret" })
        XCTAssertEqual(progress.values.last, snapshot.fileCount + snapshot.folderCount)
        XCTAssertEqual(progress.values, progress.values.sorted())
    }

    func testRendererProducesStructuredTreeRowsAndMatchingTXT() {
        let file = ManifestNode(
            id: "root/file.txt",
            name: "file.txt",
            isDirectory: false,
            size: 1024,
            modifiedDate: nil,
            children: []
        )
        let root = ManifestNode(
            id: "root",
            name: "root",
            isDirectory: true,
            size: 0,
            modifiedDate: nil,
            children: [file]
        )
        let snapshot = ManifestSnapshot(root: root, skippedCount: 0)
        let display = DisplayOptions(showFileSize: true, showModifiedDate: false, showFileCount: true)

        let renderer = ManifestRenderer()
        let rows = renderer.treeRows(snapshot: snapshot, display: display)
        let tree = renderer.render(snapshot: snapshot, display: display)

        XCTAssertEqual(rows.map(\.id), ["root", "root/file.txt"])
        XCTAssertEqual(rows.map(\.text).joined(separator: "\n"), tree)
        XCTAssertEqual(rows[0].connectorSegments, [])
        XCTAssertEqual(rows[1].connectorSegments, [.lastBranch])
        XCTAssertEqual(
            rows[1].visibleText,
            String(rows[1].text.dropFirst(rows[1].prefix.count))
        )
        XCTAssertTrue(tree.contains("└── file.txt"))
        XCTAssertTrue(tree.contains("1 个文件"))
    }

    func testManifestOrderingSortsEachFolderEntirelyInMemory() {
        let nestedB = ManifestNode(id: "root/folder/b.txt", name: "b.txt", isDirectory: false, size: 5, modifiedDate: nil, children: [])
        let nestedA = ManifestNode(id: "root/folder/a.txt", name: "a.txt", isDirectory: false, size: 10, modifiedDate: nil, children: [])
        let folder = ManifestNode(id: "root/folder", name: "folder", isDirectory: true, size: 0, modifiedDate: nil, children: [nestedB, nestedA])
        let smallFile = ManifestNode(id: "root/small.pdf", name: "small.pdf", isDirectory: false, size: 20, modifiedDate: nil, children: [])
        let largeFile = ManifestNode(id: "root/large.txt", name: "large.txt", isDirectory: false, size: 100, modifiedDate: nil, children: [])
        let root = ManifestNode(id: "root", name: "root", isDirectory: true, size: 0, modifiedDate: nil, children: [smallFile, largeFile, folder])
        let snapshot = ManifestSnapshot(root: root, skippedCount: 0)

        var nameOptions = ScanOptions()
        nameOptions.sort = .name
        let nameSorted = ManifestOrdering.sorted(snapshot: snapshot, options: nameOptions)
        XCTAssertEqual(nameSorted.root.children.map(\.name), ["folder", "large.txt", "small.pdf"])
        XCTAssertEqual(nameSorted.root.children[0].children.map(\.name), ["a.txt", "b.txt"])

        var sizeOptions = ScanOptions()
        sizeOptions.foldersFirst = false
        sizeOptions.sort = .size
        let sizeSorted = ManifestOrdering.sorted(snapshot: snapshot, options: sizeOptions)
        XCTAssertEqual(sizeSorted.root.children.map(\.name), ["large.txt", "small.pdf", "folder"])
    }

    func testFolderOnlyVisibilityFiltersFilesWithoutChangingOriginalSnapshot() {
        let nestedFile = ManifestNode(id: "root/folder/nested.txt", name: "nested.txt", isDirectory: false, size: 1, modifiedDate: nil, children: [])
        let folder = ManifestNode(id: "root/folder", name: "folder", isDirectory: true, size: 0, modifiedDate: nil, children: [nestedFile])
        let rootFile = ManifestNode(id: "root/root.txt", name: "root.txt", isDirectory: false, size: 1, modifiedDate: nil, children: [])
        let snapshot = ManifestSnapshot(
            root: ManifestNode(id: "root", name: "root", isDirectory: true, size: 0, modifiedDate: nil, children: [folder, rootFile]),
            skippedCount: 0
        )

        let foldersOnly = ManifestVisibility.foldersOnly(snapshot: snapshot)

        XCTAssertEqual(foldersOnly.root.children.map(\.name), ["folder"])
        XCTAssertTrue(foldersOnly.root.children[0].children.isEmpty)
        XCTAssertEqual(foldersOnly.fileCount, 2)
        XCTAssertEqual(foldersOnly.totalSize, 2)
        XCTAssertEqual(foldersOnly.root.children[0].totalFileCount, 1)
        XCTAssertTrue(
            ManifestRenderer().render(snapshot: foldersOnly, display: DisplayOptions())
                .contains("folder  [1 个文件]")
        )
        XCTAssertEqual(snapshot.fileCount, 2)
        XCTAssertEqual(snapshot.root.children[0].children.first?.name, "nested.txt")
    }

    func testSearchResultsFollowInMemoryOrderAndKeepCurrentMatch() {
        let fileZ = ManifestNode(id: "root/z.txt", name: "z.txt", isDirectory: false, size: 0, modifiedDate: nil, children: [])
        let fileA = ManifestNode(id: "root/a.txt", name: "a.txt", isDirectory: false, size: 0, modifiedDate: nil, children: [])
        let root = ManifestNode(id: "root", name: "root", isDirectory: true, size: 0, modifiedDate: nil, children: [fileZ, fileA])
        let snapshot = ManifestSnapshot(root: root, skippedCount: 0)
        let renderer = ManifestRenderer()
        var state = ManifestSearchState(draftPattern: #"\.txt$"#)
        state.submit(snapshot: snapshot, renderer: renderer)
        XCTAssertEqual(state.selectedMatchID, "root/z.txt")

        let sortedSnapshot = ManifestOrdering.sorted(snapshot: snapshot, options: ScanOptions())
        state.refresh(snapshot: sortedSnapshot, renderer: renderer)

        XCTAssertEqual(state.matches.map(\.id), ["root/a.txt", "root/z.txt"])
        XCTAssertEqual(state.selectedMatchID, "root/z.txt")
        XCTAssertEqual(state.selectedPosition, 2)
    }

    func testTXTRenderPreservesSpecialCharacters() {
        let file = ManifestNode(
            id: "root/a,b\"c.txt",
            name: "a,b\"c.txt",
            isDirectory: false,
            size: 2048,
            modifiedDate: nil,
            children: []
        )
        let root = ManifestNode(
            id: "root",
            name: "root",
            isDirectory: true,
            size: 0,
            modifiedDate: nil,
            children: [file]
        )
        let snapshot = ManifestSnapshot(root: root, skippedCount: 0)
        let display = DisplayOptions(showFileSize: true, showModifiedDate: false, showFileCount: true)

        let renderer = ManifestRenderer()
        let text = renderer.render(snapshot: snapshot, display: display)

        XCTAssertTrue(text.contains("a,b\"c.txt"))
        XCTAssertTrue(text.contains(renderer.sizeText(2048)))
    }

    func testRegexSearchMatchesFullPathAndRejectsInvalidPattern() throws {
        let file = ManifestNode(
            id: "课程资料/第一周/讲义.PDF",
            name: "讲义.PDF",
            isDirectory: false,
            size: 100,
            modifiedDate: nil,
            children: []
        )
        let folder = ManifestNode(
            id: "课程资料/第一周",
            name: "第一周",
            isDirectory: true,
            size: 0,
            modifiedDate: nil,
            children: [file]
        )
        let root = ManifestNode(
            id: "课程资料",
            name: "课程资料",
            isDirectory: true,
            size: 0,
            modifiedDate: nil,
            children: [folder]
        )
        let snapshot = ManifestSnapshot(root: root, skippedCount: 0)
        let renderer = ManifestRenderer()

        let pdfMatches = try renderer.search(snapshot: snapshot, pattern: #"第一周/.+\.pdf$"#)
        let folderMatches = try renderer.search(snapshot: snapshot, pattern: "第一周$")
        let parentKeywordMatches = try renderer.search(snapshot: snapshot, pattern: "第一周")

        XCTAssertEqual(pdfMatches.map(\.path), ["课程资料/第一周/讲义.PDF"])
        XCTAssertFalse(pdfMatches[0].matchRanges.isEmpty)
        XCTAssertEqual(folderMatches.map(\.path), ["课程资料/第一周"])
        XCTAssertEqual(parentKeywordMatches.map(\.path), ["课程资料/第一周"])
        XCTAssertThrowsError(try renderer.search(snapshot: snapshot, pattern: "[未闭合"))
    }

    func testSearchStateWaitsForSubmitAndClearsWhenDraftChanges() {
        let file = ManifestNode(
            id: "root/report.pdf",
            name: "report.pdf",
            isDirectory: false,
            size: 0,
            modifiedDate: nil,
            children: []
        )
        let root = ManifestNode(
            id: "root",
            name: "root",
            isDirectory: true,
            size: 0,
            modifiedDate: nil,
            children: [file]
        )
        let snapshot = ManifestSnapshot(root: root, skippedCount: 0)
        var state = ManifestSearchState()

        state.updateDraft(#"\.pdf$"#)
        XCTAssertTrue(state.matches.isEmpty)
        XCTAssertTrue(state.committedPattern.isEmpty)

        state.submit(snapshot: snapshot, renderer: ManifestRenderer())
        XCTAssertEqual(state.matches.map(\.id), ["root/report.pdf"])
        XCTAssertEqual(state.selectedPosition, 1)

        state.updateDraft("report")
        XCTAssertTrue(state.matches.isEmpty)
        XCTAssertNil(state.selectedPosition)
    }

    func testSearchNavigationWrapsAtBothEnds() {
        let files = (1...3).map { index in
            ManifestNode(
                id: "root/file\(index).txt",
                name: "file\(index).txt",
                isDirectory: false,
                size: 0,
                modifiedDate: nil,
                children: []
            )
        }
        let root = ManifestNode(
            id: "root",
            name: "root",
            isDirectory: true,
            size: 0,
            modifiedDate: nil,
            children: files
        )
        var state = ManifestSearchState(draftPattern: #"\.txt$"#)
        state.submit(
            snapshot: ManifestSnapshot(root: root, skippedCount: 0),
            renderer: ManifestRenderer()
        )

        XCTAssertEqual(state.selectedPosition, 1)
        state.selectPrevious()
        XCTAssertEqual(state.selectedPosition, 3)
        state.selectNext()
        XCTAssertEqual(state.selectedPosition, 1)
    }

    func testSelectedTreeTextImmediatelyFillsAndSubmitsSearch() {
        let file = ManifestNode(
            id: "root/report.pdf",
            name: "report.pdf",
            isDirectory: false,
            size: 0,
            modifiedDate: nil,
            children: []
        )
        let root = ManifestNode(
            id: "root",
            name: "root",
            isDirectory: true,
            size: 0,
            modifiedDate: nil,
            children: [file]
        )
        var state = ManifestSearchState()

        state.submitSelectedText(
            #"report\.pdf"#,
            snapshot: ManifestSnapshot(root: root, skippedCount: 0),
            renderer: ManifestRenderer()
        )

        XCTAssertEqual(state.draftPattern, #"report\.pdf"#)
        XCTAssertEqual(state.committedPattern, #"report\.pdf"#)
        XCTAssertEqual(state.matches.map(\.id), ["root/report.pdf"])
    }

    func testTreeRowResolvesFileURLWithoutSearchState() {
        let node = ManifestNode(
            id: "课程资料/第一周/讲义.pdf",
            name: "讲义.pdf",
            isDirectory: false,
            size: 0,
            modifiedDate: nil,
            children: []
        )
        let row = ManifestTreeRow(
            path: "课程资料/第一周/讲义.pdf",
            node: node,
            prefix: "└── ",
            metadata: ""
        )
        let rootURL = URL(fileURLWithPath: "/Users/example/课程资料", isDirectory: true)

        XCTAssertEqual(
            row.fileURL(relativeTo: rootURL).path,
            "/Users/example/课程资料/第一周/讲义.pdf"
        )
    }
}

private final class ScanProgressRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var recordedValues: [Int] = []

    var values: [Int] {
        lock.withLock { recordedValues }
    }

    func record(_ value: Int) {
        lock.withLock { recordedValues.append(value) }
    }
}
