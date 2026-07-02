//
//  DisplayWallpaperAssignment.swift
//  RioVideoWallpaper
//

import AppKit
import Foundation

struct DisplayVideoAssignment: Equatable {
    var defaultVideoURL: URL
    var videoURLByDisplayID: [String: URL]

    func videoURL(for screen: NSScreen) -> URL {
        videoURLByDisplayID[DisplayIdentifier.id(for: screen)] ?? defaultVideoURL
    }
}

enum DisplayIdentifier {
    static func id(for screen: NSScreen) -> String {
        if let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber {
            return "display-\(screenNumber.uint32Value)"
        }

        let frame = screen.frame
        return "frame-\(Int(frame.origin.x))-\(Int(frame.origin.y))-\(Int(frame.width))-\(Int(frame.height))"
    }

    static func label(for screen: NSScreen, index: Int) -> String {
        let size = screen.frame.size
        let role = screen == NSScreen.main ? "Main" : "Display"
        return "\(role) \(index + 1) (\(Int(size.width)) x \(Int(size.height)))"
    }
}

struct StoredWallpaperSelection: Codable, Equatable {
    var url: URL
    var bookmarkData: Data?
    var isGenerated: Bool
}

struct StoredDisplayWallpaperAssignments: Codable, Equatable {
    var defaultSelection: StoredWallpaperSelection
    var perDisplaySelections: [String: StoredWallpaperSelection]

    var videoAssignment: DisplayVideoAssignment {
        DisplayVideoAssignment(
            defaultVideoURL: defaultSelection.url,
            videoURLByDisplayID: perDisplaySelections.mapValues { $0.url }
        )
    }

    func allSelections() -> [StoredWallpaperSelection] {
        [defaultSelection] + Array(perDisplaySelections.values)
    }
}

struct DisplayWallpaperAssignmentStore {
    static let userDefaultsKey = "DisplayWallpaperAssignments"

    var defaults: UserDefaults = .standard

    func load() -> StoredDisplayWallpaperAssignments? {
        guard let data = defaults.data(forKey: Self.userDefaultsKey) else {
            return nil
        }
        return try? JSONDecoder().decode(StoredDisplayWallpaperAssignments.self, from: data)
    }

    func save(_ assignments: StoredDisplayWallpaperAssignments) throws {
        let data = try JSONEncoder().encode(assignments)
        defaults.set(data, forKey: Self.userDefaultsKey)
    }

    func remove() {
        defaults.removeObject(forKey: Self.userDefaultsKey)
    }
}
