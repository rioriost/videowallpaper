//
//  VideoAssetDiagnostics.swift
//  VideoWallpaper
//
//  Created by GitHub Copilot on 2026/06/23.
//

import AVFoundation
import CoreGraphics
import CoreMedia

struct VideoAssetDiagnostics {
    let codecName: String
    let presentationSize: CGSize
    let warnings: [String]

    var summary: String {
        let width = Int(presentationSize.width.rounded())
        let height = Int(presentationSize.height.rounded())
        return "\(codecName), \(width)x\(height)"
    }

    static func inspect(videoURL: URL, largestScreenPixelSize: CGSize) async throws -> VideoAssetDiagnostics {
        let asset = AVURLAsset(url: videoURL)
        let tracks = try await asset.loadTracks(withMediaType: .video)
        guard let track = tracks.first else {
            throw DiagnosticsError.noVideoTrack
        }

        let naturalSize = try await track.load(.naturalSize)
        let preferredTransform = try await track.load(.preferredTransform)
        let formatDescriptions = try await track.load(.formatDescriptions)
        let presentationSize = Self.presentationSize(naturalSize: naturalSize, transform: preferredTransform)
        let codecName = formatDescriptions.first.map(Self.codecName(for:)) ?? "Unknown"
        let warnings = Self.warnings(
            codecName: codecName,
            presentationSize: presentationSize,
            largestScreenPixelSize: largestScreenPixelSize
        )

        return VideoAssetDiagnostics(
            codecName: codecName,
            presentationSize: presentationSize,
            warnings: warnings
        )
    }

    private static func presentationSize(naturalSize: CGSize, transform: CGAffineTransform) -> CGSize {
        let transformed = CGRect(origin: .zero, size: naturalSize).applying(transform)
        return CGSize(width: abs(transformed.width), height: abs(transformed.height))
    }

    private static func codecName(for formatDescription: CMFormatDescription) -> String {
        switch CMFormatDescriptionGetMediaSubType(formatDescription) {
        case kCMVideoCodecType_H264:
            return "H.264"
        case kCMVideoCodecType_HEVC:
            return "HEVC"
        case kCMVideoCodecType_AppleProRes4444:
            return "Apple ProRes 4444"
        case kCMVideoCodecType_AppleProRes422:
            return "Apple ProRes 422"
        case kCMVideoCodecType_MPEG4Video:
            return "MPEG-4 Video"
        default:
            return fourCharacterCode(CMFormatDescriptionGetMediaSubType(formatDescription))
        }
    }

    private static func warnings(
        codecName: String,
        presentationSize: CGSize,
        largestScreenPixelSize: CGSize
    ) -> [String] {
        var warnings: [String] = []

        if !["H.264", "HEVC"].contains(codecName) {
            warnings.append("H.264 または HEVC 以外の動画です。ハードウェアデコード効率が下がる場合があります。")
        }

        let sizeTolerance = 1.25
        if largestScreenPixelSize != .zero &&
            (presentationSize.width > largestScreenPixelSize.width * sizeTolerance ||
             presentationSize.height > largestScreenPixelSize.height * sizeTolerance) {
            let videoSize = "\(Int(presentationSize.width.rounded()))x\(Int(presentationSize.height.rounded()))"
            let screenSize = "\(Int(largestScreenPixelSize.width.rounded()))x\(Int(largestScreenPixelSize.height.rounded()))"
            warnings.append("動画解像度 \(videoSize) が最大ディスプレイ \(screenSize) よりかなり大きいため、負荷が増える可能性があります。")
        }

        return warnings
    }

    private static func fourCharacterCode(_ code: FourCharCode) -> String {
        let characters = [
            UInt8((code >> 24) & 0xff),
            UInt8((code >> 16) & 0xff),
            UInt8((code >> 8) & 0xff),
            UInt8(code & 0xff)
        ]
        return String(bytes: characters, encoding: .macOSRoman) ?? "Unknown"
    }
}

enum DiagnosticsError: Error {
    case noVideoTrack
}
