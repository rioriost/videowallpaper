//
//  IntentToRenderParametersMapper.swift
//  VideoWallpaper
//

import Foundation

enum IntentToRenderParametersMapper {
    static func renderParameters(
        from intent: VisualIntent,
        capabilities: RendererCapabilities? = nil,
        reducedMotion: Bool = false
    ) -> RenderParameters {
        switch intent.rendererFamily {
        case .fieldLines:
            return .fieldLines(fieldLinesParameters(
                from: intent,
                capabilities: capabilities ?? .fieldLines,
                reducedMotion: reducedMotion
            ))
        case .orbital:
            return .orbital(orbitalParameters(
                from: intent,
                capabilities: capabilities ?? .orbital,
                reducedMotion: reducedMotion
            ))
        case .softVolumetric:
            return .softVolumetric(softVolumetricParameters(
                from: intent,
                capabilities: capabilities ?? .softVolumetric,
                reducedMotion: reducedMotion
            ))
        case .gridCity:
            return .gridCity(gridCityParameters(
                from: intent,
                capabilities: capabilities ?? .gridCity,
                reducedMotion: reducedMotion
            ))
        case .interferenceField:
            return .interferenceField(interferenceFieldParameters(
                from: intent,
                capabilities: capabilities ?? .interferenceField,
                reducedMotion: reducedMotion
            ))
        case .periodicNoise:
            return .periodicNoise(periodicNoiseParameters(
                from: intent,
                capabilities: capabilities ?? .periodicNoise,
                reducedMotion: reducedMotion
            ))
        case .cyclicAutomata:
            return .cyclicAutomata(cyclicAutomataParameters(
                from: intent,
                capabilities: capabilities ?? .cyclicAutomata,
                reducedMotion: reducedMotion
            ))
        case .agentSwarm:
            return .agentSwarm(agentSwarmParameters(
                from: intent,
                capabilities: capabilities ?? .agentSwarm,
                reducedMotion: reducedMotion
            ))
        case .kaleidoscope:
            return .kaleidoscope(kaleidoscopeParameters(
                from: intent,
                capabilities: capabilities ?? .kaleidoscope,
                reducedMotion: reducedMotion
            ))
        case .voronoiFlow:
            return .voronoiFlow(voronoiFlowParameters(
                from: intent,
                capabilities: capabilities ?? .voronoiFlow,
                reducedMotion: reducedMotion
            ))
        case .reactionDiffusion:
            return .reactionDiffusion(reactionDiffusionParameters(
                from: intent,
                capabilities: capabilities ?? .reactionDiffusion,
                reducedMotion: reducedMotion
            ))
        case .plasmaField:
            return .plasmaField(plasmaFieldParameters(
                from: intent,
                capabilities: capabilities ?? .plasmaField,
                reducedMotion: reducedMotion
            ))
        case .harmonicTunnel:
            return .harmonicTunnel(harmonicTunnelParameters(
                from: intent,
                capabilities: capabilities ?? .harmonicTunnel,
                reducedMotion: reducedMotion
            ))
        case .lissajousWeave:
            return .lissajousWeave(lissajousWeaveParameters(
                from: intent,
                capabilities: capabilities ?? .lissajousWeave,
                reducedMotion: reducedMotion
            ))
        case .phyllotaxisBloom:
            return .phyllotaxisBloom(phyllotaxisBloomParameters(
                from: intent,
                capabilities: capabilities ?? .phyllotaxisBloom,
                reducedMotion: reducedMotion
            ))
        case .hexPulseLattice:
            return .hexPulseLattice(hexPulseLatticeParameters(
                from: intent,
                capabilities: capabilities ?? .hexPulseLattice,
                reducedMotion: reducedMotion
            ))
        case .superformulaMorph:
            return .superformulaMorph(superformulaMorphParameters(
                from: intent,
                capabilities: capabilities ?? .superformulaMorph,
                reducedMotion: reducedMotion
            ))
        case .closedFlowParticles:
            return proceduralRenderParameters(
                family: .closedFlowParticles,
                from: intent,
                capabilities: capabilities ?? .closedFlowParticles,
                reducedMotion: reducedMotion
            )
        case .sdfTunnel:
            return proceduralRenderParameters(
                family: .sdfTunnel,
                from: intent,
                capabilities: capabilities ?? .sdfTunnel,
                reducedMotion: reducedMotion
            )
        case .feedbackSynth:
            return proceduralRenderParameters(
                family: .feedbackSynth,
                from: intent,
                capabilities: capabilities ?? .feedbackSynth,
                reducedMotion: reducedMotion
            )
        case .guillocheRose:
            return proceduralRenderParameters(
                family: .guillocheRose,
                from: intent,
                capabilities: capabilities ?? .guillocheRose,
                reducedMotion: reducedMotion
            )
        case .instancedGeometry:
            return proceduralRenderParameters(
                family: .instancedGeometry,
                from: intent,
                capabilities: capabilities ?? .instancedGeometry,
                reducedMotion: reducedMotion
            )
        case .metaballField:
            return proceduralRenderParameters(
                family: .metaballField,
                from: intent,
                capabilities: capabilities ?? .metaballField,
                reducedMotion: reducedMotion
            )
        case .penroseTiling:
            return proceduralRenderParameters(
                family: .penroseTiling,
                from: intent,
                capabilities: capabilities ?? .penroseTiling,
                reducedMotion: reducedMotion
            )
        case .waveTerrain:
            return proceduralRenderParameters(
                family: .waveTerrain,
                from: intent,
                capabilities: capabilities ?? .waveTerrain,
                reducedMotion: reducedMotion
            )
        }
    }

