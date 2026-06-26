//
//  VisualIntentValidator.swift
//  VideoWallpaper
//

import Foundation

enum VisualIntentValidationError: LocalizedError, Equatable {
    case unsupportedSchemaVersion(Int)
    case unsupportedRendererFamily(RendererFamily)

    var errorDescription: String? {
        switch self {
        case .unsupportedSchemaVersion(let version):
            return "Unsupported VisualIntent schema version: \(version)"
        case .unsupportedRendererFamily(let rendererFamily):
            return "Unsupported renderer family: \(rendererFamily.displayName)"
        }
    }
}

enum VisualIntentValidator {
    static func normalized(
        _ intent: VisualIntent,
        capabilities: RendererCapabilities,
        reducedMotion: Bool = false
    ) throws -> VisualIntent {
        guard capabilities.supportedIntentSchemaVersions.contains(intent.schemaVersion) else {
            throw VisualIntentValidationError.unsupportedSchemaVersion(intent.schemaVersion)
        }

        guard capabilities.supportedRendererFamilies.contains(intent.rendererFamily) else {
            throw VisualIntentValidationError.unsupportedRendererFamily(intent.rendererFamily)
        }

        var normalizedIntent = intent
        normalizedIntent.palette.hueBaseDegrees = intent.palette.hueBaseDegrees.normalizedDegrees
        normalizedIntent.palette.hueSpreadDegrees = intent.palette.hueSpreadDegrees.clamped(to: 0...120)
        normalizedIntent.palette.saturation = intent.palette.saturation.clamped(to: 0...1)
        normalizedIntent.palette.brightness = intent.palette.brightness.clamped(to: 0...1.15)
        normalizedIntent.palette.contrast = intent.palette.contrast.clamped(to: 0...1)
        normalizedIntent.palette.warmth = intent.palette.warmth.clamped(to: 0...1)
        normalizedIntent.composition.density = intent.composition.density.clamped(to: 0...1)
        normalizedIntent.composition.symmetry = intent.composition.symmetry.clamped(to: 0...1)
        normalizedIntent.composition.depth = intent.composition.depth.clamped(to: 0...1)
        normalizedIntent.composition.centerPull = intent.composition.centerPull.clamped(to: 0...1)
        normalizedIntent.composition.negativeSpace = intent.composition.negativeSpace.clamped(to: 0...1)
        normalizedIntent.motion.loopSeconds = intent.motion.loopSeconds.clamped(to: 4...30)
        normalizedIntent.motion.speed = intent.motion.speed.clamped(to: 0.15...2.0)
        normalizedIntent.motion.turbulence = intent.motion.turbulence.clamped(to: 0.1...2.0)
        normalizedIntent.motion.regularity = intent.motion.regularity.clamped(to: 0...1)
        normalizedIntent.motion.trailLength = intent.motion.trailLength.clamped(to: 0...1)
        normalizedIntent.elements.particleAmount = intent.elements.particleAmount.clamped(to: 0...1)
        normalizedIntent.elements.lineAmount = intent.elements.lineAmount.clamped(to: 0...1)
        normalizedIntent.elements.objectAmount = intent.elements.objectAmount.clamped(to: 0...1)
        normalizedIntent.elements.gridAmount = intent.elements.gridAmount.clamped(to: 0...1)
        normalizedIntent.elements.glowAmount = intent.elements.glowAmount.clamped(to: 0...1)
        normalizedIntent.styleWeights.sciFi = intent.styleWeights.sciFi.clamped(to: 0...1)
        normalizedIntent.styleWeights.fantasy = intent.styleWeights.fantasy.clamped(to: 0...1)
        normalizedIntent.styleWeights.nostalgia = intent.styleWeights.nostalgia.clamped(to: 0...1)
        normalizedIntent.styleWeights.virtual = intent.styleWeights.virtual.clamped(to: 0...1)
        normalizedIntent.styleWeights.futureCity = intent.styleWeights.futureCity.clamped(to: 0...1)
        normalizedIntent.styleWeights.cosmic = intent.styleWeights.cosmic.clamped(to: 0...1)
        normalizedIntent.safety.flashIntensity = intent.safety.flashIntensity.clamped(to: 0...0.45)
        normalizedIntent.safety.motionIntensity = intent.safety.motionIntensity.clamped(to: 0...0.9)

        if normalizedIntent.safety.motionIntensity >= 0.9 {
            normalizedIntent.motion.speed = min(normalizedIntent.motion.speed, 1.8)
            normalizedIntent.motion.turbulence = min(normalizedIntent.motion.turbulence, 1.6)
        }

        return PhotosensitivitySafetyPolicy.normalizedIntent(normalizedIntent, reducedMotion: reducedMotion)
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

private extension Double {
    var normalizedDegrees: Double {
        let value = truncatingRemainder(dividingBy: 360)
        return value >= 0 ? value : value + 360
    }
}
