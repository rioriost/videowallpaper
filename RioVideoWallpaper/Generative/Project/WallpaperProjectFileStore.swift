//
//  WallpaperProjectFileStore.swift
//  RioVideoWallpaper
//

import Foundation

enum WallpaperProjectFileStore {
    static let fileExtension = "riovideowallpaperproject"
    static let contentTypeIdentifier = "st.rio.riovideowallpaper.project"

    static func encode(_ project: WallpaperProject) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(project)
    }

    static func decode(_ data: Data) throws -> WallpaperProject {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(WallpaperProject.self, from: data)
    }

    static func save(_ project: WallpaperProject, to url: URL) throws {
        let outputURL = url.pathExtension.isEmpty
            ? url.appendingPathExtension(fileExtension)
            : url
        try encode(project).write(to: outputURL, options: [.atomic])
    }

    static func load(from url: URL) throws -> WallpaperProject {
        let data = try Data(contentsOf: url)
        return try decode(data)
    }
}