    static func fieldLinesParameters(
        from intent: VisualIntent,
        capabilities: RendererCapabilities = .fieldLines,
        reducedMotion: Bool = false
    ) -> FieldLinesParameters {
        let safeIntent = PhotosensitivitySafetyPolicy.normalizedIntent(intent, reducedMotion: reducedMotion)
        let density = safeIntent.composition.density
        let lineAmount = safeIntent.elements.lineAmount
        let particleAmount = safeIntent.elements.particleAmount
        let glow = safeIntent.elements.glowAmount
        let structure = 0.8 +
            density * 0.65 +
            safeIntent.motion.turbulence * 0.45 +
            (1.0 - safeIntent.motion.regularity) * 0.55 +
            safeIntent.elements.gridAmount * 0.35
        let rawParameters = FieldLinesParameters(
            bandCount: Int((4 + lineAmount * 14 + density * 5).rounded()),
            pointsPerBand: Int((420 + density * 780 + safeIntent.composition.depth * 260).rounded()),
            particleCount: Int((450 + particleAmount * 5_800 + density * 2_200).rounded()),
            fadeAlpha: 0.28 - safeIntent.motion.trailLength * 0.18,
            lineStep: structure,
            hueBaseDegrees: safeIntent.palette.hueBaseDegrees,
            hueDriftDegrees: safeIntent.palette.hueSpreadDegrees,
            saturation: safeIntent.palette.saturation,
            brightness: safeIntent.palette.brightness + glow * 0.1,
            lineAlpha: 0.10 + glow * 0.14 + lineAmount * 0.06,
            particleAlpha: 0.08 + particleAmount * 0.18 + glow * 0.08,
            lineWeight: 1.1 + glow * 1.7 + safeIntent.composition.depth * 0.5,
            speed: safeIntent.motion.speed,
            turbulence: safeIntent.motion.turbulence
        )

        return PhotosensitivitySafetyPolicy.safeFieldLinesParameters(
            capabilities.fieldLinesLimits.clamped(rawParameters),
            reducedMotion: reducedMotion
        )
    }

    static func orbitalParameters(
        from intent: VisualIntent,
        capabilities: RendererCapabilities = .orbital,
        reducedMotion: Bool = false
    ) -> OrbitalParameters {
        let safeIntent = PhotosensitivitySafetyPolicy.normalizedIntent(intent, reducedMotion: reducedMotion)
        let density = safeIntent.composition.density
        let symmetry = safeIntent.composition.symmetry
        let objectAmount = max(safeIntent.elements.objectAmount, safeIntent.elements.particleAmount * 0.7)
        let glow = safeIntent.elements.glowAmount
        let rawParameters = OrbitalParameters(
            orbitCount: Int((3 + density * 10 + symmetry * 4).rounded()),
            pointsPerOrbit: Int((320 + density * 620 + safeIntent.composition.depth * 360).rounded()),
            satelliteCount: Int((16 + objectAmount * 170 + density * 42).rounded()),
            fadeAlpha: 0.26 - safeIntent.motion.trailLength * 0.16,
            radiusScale: 0.72 + safeIntent.composition.depth * 0.52 + safeIntent.composition.negativeSpace * 0.18,
            hueBaseDegrees: safeIntent.palette.hueBaseDegrees,
            hueSpreadDegrees: safeIntent.palette.hueSpreadDegrees,
            saturation: safeIntent.palette.saturation,
            brightness: safeIntent.palette.brightness + glow * 0.08,
            orbitAlpha: 0.08 + safeIntent.elements.lineAmount * 0.12 + glow * 0.08,
            satelliteAlpha: 0.10 + objectAmount * 0.22 + glow * 0.08,
            glowSize: 1.1 + glow * 2.4 + safeIntent.composition.depth * 0.45,
            speed: safeIntent.motion.speed,
            eccentricity: (1.0 - safeIntent.motion.regularity) * 0.34 + safeIntent.motion.turbulence * 0.22
        )

        return PhotosensitivitySafetyPolicy.safeOrbitalParameters(
            capabilities.orbitalLimits.clamped(rawParameters),
            reducedMotion: reducedMotion
        )
    }

    static func softVolumetricParameters(
        from intent: VisualIntent,
        capabilities: RendererCapabilities = .softVolumetric,
        reducedMotion: Bool = false
    ) -> SoftVolumetricParameters {
        let safeIntent = PhotosensitivitySafetyPolicy.normalizedIntent(intent, reducedMotion: reducedMotion)
        let density = safeIntent.composition.density
        let depth = safeIntent.composition.depth
        let glow = safeIntent.elements.glowAmount
        let negativeSpace = safeIntent.composition.negativeSpace
        let rawParameters = SoftVolumetricParameters(
            cloudCount: Int((3 + density * 9 + depth * 4).rounded()),
            pointsPerCloud: Int((260 + density * 640 + glow * 260).rounded()),
            layerCount: Int((2 + depth * 4 + glow * 1.5).rounded()),
            fadeAlpha: 0.24 - safeIntent.motion.trailLength * 0.13,
            spread: 0.70 + depth * 0.48 + negativeSpace * 0.28,
            hueBaseDegrees: safeIntent.palette.hueBaseDegrees,
            hueSpreadDegrees: safeIntent.palette.hueSpreadDegrees,
            saturation: safeIntent.palette.saturation * (0.82 + glow * 0.12),
            brightness: safeIntent.palette.brightness + glow * 0.06,
            cloudAlpha: 0.035 + density * 0.055 + glow * 0.035,
            coreAlpha: 0.055 + glow * 0.13 + safeIntent.elements.particleAmount * 0.04,
            glowSize: 2.2 + glow * 4.0 + depth * 0.9,
            speed: safeIntent.motion.speed * 0.82,
            turbulence: safeIntent.motion.turbulence * 0.82 + (1.0 - safeIntent.motion.regularity) * 0.22
        )

        return PhotosensitivitySafetyPolicy.safeSoftVolumetricParameters(
            capabilities.softVolumetricLimits.clamped(rawParameters),
            reducedMotion: reducedMotion
        )
    }

