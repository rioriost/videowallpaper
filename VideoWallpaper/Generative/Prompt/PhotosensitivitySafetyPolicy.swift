//
//  PhotosensitivitySafetyPolicy.swift
//  VideoWallpaper
//

import Foundation

enum PhotosensitivitySafetyPolicy {
    static let maxFlashIntensity = 0.35
    static let maxContrast = 0.85
    static let maxBrightness = 1.05
    static let maxMotionIntensity = 0.85
    static let maxSpeedWhenPulsing = 1.4
    static let maxTurbulenceWhenPulsing = 1.35
    static let reducedMotionMaxSpeed = 0.75
    static let reducedMotionMaxTurbulence = 0.75
    static let reducedMotionMaxMotionIntensity = 0.45

    static func normalizedIntent(_ intent: VisualIntent, reducedMotion: Bool = false) -> VisualIntent {
        var normalizedIntent = intent
        normalizedIntent.palette.brightness = min(normalizedIntent.palette.brightness, maxBrightness)
        normalizedIntent.palette.contrast = min(normalizedIntent.palette.contrast, maxContrast)
        normalizedIntent.safety.flashIntensity = min(normalizedIntent.safety.flashIntensity, maxFlashIntensity)
        normalizedIntent.safety.motionIntensity = min(normalizedIntent.safety.motionIntensity, maxMotionIntensity)

        if intent.safety.flashIntensity > 0.2 || intent.palette.contrast > 0.75 {
            normalizedIntent.motion.speed = min(normalizedIntent.motion.speed, maxSpeedWhenPulsing)
            normalizedIntent.motion.turbulence = min(normalizedIntent.motion.turbulence, maxTurbulenceWhenPulsing)
            normalizedIntent.elements.glowAmount = min(normalizedIntent.elements.glowAmount, 0.8)
        }

        if reducedMotion {
            normalizedIntent.motion.speed = min(normalizedIntent.motion.speed, reducedMotionMaxSpeed)
            normalizedIntent.motion.turbulence = min(normalizedIntent.motion.turbulence, reducedMotionMaxTurbulence)
            normalizedIntent.safety.motionIntensity = min(
                normalizedIntent.safety.motionIntensity,
                reducedMotionMaxMotionIntensity
            )
        }

        return normalizedIntent
    }

    static func safeFieldLinesParameters(
        _ parameters: FieldLinesParameters,
        reducedMotion: Bool = false
    ) -> FieldLinesParameters {
        var safeParameters = parameters
        safeParameters.brightness = min(safeParameters.brightness, maxBrightness)

        if reducedMotion {
            safeParameters.speed = min(safeParameters.speed, reducedMotionMaxSpeed)
            safeParameters.turbulence = min(safeParameters.turbulence, reducedMotionMaxTurbulence)
        }

        return safeParameters
    }

    static func safeOrbitalParameters(
        _ parameters: OrbitalParameters,
        reducedMotion: Bool = false
    ) -> OrbitalParameters {
        var safeParameters = parameters
        safeParameters.brightness = min(safeParameters.brightness, maxBrightness)

        if reducedMotion {
            safeParameters.speed = min(safeParameters.speed, reducedMotionMaxSpeed)
            safeParameters.eccentricity = min(safeParameters.eccentricity, 0.45)
        }

        return safeParameters
    }

    static func safeSoftVolumetricParameters(
        _ parameters: SoftVolumetricParameters,
        reducedMotion: Bool = false
    ) -> SoftVolumetricParameters {
        var safeParameters = parameters
        safeParameters.brightness = min(safeParameters.brightness, maxBrightness)

        if reducedMotion {
            safeParameters.speed = min(safeParameters.speed, reducedMotionMaxSpeed)
            safeParameters.turbulence = min(safeParameters.turbulence, reducedMotionMaxTurbulence)
        }

        return safeParameters
    }

    static func safeGridCityParameters(
        _ parameters: GridCityParameters,
        reducedMotion: Bool = false
    ) -> GridCityParameters {
        var safeParameters = parameters
        safeParameters.brightness = min(safeParameters.brightness, maxBrightness)

        if reducedMotion {
            safeParameters.speed = min(safeParameters.speed, reducedMotionMaxSpeed)
            safeParameters.depth = min(safeParameters.depth, 0.72)
        }

        return safeParameters
    }

