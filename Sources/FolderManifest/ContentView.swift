import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject private var languageSettings: LanguageSettings
    @StateObject private var recentStore = RecentFolderStore()
    @State private var selectedURL: URL?
    @State private var selectedRecentPath: String?
    @State private var snapshot: ManifestSnapshot?
    @State private var scanOptions = ScanOptions()
    @State private var displayOptions = DisplayOptions()
    @State private var searchState = ManifestSearchState()
    @State private var isScanning = false
    @State private var isShowingScanCompletion = false
    @State private var discoveredItemCount = 0
    @State private var currentScanID = UUID()
    @State private var isDropTargeted = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    private let scanner = FolderScanner()
    private var strings: AppStrings { AppStrings(language: languageSettings.language) }
    private var renderer: ManifestRenderer { ManifestRenderer(strings: strings) }

    private var output: String {
        guard let snapshot = visibleSnapshot else { return "" }
        return renderer.render(snapshot: snapshot, display: displayOptions)
    }

    private var treeRows: [ManifestTreeRow] {
        guard let snapshot = visibleSnapshot else { return [] }
        return renderer.treeRows(snapshot: snapshot, display: displayOptions)
    }

    private var visibleSnapshot: ManifestSnapshot? {
        guard let snapshot else { return nil }
        return scanOptions.includeSubfolders
            ? snapshot
            : ManifestVisibility.foldersOnly(snapshot: snapshot)
    }

    private var matchesByID: [String: ManifestSearchMatch] {
        Dictionary(uniqueKeysWithValues: searchState.matches.map { ($0.id, $0) })
    }

    private var regexError: String? {
        searchState.regexErrorDescription.map(strings.invalidRegex)
    }

    private var activeRecentPath: String? {
        selectedRecentPath ?? selectedURL?.path(percentEncoded: false)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            if snapshot == nil && !isScanning && recentStore.entries.isEmpty {
                emptyState
            } else {
                workspace
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .alert(strings.alertTitle, isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button(strings.dismiss, role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? strings.unknownError)
        }
        .overlay(alignment: .bottom) {
            if let successMessage {
                statusToast(successMessage)
                    .padding(.bottom, 18)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.2), value: successMessage)
    }

    private var header: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 11)
                    .fill(Color.accentColor.gradient)
                Image(systemName: "list.bullet.rectangle.portrait.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 2) {
                Text("FolderManifest")
                    .font(.system(size: 19, weight: .bold))
                Text(selectedURL?.path(percentEncoded: false) ?? strings.appSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            Button {
                chooseFolder()
            } label: {
                Label(snapshot == nil ? strings.selectFolder : strings.changeFolder, systemImage: "folder.badge.plus")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
    }

    private var emptyState: some View {
        VStack(spacing: 22) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.10))
                    .frame(width: 132, height: 132)
                Image(systemName: isDropTargeted ? "arrow.down.folder.fill" : "folder.fill.badge.plus")
                    .font(.system(size: 58, weight: .light))
                    .foregroundStyle(Color.accentColor)
                    .symbolEffect(.bounce, value: isDropTargeted)
            }

            VStack(spacing: 8) {
                Text(isDropTargeted ? strings.releaseToScan : strings.dropFolderHere)
                    .font(.system(size: 28, weight: .bold))
                Text(strings.emptyDescription)
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
            }

            Button(strings.chooseFolderEllipsis) { chooseFolder() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

            HStack(spacing: 20) {
                featurePill(strings.fullyOffline, icon: "lock.shield")
                featurePill(strings.readOnlyScan, icon: "eye")
                featurePill(strings.oneClickExport, icon: "square.and.arrow.up")
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(
                    isDropTargeted ? Color.accentColor : Color.secondary.opacity(0.22),
                    style: StrokeStyle(lineWidth: isDropTargeted ? 3 : 1.5, dash: [10, 7])
                )
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(isDropTargeted ? Color.accentColor.opacity(0.06) : .clear)
                )
                .padding(34)
        }
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted, perform: handleDrop)
    }

    private var workspace: some View {
        HSplitView {
            settingsPanel
                .frame(minWidth: 130, idealWidth: 145, maxWidth: 150)
            recentPanel
                .frame(minWidth: 240, idealWidth: 270, maxWidth: 315)
            previewPanel
                .frame(minWidth: 520)
        }
    }

    private var settingsPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                settingSection(strings.scanScope, icon: "folder") {
                    Toggle(strings.includeSubfolders, isOn: includeSubfoldersBinding)
                    Toggle(strings.includeHidden, isOn: scanOptionBinding(\.includeHidden))
                    Toggle(strings.foldersFirst, isOn: orderingBinding(\.foldersFirst))
                }

                settingSection(strings.sortBy, icon: "arrow.up.arrow.down") {
                    Menu {
                        ForEach(ManifestSort.allCases) { option in
                            Button(strings.sortName(option)) {
                                scanOptions.sort = option
                                reorderTree()
                            }
                        }
                    } label: {
                        HStack {
                            Text(strings.sortName(scanOptions.sort))
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .menuStyle(.borderlessButton)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                settingSection(strings.displayInformation, icon: "line.3.horizontal.decrease.circle") {
                    Toggle(strings.fileSize, isOn: displayBinding(\.showFileSize))
                    Toggle(strings.modifiedDate, isOn: displayBinding(\.showModifiedDate))
                    Toggle(strings.filesInFolder, isOn: displayBinding(\.showFileCount))
                }

            }
            .padding(12)
        }
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.55))
    }

    private var recentPanel: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Label(strings.recentlyOpened, systemImage: "clock")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)

                HStack(spacing: 0) {
                    Text(strings.pinnedCountPrefix)
                    Text("\(recentStore.pinnedFolderCount)")
                        .monospacedDigit()
                        .frame(width: 18, alignment: .trailing)
                    Text(strings.pinnedCountSuffix)
                }
                .font(.caption)
                .foregroundStyle(.tertiary)
                .fixedSize()

                Spacer()

                Button {
                    recentStore.movePinned(path: activeRecentPath, by: -1)
                } label: {
                    Image(systemName: "arrow.up")
                }
                .buttonStyle(.plain)
                .disabled(!recentStore.canMovePinned(path: activeRecentPath, by: -1))
                .help(strings.movePinnedUp)

                Button {
                    recentStore.movePinned(path: activeRecentPath, by: 1)
                } label: {
                    Image(systemName: "arrow.down")
                }
                .buttonStyle(.plain)
                .disabled(!recentStore.canMovePinned(path: activeRecentPath, by: 1))
                .help(strings.movePinnedDown)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            ScrollView {
                Group {
                    if recentStore.entries.isEmpty {
                        Text(strings.noRecentFolders)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 7)
                    } else {
                        VStack(alignment: .leading, spacing: 3) {
                            ForEach(recentStore.entries) { entry in
                                recentFolderButton(entry)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.leading, 16)
                .padding(.trailing, 32)
                .padding(.bottom, 16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.32))
    }

    private var previewPanel: some View {
        VStack(spacing: 0) {
            HStack(spacing: 18) {
                if let snapshot = visibleSnapshot {
                    statistic("\(snapshot.fileCount)", strings.files, icon: "doc")
                    statistic("\(snapshot.folderCount)", strings.folders, icon: "folder")
                    statistic(renderer.sizeText(snapshot.totalSize), strings.totalSize, icon: "externaldrive")
                    if snapshot.skippedCount > 0 {
                        statistic("\(snapshot.skippedCount)", strings.skipped, icon: "exclamationmark.triangle")
                    }
                }

                Spacer()

                Button { rescan() } label: {
                    Label(strings.rescan, systemImage: "arrow.clockwise")
                }
                .disabled(isScanning || selectedURL == nil)

                Button { copyOutput() } label: {
                    Label(strings.copy, systemImage: "doc.on.doc")
                }
                .disabled(output.isEmpty)

                Button { exportOutput() } label: {
                    Label("\(strings.export) .TXT", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.borderedProminent)
                .disabled(output.isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField(strings.searchPlaceholder, text: searchPatternBinding)
                        .textFieldStyle(.plain)
                        .frame(minWidth: 170)
                        .onSubmit(performSearch)

                    Text(strings.searchHint)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .layoutPriority(-1)

                    Button(action: performSearch) {
                        Label(strings.search, systemImage: "magnifyingglass")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(isScanning || snapshot == nil)

                    Button(action: selectPreviousMatch) {
                        Label(strings.previous, systemImage: "chevron.up")
                    }
                    .controlSize(.small)
                    .disabled(searchState.matches.isEmpty)

                    Button(action: selectNextMatch) {
                        Label(strings.next, systemImage: "chevron.down")
                    }
                    .controlSize(.small)
                    .disabled(searchState.matches.isEmpty)

                    Text(searchPositionText)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 32)
                        .accessibilityLabel(searchPositionAccessibilityText)

                    if !searchState.draftPattern.isEmpty {
                        Button(action: clearSearch) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help(strings.clearSearch)
                    }
                }

                if let regexError {
                    Label(regexError, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 11)

            Divider()

            if isScanning || isShowingScanCompletion {
                scanStatusView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                GeometryReader { viewport in
                    ScrollViewReader { proxy in
                        ScrollView([.vertical, .horizontal]) {
                            LazyVStack(alignment: .leading, spacing: 0) {
                                ForEach(treeRows) { row in
                                    treeRow(
                                        row,
                                        match: matchesByID[row.id],
                                        isSelected: searchState.selectedMatchID == row.id
                                    )
                                    .id(row.id)
                                }
                            }
                            .frame(
                                minWidth: max(0, viewport.size.width - 44),
                                minHeight: max(0, viewport.size.height - 44),
                                alignment: .topLeading
                            )
                            .padding(22)
                        }
                        .onChange(of: searchState.navigationRevision) { _, _ in
                            guard let id = searchState.selectedMatchID else { return }
                            withAnimation(.easeOut(duration: 0.2)) {
                                proxy.scrollTo(id, anchor: .leading)
                            }
                        }
                    }
                }
                .background(Color(nsColor: .textBackgroundColor))
                .onDrop(of: [.fileURL], isTargeted: $isDropTargeted, perform: handleDrop)
            }
        }
    }

    private var scanStatusView: some View {
        HStack(spacing: 7) {
            Text(isScanning ? strings.scanning : strings.scanFinished)
            RunningFigure(isRunning: isScanning)
            Text(isScanning
                ? strings.discoveredItems(discoveredItemCount)
                : strings.totalDiscoveredItems(discoveredItemCount))
                .contentTransition(.numericText())
        }
        .font(.headline)
        .foregroundStyle(.secondary)
        .accessibilityElement(children: .combine)
    }

    private func treeRow(
        _ row: ManifestTreeRow,
        match: ManifestSearchMatch?,
        isSelected: Bool
    ) -> some View {
        HStack(spacing: 0) {
            TreeConnectorView(segments: row.connectorSegments)

            SelectableTreeText(
                text: highlightedText(for: row, match: match),
                searchTitle: strings.search,
                copyTitle: strings.copy,
                onSearch: performSelectedTextSearch,
                onDoubleClick: { revealInFinder(row) }
            )
            .fixedSize(horizontal: true, vertical: false)
        }
        .frame(height: TreeConnectorView.rowHeight, alignment: .leading)
        .padding(.horizontal, 5)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(rowHighlightColor(isMatched: match != nil, isSelected: isSelected))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(isSelected ? Color.accentColor : .clear, lineWidth: 1.5)
        )
        .contentShape(Rectangle())
        .help(strings.revealHelp)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var searchPatternBinding: Binding<String> {
        Binding(
            get: { searchState.draftPattern },
            set: { searchState.updateDraft($0) }
        )
    }

    private var searchPositionText: String {
        guard searchState.regexErrorDescription == nil,
              !searchState.committedPattern.isEmpty
        else { return "—" }
        guard let position = searchState.selectedPosition else { return "0" }
        return "\(position)/\(searchState.matches.count)"
    }

    private var searchPositionAccessibilityText: String {
        guard let position = searchState.selectedPosition else {
            return strings.matchCount(searchState.matches.count)
        }
        return strings.matchPosition(position, total: searchState.matches.count)
    }

    private func highlightedText(
        for row: ManifestTreeRow,
        match: ManifestSearchMatch?
    ) -> NSAttributedString {
        let text = NSMutableAttributedString(string: row.visibleText)
        text.addAttributes([
            .font: NSFont.monospacedSystemFont(ofSize: 13.5, weight: .regular),
            .foregroundColor: NSColor.labelColor,
        ], range: NSRange(location: 0, length: text.length))
        guard let match else { return text }

        let pathLength = (match.path as NSString).length
        let nameLength = (row.node.name as NSString).length
        let nameStartInPath = pathLength - nameLength
        let nameStartInRow = 0
        let nameRangeInPath = NSRange(location: nameStartInPath, length: nameLength)

        for matchRange in match.matchRanges {
            let intersection = NSIntersectionRange(matchRange, nameRangeInPath)
            guard intersection.length > 0 else { continue }
            let visibleRange = NSRange(
                location: nameStartInRow + intersection.location - nameStartInPath,
                length: intersection.length
            )
            text.addAttributes([
                .backgroundColor: NSColor.systemYellow.withAlphaComponent(0.72),
                .font: NSFont.monospacedSystemFont(ofSize: 13.5, weight: .bold),
            ], range: visibleRange)
        }
        return text
    }

    private func rowHighlightColor(isMatched: Bool, isSelected: Bool) -> Color {
        if isSelected { return Color.accentColor.opacity(0.22) }
        if isMatched { return Color.yellow.opacity(0.16) }
        return .clear
    }

    private func settingSection<Content: View>(
        _ title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 10, content: content)
        }
    }

    private func featurePill(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(.quaternary, in: Capsule())
    }

    private func recentFolderButton(_ entry: RecentFolderEntry) -> some View {
        HStack(spacing: 5) {
            Button {
                openRecent(entry)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "folder")
                        .foregroundStyle(Color.accentColor)
                    Text(entry.name)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(entry.path)

            Button {
                selectedRecentPath = entry.path
                recentStore.togglePin(path: entry.path)
            } label: {
                Image(systemName: entry.isPinned ? "pin.fill" : "pin")
                    .foregroundStyle(entry.isPinned ? Color.accentColor : Color.secondary)
            }
            .buttonStyle(.plain)
            .disabled(!recentStore.canTogglePin(path: entry.path))
            .help(entry.isPinned
                ? strings.unpinFolder
                : (recentStore.canTogglePin(path: entry.path)
                    ? strings.pinFolder
                    : strings.pinnedLimitReached))
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(entry.path == activeRecentPath
                    ? Color.accentColor.opacity(0.16)
                    : .clear)
        )
    }

    private func statistic(_ value: String, _ label: String, icon: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .foregroundStyle(Color.accentColor)
            VStack(alignment: .leading, spacing: 0) {
                Text(value).font(.system(size: 13, weight: .semibold))
                Text(label).font(.caption2).foregroundStyle(.secondary)
            }
        }
    }

    private func statusToast(_ message: String) -> some View {
        Label(message, systemImage: "checkmark.circle.fill")
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.black.opacity(0.78), in: Capsule())
            .shadow(radius: 10, y: 4)
    }

    private func scanOptionBinding<Value>(_ keyPath: WritableKeyPath<ScanOptions, Value>) -> Binding<Value> {
        Binding(
            get: { scanOptions[keyPath: keyPath] },
            set: { value in
                scanOptions[keyPath: keyPath] = value
                rescan()
            }
        )
    }

    private var includeSubfoldersBinding: Binding<Bool> {
        Binding(
            get: { scanOptions.includeSubfolders },
            set: { value in
                scanOptions.includeSubfolders = value
                if let selectedURL, let snapshot {
                    recentStore.updateCurrent(
                        path: selectedURL.path(percentEncoded: false),
                        snapshot: snapshot,
                        options: scanOptions
                    )
                }
                if let visibleSnapshot {
                    searchState.refresh(snapshot: visibleSnapshot, renderer: renderer)
                }
            }
        )
    }

    private func orderingBinding<Value>(_ keyPath: WritableKeyPath<ScanOptions, Value>) -> Binding<Value> {
        Binding(
            get: { scanOptions[keyPath: keyPath] },
            set: { value in
                scanOptions[keyPath: keyPath] = value
                reorderTree()
            }
        )
    }

    private func reorderTree() {
        guard let snapshot else { return }
        let reorderedSnapshot = ManifestOrdering.sorted(snapshot: snapshot, options: scanOptions)
        self.snapshot = reorderedSnapshot
        if let selectedURL {
            recentStore.updateCurrent(
                path: selectedURL.path(percentEncoded: false),
                snapshot: reorderedSnapshot,
                options: scanOptions
            )
        }
        if let visibleSnapshot {
            searchState.refresh(snapshot: visibleSnapshot, renderer: renderer)
        }
    }

    private func displayBinding<Value>(_ keyPath: WritableKeyPath<DisplayOptions, Value>) -> Binding<Value> {
        Binding(
            get: { displayOptions[keyPath: keyPath] },
            set: { displayOptions[keyPath: keyPath] = $0 }
        )
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.title = strings.choosePanelTitle
        panel.prompt = strings.startScan
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        if panel.runModal() == .OK, let url = panel.url {
            startScan(url)
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            let url: URL?
            if let data = item as? Data {
                url = URL(dataRepresentation: data, relativeTo: nil)
            } else if let itemURL = item as? URL {
                url = itemURL
            } else {
                url = nil
            }

            if let url {
                DispatchQueue.main.async { startScan(url) }
            }
        }
        return true
    }

    private func rescan() {
        guard let selectedURL else { return }
        startScan(recentStore.resolvedURL(forPath: selectedURL.path(percentEncoded: false)))
    }

    private func openRecent(_ entry: RecentFolderEntry) {
        currentScanID = UUID()
        isScanning = false
        isShowingScanCompletion = false
        selectedURL = recentStore.resolvedURL(forPath: entry.path)
        selectedRecentPath = entry.path
        scanOptions = entry.scanOptions
        snapshot = entry.snapshot
        discoveredItemCount = entry.snapshot.fileCount + entry.snapshot.folderCount
        errorMessage = nil
        searchState.reset()
        recentStore.touch(entry)
    }

    private func startScan(_ url: URL) {
        let scanID = UUID()
        currentScanID = scanID
        isScanning = true
        isShowingScanCompletion = false
        discoveredItemCount = 0
        snapshot = nil
        errorMessage = nil
        searchState.reset()
        selectedURL = url
        selectedRecentPath = url.path(percentEncoded: false)
        let scanOptionsForDisk: ScanOptions = {
            var options = scanOptions
            options.includeSubfolders = true
            return options
        }()

        Task {
            let hasSecurityScope = url.startAccessingSecurityScopedResource()
            defer {
                if hasSecurityScope { url.stopAccessingSecurityScopedResource() }
            }
            let (progressStream, progressContinuation) = AsyncStream.makeStream(
                of: Int.self,
                bufferingPolicy: .bufferingNewest(1)
            )
            let progressTask = Task {
                for await count in progressStream {
                    guard currentScanID == scanID else { break }
                    discoveredItemCount = count
                }
            }

            do {
                let result = try await Task.detached(priority: .userInitiated) {
                    try scanner.scan(url: url, options: scanOptionsForDisk) { count in
                        progressContinuation.yield(count)
                    }
                }.value
                progressContinuation.finish()
                await progressTask.value
                guard currentScanID == scanID else { return }
                snapshot = ManifestOrdering.sorted(snapshot: result, options: scanOptions)
                if let snapshot {
                    recentStore.record(url: url, snapshot: snapshot, options: scanOptions)
                }
                discoveredItemCount = result.fileCount + result.folderCount
                isScanning = false
                isShowingScanCompletion = true
                try? await Task.sleep(for: .milliseconds(900))
                guard currentScanID == scanID else { return }
                isShowingScanCompletion = false
            } catch {
                progressContinuation.finish()
                progressTask.cancel()
                guard currentScanID == scanID else { return }
                snapshot = nil
                if let failure = error as? ScanFailure {
                    errorMessage = localizedScanError(failure)
                } else {
                    errorMessage = error.localizedDescription
                }
                isScanning = false
                isShowingScanCompletion = false
            }
        }
    }

    private func copyOutput() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(output, forType: .string)
        showSuccess(strings.manifestCopied)
    }

    private func revealInFinder(_ row: ManifestTreeRow) {
        guard let selectedURL else { return }
        let rootURL = recentStore.resolvedURL(
            forPath: selectedURL.path(percentEncoded: false)
        )
        let hasSecurityScope = rootURL.startAccessingSecurityScopedResource()
        defer {
            if hasSecurityScope { rootURL.stopAccessingSecurityScopedResource() }
        }

        let targetURL = row.fileURL(relativeTo: rootURL)
        guard FileManager.default.fileExists(atPath: targetURL.path) else {
            errorMessage = strings.itemMissing
            return
        }
        if row.node.isDirectory {
            NSWorkspace.shared.open(targetURL)
        } else {
            NSWorkspace.shared.activateFileViewerSelecting([targetURL])
        }
        showSuccess(strings.shownInFinder)
    }

    private func exportOutput() {
        guard let selectedURL, snapshot != nil else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = "\(selectedURL.lastPathComponent)-\(strings.exportFilenameSuffix).txt"
        panel.title = strings.exportPanelTitle
        panel.prompt = strings.export
        if panel.runModal() == .OK, let destination = panel.url {
            do {
                try output.write(to: destination, atomically: true, encoding: .utf8)
                showSuccess(strings.manifestExported)
            } catch {
                errorMessage = strings.exportFailure(error.localizedDescription)
            }
        }
    }

    private func performSearch() {
        guard let snapshot = visibleSnapshot, !isScanning else { return }
        searchState.submit(snapshot: snapshot, renderer: renderer)
    }

    private func performSelectedTextSearch(_ selectedText: String) {
        guard let snapshot = visibleSnapshot, !isScanning else { return }
        searchState.submitSelectedText(selectedText, snapshot: snapshot, renderer: renderer)
    }

    private func selectPreviousMatch() {
        searchState.selectPrevious()
    }

    private func selectNextMatch() {
        searchState.selectNext()
    }

    private func clearSearch() {
        searchState.reset()
    }

    private func showSuccess(_ message: String) {
        successMessage = message
        Task {
            try? await Task.sleep(for: .seconds(2))
            if successMessage == message { successMessage = nil }
        }
    }

    private func localizedScanError(_ failure: ScanFailure) -> String {
        switch failure {
        case .notFolder:
            strings.notFolderError()
        case .unreadable(let name):
            strings.unreadableError(name)
        }
    }
}