    static func gridCityParameters(
        from intent: VisualIntent,
        capabilities: RendererCapabilities = .gridCity,
        reducedMotion: Bool = false
    ) -> GridCityParameters {
        let safeIntent = PhotosensitivitySafetyPolicy.normalizedIntent(intent, reducedMotion: reducedMotion)
        let density = safeIntent.composition.density
        let depth = safeIntent.composition.depth
        let gridAmount = max(safeIntent.elements.gridAmount, safeIntent.styleWeights.futureCity * 0.7)
        let glow = safeIntent.elements.glowAmount
        let rawParameters = GridCityParameters(
            laneCount: Int((5 + density * 12 + gridAmount * 8).rounded()),
            pointsPerLane: Int((120 + density * 420 + depth * 280).rounded()),
            towerCount: Int((12 + safeIntent.elements.objectAmount * 90 + safeIntent.styleWeights.futureCity * 72).rounded()),
            fadeAlpha: 0.24 - safeIntent.motion.trailLength * 0.12,
            perspective: 0.35 + depth * 0.48 + safeIntent.composition.centerPull * 0.12,
            hueBaseDegrees: safeIntent.palette.hueBaseDegrees,
            hueSpreadDegrees: safeIntent.palette.hueSpreadDegrees,
            saturation: safeIntent.palette.saturation,
            brightness: safeIntent.palette.brightness + glow * 0.08,
            gridAlpha: 0.055 + gridAmount * 0.13 + glow * 0.035,
            towerAlpha: 0.055 + density * 0.09 + glow * 0.055,
            glowSize: 1.1 + glow * 2.3 + safeIntent.styleWeights.virtual * 0.8,
            speed: safeIntent.motion.speed,
            depth: 0.42 + depth * 0.48 + gridAmount * 0.08
        )

        return PhotosensitivitySafetyPolicy.safeGridCityParameters(
            capabilities.gridCityLimits.clamped(rawParameters),
            reducedMotion: reducedMotion
        )
    }

    static func interferenceFieldParameters(
        from intent: VisualIntent,
        capabilities: RendererCapabilities = .interferenceField,
        reducedMotion: Bool = false
    ) -> InterferenceFieldParameters {
        let safeIntent = PhotosensitivitySafetyPolicy.normalizedIntent(intent, reducedMotion: reducedMotion)
        let density = safeIntent.composition.density
        let symmetry = safeIntent.composition.symmetry
        let depth = safeIntent.composition.depth
        let glow = safeIntent.elements.glowAmount
        let regularity = safeIntent.motion.regularity
        let rawParameters = InterferenceFieldParameters(
            waveCount: Int((4 + symmetry * 5 + density * 4).rounded()),
            samplesPerAxis: Int((72 + density * 42 + depth * 26).rounded()),
            fadeAlpha: 0.24 - safeIntent.motion.trailLength * 0.12,
            spatialFrequency: 0.82 + density * 0.88 + (1.0 - safeIntent.composition.negativeSpace) * 0.42,
            phaseOffset: safeIntent.palette.warmth * 120.0 + safeIntent.styleWeights.nostalgia * 60.0,
            hueBaseDegrees: safeIntent.palette.hueBaseDegrees,
            hueSpreadDegrees: safeIntent.palette.hueSpreadDegrees,
            saturation: safeIntent.palette.saturation,
            brightness: safeIntent.palette.brightness + glow * 0.10,
            pointAlpha: 0.12 + density * 0.12 + glow * 0.08,
            pointSize: 1.4 + glow * 2.1 + safeIntent.palette.contrast * 0.9,
            speed: safeIntent.motion.speed,
            symmetry: 0.35 + symmetry * 0.55 + regularity * 0.1,
            contrast: 0.18 + safeIntent.palette.contrast * 0.40 + regularity * 0.14
        )

        return PhotosensitivitySafetyPolicy.safeInterferenceFieldParameters(
            capabilities.interferenceFieldLimits.clamped(rawParameters),
            reducedMotion: reducedMotion
        )
    }

    static func periodicNoiseParameters(
        from intent: VisualIntent,
        capabilities: RendererCapabilities = .periodicNoise,
        reducedMotion: Bool = false
    ) -> PeriodicNoiseParameters {
        let safeIntent = PhotosensitivitySafetyPolicy.normalizedIntent(intent, reducedMotion: reducedMotion)
        let density = safeIntent.composition.density
        let depth = safeIntent.composition.depth
        let glow = safeIntent.elements.glowAmount
        let fluidAmount = max(safeIntent.elements.lineAmount * 0.45, safeIntent.styleWeights.fantasy * 0.35)
        let rawParameters = PeriodicNoiseParameters(
            samplesPerAxis: Int((72 + density * 48 + depth * 32).rounded()),
            octaveCount: Int((2 + density * 3 + safeIntent.motion.turbulence * 2).rounded()),
            fadeAlpha: 0.25 - safeIntent.motion.trailLength * 0.12,
            noiseScale: 0.62 + density * 0.92 + (1.0 - safeIntent.composition.negativeSpace) * 0.52,
            warpAmount: 0.18 + safeIntent.motion.turbulence * 0.42 + fluidAmount * 0.28,
            hueBaseDegrees: safeIntent.palette.hueBaseDegrees,
            hueSpreadDegrees: safeIntent.palette.hueSpreadDegrees,
            saturation: safeIntent.palette.saturation * (0.86 + glow * 0.10),
            brightness: safeIntent.palette.brightness + glow * 0.11,
            pointAlpha: 0.11 + density * 0.12 + glow * 0.075,
            pointSize: 1.35 + glow * 2.0 + safeIntent.palette.contrast * 0.9,
            speed: safeIntent.motion.speed * 0.86,
            turbulence: safeIntent.motion.turbulence * 0.92 + (1.0 - safeIntent.motion.regularity) * 0.34,
            contourSharpness: 0.28 + safeIntent.palette.contrast * 0.46 + safeIntent.motion.regularity * 0.14
        )

        return PhotosensitivitySafetyPolicy.safePeriodicNoiseParameters(
            capabilities.periodicNoiseLimits.clamped(rawParameters),
            reducedMotion: reducedMotion
        )
    }

