//
//  StylePreset.swift
//  VideoWallpaper
//

import Foundation

enum StylePreset: String, CaseIterable, Identifiable {
    case calmFlow
    case neonCity
    case cosmicDust
    case minimalInk
    case stormCurrent
    case sakuraMist

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .calmFlow:
            return "Calm"
        case .neonCity:
            return "Neon"
        case .cosmicDust:
            return "Cosmic"
        case .minimalInk:
            return "Minimal"
        case .stormCurrent:
            return "Storm"
        case .sakuraMist:
            return "Sakura"
        }
    }

    var systemImageName: String {
        switch self {
        case .calmFlow:
            return "water.waves"
        case .neonCity:
            return "building.2"
        case .cosmicDust:
            return "sparkles"
        case .minimalInk:
            return "circle"
        case .stormCurrent:
            return "bolt"
        case .sakuraMist:
            return "camera.macro"
        }
    }

    var promptFragment: String {
        switch self {
        case .calmFlow:
            return "calm blue gentle smooth long trail"
        case .neonCity:
            return "neon cyber future city vivid fast glow"
        case .cosmicDust:
            return "cosmic space galaxy stars dust deep glow"
        case .minimalInk:
            return "minimal simple quiet sparse smooth monochrome lines"
        case .stormCurrent:
            return "storm turbulent rapid electric dense particles"
        case .sakuraMist:
            return "soft pink pastel dreamy mist gentle flowing particles"
        }
    }

    func combinedPrompt(with userPrompt: String) -> String {
        let trimmedPrompt = userPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else {
            return promptFragment
        }
        return "\(trimmedPrompt), \(promptFragment)"
    }
}
