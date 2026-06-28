//
//  GeneratedAssetLibrary.swift
//  VideoWallpaper
//

import Foundation

struct ProjectLibraryEntry: Equatable, Identifiable {
    var id: String
    var projectID: UUID
    var title: String
    var updatedAt: Date
    var rendererFamily: RendererFamily
    var projectURL: URL
    var outputVideoPath: String?
    var thumbnailPath: String?
    var promptPreview: String?
}

struct GeneratedAssetCleanupReport: Equatable {
    var removedVideoCount: Int
    var removedThumbnailCount: Int

    var removedAssetCount: Int {
        removedVideoCount + removedThumbnailCount
    }
}

struct GeneratedAssetLibrary {
    static let rootDidChangeNotification = Notification.Name("GeneratedAssetLibraryRootDidChange")
    private static let customRootPathKey = "GeneratedAssetLibrary.customRootPath"
    private static let customRootBookmarkKey = "GeneratedAssetLibrary.customRootBookmark"

    private let explicitRootURL: URL?

    init(rootURL: URL? = nil) {
        self.explicitRootURL = rootURL
    }

    var rootURL: URL {
        explicitRootURL ?? Self.currentRootURL
    }

    var projectsDirectoryURL: URL {
        rootURL.appendingPathComponent("Projects", isDirectory: true)
    }

    var videosDirectoryURL: URL {
        rootURL.appendingPathComponent("Videos", isDirectory: true)
    }

    var thumbnailsDirectoryURL: URL {
        rootURL.appendingPathComponent("Thumbnails", isDirectory: true)
    }

    @discardableResult
    func withRootAccess<T>(_ work: () throws -> T) rethrows -> T {
        let stopAccessing = startAccessingRootIfNeeded()
        defer {
            stopAccessing?()
        }
        return try work()
    }

    func startAccessingRootIfNeeded() -> (() -> Void)? {
        guard explicitRootURL == nil, Self.usesCustomRootURL else {
            return nil
        }

        let scopedRootURL = rootURL
        guard scopedRootURL.startAccessingSecurityScopedResource() else {
            return nil
        }

        return {
            scopedRootURL.stopAccessingSecurityScopedResource()
        }
    }

    func save(_ project: WallpaperProject) throws -> URL {
        try withRootAccess {
            let normalizedProject = Self.normalizedRendererFamily(in: project)
            let url = try projectURL(for: normalizedProject)
            try WallpaperProjectFileStore.save(normalizedProject, to: url)
            return url
        }
    }

    func projectURL(for project: WallpaperProject, date: Date = Date()) throws -> URL {
        try withRootAccess {
            try ensureDirectories()

            let normalizedProject = Self.normalizedRendererFamily(in: project)
            return projectsDirectoryURL.appendingPathComponent(Self.projectFileName(for: normalizedProject, date: date))
        }
    }

    func videoURL(for project: WallpaperProject, fileExtension: String = "mp4") throws -> URL {
        try withRootAccess {
            try ensureDirectories()

            let normalizedExtension = fileExtension.trimmingCharacters(in: CharacterSet(charactersIn: "."))
            let fileURL = videosDirectoryURL.appendingPathComponent(
                Self.exportFileName(for: project, fileExtension: "")
            )
            return normalizedExtension.isEmpty ? fileURL : fileURL.appendingPathExtension(normalizedExtension)
        }
    }

    func thumbnailURL(for project: WallpaperProject, fileExtension: String = "png") throws -> URL {
        try withRootAccess {
            try ensureDirectories()

            let normalizedExtension = fileExtension.trimmingCharacters(in: CharacterSet(charactersIn: "."))
            let fileURL = thumbnailsDirectoryURL.appendingPathComponent(project.id.uuidString)
            return normalizedExtension.isEmpty ? fileURL : fileURL.appendingPathExtension(normalizedExtension)
        }
    }

    func thumbnailURL(forProjectURL projectURL: URL, fileExtension: String = "png") throws -> URL {
        try withRootAccess {
            try ensureDirectories()

            let normalizedExtension = fileExtension.trimmingCharacters(in: CharacterSet(charactersIn: "."))
            let fileURL = thumbnailsDirectoryURL.appendingPathComponent(projectURL.deletingPathExtension().lastPathComponent)
            return normalizedExtension.isEmpty ? fileURL : fileURL.appendingPathExtension(normalizedExtension)
        }
    }