    static func cyclicAutomataParameters(
        from intent: VisualIntent,
        capabilities: RendererCapabilities = .cyclicAutomata,
        reducedMotion: Bool = false
    ) -> CyclicAutomataParameters {
        let safeIntent = PhotosensitivitySafetyPolicy.normalizedIntent(intent, reducedMotion: reducedMotion)
        let density = safeIntent.composition.density
        let glow = safeIntent.elements.glowAmount
        let regularity = safeIntent.motion.regularity
        let rawParameters = CyclicAutomataParameters(
            cellsPerAxis: Int((54 + density * 58 + safeIntent.elements.gridAmount * 28).rounded()),
            stateCount: Int((4 + safeIntent.palette.contrast * 4 + regularity * 3).rounded()),
            fadeAlpha: 0.24 - safeIntent.motion.trailLength * 0.12,
            cellScale: 0.75 + density * 0.72 + safeIntent.composition.depth * 0.32,
            phaseOffset: safeIntent.palette.warmth * 120.0 + safeIntent.styleWeights.virtual * 45.0,
            hueBaseDegrees: safeIntent.palette.hueBaseDegrees,
            hueSpreadDegrees: max(safeIntent.palette.hueSpreadDegrees, 70.0 + glow * 40.0),
            saturation: safeIntent.palette.saturation,
            brightness: safeIntent.palette.brightness + glow * 0.08,
            cellAlpha: 0.10 + density * 0.12 + glow * 0.08,
            cellSize: 2.0 + glow * 3.0 + safeIntent.palette.contrast,
            speed: safeIntent.motion.speed,
            neighborhood: 0.25 + regularity * 0.55 + safeIntent.composition.symmetry * 0.18,
            mutation: 0.18 + safeIntent.motion.turbulence * 0.44 + (1.0 - regularity) * 0.22,
            edgeSharpness: 0.30 + safeIntent.palette.contrast * 0.46 + safeIntent.elements.gridAmount * 0.16
        )

        return PhotosensitivitySafetyPolicy.safeCyclicAutomataParameters(
            capabilities.cyclicAutomataLimits.clamped(rawParameters),
            reducedMotion: reducedMotion
        )
    }

    static func agentSwarmParameters(
        from intent: VisualIntent,
        capabilities: RendererCapabilities = .agentSwarm,
        reducedMotion: Bool = false
    ) -> AgentSwarmParameters {
        let safeIntent = PhotosensitivitySafetyPolicy.normalizedIntent(intent, reducedMotion: reducedMotion)
        let density = safeIntent.composition.density
        let glow = safeIntent.elements.glowAmount
        let particleAmount = max(safeIntent.elements.particleAmount, safeIntent.elements.objectAmount * 0.7)
        let rawParameters = AgentSwarmParameters(
            agentCount: Int((64 + density * 360 + particleAmount * 260).rounded()),
            trailCount: Int((2 + safeIntent.motion.trailLength * 7 + glow * 2).rounded()),
            fadeAlpha: 0.24 - safeIntent.motion.trailLength * 0.13,
            orbitRadius: 0.35 + safeIntent.composition.depth * 0.42 + safeIntent.composition.negativeSpace * 0.22,
            cohesion: 0.22 + safeIntent.composition.centerPull * 0.46 + safeIntent.composition.symmetry * 0.20,
            wander: 0.18 + safeIntent.motion.turbulence * 0.46 + (1.0 - safeIntent.motion.regularity) * 0.26,
            hueBaseDegrees: safeIntent.palette.hueBaseDegrees,
            hueSpreadDegrees: max(safeIntent.palette.hueSpreadDegrees, 52.0 + glow * 54.0),
            saturation: safeIntent.palette.saturation,
            brightness: safeIntent.palette.brightness + glow * 0.09,
            agentAlpha: 0.10 + glow * 0.12 + density * 0.08,
            trailAlpha: 0.04 + glow * 0.06 + safeIntent.motion.trailLength * 0.08,
            agentSize: 1.4 + glow * 2.4 + safeIntent.palette.contrast,
            speed: safeIntent.motion.speed,
            separation: 0.16 + safeIntent.composition.negativeSpace * 0.44 + safeIntent.motion.regularity * 0.18
        )

        return PhotosensitivitySafetyPolicy.safeAgentSwarmParameters(
            capabilities.agentSwarmLimits.clamped(rawParameters),
            reducedMotion: reducedMotion
        )
    }

    static func kaleidoscopeParameters(
        from intent: VisualIntent,
        capabilities: RendererCapabilities = .kaleidoscope,
        reducedMotion: Bool = false
    ) -> KaleidoscopeParameters {
        let safeIntent = PhotosensitivitySafetyPolicy.normalizedIntent(intent, reducedMotion: reducedMotion)
        let density = safeIntent.composition.density
        let symmetry = safeIntent.composition.symmetry
        let glow = safeIntent.elements.glowAmount
        let regularity = safeIntent.motion.regularity
        let rawParameters = KaleidoscopeParameters(
            ringCount: Int((4 + density * 8 + symmetry * 5).rounded()),
            segments: Int((5 + symmetry * 12 + regularity * 5).rounded()),
            pointsPerRing: Int((180 + density * 460 + glow * 150).rounded()),
            fadeAlpha: 0.24 - safeIntent.motion.trailLength * 0.12,
            radiusScale: 0.62 + safeIntent.composition.depth * 0.34 + safeIntent.composition.negativeSpace * 0.18,
            twist: 0.18 + safeIntent.motion.turbulence * 0.34 + (1.0 - regularity) * 0.22,
            petalAmount: 0.24 + symmetry * 0.48 + safeIntent.styleWeights.fantasy * 0.18,
            hueBaseDegrees: safeIntent.palette.hueBaseDegrees,
            hueSpreadDegrees: max(safeIntent.palette.hueSpreadDegrees, 62.0 + glow * 52.0),
            saturation: safeIntent.palette.saturation,
            brightness: safeIntent.palette.brightness + glow * 0.10,
            pointAlpha: 0.09 + density * 0.11 + glow * 0.08,
            pointSize: 1.2 + glow * 2.2 + safeIntent.palette.contrast * 1.2,
            speed: safeIntent.motion.speed * 0.88,
            complexity: 0.20 + safeIntent.motion.turbulence * 0.30 + density * 0.28 + safeIntent.palette.contrast * 0.18
        )

        return PhotosensitivitySafetyPolicy.safeKaleidoscopeParameters(
            capabilities.kaleidoscopeLimits.clamped(rawParameters),
            reducedMotion: reducedMotion
        )
    }

