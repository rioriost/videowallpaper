//
//  VisualIntentCommandEditor.swift
//  RioVideoWallpaper
//

import Foundation

enum VisualIntentCommandEditor {
    static func intent(_ current: VisualIntent, applying command: String) -> VisualIntent? {
        let normalized = command.normalizedForCommandMatching
        guard !normalized.isEmpty else {
            return nil
        }

        var edited = current
        var didEdit = false

        if normalized.matches(any: ["more particles", "more stars", "粒子を増や", "星を増や"]) {
            edited.elements.particleAmount = min(1.0, edited.elements.particleAmount + 0.18)
            edited.composition.density = min(1.0, edited.composition.density + 0.08)
            didEdit = true
        }

        if normalized.matches(any: ["slower", "slow down", "もっと遅", "ゆっくり"]) {
            edited.motion.speed = max(0.15, edited.motion.speed * 0.75)
            edited.motion.loopSeconds = min(30.0, edited.motion.loopSeconds + 2.0)
            didEdit = true
        }

        if normalized.matches(any: ["more blue", "bluer", "青く", "もっと青"]) {
            edited.palette.hueBaseDegrees = 215
            edited.palette.hueSpreadDegrees = min(95, max(28, edited.palette.hueSpreadDegrees))
            didEdit = true
        }

        if normalized.matches(any: ["less bright", "darker", "暗く", "明るさを下げ"]) {
            edited.palette.brightness = max(0.25, edited.palette.brightness - 0.12)
            edited.elements.glowAmount = max(0.0, edited.elements.glowAmount - 0.1)
            didEdit = true
        }

        if normalized.matches(any: ["longer trails", "long trail", "軌跡を長", "残像を長"]) {
            edited.motion.trailLength = min(1.0, edited.motion.trailLength + 0.2)
            didEdit = true
        }

        guard didEdit else {
            return nil
        }

        edited.summary = "Edited locally from follow-up command."
        edited.seedHint = current.seedHint
        return edited
    }
}

private extension String {
    var normalizedForCommandMatching: String {
        folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: .current)
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func matches(any keywords: [String]) -> Bool {
        keywords.contains { contains($0.normalizedForCommandMatching) }
    }
}
