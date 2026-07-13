import Foundation

struct FolderScanner: Sendable {
    private let keys: Set<URLResourceKey> = [
        .isDirectoryKey,
        .isHiddenKey,
        .fileSizeKey,
        .contentModificationDateKey
    ]

    func scan(url: URL, options: ScanOptions) throws -> ManifestSnapshot {
        let values = try url.resourceValues(forKeys: [.isDirectoryKey])
        guard values.isDirectory == true else { throw ScanFailure.notFolder }

        var skipped = 0
        let root = try makeNode(
            at: url,
            relativePath: url.lastPathComponent,
            depth: 0,
            options: options,
            skipped: &skipped
        )
        return ManifestSnapshot(root: root, skippedCount: skipped)
    }

    private func makeNode(
        at url: URL,
        relativePath: String,
        depth: Int,
        options: ScanOptions,
        skipped: inout Int
    ) throws -> ManifestNode {
        let values = try url.resourceValues(forKeys: keys)
        let isDirectory = values.isDirectory == true

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
                        skipped: &skipped
                    ))
                } catch {
                    skipped += 1
                }
            }
            children.sort { comesBefore($0, $1, options: options) }
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

    private func comesBefore(_ left: ManifestNode, _ right: ManifestNode, options: ScanOptions) -> Bool {
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
}
