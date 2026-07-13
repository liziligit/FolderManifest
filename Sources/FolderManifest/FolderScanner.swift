import Foundation

struct FolderScanner: Sendable {
    private let keys: Set<URLResourceKey> = [
        .isDirectoryKey,
        .isHiddenKey,
        .fileSizeKey,
        .contentModificationDateKey
    ]

    func scan(
        url: URL,
        options: ScanOptions,
        progress: (@Sendable (Int) -> Void)? = nil
    ) throws -> ManifestSnapshot {
        let values = try url.resourceValues(forKeys: [.isDirectoryKey])
        guard values.isDirectory == true else { throw ScanFailure.notFolder }

        var skipped = 0
        var progressReporter = ScanProgressReporter(handler: progress)
        let root = try makeNode(
            at: url,
            relativePath: url.lastPathComponent,
            depth: 0,
            options: options,
            skipped: &skipped,
            progressReporter: &progressReporter
        )
        progressReporter.finish()
        return ManifestSnapshot(root: root, skippedCount: skipped)
    }

    private func makeNode(
        at url: URL,
        relativePath: String,
        depth: Int,
        options: ScanOptions,
        skipped: inout Int,
        progressReporter: inout ScanProgressReporter
    ) throws -> ManifestNode {
        let values = try url.resourceValues(forKeys: keys)
        let isDirectory = values.isDirectory == true
        if depth > 0 { progressReporter.discoveredItem() }

        var children: [ManifestNode] = []
        if isDirectory && (depth == 0 || options.includeSubfolders) {
            let urls: [URL]
            do {
                urls = try FileManager.default.contentsOfDirectory(
                    at: url,
                    includingPropertiesForKeys: Array(keys),
                    options: [.skipsPackageDescendants]
                )
            } catch {
                if depth == 0 { throw ScanFailure.unreadable(url.lastPathComponent) }
                skipped += 1
                return node(url: url, path: relativePath, values: values, children: [])
            }

            for childURL in urls where childURL.lastPathComponent != ".DS_Store" {
                do {
                    let childValues = try childURL.resourceValues(forKeys: keys)
                    if !options.includeHidden && childValues.isHidden == true { continue }
                    let childPath = relativePath + "/" + childURL.lastPathComponent
                    children.append(try makeNode(
                        at: childURL,
                        relativePath: childPath,
                        depth: depth + 1,
                        options: options,
                        skipped: &skipped,
                        progressReporter: &progressReporter
                    ))
                } catch {
                    skipped += 1
                }
            }
            children.sort { ManifestOrdering.comesBefore($0, $1, options: options) }
        }

        return node(url: url, path: relativePath, values: values, children: children)
    }

    private func node(
        url: URL,
        path: String,
        values: URLResourceValues,
        children: [ManifestNode]
    ) -> ManifestNode {
        ManifestNode(
            id: path,
            name: url.lastPathComponent,
            isDirectory: values.isDirectory == true,
            size: Int64(values.fileSize ?? 0),
            modifiedDate: values.contentModificationDate,
            children: children
        )
    }

}

private struct ScanProgressReporter {
    let handler: (@Sendable (Int) -> Void)?
    private(set) var count = 0
    private var lastReportTime = Date.distantPast

    init(handler: (@Sendable (Int) -> Void)?) {
        self.handler = handler
    }

    mutating func discoveredItem() {
        count += 1
        guard count == 1 || count.isMultiple(of: 32) else { return }
        let now = Date()
        guard count == 1 || now.timeIntervalSince(lastReportTime) >= 0.15 else { return }
        lastReportTime = now
        handler?(count)
    }

    func finish() {
        handler?(count)
    }
}