private struct TreeConnectorView: View {
    static let font = NSFont.monospacedSystemFont(ofSize: 13.5, weight: .regular)
    static let characterWidth = ceil(
        NSAttributedString(string: "0", attributes: [.font: font]).size().width
    )
    static let indentWidth = characterWidth * 4
    static let rowHeight = ceil(font.boundingRectForFont.height) + 6

    let segments: [ManifestTreeConnectorSegment]

    var body: some View {
        Canvas { context, size in
            let middleY = size.height / 2
            for (index, segment) in segments.enumerated() {
                let startX = CGFloat(index) * Self.indentWidth
                let lineX = startX + Self.characterWidth / 2
                let endX = startX + Self.indentWidth - Self.characterWidth / 2
                var path = Path()

                switch segment {
                case .spacer:
                    continue
                case .continuation:
                    path.move(to: CGPoint(x: lineX, y: 0))
                    path.addLine(to: CGPoint(x: lineX, y: size.height))
                case .branch:
                    path.move(to: CGPoint(x: lineX, y: 0))
                    path.addLine(to: CGPoint(x: lineX, y: size.height))
                    path.move(to: CGPoint(x: lineX, y: middleY))
                    path.addLine(to: CGPoint(x: endX, y: middleY))
                case .lastBranch:
                    path.move(to: CGPoint(x: lineX, y: 0))
                    path.addLine(to: CGPoint(x: lineX, y: middleY))
                    path.addLine(to: CGPoint(x: endX, y: middleY))
                }

                context.stroke(
                    path,
                    with: .color(Color(nsColor: .secondaryLabelColor)),
                    style: StrokeStyle(lineWidth: 1, lineCap: .square, lineJoin: .miter)
                )
            }
        }
        .frame(width: CGFloat(segments.count) * Self.indentWidth)
        .accessibilityHidden(true)
    }
}

private struct RunningFigure: View {
    let isRunning: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.05, paused: !isRunning)) { timeline in
            let phase = sin(timeline.date.timeIntervalSinceReferenceDate * 22)
            Image(systemName: "figure.run")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.accentColor)
                .rotationEffect(.degrees(isRunning ? phase * 5 : 0))
                .offset(y: isRunning ? -abs(phase) * 3 : 0)
        }
        .frame(width: 20, height: 22)
        .accessibilityHidden(true)
    }
}