    func containsGeneratedVideo(_ url: URL) -> Bool {
        url.isDescendant(of: videosDirectoryURL)
    }

    func load(_ entry: ProjectLibraryEntry) throws -> WallpaperProject {
        try withRootAccess {
            try WallpaperProjectFileStore.load(from: entry.projectURL)
        }
    }

    func delete(_ entry: ProjectLibraryEntry) throws {
        try withRootAccess {
            try ensureDirectories()

            try removeItemIfExists(at: entry.projectURL)
            if let thumbnailPath = entry.thumbnailPath {
                try removeLibraryAssetIfExists(atPath: thumbnailPath, under: thumbnailsDirectoryURL)
            }
            if let outputVideoPath = entry.outputVideoPath {
                try removeLibraryAssetIfExists(atPath: outputVideoPath, under: videosDirectoryURL)
            }
        }
    }

    func cleanupOrphanedAssets() throws -> GeneratedAssetCleanupReport {
        try withRootAccess {
            try ensureDirectories()

            let entries = try listProjects()
            let referencedVideos = Set(entries.compactMap { entry in
                libraryAssetURL(fromPath: entry.outputVideoPath, under: videosDirectoryURL)?.standardizedFileURL
            })
            let referencedThumbnails = Set(entries.compactMap { entry in
                libraryAssetURL(fromPath: entry.thumbnailPath, under: thumbnailsDirectoryURL)?.standardizedFileURL
            })

            let removedVideoCount = try removeUnreferencedFiles(
                under: videosDirectoryURL,
                referencedURLs: referencedVideos
            )
            let removedThumbnailCount = try removeUnreferencedFiles(
                under: thumbnailsDirectoryURL,
                referencedURLs: referencedThumbnails
            )

            return GeneratedAssetCleanupReport(
                removedVideoCount: removedVideoCount,
                removedThumbnailCount: removedThumbnailCount
            )
        }
    }

    func listProjects() throws -> [ProjectLibraryEntry] {
        try withRootAccess {
            try ensureDirectories()

            let projectURLs = try FileManager.default.contentsOfDirectory(
                at: projectsDirectoryURL,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: [.skipsHiddenFiles]
            )

            return projectURLs
                .filter { $0.pathExtension == WallpaperProjectFileStore.fileExtension }
                .compactMap { url in
                    guard let project = try? WallpaperProjectFileStore.load(from: url) else {
                        return nil
                    }
                    return ProjectLibraryEntry(project: project, projectURL: url)
                }
                .sorted { lhs, rhs in
                    if lhs.updatedAt == rhs.updatedAt {
                        return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
                    }
                    return lhs.updatedAt > rhs.updatedAt
                }
        }
    }

    private func ensureDirectories() throws {
        try FileManager.default.createDirectory(
            at: projectsDirectoryURL,
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: videosDirectoryURL,
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: thumbnailsDirectoryURL,
            withIntermediateDirectories: true
        )
    }

    private func removeLibraryAssetIfExists(atPath path: String, under directoryURL: URL) throws {
        guard let assetURL = libraryAssetURL(fromPath: path, under: directoryURL) else {
            return
        }
        try removeItemIfExists(at: assetURL)
    }

    private func libraryAssetURL(fromPath path: String?, under directoryURL: URL) -> URL? {
        guard let path else {
            return nil
        }

        let assetURL = URL(fileURLWithPath: path)
        guard assetURL.isDescendant(of: directoryURL) else {
            return nil
        }
        return assetURL
    }

    private func removeUnreferencedFiles(under directoryURL: URL, referencedURLs: Set<URL>) throws -> Int {
        let fileURLs = try FileManager.default.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )

