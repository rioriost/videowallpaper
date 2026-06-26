//
//  ExportSettings.swift
//  VideoWallpaper
//

import Foundation

enum VideoCodec: String, Codable, CaseIterable, Identifiable {
    case h264
    case hevc

    var id: String { rawValue }
}

enum ExportQuality: String, Codable, CaseIterable, Identifiable {
    case draft
    case high
    case archive

    var id: String { rawValue }
}

struct ExportSettings: Codable, Equatable {
    static let minimumWidth = 16
    static let minimumHeight = 16
    static let minimumFPS = 1
    static let minimumLoopSeconds = 0.1
    static let minimumWarmupLoops = 0

    var width: Int
    var height: Int
    var fps: Int
    var loopSeconds: Double
    var codec: VideoCodec
    var quality: ExportQuality
    var warmupLoops: Int

    static let standard = ExportSettings(
        width: 1920,
        height: 1200,
        fps: 30,
        loopSeconds: 10.0,
        codec: .h264,
        quality: .high,
        warmupLoops: 1
    )

    func normalizedForExport() -> ExportSettings {
        ExportSettings(
            width: max(Self.minimumWidth, width),
            height: max(Self.minimumHeight, height),
            fps: max(Self.minimumFPS, fps),
            loopSeconds: max(Self.minimumLoopSeconds, loopSeconds),
            codec: codec,
            quality: quality,
            warmupLoops: max(Self.minimumWarmupLoops, warmupLoops)
        )
    }
}

enum ExportPreset: String, CaseIterable, Identifiable {
    case size1280x800
    case size1440x900
    case size1920x1080
    case size1920x1200
    case size2560x1080
    case size2560x1440
    case size2560x1600
    case size2880x1800
    case size3440x1440
    case size3840x2160
    case size3840x2560
    case size4096x2160
    case size5120x1440
    case size5120x2160
    case size5120x2880
    case size6016x3384
    case size7680x4320
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .size1280x800:
            return "1280x800"
        case .size1440x900:
            return "1440x900"
        case .size1920x1080:
            return "1920x1080 (Full HD)"
        case .size1920x1200:
            return "1920x1200 (WUXGA)"
        case .size2560x1080:
            return "2560x1080 (WFHD)"
        case .size2560x1440:
            return "2560x1440 (WQHD)"
        case .size2560x1600:
            return "2560x1600 (WQXGA)"
        case .size2880x1800:
            return "2880x1800"
        case .size3440x1440:
            return "3440x1440 (UWQHD)"
        case .size3840x2160:
            return "3840x2160 (4K)"
        case .size3840x2560:
            return "3840x2560 (4K+)"
        case .size4096x2160:
            return "4096x2160 (DCI 4K)"
        case .size5120x1440:
            return "5120x1440 (DQHD)"
        case .size5120x2160:
            return "5120x2160 (WUHD)"
        case .size5120x2880:
            return "5120x2880 (5K)"
        case .size6016x3384:
            return "6016x3384 (6K)"
        case .size7680x4320:
            return "7680x4320 (8K)"
        case .custom:
            return "Custom"
        }
    }

    var baseSettings: ExportSettings? {
        switch self {
        case .size1280x800:
            return makeBaseSettings(width: 1280, height: 800)
        case .size1440x900:
            return makeBaseSettings(width: 1440, height: 900)
        case .size1920x1080:
            return makeBaseSettings(width: 1920, height: 1080)
        case .size1920x1200:
            return makeBaseSettings(width: 1920, height: 1200)
        case .size2560x1080:
            return makeBaseSettings(width: 2560, height: 1080)
        case .size2560x1440:
            return makeBaseSettings(width: 2560, height: 1440)
        case .size2560x1600:
            return makeBaseSettings(width: 2560, height: 1600)
        case .size2880x1800:
            return makeBaseSettings(width: 2880, height: 1800)
        case .size3440x1440:
            return makeBaseSettings(width: 3440, height: 1440)
        case .size3840x2160:
            return makeBaseSettings(width: 3840, height: 2160)
        case .size3840x2560:
            return makeBaseSettings(width: 3840, height: 2560)
        case .size4096x2160:
            return makeBaseSettings(width: 4096, height: 2160)
        case .size5120x1440:
            return makeBaseSettings(width: 5120, height: 1440)
        case .size5120x2160:
            return makeBaseSettings(width: 5120, height: 2160)
        case .size5120x2880:
            return makeBaseSettings(width: 5120, height: 2880)
        case .size6016x3384:
            return makeBaseSettings(width: 6016, height: 3384)
        case .size7680x4320:
            return makeBaseSettings(width: 7680, height: 4320)
        case .custom:
            return nil
        }
    }

    private func makeBaseSettings(width: Int, height: Int) -> ExportSettings {
        ExportSettings(width: width, height: height, fps: 30, loopSeconds: 10, codec: .h264, quality: .high, warmupLoops: 1)
    }

    func exportSettings(preservingCodec codec: VideoCodec) -> ExportSettings? {
        guard var settings = baseSettings else { return nil }
        settings.codec = codec
        return settings
    }

    static func matching(_ settings: ExportSettings) -> ExportPreset {
        allCases.first { preset in
            guard let baseSettings = preset.baseSettings else { return false }
            return baseSettings.width == settings.width &&
                baseSettings.height == settings.height &&
                baseSettings.fps == settings.fps &&
                baseSettings.loopSeconds == settings.loopSeconds &&
                baseSettings.quality == settings.quality &&
                baseSettings.warmupLoops == settings.warmupLoops
        } ?? .custom
    }
}