    static func voronoiFlowParameters(
        from intent: VisualIntent,
        capabilities: RendererCapabilities = .voronoiFlow,
        reducedMotion: Bool = false
    ) -> VoronoiFlowParameters {
        let safeIntent = PhotosensitivitySafetyPolicy.normalizedIntent(intent, reducedMotion: reducedMotion)
        let density = safeIntent.composition.density
        let glow = safeIntent.elements.glowAmount
        let gridAmount = max(safeIntent.elements.gridAmount, safeIntent.styleWeights.virtual * 0.25)
        let rawParameters = VoronoiFlowParameters(
            siteCount: Int((14 + density * 38 + gridAmount * 20).rounded()),
            samplesPerAxis: Int((72 + density * 42 + safeIntent.composition.depth * 24).rounded()),
            fadeAlpha: 0.24 - safeIntent.motion.trailLength * 0.12,
            cellScale: 0.72 + density * 0.54 + safeIntent.composition.depth * 0.24,
            edgeWidth: 0.18 + safeIntent.palette.contrast * 0.32 + glow * 0.10,
            pulseAmount: 0.18 + safeIntent.motion.turbulence * 0.36 + glow * 0.22,
            hueBaseDegrees: safeIntent.palette.hueBaseDegrees,
            hueSpreadDegrees: max(safeIntent.palette.hueSpreadDegrees, 48.0 + glow * 48.0),
            saturation: safeIntent.palette.saturation,
            brightness: safeIntent.palette.brightness + glow * 0.08,
            edgeAlpha: 0.10 + glow * 0.10 + safeIntent.palette.contrast * 0.08,
            fillAlpha: 0.025 + density * 0.055 + glow * 0.035,
            pointSize: 1.4 + glow * 2.0 + safeIntent.palette.contrast * 0.9,
            speed: safeIntent.motion.speed * 0.82,
            drift: 0.20 + safeIntent.motion.turbulence * 0.34 + (1.0 - safeIntent.motion.regularity) * 0.28
        )

        return PhotosensitivitySafetyPolicy.safeVoronoiFlowParameters(
            capabilities.voronoiFlowLimits.clamped(rawParameters),
            reducedMotion: reducedMotion
        )
    }

    static func reactionDiffusionParameters(
        from intent: VisualIntent,
        capabilities: RendererCapabilities = .reactionDiffusion,
        reducedMotion: Bool = false
    ) -> ReactionDiffusionParameters {
        let safeIntent = PhotosensitivitySafetyPolicy.normalizedIntent(intent, reducedMotion: reducedMotion)
        let density = safeIntent.composition.density
        let glow = safeIntent.elements.glowAmount
        let regularity = safeIntent.motion.regularity
        let rawParameters = ReactionDiffusionParameters(
            samplesPerAxis: Int((72 + density * 50 + safeIntent.composition.depth * 28).rounded()),
            layerCount: Int((3 + density * 3 + safeIntent.motion.turbulence * 2).rounded()),
            fadeAlpha: 0.24 - safeIntent.motion.trailLength * 0.12,
            patternScale: 0.64 + density * 0.82 + (1.0 - safeIntent.composition.negativeSpace) * 0.42,
            stripeSharpness: 0.24 + safeIntent.palette.contrast * 0.42 + regularity * 0.18,
            diffusion: 0.20 + safeIntent.motion.turbulence * 0.34 + safeIntent.styleWeights.fantasy * 0.20,
            hueBaseDegrees: safeIntent.palette.hueBaseDegrees,
            hueSpreadDegrees: max(safeIntent.palette.hueSpreadDegrees, 58.0 + glow * 44.0),
            saturation: safeIntent.palette.saturation,
            brightness: safeIntent.palette.brightness + glow * 0.08,
            pointAlpha: 0.10 + density * 0.12 + glow * 0.07,
            pointSize: 1.3 + glow * 2.1 + safeIntent.palette.contrast,
            speed: safeIntent.motion.speed * 0.82,
            turbulence: safeIntent.motion.turbulence * 0.92 + (1.0 - regularity) * 0.24,
            symmetry: safeIntent.composition.symmetry
        )

        return PhotosensitivitySafetyPolicy.safeReactionDiffusionParameters(
            capabilities.reactionDiffusionLimits.clamped(rawParameters),
            reducedMotion: reducedMotion
        )
    }

    static func plasmaFieldParameters(
        from intent: VisualIntent,
        capabilities: RendererCapabilities = .plasmaField,
        reducedMotion: Bool = false
    ) -> PlasmaFieldParameters {
        let safeIntent = PhotosensitivitySafetyPolicy.normalizedIntent(intent, reducedMotion: reducedMotion)
        let density = safeIntent.composition.density
        let depth = safeIntent.composition.depth
        let glow = safeIntent.elements.glowAmount
        let fluidAmount = max(safeIntent.styleWeights.fantasy * 0.35, safeIntent.elements.lineAmount * 0.30)
        let rawParameters = PlasmaFieldParameters(
            samplesPerAxis: Int((76 + density * 52 + depth * 26).rounded()),
            octaveCount: Int((2 + density * 3 + safeIntent.motion.turbulence * 2).rounded()),
            fadeAlpha: 0.24 - safeIntent.motion.trailLength * 0.12,
            waveScale: 0.58 + density * 0.84 + (1.0 - safeIntent.composition.negativeSpace) * 0.42,
            warpAmount: 0.18 + safeIntent.motion.turbulence * 0.38 + fluidAmount * 0.30,
            hueBaseDegrees: safeIntent.palette.hueBaseDegrees,
            hueSpreadDegrees: max(safeIntent.palette.hueSpreadDegrees, 70.0 + glow * 54.0),
            saturation: safeIntent.palette.saturation,
            brightness: safeIntent.palette.brightness + glow * 0.10,
            pointAlpha: 0.10 + density * 0.11 + glow * 0.08,
            pointSize: 1.3 + glow * 2.2 + safeIntent.palette.contrast,
            speed: safeIntent.motion.speed * 0.84,
            contrast: 0.22 + safeIntent.palette.contrast * 0.46 + glow * 0.12,
            flowAngle: safeIntent.palette.warmth * 120.0 + safeIntent.styleWeights.nostalgia * 80.0
        )

        return PhotosensitivitySafetyPolicy.safePlasmaFieldParameters(
            capabilities.plasmaFieldLimits.clamped(rawParameters),
            reducedMotion: reducedMotion
        )
    }

