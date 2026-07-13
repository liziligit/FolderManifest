import Foundation

struct ManifestRenderer {
    private let strings: AppStrings
    private let byteFormatter: ByteCountFormatter
    private let dateFormatter: DateFormatter

    init(strings: AppStrings = AppStrings(language: .simplifiedChinese)) {
        self.strings = strings
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB, .useTB]
        formatter.countStyle = .file
        formatter.includesUnit = true
        byteFormatter = formatter

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: strings.language.localeIdentifier)
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        self.dateFormatter = dateFormatter
    }

    func render(snapshot: ManifestSnapshot, display: DisplayOptions) -> String {
        treeRows(snapshot: snapshot, display: display)
            .map(\.text)
            .joined(separator: "\n")
    }

    func sizeText(_ bytes: Int64) -> String {
        guard bytes > 0 else { return "0 KB" }
        return byteFormatter.string(fromByteCount: bytes)
    }

    func treeRows(snapshot: ManifestSnapshot, display: DisplayOptions) -> [ManifestTreeRow] {
        var rows = [ManifestTreeRow(
            path: snapshot.root.name,
            node: snapshot.root,
            prefix: "",
            metadata: metadata(for: snapshot.root, display: display)
        )]
        appendTreeRows(
            snapshot.root.children,
            parentPath: snapshot.root.name,
            prefix: "",
            rows: &rows,
            display: display
        )
        return rows
    }

    func search(snapshot: ManifestSnapshot, pattern: String) throws -> [ManifestSearchMatch] {
        let expression = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
        var matches: [ManifestSearchMatch] = []
        appendSearchMatches(
            snapshot.root,
            path: snapshot.root.name,
            expression: expression,
            matches: &matches
        )
        return matches
    }

    private func appendSearchMatches(
        _ node: ManifestNode,
        path: String,
        expression: NSRegularExpression,
        matches: inout [ManifestSearchMatch]
    ) {
        let range = NSRange(path.startIndex..<path.endIndex, in: path)
        let nameLength = (node.name as NSString).length
        let nameRange = NSRange(location: range.length - nameLength, length: nameLength)
        let results = expression.matches(in: path, range: range).filter {
            NSIntersectionRange($0.range, nameRange).length > 0
        }
        if !results.isEmpty {
            matches.append(ManifestSearchMatch(
                path: path,
                node: node,
                matchRanges: results.map(\.range)
            ))
        }
        for child in node.children {
            appendSearchMatches(
                child,
                path: path + "/" + child.name,
                expression: expression,
                matches: &matches
            )
        }
    }

    private func appendTreeRows(
        _ children: [ManifestNode],
        parentPath: String,
        prefix: String,
        rows: inout [ManifestTreeRow],
        display: DisplayOptions
    ) {
        for (index, child) in children.enumerated() {
            let isLast = index == children.count - 1
            let childPath = parentPath + "/" + child.name
            rows.append(ManifestTreeRow(
                path: childPath,
                node: child,
                prefix: prefix + (isLast ? "└── " : "├── "),
                metadata: metadata(for: child, display: display)
            ))
            if child.isDirectory {
                appendTreeRows(
                    child.children,
                    parentPath: childPath,
                    prefix: prefix + (isLast ? "    " : "│   "),
                    rows: &rows,
                    display: display
                )
            }
        }
    }

    private func metadata(for node: ManifestNode, display: DisplayOptions) -> String {
        var parts: [String] = []
        if display.showFileSize && !node.isDirectory {
            parts.append(sizeText(node.size))
        }
        if display.showModifiedDate, let date = node.modifiedDate {
            parts.append(dateFormatter.string(from: date))
        }
        if display.showFileCount && node.isDirectory {
            parts.append(strings.fileCount(node.totalFileCount))
        }
        return parts.isEmpty ? "" : "  [" + parts.joined(separator: " · ") + "]"
    }
}
