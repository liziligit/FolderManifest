import Foundation

enum ManifestSort: String, CaseIterable, Identifiable, Sendable, Codable {
    case name = "名称"
    case type = "类型"
    case modified = "修改时间"
    case size = "大小"

    var id: String { rawValue }
}

struct ScanOptions: Sendable, Equatable, Codable {
    var includeSubfolders = true
    var includeHidden = false
    var foldersFirst = true
    var sort: ManifestSort = .name
}

struct DisplayOptions: Sendable, Equatable {
    var showFileSize = true
    var showModifiedDate = false
    var showFileCount = true
}

struct ManifestNode: Identifiable, Sendable, Equatable, Codable {
    let id: String
    let name: String
    let isDirectory: Bool
    let size: Int64
    let modifiedDate: Date?
    let children: [ManifestNode]
    var preservedFileCount: Int? = nil
    var preservedTotalSize: Int64? = nil

    var totalFileCount: Int {
        isDirectory
            ? preservedFileCount ?? children.reduce(0) { $0 + $1.totalFileCount }
            : 1
    }

    var totalFolderCount: Int {
        guard isDirectory else { return 0 }
        return children.reduce(1) { $0 + $1.totalFolderCount }
    }

    var totalSize: Int64 {
        isDirectory
            ? preservedTotalSize ?? children.reduce(0) { $0 + $1.totalSize }
            : size
    }
}

struct ManifestSnapshot: Sendable, Equatable, Codable {
    let root: ManifestNode
    let skippedCount: Int

    var fileCount: Int { root.totalFileCount }
    var folderCount: Int { max(0, root.totalFolderCount - 1) }
    var totalSize: Int64 { root.totalSize }
}

enum ManifestVisibility {
    static func foldersOnly(snapshot: ManifestSnapshot) -> ManifestSnapshot {
        ManifestSnapshot(
            root: foldersOnly(node: snapshot.root),
            skippedCount: snapshot.skippedCount
        )
    }

    private static func foldersOnly(node: ManifestNode) -> ManifestNode {
        ManifestNode(
            id: node.id,
            name: node.name,
            isDirectory: node.isDirectory,
            size: node.size,
            modifiedDate: node.modifiedDate,
            children: node.children
                .filter(\.isDirectory)
                .map(foldersOnly),
            preservedFileCount: node.totalFileCount,
            preservedTotalSize: node.totalSize
        )
    }
}

enum ManifestOrdering {
    static func sorted(snapshot: ManifestSnapshot, options: ScanOptions) -> ManifestSnapshot {
        ManifestSnapshot(
            root: sorted(node: snapshot.root, options: options),
            skippedCount: snapshot.skippedCount
        )
    }

    static func comesBefore(
        _ left: ManifestNode,
        _ right: ManifestNode,
        options: ScanOptions
    ) -> Bool {
        if options.foldersFirst && left.isDirectory != right.isDirectory {
            return left.isDirectory
        }

        switch options.sort {
        case .name:
            return left.name.localizedStandardCompare(right.name) == .orderedAscending
        case .type:
            let leftType = (left.name as NSString).pathExtension
            let rightType = (right.name as NSString).pathExtension
            if leftType != rightType {
                return leftType.localizedStandardCompare(rightType) == .orderedAscending
            }
        case .modified:
            if left.modifiedDate != right.modifiedDate {
                return (left.modifiedDate ?? .distantPast) > (right.modifiedDate ?? .distantPast)
            }
        case .size:
            if left.totalSize != right.totalSize { return left.totalSize > right.totalSize }
        }
        return left.name.localizedStandardCompare(right.name) == .orderedAscending
    }

    private static func sorted(node: ManifestNode, options: ScanOptions) -> ManifestNode {
        let children = node.children
            .map { sorted(node: $0, options: options) }
            .sorted { comesBefore($0, $1, options: options) }
        return ManifestNode(
            id: node.id,
            name: node.name,
            isDirectory: node.isDirectory,
            size: node.size,
            modifiedDate: node.modifiedDate,
            children: children,
            preservedFileCount: node.preservedFileCount,
            preservedTotalSize: node.preservedTotalSize
        )
    }
}

