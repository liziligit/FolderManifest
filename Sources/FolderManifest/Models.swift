import Foundation

enum ManifestSort: String, CaseIterable, Identifiable, Sendable {
    case name = "名称"
    case type = "类型"
    case modified = "修改时间"
    case size = "大小"

    var id: String { rawValue }
}

struct ScanOptions: Sendable, Equatable {
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

struct ManifestNode: Identifiable, Sendable, Equatable {
    let id: String
    let name: String
    let isDirectory: Bool
    let size: Int64
    let modifiedDate: Date?
    let children: [ManifestNode]

    var totalFileCount: Int {
        isDirectory ? children.reduce(0) { $0 + $1.totalFileCount } : 1
    }

    var totalFolderCount: Int {
        guard isDirectory else { return 0 }
        return children.reduce(1) { $0 + $1.totalFolderCount }
    }

    var totalSize: Int64 {
        isDirectory ? children.reduce(0) { $0 + $1.totalSize } : size
    }
}

struct ManifestSnapshot: Sendable, Equatable {
    let root: ManifestNode
    let skippedCount: Int

    var fileCount: Int { root.totalFileCount }
    var folderCount: Int { max(0, root.totalFolderCount - 1) }
    var totalSize: Int64 { root.totalSize }
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
