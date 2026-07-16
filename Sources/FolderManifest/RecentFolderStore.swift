import Foundation

struct RecentFolderEntry: Identifiable, Codable, Equatable, Sendable {
    let path: String
    let name: String
    let bookmarkData: Data?
    let snapshot: ManifestSnapshot
    let scanOptions: ScanOptions
    let isPinned: Bool

    var id: String { path }

    init(
        path: String,
        name: String,
        bookmarkData: Data?,
        snapshot: ManifestSnapshot,
        scanOptions: ScanOptions,
        isPinned: Bool = false
    ) {
        self.path = path
        self.name = name
        self.bookmarkData = bookmarkData
        self.snapshot = snapshot
        self.scanOptions = scanOptions
        self.isPinned = isPinned
    }

    private enum CodingKeys: String, CodingKey {
        case path, name, bookmarkData, snapshot, scanOptions, isPinned
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        path = try container.decode(String.self, forKey: .path)
        name = try container.decode(String.self, forKey: .name)
        bookmarkData = try container.decodeIfPresent(Data.self, forKey: .bookmarkData)
        snapshot = try container.decode(ManifestSnapshot.self, forKey: .snapshot)
        scanOptions = try container.decode(ScanOptions.self, forKey: .scanOptions)
        isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
    }
}

@MainActor
final class RecentFolderStore: ObservableObject {
    @Published private(set) var entries: [RecentFolderEntry]

    private let storageURL: URL
    private let maximumUnpinnedCount = 20

    init(storageURL: URL? = nil) {
        self.storageURL = storageURL ?? Self.defaultStorageURL
        entries = Self.load(from: self.storageURL)
    }

    func record(url: URL, snapshot: ManifestSnapshot, options: ScanOptions) {
        let path = url.path(percentEncoded: false)
        let oldEntry = entries.first { $0.path == path }
        let oldIndex = entries.firstIndex { $0.path == path }
        let entry = RecentFolderEntry(
            path: path,
            name: url.lastPathComponent,
            bookmarkData: (try? url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )) ?? oldEntry?.bookmarkData,
            snapshot: snapshot,
            scanOptions: options,
            isPinned: oldEntry?.isPinned ?? false
        )
        entries.removeAll { $0.path == entry.path }
        if entry.isPinned, let oldIndex {
            entries.insert(entry, at: min(oldIndex, entries.count))
        } else {
            entries.insert(entry, at: pinnedCount)
        }
        trimUnpinnedEntries()
        save()
    }

    func touch(_ entry: RecentFolderEntry) {
        guard !entry.isPinned else { return }
        entries.removeAll { $0.path == entry.path }
        entries.insert(entry, at: pinnedCount)
        trimUnpinnedEntries()
        save()
    }

    func togglePin(path: String) {
        guard let index = entries.firstIndex(where: { $0.path == path }) else { return }
        let oldEntry = entries.remove(at: index)
        let updatedEntry = copy(oldEntry, isPinned: !oldEntry.isPinned)
        entries.insert(updatedEntry, at: pinnedCount)
        trimUnpinnedEntries()
        save()
    }

    func canMovePinned(path: String?, by offset: Int) -> Bool {
        guard let path,
              let index = entries.firstIndex(where: { $0.path == path }),
              entries[index].isPinned
        else { return false }
        return (0..<pinnedCount).contains(index + offset)
    }

    func movePinned(path: String?, by offset: Int) {
        guard canMovePinned(path: path, by: offset),
              let path,
              let index = entries.firstIndex(where: { $0.path == path })
        else { return }
        entries.swapAt(index, index + offset)
        save()
    }

    func updateCurrent(path: String, snapshot: ManifestSnapshot, options: ScanOptions) {
        guard let index = entries.firstIndex(where: { $0.path == path }) else { return }
        let oldEntry = entries[index]
        entries[index] = RecentFolderEntry(
            path: oldEntry.path,
            name: oldEntry.name,
            bookmarkData: oldEntry.bookmarkData,
            snapshot: snapshot,
            scanOptions: options,
            isPinned: oldEntry.isPinned
        )
        save()
    }

    func resolvedURL(forPath path: String) -> URL {
        guard let bookmark = entries.first(where: { $0.path == path })?.bookmarkData else {
            return URL(fileURLWithPath: path, isDirectory: true)
        }
        var isStale = false
        return (try? URL(
            resolvingBookmarkData: bookmark,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )) ?? URL(fileURLWithPath: path, isDirectory: true)
    }

    private func save() {
        do {
            let directory = storageURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let encoder = PropertyListEncoder()
            encoder.outputFormat = .binary
            try encoder.encode(entries).write(to: storageURL, options: .atomic)
        } catch {
            // A cache write failure must not interrupt scanning or viewing a manifest.
        }
    }

    private static func load(from url: URL) -> [RecentFolderEntry] {
        guard let data = try? Data(contentsOf: url),
              let entries = try? PropertyListDecoder().decode([RecentFolderEntry].self, from: data)
        else { return [] }
        let pinned = entries.filter(\.isPinned)
        let unpinned = entries.filter { !$0.isPinned }.prefix(20)
        return pinned + unpinned
    }

    private var pinnedCount: Int {
        entries.prefix(while: \.isPinned).count
    }

    private func trimUnpinnedEntries() {
        let pinned = entries.filter(\.isPinned)
        let unpinned = entries.filter { !$0.isPinned }.prefix(maximumUnpinnedCount)
        entries = pinned + unpinned
    }

    private func copy(_ entry: RecentFolderEntry, isPinned: Bool) -> RecentFolderEntry {
        RecentFolderEntry(
            path: entry.path,
            name: entry.name,
            bookmarkData: entry.bookmarkData,
            snapshot: entry.snapshot,
            scanOptions: entry.scanOptions,
            isPinned: isPinned
        )
    }

    private static var defaultStorageURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base
            .appendingPathComponent("FolderManifest", isDirectory: true)
            .appendingPathComponent("RecentFolders.plist")
    }
}