struct ManifestSearchMatch: Identifiable, Sendable, Equatable {
    let path: String
    let node: ManifestNode
    let matchRanges: [NSRange]

    var id: String { node.id }

    init(path: String, node: ManifestNode, matchRanges: [NSRange] = []) {
        self.path = path
        self.node = node
        self.matchRanges = matchRanges
    }

}

struct ManifestTreeRow: Identifiable, Sendable, Equatable {
    let path: String
    let node: ManifestNode
    let prefix: String
    let metadata: String

    var id: String { node.id }
    var text: String { prefix + node.name + metadata }

    func fileURL(relativeTo rootURL: URL) -> URL {
        path.split(separator: "/").dropFirst().reduce(rootURL) { url, component in
            url.appendingPathComponent(String(component))
        }
    }
}

struct ManifestSearchState: Sendable, Equatable {
    var draftPattern = ""
    private(set) var committedPattern = ""
    private(set) var matches: [ManifestSearchMatch] = []
    private(set) var selectedIndex: Int?
    private(set) var regexErrorDescription: String?
    private(set) var navigationRevision = 0

    var selectedMatchID: String? {
        guard let selectedIndex, matches.indices.contains(selectedIndex) else { return nil }
        return matches[selectedIndex].id
    }

    var selectedPosition: Int? {
        selectedIndex.map { $0 + 1 }
    }

    mutating func updateDraft(_ value: String) {
        draftPattern = value
        clearResults()
    }

    mutating func submit(snapshot: ManifestSnapshot, renderer: ManifestRenderer) {
        let pattern = draftPattern.trimmingCharacters(in: .whitespacesAndNewlines)
        clearResults()
        guard !pattern.isEmpty else { return }
        committedPattern = pattern

        do {
            matches = try renderer.search(snapshot: snapshot, pattern: pattern)
            selectedIndex = matches.isEmpty ? nil : 0
            if selectedIndex != nil { navigationRevision += 1 }
        } catch {
            regexErrorDescription = error.localizedDescription
        }
    }

    mutating func submitSelectedText(
        _ selectedText: String,
        snapshot: ManifestSnapshot,
        renderer: ManifestRenderer
    ) {
        updateDraft(selectedText)
        submit(snapshot: snapshot, renderer: renderer)
    }

    mutating func refresh(snapshot: ManifestSnapshot, renderer: ManifestRenderer) {
        guard !committedPattern.isEmpty else { return }
        let selectedID = selectedMatchID

        do {
            matches = try renderer.search(snapshot: snapshot, pattern: committedPattern)
            selectedIndex = selectedID.flatMap { id in
                matches.firstIndex { $0.id == id }
            } ?? (matches.isEmpty ? nil : 0)
            regexErrorDescription = nil
            if selectedIndex != nil { navigationRevision += 1 }
        } catch {
            matches = []
            selectedIndex = nil
            regexErrorDescription = error.localizedDescription
        }
    }

    mutating func selectPrevious() {
        moveSelection(by: -1)
    }

    mutating func selectNext() {
        moveSelection(by: 1)
    }

    mutating func reset() {
        draftPattern = ""
        clearResults()
    }

    private mutating func clearResults() {
        committedPattern = ""
        matches = []
        selectedIndex = nil
        regexErrorDescription = nil
    }

    private mutating func moveSelection(by offset: Int) {
        guard !matches.isEmpty else { return }
        let current = selectedIndex ?? 0
        selectedIndex = (current + offset + matches.count) % matches.count
        navigationRevision += 1
    }
}

enum ScanFailure: LocalizedError {
    case notFolder
    case unreadable(String)

    var errorDescription: String? {
        switch self {
        case .notFolder:
            return "请选择一个文件夹，而不是单个文件。"
        case .unreadable(let name):
            return "无法读取“\(name)”。请确认文件夹仍然存在且具有访问权限。"
        }
    }
}