    static func harmonicTunnelParameters(
        from intent: VisualIntent,
        capabilities: RendererCapabilities = .harmonicTunnel,
        reducedMotion: Bool = false
    ) -> HarmonicTunnelParameters {
        let safeIntent = PhotosensitivitySafetyPolicy.normalizedIntent(intent, reducedMotion: reducedMotion)
        let density = safeIntent.composition.density
        let depth = safeIntent.composition.depth
        let glow = safeIntent.elements.glowAmount
        let radialEnergy = max(safeIntent.elements.lineAmount, safeIntent.styleWeights.fantasy * 0.72)
        let rawParameters = HarmonicTunnelParameters(
            ringCount: Int((18 + density * 28 + depth * 18).rounded()),
            pointsPerRing: Int((72 + density * 92 + radialEnergy * 52).rounded()),
            fadeAlpha: 0.23 - safeIntent.motion.trailLength * 0.11,
            tunnelDepth: 0.36 + depth * 0.44 + safeIntent.motion.speed * 0.08,
            waveAmplitude: 0.10 + safeIntent.motion.turbulence * 0.28 + radialEnergy * 0.14,
            twist: 0.16 + safeIntent.composition.symmetry * 0.20 + safeIntent.motion.turbulence * 0.28,
            spokeAmount: 0.12 + safeIntent.elements.gridAmount * 0.34 + radialEnergy * 0.20,
            hueBaseDegrees: safeIntent.palette.hueBaseDegrees,
            hueSpreadDegrees: max(safeIntent.palette.hueSpreadDegrees, 54.0 + glow * 48.0),
            saturation: safeIntent.palette.saturation,
            brightness: safeIntent.palette.brightness + glow * 0.09,
            pointAlpha: 0.11 + density * 0.10 + glow * 0.07,
            pointSize: 1.2 + glow * 2.0 + safeIntent.palette.contrast,
            speed: safeIntent.motion.speed * 0.88,
            perspective: 0.42 + depth * 0.42,
            centerDrift: 0.08 + safeIntent.motion.turbulence * 0.18 + (1.0 - safeIntent.motion.regularity) * 0.12
        )

        return PhotosensitivitySafetyPolicy.safeHarmonicTunnelParameters(
            capabilities.harmonicTunnelLimits.clamped(rawParameters),
            reducedMotion: reducedMotion
        )
    }

    static func lissajousWeaveParameters(
        from intent: VisualIntent,
        capabilities: RendererCapabilities = .lissajousWeave,
        reducedMotion: Bool = false
    ) -> LissajousWeaveParameters {
        let safeIntent = PhotosensitivitySafetyPolicy.normalizedIntent(intent, reducedMotion: reducedMotion)
        let density = safeIntent.composition.density
        let glow = safeIntent.elements.glowAmount
        let lineAmount = safeIntent.elements.lineAmount
        let regularity = safeIntent.motion.regularity
        let harmonicBase = 2 + Int((safeIntent.composition.symmetry * 4 + density * 2).rounded())
        let rawParameters = LissajousWeaveParameters(
            curveCount: Int((3 + lineAmount * 8 + density * 6).rounded()),
            pointsPerCurve: Int((300 + density * 480 + safeIntent.composition.depth * 260).rounded()),
            fadeAlpha: 0.24 - safeIntent.motion.trailLength * 0.13,
            frequencyX: harmonicBase,
            frequencyY: harmonicBase + 1 + Int((safeIntent.motion.turbulence * 3).rounded()),
            phaseSpread: 0.18 + regularity * 0.28 + safeIntent.styleWeights.fantasy * 0.28,
            weaveAmount: 0.10 + safeIntent.motion.turbulence * 0.28 + lineAmount * 0.30,
            modulation: 0.10 + safeIntent.palette.contrast * 0.32 + (1.0 - regularity) * 0.24,
            hueBaseDegrees: safeIntent.palette.hueBaseDegrees,
            hueSpreadDegrees: max(safeIntent.palette.hueSpreadDegrees, 52.0 + glow * 50.0),
            saturation: safeIntent.palette.saturation,
            brightness: safeIntent.palette.brightness + glow * 0.09,
            pointAlpha: 0.09 + density * 0.10 + glow * 0.08,
            pointSize: 1.1 + glow * 1.7 + safeIntent.palette.contrast,
            speed: safeIntent.motion.speed * 0.82,
            rotation: safeIntent.palette.warmth * 90.0 + safeIntent.styleWeights.nostalgia * 120.0
        )

        return PhotosensitivitySafetyPolicy.safeLissajousWeaveParameters(
            capabilities.lissajousWeaveLimits.clamped(rawParameters),
            reducedMotion: reducedMotion
        )
    }