    static func safeInterferenceFieldParameters(
        _ parameters: InterferenceFieldParameters,
        reducedMotion: Bool = false
    ) -> InterferenceFieldParameters {
        var safeParameters = parameters
        safeParameters.brightness = min(safeParameters.brightness, maxBrightness)
        safeParameters.contrast = min(safeParameters.contrast, maxContrast)

        if reducedMotion {
            safeParameters.speed = min(safeParameters.speed, reducedMotionMaxSpeed)
            safeParameters.contrast = min(safeParameters.contrast, 0.62)
        }

        return safeParameters
    }

    static func safePeriodicNoiseParameters(
        _ parameters: PeriodicNoiseParameters,
        reducedMotion: Bool = false
    ) -> PeriodicNoiseParameters {
        var safeParameters = parameters
        safeParameters.brightness = min(safeParameters.brightness, maxBrightness)
        safeParameters.contourSharpness = min(safeParameters.contourSharpness, maxContrast)

        if reducedMotion {
            safeParameters.speed = min(safeParameters.speed, reducedMotionMaxSpeed)
            safeParameters.turbulence = min(safeParameters.turbulence, reducedMotionMaxTurbulence)
            safeParameters.contourSharpness = min(safeParameters.contourSharpness, 0.62)
        }

        return safeParameters
    }

    static func safeCyclicAutomataParameters(
        _ parameters: CyclicAutomataParameters,
        reducedMotion: Bool = false
    ) -> CyclicAutomataParameters {
        var safeParameters = parameters
        safeParameters.brightness = min(safeParameters.brightness, maxBrightness)
        safeParameters.edgeSharpness = min(safeParameters.edgeSharpness, maxContrast)

        if reducedMotion {
            safeParameters.speed = min(safeParameters.speed, reducedMotionMaxSpeed)
            safeParameters.mutation = min(safeParameters.mutation, 0.55)
            safeParameters.edgeSharpness = min(safeParameters.edgeSharpness, 0.58)
        }

        return safeParameters
    }

    static func safeAgentSwarmParameters(
        _ parameters: AgentSwarmParameters,
        reducedMotion: Bool = false
    ) -> AgentSwarmParameters {
        var safeParameters = parameters
        safeParameters.brightness = min(safeParameters.brightness, maxBrightness)

        if reducedMotion {
            safeParameters.speed = min(safeParameters.speed, reducedMotionMaxSpeed)
            safeParameters.wander = min(safeParameters.wander, 0.55)
            safeParameters.trailCount = min(safeParameters.trailCount, 6)
        }

        return safeParameters
    }

    static func safeKaleidoscopeParameters(
        _ parameters: KaleidoscopeParameters,
        reducedMotion: Bool = false
    ) -> KaleidoscopeParameters {
        var safeParameters = parameters
        safeParameters.brightness = min(safeParameters.brightness, maxBrightness)

        if reducedMotion {
            safeParameters.speed = min(safeParameters.speed, reducedMotionMaxSpeed)
            safeParameters.twist = min(safeParameters.twist, 0.58)
            safeParameters.complexity = min(safeParameters.complexity, 0.68)
        }

        return safeParameters
    }

    static func safeVoronoiFlowParameters(
        _ parameters: VoronoiFlowParameters,
        reducedMotion: Bool = false
    ) -> VoronoiFlowParameters {
        var safeParameters = parameters
        safeParameters.brightness = min(safeParameters.brightness, maxBrightness)

        if reducedMotion {
            safeParameters.speed = min(safeParameters.speed, reducedMotionMaxSpeed)
            safeParameters.drift = min(safeParameters.drift, 0.55)
            safeParameters.pulseAmount = min(safeParameters.pulseAmount, 0.55)
        }

        return safeParameters
    }

    static func safeReactionDiffusionParameters(
        _ parameters: ReactionDiffusionParameters,
        reducedMotion: Bool = false
    ) -> ReactionDiffusionParameters {
        var safeParameters = parameters
        safeParameters.brightness = min(safeParameters.brightness, maxBrightness)

        if reducedMotion {
            safeParameters.speed = min(safeParameters.speed, reducedMotionMaxSpeed)
            safeParameters.turbulence = min(safeParameters.turbulence, reducedMotionMaxTurbulence)
            safeParameters.stripeSharpness = min(safeParameters.stripeSharpness, 0.62)
        }

        return safeParameters
    }