        var removedCount = 0
        for fileURL in fileURLs {
            let resourceValues = try fileURL.resourceValues(forKeys: [.isRegularFileKey])
            guard resourceValues.isRegularFile == true,
                  !referencedURLs.contains(fileURL.standardizedFileURL) else {
                continue
            }

            try FileManager.default.removeItem(at: fileURL)
            removedCount += 1
        }
        return removedCount
    }

    private func removeItemIfExists(at url: URL) throws {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return
        }
        try FileManager.default.removeItem(at: url)
    }

    static var currentRootURL: URL {
        if let bookmarkRootURL = resolvedCustomRootURL() {
            return bookmarkRootURL
        }
        guard let customRootPath = UserDefaults.standard.string(forKey: customRootPathKey),
              !customRootPath.isEmpty else {
            return defaultRootURL()
        }
        return URL(fileURLWithPath: customRootPath, isDirectory: true)
    }

    static var usesCustomRootURL: Bool {
        UserDefaults.standard.string(forKey: customRootPathKey)?.isEmpty == false
            || UserDefaults.standard.data(forKey: customRootBookmarkKey) != nil
    }

    static func setCustomRootURL(_ url: URL) throws {
        let bookmarkData = try url.bookmarkData(
            options: [.withSecurityScope],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        UserDefaults.standard.set(bookmarkData, forKey: customRootBookmarkKey)
        UserDefaults.standard.set(url.standardizedFileURL.path, forKey: customRootPathKey)
        NotificationCenter.default.post(name: rootDidChangeNotification, object: nil)
    }

    static func resetRootURL() {
        UserDefaults.standard.removeObject(forKey: customRootBookmarkKey)
        UserDefaults.standard.removeObject(forKey: customRootPathKey)
        NotificationCenter.default.post(name: rootDidChangeNotification, object: nil)
    }

    static func defaultRootURL() -> URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support", isDirectory: true)

        return baseURL
            .appendingPathComponent("VideoWallpaper", isDirectory: true)
            .appendingPathComponent("Generated", isDirectory: true)
    }

    private static func resolvedCustomRootURL() -> URL? {
        guard let bookmarkData = UserDefaults.standard.data(forKey: customRootBookmarkKey) else {
            return nil
        }

        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: bookmarkData,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else {
            return nil
        }

        if isStale, let refreshedBookmarkData = try? url.bookmarkData(
            options: [.withSecurityScope],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        ) {
            UserDefaults.standard.set(refreshedBookmarkData, forKey: customRootBookmarkKey)
        }

        return url
    }

    static func exportFileName(
        for project: WallpaperProject,
        date: Date = Date(),
        fileExtension: String = "mp4"
    ) -> String {
        let familyName = sanitizedFileNameComponent(project.renderParameters.rendererFamily.displayName)
        let timestamp = exportTimestampFormatter.string(from: date)
        let baseName = "RioVideoWallpaper-\(familyName)-\(timestamp)"
        let normalizedExtension = fileExtension.trimmingCharacters(in: CharacterSet(charactersIn: "."))
        return normalizedExtension.isEmpty ? baseName : "\(baseName).\(normalizedExtension)"
    }

    static func projectFileName(
        for project: WallpaperProject,
        date: Date = Date()
    ) -> String {
        exportFileName(
            for: project,
            date: date,
            fileExtension: WallpaperProjectFileStore.fileExtension
        )
    }

    private static func sanitizedFileNameComponent(_ value: String) -> String {
        let allowed = CharacterSet.alphanumerics
        let pieces = value
            .components(separatedBy: allowed.inverted)
            .filter { !$0.isEmpty }
        return pieces.isEmpty ? "Renderer" : pieces.joined(separator: "-")
    }

    private static var exportTimestampFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter
    }

    private static func normalizedRendererFamily(in project: WallpaperProject) -> WallpaperProject {
        var normalizedProject = project
        normalizedProject.rendererFamily = project.renderParameters.rendererFamily
        if var intent = normalizedProject.visualIntent {
            intent.rendererFamily = normalizedProject.rendererFamily
            normalizedProject.visualIntent = intent
        }
        return normalizedProject
    }
}

private extension URL {
    func isDescendant(of directoryURL: URL) -> Bool {
        let path = standardizedFileURL.path
        let directoryPath = directoryURL.standardizedFileURL.path

        return path == directoryPath || path.hasPrefix(directoryPath + "/")
    }
}

private extension ProjectLibraryEntry {
    init(project: WallpaperProject, projectURL: URL) {
        let rendererFamily = project.renderParameters.rendererFamily
        self.id = projectURL.standardizedFileURL.path
        self.projectID = project.id
        self.title = rendererFamily.displayName
        self.updatedAt = project.updatedAt
        self.rendererFamily = rendererFamily
        self.projectURL = projectURL
        self.outputVideoPath = project.assets.outputVideoPath
        self.thumbnailPath = project.assets.thumbnailPath
        self.promptPreview = project.promptHistory.last?.prompt
    }
}
