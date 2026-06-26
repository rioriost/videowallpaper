//
//  GeneratedAssetLibrary.swift
//  VideoWallpaper
//

import Foundation

struct ProjectLibraryEntry: Equatable, Identifiable {
    var id: UUID
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
    private let rootURL: URL

    init(rootURL: URL = GeneratedAssetLibrary.defaultRootURL()) {
        self.rootURL = rootURL
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

    func save(_ project: WallpaperProject) throws -> URL {
        try ensureDirectories()

        let url = projectURL(for: project.id)
        try WallpaperProjectFileStore.save(project, to: url)
        return url
    }

    func videoURL(for project: WallpaperProject, fileExtension: String = "mp4") throws -> URL {
        try ensureDirectories()

        let normalizedExtension = fileExtension.trimmingCharacters(in: CharacterSet(charactersIn: "."))
        let fileURL = videosDirectoryURL.appendingPathComponent(project.id.uuidString)
        return normalizedExtension.isEmpty ? fileURL : fileURL.appendingPathExtension(normalizedExtension)
    }

    func thumbnailURL(for project: WallpaperProject, fileExtension: String = "png") throws -> URL {
        try ensureDirectories()

        let normalizedExtension = fileExtension.trimmingCharacters(in: CharacterSet(charactersIn: "."))
        let fileURL = thumbnailsDirectoryURL.appendingPathComponent(project.id.uuidString)
        return normalizedExtension.isEmpty ? fileURL : fileURL.appendingPathExtension(normalizedExtension)
    }

    func containsGeneratedVideo(_ url: URL) -> Bool {
        url.isDescendant(of: videosDirectoryURL)
    }

    func load(_ entry: ProjectLibraryEntry) throws -> WallpaperProject {
        try WallpaperProjectFileStore.load(from: entry.projectURL)
    }

    func delete(_ entry: ProjectLibraryEntry) throws {
        try ensureDirectories()

        try removeItemIfExists(at: entry.projectURL)
        if let thumbnailPath = entry.thumbnailPath {
            try removeLibraryAssetIfExists(atPath: thumbnailPath, under: thumbnailsDirectoryURL)
        }
        if let outputVideoPath = entry.outputVideoPath {
            try removeLibraryAssetIfExists(atPath: outputVideoPath, under: videosDirectoryURL)
        }
    }

    func cleanupOrphanedAssets() throws -> GeneratedAssetCleanupReport {
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

    func listProjects() throws -> [ProjectLibraryEntry] {
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

    private func projectURL(for id: UUID) -> URL {
        projectsDirectoryURL
            .appendingPathComponent(id.uuidString)
            .appendingPathExtension(WallpaperProjectFileStore.fileExtension)
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

    private static func defaultRootURL() -> URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support", isDirectory: true)

        return baseURL
            .appendingPathComponent("VideoWallpaper", isDirectory: true)
            .appendingPathComponent("Generated", isDirectory: true)
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
        self.id = project.id
        self.title = project.visualIntent?.title ?? project.promptHistory.last?.prompt ?? project.rendererFamily.displayName
        self.updatedAt = project.updatedAt
        self.rendererFamily = project.rendererFamily
        self.projectURL = projectURL
        self.outputVideoPath = project.assets.outputVideoPath
        self.thumbnailPath = project.assets.thumbnailPath
        self.promptPreview = project.promptHistory.last?.prompt
    }
}