    static func phyllotaxisBloomParameters(
        from intent: VisualIntent,
        capabilities: RendererCapabilities = .phyllotaxisBloom,
        reducedMotion: Bool = false
    ) -> PhyllotaxisBloomParameters {
        let safeIntent = PhotosensitivitySafetyPolicy.normalizedIntent(intent, reducedMotion: reducedMotion)
        let density = safeIntent.composition.density
        let depth = safeIntent.composition.depth
        let glow = safeIntent.elements.glowAmount
        let radialAmount = max(safeIntent.composition.symmetry, safeIntent.styleWeights.fantasy * 0.74)
        let rawParameters = PhyllotaxisBloomParameters(
            pointCount: Int((1400 + density * 5600 + glow * 2400 + depth * 1600).rounded()),
            armCount: Int((2 + radialAmount * 7 + safeIntent.elements.particleAmount * 3).rounded()),
            fadeAlpha: 0.24 - safeIntent.motion.trailLength * 0.13,
            spiralTightness: 0.26 + density * 0.28 + (1.0 - safeIntent.composition.negativeSpace) * 0.28,
            bloomAmount: 0.16 + depth * 0.24 + safeIntent.motion.turbulence * 0.22 + glow * 0.14,
            pulseAmount: 0.12 + glow * 0.26 + safeIntent.palette.contrast * 0.24,
            hueBaseDegrees: safeIntent.palette.hueBaseDegrees,
            hueSpreadDegrees: max(safeIntent.palette.hueSpreadDegrees, 60.0 + glow * 50.0),
            saturation: safeIntent.palette.saturation,
            brightness: safeIntent.palette.brightness + glow * 0.09,
            pointAlpha: 0.08 + density * 0.08 + glow * 0.08,
            pointSize: 1.0 + glow * 1.8 + safeIntent.palette.contrast,
            speed: safeIntent.motion.speed * 0.80,
            rotation: safeIntent.palette.warmth * 120.0 + safeIntent.styleWeights.nostalgia * 80.0,
            centerDrift: 0.06 + safeIntent.motion.turbulence * 0.16 + (1.0 - safeIntent.motion.regularity) * 0.12
        )

        return PhotosensitivitySafetyPolicy.safePhyllotaxisBloomParameters(
            capabilities.phyllotaxisBloomLimits.clamped(rawParameters),
            reducedMotion: reducedMotion
        )
    }

    static func hexPulseLatticeParameters(
        from intent: VisualIntent,
        capabilities: RendererCapabilities = .hexPulseLattice,
        reducedMotion: Bool = false
    ) -> HexPulseLatticeParameters {
        let safeIntent = PhotosensitivitySafetyPolicy.normalizedIntent(intent, reducedMotion: reducedMotion)
        let density = safeIntent.composition.density
        let glow = safeIntent.elements.glowAmount
        let gridAmount = max(safeIntent.elements.gridAmount, safeIntent.styleWeights.sciFi * 0.72)
        let rawParameters = HexPulseLatticeParameters(
            columnCount: Int((12 + density * 18 + gridAmount * 12).rounded()),
            rowCount: Int((8 + density * 12 + safeIntent.composition.depth * 8).rounded()),
            pointsPerEdge: Int((4 + density * 5 + glow * 3).rounded()),
            fadeAlpha: 0.24 - safeIntent.motion.trailLength * 0.13,
            pulseAmount: 0.16 + glow * 0.30 + safeIntent.palette.contrast * 0.24,
            waveScale: 0.16 + safeIntent.motion.turbulence * 0.28 + gridAmount * 0.28,
            lineThickness: 0.18 + safeIntent.elements.lineAmount * 0.32 + density * 0.18,
            hueBaseDegrees: safeIntent.palette.hueBaseDegrees,
            hueSpreadDegrees: max(safeIntent.palette.hueSpreadDegrees, 42.0 + glow * 44.0),
            saturation: safeIntent.palette.saturation,
            brightness: safeIntent.palette.brightness + glow * 0.08,
            pointAlpha: 0.09 + density * 0.08 + glow * 0.08,
            pointSize: 1.0 + glow * 1.8 + safeIntent.palette.contrast,
            speed: safeIntent.motion.speed * 0.78,
            rotation: safeIntent.palette.warmth * 90.0 + safeIntent.styleWeights.nostalgia * 60.0
        )

        return PhotosensitivitySafetyPolicy.safeHexPulseLatticeParameters(
            capabilities.hexPulseLatticeLimits.clamped(rawParameters),
            reducedMotion: reducedMotion
        )
    }

    static func superformulaMorphParameters(
        from intent: VisualIntent,
        capabilities: RendererCapabilities = .superformulaMorph,
        reducedMotion: Bool = false
    ) -> SuperformulaMorphParameters {
        let safeIntent = PhotosensitivitySafetyPolicy.normalizedIntent(intent, reducedMotion: reducedMotion)
        let density = safeIntent.composition.density
        let symmetry = safeIntent.composition.symmetry
        let glow = safeIntent.elements.glowAmount
        let organicAmount = max(safeIntent.styleWeights.fantasy, safeIntent.elements.objectAmount * 0.82)
        let rawParameters = SuperformulaMorphParameters(
            contourCount: Int((4 + density * 10 + safeIntent.composition.depth * 7).rounded()),
            pointsPerContour: Int((280 + density * 620 + glow * 260).rounded()),
            harmonicA: Int((3 + symmetry * 8 + organicAmount * 3).rounded()),
            harmonicB: Int((4 + safeIntent.motion.turbulence * 6 + safeIntent.palette.contrast * 5).rounded()),
            morphAmount: 0.12 + organicAmount * 0.28 + safeIntent.motion.turbulence * 0.24 + glow * 0.14,
            radialScale: 0.48 + safeIntent.composition.depth * 0.28 + (1.0 - safeIntent.composition.negativeSpace) * 0.24,
            contourSpread: 0.20 + density * 0.34 + safeIntent.composition.depth * 0.30,
            fadeAlpha: 0.24 - safeIntent.motion.trailLength * 0.13,
            hueBaseDegrees: safeIntent.palette.hueBaseDegrees,
            hueSpreadDegrees: max(safeIntent.palette.hueSpreadDegrees, 48.0 + glow * 48.0),
            saturation: safeIntent.palette.saturation,
            brightness: safeIntent.palette.brightness + glow * 0.09,
            pointAlpha: 0.08 + density * 0.10 + glow * 0.07,
            pointSize: 1.0 + glow * 1.7 + safeIntent.palette.contrast,
            speed: safeIntent.motion.speed * 0.78,
            rotation: safeIntent.palette.warmth * 130.0 + safeIntent.styleWeights.nostalgia * 90.0,
            centerDrift: 0.04 + safeIntent.motion.turbulence * 0.14 + (1.0 - safeIntent.motion.regularity) * 0.10
        )

        return PhotosensitivitySafetyPolicy.safeSuperformulaMorphParameters(
            capabilities.superformulaMorphLimits.clamped(rawParameters),
            reducedMotion: reducedMotion
        )
    }

