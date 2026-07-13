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
            XCTAssertFalse(strings.selectFolder.isEmpty)
            XCTAssertFalse(strings.searchPlaceholder.isEmpty)
            XCTAssertFalse(strings.search.isEmpty)
            XCTAssertFalse(strings.previous.isEmpty)
            XCTAssertFalse(strings.next.isEmpty)
            XCTAssertFalse(strings.matchPosition(1, total: 2).isEmpty)
            XCTAssertFalse(strings.exportPanelTitle.isEmpty)
        }
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

        let snapshot = try FolderScanner().scan(url: root, options: ScanOptions())

        XCTAssertEqual(snapshot.fileCount, 2)
        XCTAssertEqual(snapshot.folderCount, 1)
        XCTAssertFalse(snapshot.root.children.contains { $0.name == ".secret" })
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
        XCTAssertTrue(tree.contains("└── file.txt"))
        XCTAssertTrue(tree.contains("1 个文件"))
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

        XCTAssertEqual(pdfMatches.map(\.path), ["课程资料/第一周/讲义.PDF"])
        XCTAssertFalse(pdfMatches[0].matchRanges.isEmpty)
        XCTAssertEqual(folderMatches.map(\.path), ["课程资料/第一周"])
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