    static func safePlasmaFieldParameters(
        _ parameters: PlasmaFieldParameters,
        reducedMotion: Bool = false
    ) -> PlasmaFieldParameters {
        var safeParameters = parameters
        safeParameters.brightness = min(safeParameters.brightness, maxBrightness)
        safeParameters.contrast = min(safeParameters.contrast, maxContrast)

        if reducedMotion {
            safeParameters.speed = min(safeParameters.speed, reducedMotionMaxSpeed)
            safeParameters.warpAmount = min(safeParameters.warpAmount, 0.75)
            safeParameters.contrast = min(safeParameters.contrast, 0.62)
        }

        return safeParameters
    }

    static func safeHarmonicTunnelParameters(
        _ parameters: HarmonicTunnelParameters,
        reducedMotion: Bool = false
    ) -> HarmonicTunnelParameters {
        var safeParameters = parameters
        safeParameters.brightness = min(safeParameters.brightness, maxBrightness)

        if reducedMotion {
            safeParameters.speed = min(safeParameters.speed, reducedMotionMaxSpeed)
            safeParameters.waveAmplitude = min(safeParameters.waveAmplitude, 0.42)
            safeParameters.twist = min(safeParameters.twist, 0.48)
            safeParameters.centerDrift = min(safeParameters.centerDrift, 0.24)
        }

        return safeParameters
    }

    static func safeLissajousWeaveParameters(
        _ parameters: LissajousWeaveParameters,
        reducedMotion: Bool = false
    ) -> LissajousWeaveParameters {
        var safeParameters = parameters
        safeParameters.brightness = min(safeParameters.brightness, maxBrightness)

        if reducedMotion {
            safeParameters.speed = min(safeParameters.speed, reducedMotionMaxSpeed)
            safeParameters.weaveAmount = min(safeParameters.weaveAmount, 0.50)
            safeParameters.modulation = min(safeParameters.modulation, 0.48)
            safeParameters.phaseSpread = min(safeParameters.phaseSpread, 0.72)
        }

        return safeParameters
    }

    static func safePhyllotaxisBloomParameters(
        _ parameters: PhyllotaxisBloomParameters,
        reducedMotion: Bool = false
    ) -> PhyllotaxisBloomParameters {
        var safeParameters = parameters
        safeParameters.brightness = min(safeParameters.brightness, maxBrightness)

        if reducedMotion {
            safeParameters.speed = min(safeParameters.speed, reducedMotionMaxSpeed)
            safeParameters.bloomAmount = min(safeParameters.bloomAmount, 0.44)
            safeParameters.pulseAmount = min(safeParameters.pulseAmount, 0.42)
            safeParameters.centerDrift = min(safeParameters.centerDrift, 0.24)
        }

        return safeParameters
    }

    static func safeHexPulseLatticeParameters(
        _ parameters: HexPulseLatticeParameters,
        reducedMotion: Bool = false
    ) -> HexPulseLatticeParameters {
        var safeParameters = parameters
        safeParameters.brightness = min(safeParameters.brightness, maxBrightness)

        if reducedMotion {
            safeParameters.speed = min(safeParameters.speed, reducedMotionMaxSpeed)
            safeParameters.pulseAmount = min(safeParameters.pulseAmount, 0.48)
            safeParameters.waveScale = min(safeParameters.waveScale, 0.48)
        }

        return safeParameters
    }

    static func safeSuperformulaMorphParameters(
        _ parameters: SuperformulaMorphParameters,
        reducedMotion: Bool = false
    ) -> SuperformulaMorphParameters {
        var safeParameters = parameters
        safeParameters.brightness = min(safeParameters.brightness, maxBrightness)

        if reducedMotion {
            safeParameters.speed = min(safeParameters.speed, reducedMotionMaxSpeed)
            safeParameters.morphAmount = min(safeParameters.morphAmount, 0.46)
            safeParameters.centerDrift = min(safeParameters.centerDrift, 0.22)
        }

        return safeParameters
    }

    static func safeProceduralPatternParameters(
        _ parameters: ProceduralPatternParameters,
        reducedMotion: Bool = false
    ) -> ProceduralPatternParameters {
        var safeParameters = parameters
        safeParameters.brightness = min(safeParameters.brightness, maxBrightness)

        if reducedMotion {
            safeParameters.speed = min(safeParameters.speed, reducedMotionMaxSpeed)
            safeParameters.modulation = min(safeParameters.modulation, 0.52)
            safeParameters.feedback = min(safeParameters.feedback, 0.48)
        }

        return safeParameters
    }
}