    static func proceduralRenderParameters(
        family: RendererFamily,
        from intent: VisualIntent,
        capabilities: RendererCapabilities,
        reducedMotion: Bool = false
    ) -> RenderParameters {
        let parameters = proceduralPatternParameters(
            family: family,
            from: intent,
            capabilities: capabilities,
            reducedMotion: reducedMotion
        )

        switch family {
        case .closedFlowParticles:
            return .closedFlowParticles(parameters)
        case .sdfTunnel:
            return .sdfTunnel(parameters)
        case .feedbackSynth:
            return .feedbackSynth(parameters)
        case .guillocheRose:
            return .guillocheRose(parameters)
        case .instancedGeometry:
            return .instancedGeometry(parameters)
        case .metaballField:
            return .metaballField(parameters)
        case .penroseTiling:
            return .penroseTiling(parameters)
        case .waveTerrain:
            return .waveTerrain(parameters)
        default:
            return .defaultParameters(for: family)
        }
    }

    static func proceduralPatternParameters(
        family: RendererFamily,
        from intent: VisualIntent,
        capabilities: RendererCapabilities,
        reducedMotion: Bool = false
    ) -> ProceduralPatternParameters {
        let safeIntent = PhotosensitivitySafetyPolicy.normalizedIntent(intent, reducedMotion: reducedMotion)
        let density = safeIntent.composition.density
        let glow = safeIntent.elements.glowAmount
        let lineAmount = safeIntent.elements.lineAmount
        let objectAmount = safeIntent.elements.objectAmount
        let gridAmount = safeIntent.elements.gridAmount
        let depth = safeIntent.composition.depth
        let base = ProceduralPatternParameters.defaultParameters(for: family)
        let familyBoost = proceduralFamilyBoost(family)
        let rawParameters = ProceduralPatternParameters(
            elementCount: Int((Double(base.elementCount) * (0.72 + density * 0.52 + familyBoost.count * 0.18)).rounded()),
            samplesPerElement: Int((Double(base.samplesPerElement) * (0.72 + density * 0.42 + glow * 0.18)).rounded()),
            harmonicA: Int((Double(base.harmonicA) + safeIntent.composition.symmetry * 5 + familyBoost.harmonic).rounded()),
            harmonicB: Int((Double(base.harmonicB) + safeIntent.motion.turbulence * 6 + safeIntent.palette.contrast * 4).rounded()),
            fadeAlpha: 0.24 - safeIntent.motion.trailLength * 0.13,
            scale: base.scale * (0.74 + depth * 0.26 + (1.0 - safeIntent.composition.negativeSpace) * 0.18),
            modulation: base.modulation * 0.52 + safeIntent.motion.turbulence * 0.26 + glow * 0.18 + familyBoost.modulation,
            depth: base.depth * 0.50 + depth * 0.40 + familyBoost.depth,
            feedback: base.feedback * 0.55 + glow * 0.16 + safeIntent.palette.contrast * 0.16 + familyBoost.feedback,
            hueBaseDegrees: safeIntent.palette.hueBaseDegrees,
            hueSpreadDegrees: max(safeIntent.palette.hueSpreadDegrees, 42.0 + glow * 48.0),
            saturation: safeIntent.palette.saturation,
            brightness: safeIntent.palette.brightness + glow * 0.08,
            pointAlpha: 0.08 + density * 0.08 + lineAmount * 0.05 + objectAmount * 0.04 + gridAmount * 0.03,
            pointSize: 1.0 + glow * 1.7 + safeIntent.palette.contrast,
            speed: safeIntent.motion.speed * 0.78,
            rotation: safeIntent.palette.warmth * 120.0 + safeIntent.styleWeights.nostalgia * 72.0
        )

        return PhotosensitivitySafetyPolicy.safeProceduralPatternParameters(
            capabilities.proceduralPatternLimits.clamped(rawParameters),
            reducedMotion: reducedMotion
        )
    }

    private static func proceduralFamilyBoost(_ family: RendererFamily) -> (
        count: Double,
        harmonic: Double,
        modulation: Double,
        depth: Double,
        feedback: Double
    ) {
        switch family {
        case .closedFlowParticles:
            return (0.20, 0.0, 0.10, 0.10, 0.00)
        case .sdfTunnel:
            return (0.00, 1.0, 0.04, 0.22, 0.04)
        case .feedbackSynth:
            return (0.08, 1.0, 0.14, 0.10, 0.24)
        case .guillocheRose:
            return (-0.12, 3.0, 0.02, -0.12, -0.04)
        case .instancedGeometry:
            return (0.28, 1.0, 0.08, 0.10, 0.02)
        case .metaballField:
            return (-0.10, 0.0, 0.14, 0.08, 0.10)
        case .penroseTiling:
            return (0.18, 2.0, -0.04, -0.04, -0.06)
        case .waveTerrain:
            return (0.10, 1.0, 0.08, 0.22, 0.00)
        default:
            return (0.0, 0.0, 0.0, 0.0, 0.0)
        }
    }

    static func exportSettings(_ current: ExportSettings, applying intent: VisualIntent) -> ExportSettings {
        var settings = current
        settings.loopSeconds = intent.motion.loopSeconds.clamped(to: 4.0...30.0)
        return settings
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
