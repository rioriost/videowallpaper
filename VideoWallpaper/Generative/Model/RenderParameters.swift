//
//  RenderParameters.swift
//  VideoWallpaper
//

import Foundation

struct FieldLinesParameters: Codable, Equatable {
    var bandCount: Int
    var pointsPerBand: Int
    var particleCount: Int
    var fadeAlpha: Double
    var lineStep: Double
    var hueBaseDegrees: Double
    var hueDriftDegrees: Double
    var saturation: Double
    var brightness: Double
    var lineAlpha: Double
    var particleAlpha: Double
    var lineWeight: Double
    var speed: Double
    var turbulence: Double

    static let feasibilityStudyDefault = FieldLinesParameters(
        bandCount: 9,
        pointsPerBand: 720,
        particleCount: 2200,
        fadeAlpha: 0.18,
        lineStep: 1.7,
        hueBaseDegrees: 210.0,
        hueDriftDegrees: 40.0,
        saturation: 0.90,
        brightness: 1.0,
        lineAlpha: 0.18,
        particleAlpha: 0.22,
        lineWeight: 2.0,
        speed: 1.0,
        turbulence: 1.0
    )
}

struct OrbitalParameters: Codable, Equatable {
    var orbitCount: Int
    var pointsPerOrbit: Int
    var satelliteCount: Int
    var fadeAlpha: Double
    var radiusScale: Double
    var hueBaseDegrees: Double
    var hueSpreadDegrees: Double
    var saturation: Double
    var brightness: Double
    var orbitAlpha: Double
    var satelliteAlpha: Double
    var glowSize: Double
    var speed: Double
    var eccentricity: Double

    static let defaultParameters = OrbitalParameters(
        orbitCount: 7,
        pointsPerOrbit: 680,
        satelliteCount: 64,
        fadeAlpha: 0.16,
        radiusScale: 1.0,
        hueBaseDegrees: 250.0,
        hueSpreadDegrees: 58.0,
        saturation: 0.88,
        brightness: 0.96,
        orbitAlpha: 0.16,
        satelliteAlpha: 0.28,
        glowSize: 2.2,
        speed: 0.85,
        eccentricity: 0.34
    )
}

struct SoftVolumetricParameters: Codable, Equatable {
    var cloudCount: Int
    var pointsPerCloud: Int
    var layerCount: Int
    var fadeAlpha: Double
    var spread: Double
    var hueBaseDegrees: Double
    var hueSpreadDegrees: Double
    var saturation: Double
    var brightness: Double
    var cloudAlpha: Double
    var coreAlpha: Double
    var glowSize: Double
    var speed: Double
    var turbulence: Double

    static let defaultParameters = SoftVolumetricParameters(
        cloudCount: 9,
        pointsPerCloud: 520,
        layerCount: 4,
        fadeAlpha: 0.12,
        spread: 1.0,
        hueBaseDegrees: 205.0,
        hueSpreadDegrees: 48.0,
        saturation: 0.72,
        brightness: 0.86,
        cloudAlpha: 0.07,
        coreAlpha: 0.14,
        glowSize: 5.2,
        speed: 0.62,
        turbulence: 0.82
    )
}

struct GridCityParameters: Codable, Equatable {
    var laneCount: Int
    var pointsPerLane: Int
    var towerCount: Int
    var fadeAlpha: Double
    var perspective: Double
    var hueBaseDegrees: Double
    var hueSpreadDegrees: Double
    var saturation: Double
    var brightness: Double
    var gridAlpha: Double
    var towerAlpha: Double
    var glowSize: Double
    var speed: Double
    var depth: Double

    static let defaultParameters = GridCityParameters(
        laneCount: 12,
        pointsPerLane: 260,
        towerCount: 42,
        fadeAlpha: 0.14,
        perspective: 0.72,
        hueBaseDegrees: 190.0,
        hueSpreadDegrees: 64.0,
        saturation: 0.88,
        brightness: 0.92,
        gridAlpha: 0.12,
        towerAlpha: 0.18,
        glowSize: 5.2,
        speed: 0.86,
        depth: 0.78
    )
}

struct InterferenceFieldParameters: Codable, Equatable {
    var waveCount: Int
    var samplesPerAxis: Int
    var fadeAlpha: Double
    var spatialFrequency: Double
    var phaseOffset: Double
    var hueBaseDegrees: Double
    var hueSpreadDegrees: Double
    var saturation: Double
    var brightness: Double
    var pointAlpha: Double
    var pointSize: Double
    var speed: Double
    var symmetry: Double
    var contrast: Double

    static let defaultParameters = InterferenceFieldParameters(
        waveCount: 9,
        samplesPerAxis: 132,
        fadeAlpha: 0.12,
        spatialFrequency: 1.55,
        phaseOffset: 0.0,
        hueBaseDegrees: 44.0,
        hueSpreadDegrees: 86.0,
        saturation: 0.92,
        brightness: 1.02,
        pointAlpha: 0.27,
        pointSize: 2.9,
        speed: 1.0,
        symmetry: 0.82,
        contrast: 0.58
    )
}

struct PeriodicNoiseParameters: Codable, Equatable {
    var samplesPerAxis: Int
    var octaveCount: Int
    var fadeAlpha: Double
    var noiseScale: Double
    var warpAmount: Double
    var hueBaseDegrees: Double
    var hueSpreadDegrees: Double
    var saturation: Double
    var brightness: Double
    var pointAlpha: Double
    var pointSize: Double
    var speed: Double
    var turbulence: Double
    var contourSharpness: Double

    static let defaultParameters = PeriodicNoiseParameters(
        samplesPerAxis: 136,
        octaveCount: 5,
        fadeAlpha: 0.10,
        noiseScale: 1.42,
        warpAmount: 0.82,
        hueBaseDegrees: 174.0,
        hueSpreadDegrees: 72.0,
        saturation: 0.88,
        brightness: 1.0,
        pointAlpha: 0.24,
        pointSize: 5.0,
        speed: 1.0,
        turbulence: 0.92,
        contourSharpness: 0.68
    )
}

struct CyclicAutomataParameters: Codable, Equatable {
    var cellsPerAxis: Int
    var stateCount: Int
    var fadeAlpha: Double
    var cellScale: Double
    var phaseOffset: Double
    var hueBaseDegrees: Double
    var hueSpreadDegrees: Double
    var saturation: Double
    var brightness: Double
    var cellAlpha: Double
    var cellSize: Double
    var speed: Double
    var neighborhood: Double
    var mutation: Double
    var edgeSharpness: Double

    static let defaultParameters = CyclicAutomataParameters(
        cellsPerAxis: 96,
        stateCount: 7,
        fadeAlpha: 0.08,
        cellScale: 1.0,
        phaseOffset: 0.0,
        hueBaseDegrees: 300.0,
        hueSpreadDegrees: 110.0,
        saturation: 0.92,
        brightness: 1.08,
        cellAlpha: 0.40,
        cellSize: 8.4,
        speed: 1.0,
        neighborhood: 0.58,
        mutation: 0.42,
        edgeSharpness: 0.82
    )
}

struct AgentSwarmParameters: Codable, Equatable {
    var agentCount: Int
    var trailCount: Int
    var fadeAlpha: Double
    var orbitRadius: Double
    var cohesion: Double
    var wander: Double
    var hueBaseDegrees: Double
    var hueSpreadDegrees: Double
    var saturation: Double
    var brightness: Double
    var agentAlpha: Double
    var trailAlpha: Double
    var agentSize: Double
    var speed: Double
    var separation: Double

    static let defaultParameters = AgentSwarmParameters(
        agentCount: 260,
        trailCount: 5,
        fadeAlpha: 0.10,
        orbitRadius: 0.78,
        cohesion: 0.64,
        wander: 0.72,
        hueBaseDegrees: 126.0,
        hueSpreadDegrees: 96.0,
        saturation: 0.90,
        brightness: 1.02,
        agentAlpha: 0.30,
        trailAlpha: 0.13,
        agentSize: 5.8,
        speed: 1.0,
        separation: 0.42
    )
}

struct KaleidoscopeParameters: Codable, Equatable {
    var ringCount: Int
    var segments: Int
    var pointsPerRing: Int
    var fadeAlpha: Double
    var radiusScale: Double
    var twist: Double
    var petalAmount: Double
    var hueBaseDegrees: Double
    var hueSpreadDegrees: Double
    var saturation: Double
    var brightness: Double
    var pointAlpha: Double
    var pointSize: Double
    var speed: Double
    var complexity: Double

    static let defaultParameters = KaleidoscopeParameters(
        ringCount: 9,
        segments: 10,
        pointsPerRing: 420,
        fadeAlpha: 0.11,
        radiusScale: 0.96,
        twist: 0.68,
        petalAmount: 0.72,
        hueBaseDegrees: 286.0,
        hueSpreadDegrees: 104.0,
        saturation: 0.92,
        brightness: 1.02,
        pointAlpha: 0.24,
        pointSize: 4.8,
        speed: 1.0,
        complexity: 0.72
    )
}

struct VoronoiFlowParameters: Codable, Equatable {
    var siteCount: Int
    var samplesPerAxis: Int
    var fadeAlpha: Double
    var cellScale: Double
    var edgeWidth: Double
    var pulseAmount: Double
    var hueBaseDegrees: Double
    var hueSpreadDegrees: Double
    var saturation: Double
    var brightness: Double
    var edgeAlpha: Double
    var fillAlpha: Double
    var pointSize: Double
    var speed: Double
    var drift: Double

    static let defaultParameters = VoronoiFlowParameters(
        siteCount: 38,
        samplesPerAxis: 118,
        fadeAlpha: 0.10,
        cellScale: 1.0,
        edgeWidth: 0.34,
        pulseAmount: 0.58,
        hueBaseDegrees: 178.0,
        hueSpreadDegrees: 88.0,
        saturation: 0.86,
        brightness: 1.0,
        edgeAlpha: 0.27,
        fillAlpha: 0.08,
        pointSize: 5.0,
        speed: 1.0,
        drift: 0.74
    )
}

struct ReactionDiffusionParameters: Codable, Equatable {
    var samplesPerAxis: Int
    var layerCount: Int
    var fadeAlpha: Double
    var patternScale: Double
    var stripeSharpness: Double
    var diffusion: Double
    var hueBaseDegrees: Double
    var hueSpreadDegrees: Double
    var saturation: Double
    var brightness: Double
    var pointAlpha: Double
    var pointSize: Double
    var speed: Double
    var turbulence: Double
    var symmetry: Double

    static let defaultParameters = ReactionDiffusionParameters(
        samplesPerAxis: 126,
        layerCount: 5,
        fadeAlpha: 0.10,
        patternScale: 1.24,
        stripeSharpness: 0.70,
        diffusion: 0.58,
        hueBaseDegrees: 136.0,
        hueSpreadDegrees: 92.0,
        saturation: 0.88,
        brightness: 1.0,
        pointAlpha: 0.25,
        pointSize: 2.9,
        speed: 1.0,
        turbulence: 0.86,
        symmetry: 0.48
    )
}

struct PlasmaFieldParameters: Codable, Equatable {
    var samplesPerAxis: Int
    var octaveCount: Int
    var fadeAlpha: Double
    var waveScale: Double
    var warpAmount: Double
    var hueBaseDegrees: Double
    var hueSpreadDegrees: Double
    var saturation: Double
    var brightness: Double
    var pointAlpha: Double
    var pointSize: Double
    var speed: Double
    var contrast: Double
    var flowAngle: Double

    static let defaultParameters = PlasmaFieldParameters(
        samplesPerAxis: 150,
        octaveCount: 5,
        fadeAlpha: 0.08,
        waveScale: 1.18,
        warpAmount: 0.82,
        hueBaseDegrees: 314.0,
        hueSpreadDegrees: 118.0,
        saturation: 0.92,
        brightness: 1.12,
        pointAlpha: 0.34,
        pointSize: 7.0,
        speed: 1.0,
        contrast: 0.72,
        flowAngle: 24.0
    )
}

struct HarmonicTunnelParameters: Codable, Equatable {
    var ringCount: Int
    var pointsPerRing: Int
    var fadeAlpha: Double
    var tunnelDepth: Double
    var waveAmplitude: Double
    var twist: Double
    var spokeAmount: Double
    var hueBaseDegrees: Double
    var hueSpreadDegrees: Double
    var saturation: Double
    var brightness: Double
    var pointAlpha: Double
    var pointSize: Double
    var speed: Double
    var perspective: Double
    var centerDrift: Double

    static let defaultParameters = HarmonicTunnelParameters(
        ringCount: 38,
        pointsPerRing: 288,
        fadeAlpha: 0.10,
        tunnelDepth: 0.82,
        waveAmplitude: 0.26,
        twist: 0.58,
        spokeAmount: 0.44,
        hueBaseDegrees: 214.0,
        hueSpreadDegrees: 104.0,
        saturation: 0.88,
        brightness: 1.0,
        pointAlpha: 0.27,
        pointSize: 7.0,
        speed: 1.0,
        perspective: 0.72,
        centerDrift: 0.24
    )
}

struct LissajousWeaveParameters: Codable, Equatable {
    var curveCount: Int
    var pointsPerCurve: Int
    var fadeAlpha: Double
    var frequencyX: Int
    var frequencyY: Int
    var phaseSpread: Double
    var weaveAmount: Double
    var modulation: Double
    var hueBaseDegrees: Double
    var hueSpreadDegrees: Double
    var saturation: Double
    var brightness: Double
    var pointAlpha: Double
    var pointSize: Double
    var speed: Double
    var rotation: Double

    static let defaultParameters = LissajousWeaveParameters(
        curveCount: 9,
        pointsPerCurve: 760,
        fadeAlpha: 0.11,
        frequencyX: 3,
        frequencyY: 4,
        phaseSpread: 0.62,
        weaveAmount: 0.46,
        modulation: 0.38,
        hueBaseDegrees: 188.0,
        hueSpreadDegrees: 98.0,
        saturation: 0.90,
        brightness: 1.0,
        pointAlpha: 0.23,
        pointSize: 4.8,
        speed: 1.0,
        rotation: 0.0
    )
}

struct PhyllotaxisBloomParameters: Codable, Equatable {
    var pointCount: Int
    var armCount: Int
    var fadeAlpha: Double
    var spiralTightness: Double
    var bloomAmount: Double
    var pulseAmount: Double
    var hueBaseDegrees: Double
    var hueSpreadDegrees: Double
    var saturation: Double
    var brightness: Double
    var pointAlpha: Double
    var pointSize: Double
    var speed: Double
    var rotation: Double
    var centerDrift: Double

    static let defaultParameters = PhyllotaxisBloomParameters(
        pointCount: 7600,
        armCount: 5,
        fadeAlpha: 0.08,
        spiralTightness: 0.64,
        bloomAmount: 0.54,
        pulseAmount: 0.50,
        hueBaseDegrees: 42.0,
        hueSpreadDegrees: 116.0,
        saturation: 0.88,
        brightness: 1.08,
        pointAlpha: 0.30,
        pointSize: 4.2,
        speed: 1.0,
        rotation: 0.0,
        centerDrift: 0.18
    )
}

struct HexPulseLatticeParameters: Codable, Equatable {
    var columnCount: Int
    var rowCount: Int
    var pointsPerEdge: Int
    var fadeAlpha: Double
    var pulseAmount: Double
    var waveScale: Double
    var lineThickness: Double
    var hueBaseDegrees: Double
    var hueSpreadDegrees: Double
    var saturation: Double
    var brightness: Double
    var pointAlpha: Double
    var pointSize: Double
    var speed: Double
    var rotation: Double

    static let defaultParameters = HexPulseLatticeParameters(
        columnCount: 32,
        rowCount: 16,
        pointsPerEdge: 8,
        fadeAlpha: 0.10,
        pulseAmount: 0.56,
        waveScale: 0.62,
        lineThickness: 0.62,
        hueBaseDegrees: 184.0,
        hueSpreadDegrees: 96.0,
        saturation: 0.88,
        brightness: 1.0,
        pointAlpha: 0.28,
        pointSize: 4.8,
        speed: 1.0,
        rotation: 0.0
    )
}

struct SuperformulaMorphParameters: Codable, Equatable {
    var contourCount: Int
    var pointsPerContour: Int
    var harmonicA: Int
    var harmonicB: Int
    var morphAmount: Double
    var radialScale: Double
    var contourSpread: Double
    var fadeAlpha: Double
    var hueBaseDegrees: Double
    var hueSpreadDegrees: Double
    var saturation: Double
    var brightness: Double
    var pointAlpha: Double
    var pointSize: Double
    var speed: Double
    var rotation: Double
    var centerDrift: Double

    static let defaultParameters = SuperformulaMorphParameters(
        contourCount: 11,
        pointsPerContour: 760,
        harmonicA: 5,
        harmonicB: 8,
        morphAmount: 0.58,
        radialScale: 0.82,
        contourSpread: 0.72,
        fadeAlpha: 0.10,
        hueBaseDegrees: 318.0,
        hueSpreadDegrees: 104.0,
        saturation: 0.86,
        brightness: 1.0,
        pointAlpha: 0.20,
        pointSize: 2.2,
        speed: 1.0,
        rotation: 0.0,
        centerDrift: 0.16
    )
}

struct ProceduralPatternParameters: Codable, Equatable {
    var elementCount: Int
    var samplesPerElement: Int
    var harmonicA: Int
    var harmonicB: Int
    var fadeAlpha: Double
    var scale: Double
    var modulation: Double
    var depth: Double
    var feedback: Double
    var hueBaseDegrees: Double
    var hueSpreadDegrees: Double
    var saturation: Double
    var brightness: Double
    var pointAlpha: Double
    var pointSize: Double
    var speed: Double
    var rotation: Double

    static func defaultParameters(for rendererFamily: RendererFamily) -> ProceduralPatternParameters {
        switch rendererFamily {
        case .auroraCurtain:
            return ProceduralPatternParameters(
                elementCount: 54,
                samplesPerElement: 260,
                harmonicA: 5,
                harmonicB: 9,
                fadeAlpha: 0.05,
                scale: 1.42,
                modulation: 0.80,
                depth: 0.72,
                feedback: 0.18,
                hueBaseDegrees: 184,
                hueSpreadDegrees: 112,
                saturation: 0.92,
                brightness: 1.18,
                pointAlpha: 0.34,
                pointSize: 5.4,
                speed: 1.0,
                rotation: 0
            )
        case .cityLightsBokeh:
            return ProceduralPatternParameters(
                elementCount: 110,
                samplesPerElement: 16,
                harmonicA: 4,
                harmonicB: 9,
                fadeAlpha: 0.06,
                scale: 1.36,
                modulation: 0.70,
                depth: 0.78,
                feedback: 0.18,
                hueBaseDegrees: 42,
                hueSpreadDegrees: 120,
                saturation: 0.90,
                brightness: 1.18,
                pointAlpha: 0.34,
                pointSize: 7.2,
                speed: 1.0,
                rotation: 0
            )
        case .digitalSand:
            return ProceduralPatternParameters(
                elementCount: 128,
                samplesPerElement: 22,
                harmonicA: 5,
                harmonicB: 11,
                fadeAlpha: 0.07,
                scale: 1.42,
                modulation: 0.74,
                depth: 0.58,
                feedback: 0.16,
                hueBaseDegrees: 48,
                hueSpreadDegrees: 112,
                saturation: 0.86,
                brightness: 1.14,
                pointAlpha: 0.36,
                pointSize: 5.2,
                speed: 1.0,
                rotation: 0
            )
        case .inkInWater:
            return ProceduralPatternParameters(
                elementCount: 48,
                samplesPerElement: 260,
                harmonicA: 4,
                harmonicB: 7,
                fadeAlpha: 0.05,
                scale: 1.38,
                modulation: 0.84,
                depth: 0.78,
                feedback: 0.20,
                hueBaseDegrees: 256,
                hueSpreadDegrees: 118,
                saturation: 0.78,
                brightness: 1.10,
                pointAlpha: 0.28,
                pointSize: 4.8,
                speed: 1.0,
                rotation: 0
            )
        case .origamiTessellation:
            return ProceduralPatternParameters(
                elementCount: 72,
                samplesPerElement: 12,
                harmonicA: 5,
                harmonicB: 8,
                fadeAlpha: 0.07,
                scale: 1.34,
                modulation: 0.68,
                depth: 0.58,
                feedback: 0.12,
                hueBaseDegrees: 34,
                hueSpreadDegrees: 92,
                saturation: 0.82,
                brightness: 1.10,
                pointAlpha: 0.34,
                pointSize: 6.4,
                speed: 1.0,
                rotation: 0
            )
        case .sakuraDrift:
            return ProceduralPatternParameters(
                elementCount: 124,
                samplesPerElement: 8,
                harmonicA: 4,
                harmonicB: 7,
                fadeAlpha: 0.06,
                scale: 1.34,
                modulation: 0.64,
                depth: 0.70,
                feedback: 0.16,
                hueBaseDegrees: 340,
                hueSpreadDegrees: 44,
                saturation: 0.70,
                brightness: 1.12,
                pointAlpha: 0.34,
                pointSize: 6.2,
                speed: 1.0,
                rotation: 0
            )
        case .snowfallDepth:
            return ProceduralPatternParameters(
                elementCount: 150,
                samplesPerElement: 8,
                harmonicA: 3,
                harmonicB: 8,
                fadeAlpha: 0.05,
                scale: 1.38,
                modulation: 0.58,
                depth: 0.84,
                feedback: 0.12,
                hueBaseDegrees: 206,
                hueSpreadDegrees: 38,
                saturation: 0.36,
                brightness: 1.20,
                pointAlpha: 0.36,
                pointSize: 5.8,
                speed: 1.0,
                rotation: 0
            )
        case .solarCorona:
            return ProceduralPatternParameters(
                elementCount: 92,
                samplesPerElement: 80,
                harmonicA: 7,
                harmonicB: 13,
                fadeAlpha: 0.06,
                scale: 1.22,
                modulation: 0.82,
                depth: 0.70,
                feedback: 0.20,
                hueBaseDegrees: 28,
                hueSpreadDegrees: 92,
                saturation: 0.96,
                brightness: 1.16,
                pointAlpha: 0.30,
                pointSize: 5.0,
                speed: 1.0,
                rotation: 0
            )
        case .underwaterCaustics:
            return ProceduralPatternParameters(
                elementCount: 72,
                samplesPerElement: 300,
                harmonicA: 5,
                harmonicB: 9,
                fadeAlpha: 0.05,
                scale: 1.42,
                modulation: 0.74,
                depth: 0.62,
                feedback: 0.14,
                hueBaseDegrees: 186,
                hueSpreadDegrees: 70,
                saturation: 0.82,
                brightness: 1.18,
                pointAlpha: 0.28,
                pointSize: 4.4,
                speed: 1.0,
                rotation: 0
            )
        case .volumetricNebula:
            return ProceduralPatternParameters(
                elementCount: 78,
                samplesPerElement: 130,
                harmonicA: 4,
                harmonicB: 11,
                fadeAlpha: 0.05,
                scale: 1.42,
                modulation: 0.82,
                depth: 0.80,
                feedback: 0.24,
                hueBaseDegrees: 276,
                hueSpreadDegrees: 150,
                saturation: 0.84,
                brightness: 1.14,
                pointAlpha: 0.26,
                pointSize: 5.6,
                speed: 1.0,
                rotation: 0
            )
        case .bloomingCircuits:
            return ProceduralPatternParameters(
                elementCount: 44,
                samplesPerElement: 28,
                harmonicA: 5,
                harmonicB: 9,
                fadeAlpha: 0.06,
                scale: 1.36,
                modulation: 0.74,
                depth: 0.64,
                feedback: 0.26,
                hueBaseDegrees: 178,
                hueSpreadDegrees: 118,
                saturation: 0.94,
                brightness: 1.12,
                pointAlpha: 0.34,
                pointSize: 5.8,
                speed: 1.0,
                rotation: 0
            )
        case .cellularBloom:
            return ProceduralPatternParameters(
                elementCount: 70,
                samplesPerElement: 16,
                harmonicA: 4,
                harmonicB: 7,
                fadeAlpha: 0.07,
                scale: 1.42,
                modulation: 0.68,
                depth: 0.60,
                feedback: 0.22,
                hueBaseDegrees: 126,
                hueSpreadDegrees: 124,
                saturation: 0.90,
                brightness: 1.10,
                pointAlpha: 0.36,
                pointSize: 6.6,
                speed: 1.0,
                rotation: 0
            )
        case .constellationDrift:
            return ProceduralPatternParameters(
                elementCount: 106,
                samplesPerElement: 18,
                harmonicA: 6,
                harmonicB: 11,
                fadeAlpha: 0.04,
                scale: 1.42,
                modulation: 0.76,
                depth: 0.62,
                feedback: 0.26,
                hueBaseDegrees: 218,
                hueSpreadDegrees: 118,
                saturation: 0.92,
                brightness: 1.24,
                pointAlpha: 0.42,
                pointSize: 7.2,
                speed: 1.0,
                rotation: 0
            )
        case .dataMesh:
            return ProceduralPatternParameters(
                elementCount: 54,
                samplesPerElement: 42,
                harmonicA: 5,
                harmonicB: 11,
                fadeAlpha: 0.05,
                scale: 1.36,
                modulation: 0.78,
                depth: 0.66,
                feedback: 0.26,
                hueBaseDegrees: 190,
                hueSpreadDegrees: 128,
                saturation: 0.94,
                brightness: 1.14,
                pointAlpha: 0.36,
                pointSize: 5.8,
                speed: 1.0,
                rotation: 0
            )
        case .fluidNodes:
            return ProceduralPatternParameters(
                elementCount: 76,
                samplesPerElement: 22,
                harmonicA: 4,
                harmonicB: 9,
                fadeAlpha: 0.06,
                scale: 1.34,
                modulation: 0.82,
                depth: 0.72,
                feedback: 0.34,
                hueBaseDegrees: 174,
                hueSpreadDegrees: 112,
                saturation: 0.88,
                brightness: 1.10,
                pointAlpha: 0.32,
                pointSize: 6.8,
                speed: 1.0,
                rotation: 0
            )
        case .fireworksShow:
            return ProceduralPatternParameters(
                elementCount: 18,
                samplesPerElement: 180,
                harmonicA: 5,
                harmonicB: 11,
                fadeAlpha: 0.04,
                scale: 0.67,
                modulation: 0.82,
                depth: 0.68,
                feedback: 0.24,
                hueBaseDegrees: 24,
                hueSpreadDegrees: 230,
                saturation: 0.94,
                brightness: 1.20,
                pointAlpha: 0.40,
                pointSize: 5.8,
                speed: 1.0,
                rotation: 0
            )
        case .luminousBubbles:
            return ProceduralPatternParameters(
                elementCount: 42,
                samplesPerElement: 160,
                harmonicA: 3,
                harmonicB: 8,
                fadeAlpha: 0.05,
                scale: 1.28,
                modulation: 0.76,
                depth: 0.70,
                feedback: 0.30,
                hueBaseDegrees: 188,
                hueSpreadDegrees: 96,
                saturation: 0.76,
                brightness: 1.16,
                pointAlpha: 0.26,
                pointSize: 4.8,
                speed: 1.0,
                rotation: 0
            )
        case .particleFountain:
            return ProceduralPatternParameters(
                elementCount: 108,
                samplesPerElement: 12,
                harmonicA: 4,
                harmonicB: 9,
                fadeAlpha: 0.06,
                scale: 0.46,
                modulation: 0.76,
                depth: 0.72,
                feedback: 0.26,
                hueBaseDegrees: 38,
                hueSpreadDegrees: 132,
                saturation: 0.94,
                brightness: 1.14,
                pointAlpha: 0.34,
                pointSize: 5.6,
                speed: 1.0,
                rotation: 0
            )
        case .pulseNetwork:
            return ProceduralPatternParameters(
                elementCount: 72,
                samplesPerElement: 18,
                harmonicA: 5,
                harmonicB: 12,
                fadeAlpha: 0.06,
                scale: 0.70,
                modulation: 0.70,
                depth: 0.64,
                feedback: 0.30,
                hueBaseDegrees: 194,
                hueSpreadDegrees: 130,
                saturation: 0.94,
                brightness: 1.12,
                pointAlpha: 0.34,
                pointSize: 5.8,
                speed: 1.0,
                rotation: 0
            )
        case .schoolingSwarm:
            return ProceduralPatternParameters(
                elementCount: 128,
                samplesPerElement: 8,
                harmonicA: 6,
                harmonicB: 7,
                fadeAlpha: 0.06,
                scale: 1.32,
                modulation: 0.78,
                depth: 0.66,
                feedback: 0.24,
                hueBaseDegrees: 198,
                hueSpreadDegrees: 102,
                saturation: 0.90,
                brightness: 1.12,
                pointAlpha: 0.34,
                pointSize: 8.2,
                speed: 1.0,
                rotation: 0
            )
        case .wireframeMorph:
            return ProceduralPatternParameters(
                elementCount: 32,
                samplesPerElement: 34,
                harmonicA: 5,
                harmonicB: 9,
                fadeAlpha: 0.06,
                scale: 1.34,
                modulation: 0.72,
                depth: 0.72,
                feedback: 0.20,
                hueBaseDegrees: 216,
                hueSpreadDegrees: 120,
                saturation: 0.92,
                brightness: 1.12,
                pointAlpha: 0.34,
                pointSize: 5.4,
                speed: 1.0,
                rotation: 0
            )
        case .ribbonCascade:
            return ProceduralPatternParameters(
                elementCount: 22,
                samplesPerElement: 720,
                harmonicA: 4,
                harmonicB: 10,
                fadeAlpha: 0.05,
                scale: 1.38,
                modulation: 0.82,
                depth: 0.54,
                feedback: 0.20,
                hueBaseDegrees: 286,
                hueSpreadDegrees: 144,
                saturation: 0.96,
                brightness: 1.14,
                pointAlpha: 0.30,
                pointSize: 4.8,
                speed: 1.0,
                rotation: 0
            )
        case .scanlineTopography:
            return ProceduralPatternParameters(
                elementCount: 72,
                samplesPerElement: 320,
                harmonicA: 5,
                harmonicB: 13,
                fadeAlpha: 0.04,
                scale: 1.42,
                modulation: 0.82,
                depth: 0.74,
                feedback: 0.18,
                hueBaseDegrees: 168,
                hueSpreadDegrees: 108,
                saturation: 0.94,
                brightness: 1.22,
                pointAlpha: 0.38,
                pointSize: 6.4,
                speed: 1.0,
                rotation: 0
            )
        case .chladniPlate:
            return ProceduralPatternParameters(
                elementCount: 128,
                samplesPerElement: 92,
                harmonicA: 4,
                harmonicB: 7,
                fadeAlpha: 0.06,
                scale: 1.50,
                modulation: 0.62,
                depth: 0.48,
                feedback: 0.10,
                hueBaseDegrees: 224,
                hueSpreadDegrees: 96,
                saturation: 0.88,
                brightness: 1.12,
                pointAlpha: 0.34,
                pointSize: 4.8,
                speed: 1.0,
                rotation: 0
            )
        case .circuitTracer:
            return ProceduralPatternParameters(
                elementCount: 34,
                samplesPerElement: 44,
                harmonicA: 5,
                harmonicB: 11,
                fadeAlpha: 0.06,
                scale: 1.28,
                modulation: 0.78,
                depth: 0.58,
                feedback: 0.30,
                hueBaseDegrees: 176,
                hueSpreadDegrees: 118,
                saturation: 0.94,
                brightness: 1.12,
                pointAlpha: 0.34,
                pointSize: 5.6,
                speed: 1.0,
                rotation: 0
            )
        case .closedFlowParticles:
            return ProceduralPatternParameters(
                elementCount: 42,
                samplesPerElement: 180,
                harmonicA: 3,
                harmonicB: 5,
                fadeAlpha: 0.10,
                scale: 1.00,
                modulation: 0.74,
                depth: 0.58,
                feedback: 0.18,
                hueBaseDegrees: 188,
                hueSpreadDegrees: 86,
                saturation: 0.88,
                brightness: 1.0,
                pointAlpha: 0.24,
                pointSize: 4.0,
                speed: 1.0,
                rotation: 0
            )
        case .crystalLattice:
            return ProceduralPatternParameters(
                elementCount: 72,
                samplesPerElement: 34,
                harmonicA: 6,
                harmonicB: 10,
                fadeAlpha: 0.06,
                scale: 1.50,
                modulation: 0.66,
                depth: 0.64,
                feedback: 0.14,
                hueBaseDegrees: 188,
                hueSpreadDegrees: 96,
                saturation: 0.92,
                brightness: 1.12,
                pointAlpha: 0.36,
                pointSize: 7.0,
                speed: 1.0,
                rotation: 0
            )
        case .electricStorm:
            return ProceduralPatternParameters(
                elementCount: 68,
                samplesPerElement: 96,
                harmonicA: 7,
                harmonicB: 13,
                fadeAlpha: 0.05,
                scale: 1.42,
                modulation: 0.88,
                depth: 0.62,
                feedback: 0.28,
                hueBaseDegrees: 214,
                hueSpreadDegrees: 132,
                saturation: 0.95,
                brightness: 1.12,
                pointAlpha: 0.34,
                pointSize: 5.8,
                speed: 1.0,
                rotation: 0
            )
        case .sdfTunnel:
            return ProceduralPatternParameters(
                elementCount: 34,
                samplesPerElement: 96,
                harmonicA: 5,
                harmonicB: 7,
                fadeAlpha: 0.08,
                scale: 1.00,
                modulation: 0.62,
                depth: 0.92,
                feedback: 0.22,
                hueBaseDegrees: 262,
                hueSpreadDegrees: 96,
                saturation: 0.90,
                brightness: 1.0,
                pointAlpha: 0.24,
                pointSize: 6.2,
                speed: 1.0,
                rotation: 0
            )
        case .feedbackSynth:
            return ProceduralPatternParameters(
                elementCount: 28,
                samplesPerElement: 220,
                harmonicA: 4,
                harmonicB: 9,
                fadeAlpha: 0.06,
                scale: 1.18,
                modulation: 0.76,
                depth: 0.66,
                feedback: 0.72,
                hueBaseDegrees: 302,
                hueSpreadDegrees: 118,
                saturation: 0.88,
                brightness: 1.0,
                pointAlpha: 0.20,
                pointSize: 4.0,
                speed: 1.0,
                rotation: 0
            )
        case .fourierKnots:
            return ProceduralPatternParameters(
                elementCount: 18,
                samplesPerElement: 760,
                harmonicA: 3,
                harmonicB: 7,
                fadeAlpha: 0.08,
                scale: 1.06,
                modulation: 0.72,
                depth: 0.52,
                feedback: 0.12,
                hueBaseDegrees: 286,
                hueSpreadDegrees: 108,
                saturation: 0.90,
                brightness: 1.08,
                pointAlpha: 0.26,
                pointSize: 3.8,
                speed: 1.0,
                rotation: 0
            )
        case .guillocheRose:
            return ProceduralPatternParameters(
                elementCount: 14,
                samplesPerElement: 900,
                harmonicA: 7,
                harmonicB: 11,
                fadeAlpha: 0.12,
                scale: 1.00,
                modulation: 0.52,
                depth: 0.36,
                feedback: 0.10,
                hueBaseDegrees: 42,
                hueSpreadDegrees: 72,
                saturation: 0.72,
                brightness: 0.96,
                pointAlpha: 0.24,
                pointSize: 3.4,
                speed: 1.0,
                rotation: 0
            )
        case .growingNetwork:
            return ProceduralPatternParameters(
                elementCount: 62,
                samplesPerElement: 8,
                harmonicA: 5,
                harmonicB: 13,
                fadeAlpha: 0.07,
                scale: 1.22,
                modulation: 0.72,
                depth: 0.66,
                feedback: 0.34,
                hueBaseDegrees: 204,
                hueSpreadDegrees: 132,
                saturation: 0.92,
                brightness: 1.10,
                pointAlpha: 0.34,
                pointSize: 6.4,
                speed: 1.0,
                rotation: 0
            )
        case .laserRibbons:
            return ProceduralPatternParameters(
                elementCount: 18,
                samplesPerElement: 920,
                harmonicA: 4,
                harmonicB: 9,
                fadeAlpha: 0.05,
                scale: 1.28,
                modulation: 0.84,
                depth: 0.44,
                feedback: 0.18,
                hueBaseDegrees: 306,
                hueSpreadDegrees: 128,
                saturation: 0.94,
                brightness: 1.12,
                pointAlpha: 0.30,
                pointSize: 4.6,
                speed: 1.0,
                rotation: 0
            )
        case .instancedGeometry:
            return ProceduralPatternParameters(
                elementCount: 112,
                samplesPerElement: 8,
                harmonicA: 5,
                harmonicB: 8,
                fadeAlpha: 0.07,
                scale: 1.12,
                modulation: 0.64,
                depth: 0.70,
                feedback: 0.26,
                hueBaseDegrees: 206,
                hueSpreadDegrees: 92,
                saturation: 0.88,
                brightness: 1.08,
                pointAlpha: 0.34,
                pointSize: 9.2,
                speed: 1.0,
                rotation: 0
            )
        case .metaballField:
            return ProceduralPatternParameters(
                elementCount: 12,
                samplesPerElement: 360,
                harmonicA: 3,
                harmonicB: 4,
                fadeAlpha: 0.08,
                scale: 1.00,
                modulation: 0.70,
                depth: 0.54,
                feedback: 0.34,
                hueBaseDegrees: 168,
                hueSpreadDegrees: 80,
                saturation: 0.80,
                brightness: 1.0,
                pointAlpha: 0.24,
                pointSize: 4.8,
                speed: 1.0,
                rotation: 0
            )
        case .moireRings:
            return ProceduralPatternParameters(
                elementCount: 34,
                samplesPerElement: 560,
                harmonicA: 9,
                harmonicB: 13,
                fadeAlpha: 0.09,
                scale: 1.34,
                modulation: 0.64,
                depth: 0.46,
                feedback: 0.14,
                hueBaseDegrees: 58,
                hueSpreadDegrees: 88,
                saturation: 0.84,
                brightness: 1.08,
                pointAlpha: 0.28,
                pointSize: 3.8,
                speed: 1.0,
                rotation: 0
            )
        case .neonVortex:
            return ProceduralPatternParameters(
                elementCount: 46,
                samplesPerElement: 420,
                harmonicA: 5,
                harmonicB: 12,
                fadeAlpha: 0.05,
                scale: 1.38,
                modulation: 0.86,
                depth: 0.72,
                feedback: 0.22,
                hueBaseDegrees: 278,
                hueSpreadDegrees: 144,
                saturation: 0.96,
                brightness: 1.12,
                pointAlpha: 0.32,
                pointSize: 5.2,
                speed: 1.0,
                rotation: 0
            )
        case .radialOscilloscope:
            return ProceduralPatternParameters(
                elementCount: 42,
                samplesPerElement: 720,
                harmonicA: 5,
                harmonicB: 11,
                fadeAlpha: 0.08,
                scale: 1.18,
                modulation: 0.74,
                depth: 0.50,
                feedback: 0.10,
                hueBaseDegrees: 324,
                hueSpreadDegrees: 116,
                saturation: 0.90,
                brightness: 1.08,
                pointAlpha: 0.25,
                pointSize: 3.8,
                speed: 1.0,
                rotation: 0
            )
        case .rainCurtain:
            return ProceduralPatternParameters(
                elementCount: 96,
                samplesPerElement: 18,
                harmonicA: 4,
                harmonicB: 9,
                fadeAlpha: 0.06,
                scale: 1.34,
                modulation: 0.62,
                depth: 0.72,
                feedback: 0.22,
                hueBaseDegrees: 198,
                hueSpreadDegrees: 92,
                saturation: 0.88,
                brightness: 1.12,
                pointAlpha: 0.32,
                pointSize: 4.8,
                speed: 1.0,
                rotation: 0
            )
        case .penroseTiling:
            return ProceduralPatternParameters(
                elementCount: 72,
                samplesPerElement: 7,
                harmonicA: 5,
                harmonicB: 10,
                fadeAlpha: 0.12,
                scale: 1.00,
                modulation: 0.42,
                depth: 0.42,
                feedback: 0.12,
                hueBaseDegrees: 54,
                hueSpreadDegrees: 112,
                saturation: 0.78,
                brightness: 0.96,
                pointAlpha: 0.30,
                pointSize: 6.4,
                speed: 1.0,
                rotation: 0
            )
        case .truchetFlow:
            return ProceduralPatternParameters(
                elementCount: 30,
                samplesPerElement: 18,
                harmonicA: 4,
                harmonicB: 9,
                fadeAlpha: 0.08,
                scale: 1.50,
                modulation: 0.66,
                depth: 0.40,
                feedback: 0.10,
                hueBaseDegrees: 156,
                hueSpreadDegrees: 88,
                saturation: 0.86,
                brightness: 1.06,
                pointAlpha: 0.28,
                pointSize: 4.4,
                speed: 1.0,
                rotation: 0
            )
        case .waveTerrain:
            return ProceduralPatternParameters(
                elementCount: 36,
                samplesPerElement: 260,
                harmonicA: 4,
                harmonicB: 7,
                fadeAlpha: 0.10,
                scale: 1.50,
                modulation: 0.68,
                depth: 0.84,
                feedback: 0.20,
                hueBaseDegrees: 196,
                hueSpreadDegrees: 86,
                saturation: 0.82,
                brightness: 0.98,
                pointAlpha: 0.24,
                pointSize: 5.4,
                speed: 1.0,
                rotation: 0
            )
        case .chromaticBloom:
            return ProceduralPatternParameters(
                elementCount: 96,
                samplesPerElement: 20,
                harmonicA: 5,
                harmonicB: 12,
                fadeAlpha: 0.05,
                scale: 1.42,
                modulation: 0.86,
                depth: 0.72,
                feedback: 0.32,
                hueBaseDegrees: 300,
                hueSpreadDegrees: 180,
                saturation: 0.96,
                brightness: 1.18,
                pointAlpha: 0.38,
                pointSize: 6.8,
                speed: 1.0,
                rotation: 0
            )
        case .labyrinthTrace:
            return ProceduralPatternParameters(
                elementCount: 26,
                samplesPerElement: 28,
                harmonicA: 5,
                harmonicB: 9,
                fadeAlpha: 0.05,
                scale: 1.46,
                modulation: 0.74,
                depth: 0.62,
                feedback: 0.18,
                hueBaseDegrees: 142,
                hueSpreadDegrees: 168,
                saturation: 0.92,
                brightness: 1.18,
                pointAlpha: 0.36,
                pointSize: 5.6,
                speed: 1.0,
                rotation: 0
            )
        case .photonStreams:
            return ProceduralPatternParameters(
                elementCount: 58,
                samplesPerElement: 140,
                harmonicA: 7,
                harmonicB: 15,
                fadeAlpha: 0.04,
                scale: 1.34,
                modulation: 0.88,
                depth: 0.68,
                feedback: 0.24,
                hueBaseDegrees: 204,
                hueSpreadDegrees: 160,
                saturation: 0.96,
                brightness: 1.20,
                pointAlpha: 0.32,
                pointSize: 5.6,
                speed: 1.0,
                rotation: 0
            )
        case .luminousStrings:
            return ProceduralPatternParameters(
                elementCount: 18,
                samplesPerElement: 360,
                harmonicA: 4,
                harmonicB: 11,
                fadeAlpha: 0.04,
                scale: 1.44,
                modulation: 0.88,
                depth: 0.70,
                feedback: 0.26,
                hueBaseDegrees: 190,
                hueSpreadDegrees: 185,
                saturation: 0.96,
                brightness: 1.20,
                pointAlpha: 0.30,
                pointSize: 5.2,
                speed: 1.0,
                rotation: 0
            )
        case .quantumFoam:
            return ProceduralPatternParameters(
                elementCount: 118,
                samplesPerElement: 24,
                harmonicA: 5,
                harmonicB: 9,
                fadeAlpha: 0.05,
                scale: 1.42,
                modulation: 0.86,
                depth: 0.80,
                feedback: 0.34,
                hueBaseDegrees: 166,
                hueSpreadDegrees: 138,
                saturation: 0.86,
                brightness: 1.18,
                pointAlpha: 0.34,
                pointSize: 6.6,
                speed: 1.0,
                rotation: 0
            )
        case .stardustVortex:
            return ProceduralPatternParameters(
                elementCount: 88,
                samplesPerElement: 90,
                harmonicA: 7,
                harmonicB: 13,
                fadeAlpha: 0.04,
                scale: 1.38,
                modulation: 0.88,
                depth: 0.82,
                feedback: 0.26,
                hueBaseDegrees: 230,
                hueSpreadDegrees: 168,
                saturation: 0.92,
                brightness: 1.20,
                pointAlpha: 0.32,
                pointSize: 5.8,
                speed: 1.0,
                rotation: 0
            )
        case .vortexLattice:
            return ProceduralPatternParameters(
                elementCount: 74,
                samplesPerElement: 72,
                harmonicA: 6,
                harmonicB: 15,
                fadeAlpha: 0.05,
                scale: 1.42,
                modulation: 0.78,
                depth: 0.76,
                feedback: 0.24,
                hueBaseDegrees: 126,
                hueSpreadDegrees: 176,
                saturation: 0.90,
                brightness: 1.16,
                pointAlpha: 0.34,
                pointSize: 5.8,
                speed: 1.0,
                rotation: 0
            )
        default:
            return ProceduralPatternParameters(
                elementCount: 32,
                samplesPerElement: 180,
                harmonicA: 4,
                harmonicB: 7,
                fadeAlpha: 0.10,
                scale: 1.00,
                modulation: 0.64,
                depth: 0.62,
                feedback: 0.24,
                hueBaseDegrees: 210,
                hueSpreadDegrees: 90,
                saturation: 0.86,
                brightness: 1.0,
                pointAlpha: 0.24,
                pointSize: 4.0,
                speed: 1.0,
                rotation: 0
            )
        }
    }
}

enum RenderParameters: Codable, Equatable {
    case fieldLines(FieldLinesParameters)
    case orbital(OrbitalParameters)
    case softVolumetric(SoftVolumetricParameters)
    case gridCity(GridCityParameters)
    case interferenceField(InterferenceFieldParameters)
    case periodicNoise(PeriodicNoiseParameters)
    case cyclicAutomata(CyclicAutomataParameters)
    case agentSwarm(AgentSwarmParameters)
    case auroraCurtain(ProceduralPatternParameters)
    case kaleidoscope(KaleidoscopeParameters)
    case voronoiFlow(VoronoiFlowParameters)
    case reactionDiffusion(ReactionDiffusionParameters)
    case plasmaField(PlasmaFieldParameters)
    case harmonicTunnel(HarmonicTunnelParameters)
    case lissajousWeave(LissajousWeaveParameters)
    case phyllotaxisBloom(PhyllotaxisBloomParameters)
    case hexPulseLattice(HexPulseLatticeParameters)
    case superformulaMorph(SuperformulaMorphParameters)
    case bloomingCircuits(ProceduralPatternParameters)
    case cellularBloom(ProceduralPatternParameters)
    case chladniPlate(ProceduralPatternParameters)
    case circuitTracer(ProceduralPatternParameters)
    case cityLightsBokeh(ProceduralPatternParameters)
    case closedFlowParticles(ProceduralPatternParameters)
    case constellationDrift(ProceduralPatternParameters)
    case crystalLattice(ProceduralPatternParameters)
    case dataMesh(ProceduralPatternParameters)
    case digitalSand(ProceduralPatternParameters)
    case electricStorm(ProceduralPatternParameters)
    case sdfTunnel(ProceduralPatternParameters)
    case feedbackSynth(ProceduralPatternParameters)
    case fireworksShow(ProceduralPatternParameters)
    case fluidNodes(ProceduralPatternParameters)
    case fourierKnots(ProceduralPatternParameters)
    case guillocheRose(ProceduralPatternParameters)
    case growingNetwork(ProceduralPatternParameters)
    case instancedGeometry(ProceduralPatternParameters)
    case inkInWater(ProceduralPatternParameters)
    case laserRibbons(ProceduralPatternParameters)
    case luminousBubbles(ProceduralPatternParameters)
    case metaballField(ProceduralPatternParameters)
    case moireRings(ProceduralPatternParameters)
    case neonVortex(ProceduralPatternParameters)
    case origamiTessellation(ProceduralPatternParameters)
    case particleFountain(ProceduralPatternParameters)
    case penroseTiling(ProceduralPatternParameters)
    case pulseNetwork(ProceduralPatternParameters)
    case radialOscilloscope(ProceduralPatternParameters)
    case rainCurtain(ProceduralPatternParameters)
    case ribbonCascade(ProceduralPatternParameters)
    case sakuraDrift(ProceduralPatternParameters)
    case scanlineTopography(ProceduralPatternParameters)
    case schoolingSwarm(ProceduralPatternParameters)
    case snowfallDepth(ProceduralPatternParameters)
    case solarCorona(ProceduralPatternParameters)
    case truchetFlow(ProceduralPatternParameters)
    case underwaterCaustics(ProceduralPatternParameters)
    case volumetricNebula(ProceduralPatternParameters)
    case waveTerrain(ProceduralPatternParameters)
    case wireframeMorph(ProceduralPatternParameters)
    case proceduralPattern(RendererFamily, ProceduralPatternParameters)

    private enum CodingKeys: String, CodingKey {
        case rendererFamily
        case fieldLines
        case orbital
        case softVolumetric
        case gridCity
        case interferenceField
        case periodicNoise
        case cyclicAutomata
        case agentSwarm
        case auroraCurtain
        case kaleidoscope
        case voronoiFlow
        case reactionDiffusion
        case plasmaField
        case harmonicTunnel
        case lissajousWeave
        case phyllotaxisBloom
        case hexPulseLattice
        case superformulaMorph
        case bloomingCircuits
        case cellularBloom
        case chladniPlate
        case circuitTracer
        case cityLightsBokeh
        case closedFlowParticles
        case constellationDrift
        case crystalLattice
        case dataMesh
        case digitalSand
        case electricStorm
        case sdfTunnel
        case feedbackSynth
        case fireworksShow
        case fluidNodes
        case fourierKnots
        case guillocheRose
        case growingNetwork
        case instancedGeometry
        case inkInWater
        case laserRibbons
        case luminousBubbles
        case metaballField
        case moireRings
        case neonVortex
        case origamiTessellation
        case particleFountain
        case penroseTiling
        case pulseNetwork
        case radialOscilloscope
        case rainCurtain
        case ribbonCascade
        case sakuraDrift
        case scanlineTopography
        case schoolingSwarm
        case snowfallDepth
        case solarCorona
        case truchetFlow
        case underwaterCaustics
        case volumetricNebula
        case waveTerrain
        case wireframeMorph
        case proceduralPattern
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let family = try container.decode(RendererFamily.self, forKey: .rendererFamily)

        switch family {
        case .fieldLines:
            self = .fieldLines(try container.decode(FieldLinesParameters.self, forKey: .fieldLines))
        case .orbital:
            self = .orbital(try container.decode(OrbitalParameters.self, forKey: .orbital))
        case .softVolumetric:
            self = .softVolumetric(try container.decode(SoftVolumetricParameters.self, forKey: .softVolumetric))
        case .gridCity:
            self = .gridCity(try container.decode(GridCityParameters.self, forKey: .gridCity))
        case .interferenceField:
            self = .interferenceField(try container.decode(InterferenceFieldParameters.self, forKey: .interferenceField))
        case .periodicNoise:
            self = .periodicNoise(try container.decode(PeriodicNoiseParameters.self, forKey: .periodicNoise))
        case .cyclicAutomata:
            self = .cyclicAutomata(try container.decode(CyclicAutomataParameters.self, forKey: .cyclicAutomata))
        case .agentSwarm:
            self = .agentSwarm(try container.decode(AgentSwarmParameters.self, forKey: .agentSwarm))
        case .kaleidoscope:
            self = .kaleidoscope(try container.decode(KaleidoscopeParameters.self, forKey: .kaleidoscope))
        case .voronoiFlow:
            self = .voronoiFlow(try container.decode(VoronoiFlowParameters.self, forKey: .voronoiFlow))
        case .reactionDiffusion:
            self = .reactionDiffusion(
                try container.decode(ReactionDiffusionParameters.self, forKey: .reactionDiffusion)
            )
        case .plasmaField:
            self = .plasmaField(try container.decode(PlasmaFieldParameters.self, forKey: .plasmaField))
        case .harmonicTunnel:
            self = .harmonicTunnel(try container.decode(HarmonicTunnelParameters.self, forKey: .harmonicTunnel))
        case .lissajousWeave:
            self = .lissajousWeave(try container.decode(LissajousWeaveParameters.self, forKey: .lissajousWeave))
        case .phyllotaxisBloom:
            self = .phyllotaxisBloom(
                try container.decode(PhyllotaxisBloomParameters.self, forKey: .phyllotaxisBloom)
            )
        case .hexPulseLattice:
            self = .hexPulseLattice(
                try container.decode(HexPulseLatticeParameters.self, forKey: .hexPulseLattice)
            )
        case .superformulaMorph:
            self = .superformulaMorph(
                try container.decode(SuperformulaMorphParameters.self, forKey: .superformulaMorph)
            )
        case .bloomingCircuits:
            self = .bloomingCircuits(
                try container.decode(ProceduralPatternParameters.self, forKey: .bloomingCircuits)
            )
        case .auroraCurtain:
            self = .auroraCurtain(try container.decode(ProceduralPatternParameters.self, forKey: .auroraCurtain))
        case .cellularBloom:
            self = .cellularBloom(try container.decode(ProceduralPatternParameters.self, forKey: .cellularBloom))
        case .chladniPlate:
            self = .chladniPlate(try container.decode(ProceduralPatternParameters.self, forKey: .chladniPlate))
        case .circuitTracer:
            self = .circuitTracer(try container.decode(ProceduralPatternParameters.self, forKey: .circuitTracer))
        case .cityLightsBokeh:
            self = .cityLightsBokeh(try container.decode(ProceduralPatternParameters.self, forKey: .cityLightsBokeh))
        case .closedFlowParticles:
            self = .closedFlowParticles(try container.decode(ProceduralPatternParameters.self, forKey: .closedFlowParticles))
        case .constellationDrift:
            self = .constellationDrift(
                try container.decode(ProceduralPatternParameters.self, forKey: .constellationDrift)
            )
        case .crystalLattice:
            self = .crystalLattice(try container.decode(ProceduralPatternParameters.self, forKey: .crystalLattice))
        case .dataMesh:
            self = .dataMesh(try container.decode(ProceduralPatternParameters.self, forKey: .dataMesh))
        case .digitalSand:
            self = .digitalSand(try container.decode(ProceduralPatternParameters.self, forKey: .digitalSand))
        case .electricStorm:
            self = .electricStorm(try container.decode(ProceduralPatternParameters.self, forKey: .electricStorm))
        case .sdfTunnel:
            self = .sdfTunnel(try container.decode(ProceduralPatternParameters.self, forKey: .sdfTunnel))
        case .feedbackSynth:
            self = .feedbackSynth(try container.decode(ProceduralPatternParameters.self, forKey: .feedbackSynth))
        case .fireworksShow:
            self = .fireworksShow(try container.decode(ProceduralPatternParameters.self, forKey: .fireworksShow))
        case .fluidNodes:
            self = .fluidNodes(try container.decode(ProceduralPatternParameters.self, forKey: .fluidNodes))
        case .fourierKnots:
            self = .fourierKnots(try container.decode(ProceduralPatternParameters.self, forKey: .fourierKnots))
        case .guillocheRose:
            self = .guillocheRose(try container.decode(ProceduralPatternParameters.self, forKey: .guillocheRose))
        case .growingNetwork:
            self = .growingNetwork(try container.decode(ProceduralPatternParameters.self, forKey: .growingNetwork))
        case .instancedGeometry:
            self = .instancedGeometry(try container.decode(ProceduralPatternParameters.self, forKey: .instancedGeometry))
        case .inkInWater:
            self = .inkInWater(try container.decode(ProceduralPatternParameters.self, forKey: .inkInWater))
        case .laserRibbons:
            self = .laserRibbons(try container.decode(ProceduralPatternParameters.self, forKey: .laserRibbons))
        case .luminousBubbles:
            self = .luminousBubbles(try container.decode(ProceduralPatternParameters.self, forKey: .luminousBubbles))
        case .metaballField:
            self = .metaballField(try container.decode(ProceduralPatternParameters.self, forKey: .metaballField))
        case .moireRings:
            self = .moireRings(try container.decode(ProceduralPatternParameters.self, forKey: .moireRings))
        case .neonVortex:
            self = .neonVortex(try container.decode(ProceduralPatternParameters.self, forKey: .neonVortex))
        case .origamiTessellation:
            self = .origamiTessellation(try container.decode(ProceduralPatternParameters.self, forKey: .origamiTessellation))
        case .particleFountain:
            self = .particleFountain(
                try container.decode(ProceduralPatternParameters.self, forKey: .particleFountain)
            )
        case .penroseTiling:
            self = .penroseTiling(try container.decode(ProceduralPatternParameters.self, forKey: .penroseTiling))
        case .pulseNetwork:
            self = .pulseNetwork(try container.decode(ProceduralPatternParameters.self, forKey: .pulseNetwork))
        case .radialOscilloscope:
            self = .radialOscilloscope(
                try container.decode(ProceduralPatternParameters.self, forKey: .radialOscilloscope)
            )
        case .rainCurtain:
            self = .rainCurtain(try container.decode(ProceduralPatternParameters.self, forKey: .rainCurtain))
        case .ribbonCascade:
            self = .ribbonCascade(try container.decode(ProceduralPatternParameters.self, forKey: .ribbonCascade))
        case .sakuraDrift:
            self = .sakuraDrift(try container.decode(ProceduralPatternParameters.self, forKey: .sakuraDrift))
        case .scanlineTopography:
            self = .scanlineTopography(
                try container.decode(ProceduralPatternParameters.self, forKey: .scanlineTopography)
            )
        case .schoolingSwarm:
            self = .schoolingSwarm(try container.decode(ProceduralPatternParameters.self, forKey: .schoolingSwarm))
        case .snowfallDepth:
            self = .snowfallDepth(try container.decode(ProceduralPatternParameters.self, forKey: .snowfallDepth))
        case .solarCorona:
            self = .solarCorona(try container.decode(ProceduralPatternParameters.self, forKey: .solarCorona))
        case .truchetFlow:
            self = .truchetFlow(try container.decode(ProceduralPatternParameters.self, forKey: .truchetFlow))
        case .underwaterCaustics:
            self = .underwaterCaustics(try container.decode(ProceduralPatternParameters.self, forKey: .underwaterCaustics))
        case .volumetricNebula:
            self = .volumetricNebula(try container.decode(ProceduralPatternParameters.self, forKey: .volumetricNebula))
        case .waveTerrain:
            self = .waveTerrain(try container.decode(ProceduralPatternParameters.self, forKey: .waveTerrain))
        case .wireframeMorph:
            self = .wireframeMorph(try container.decode(ProceduralPatternParameters.self, forKey: .wireframeMorph))
        case .chromaticBloom,
             .labyrinthTrace,
             .photonStreams,
             .luminousStrings,
             .quantumFoam,
             .stardustVortex,
             .vortexLattice:
            self = .proceduralPattern(
                family,
                try container.decode(ProceduralPatternParameters.self, forKey: .proceduralPattern)
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .fieldLines(let parameters):
            try container.encode(RendererFamily.fieldLines, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .fieldLines)
        case .orbital(let parameters):
            try container.encode(RendererFamily.orbital, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .orbital)
        case .softVolumetric(let parameters):
            try container.encode(RendererFamily.softVolumetric, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .softVolumetric)
        case .gridCity(let parameters):
            try container.encode(RendererFamily.gridCity, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .gridCity)
        case .interferenceField(let parameters):
            try container.encode(RendererFamily.interferenceField, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .interferenceField)
        case .periodicNoise(let parameters):
            try container.encode(RendererFamily.periodicNoise, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .periodicNoise)
        case .cyclicAutomata(let parameters):
            try container.encode(RendererFamily.cyclicAutomata, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .cyclicAutomata)
        case .agentSwarm(let parameters):
            try container.encode(RendererFamily.agentSwarm, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .agentSwarm)
        case .kaleidoscope(let parameters):
            try container.encode(RendererFamily.kaleidoscope, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .kaleidoscope)
        case .voronoiFlow(let parameters):
            try container.encode(RendererFamily.voronoiFlow, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .voronoiFlow)
        case .reactionDiffusion(let parameters):
            try container.encode(RendererFamily.reactionDiffusion, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .reactionDiffusion)
        case .plasmaField(let parameters):
            try container.encode(RendererFamily.plasmaField, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .plasmaField)
        case .harmonicTunnel(let parameters):
            try container.encode(RendererFamily.harmonicTunnel, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .harmonicTunnel)
        case .lissajousWeave(let parameters):
            try container.encode(RendererFamily.lissajousWeave, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .lissajousWeave)
        case .phyllotaxisBloom(let parameters):
            try container.encode(RendererFamily.phyllotaxisBloom, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .phyllotaxisBloom)
        case .hexPulseLattice(let parameters):
            try container.encode(RendererFamily.hexPulseLattice, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .hexPulseLattice)
        case .superformulaMorph(let parameters):
            try container.encode(RendererFamily.superformulaMorph, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .superformulaMorph)
        case .bloomingCircuits(let parameters):
            try container.encode(RendererFamily.bloomingCircuits, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .bloomingCircuits)
        case .auroraCurtain(let parameters):
            try container.encode(RendererFamily.auroraCurtain, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .auroraCurtain)
        case .cellularBloom(let parameters):
            try container.encode(RendererFamily.cellularBloom, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .cellularBloom)
        case .chladniPlate(let parameters):
            try container.encode(RendererFamily.chladniPlate, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .chladniPlate)
        case .circuitTracer(let parameters):
            try container.encode(RendererFamily.circuitTracer, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .circuitTracer)
        case .cityLightsBokeh(let parameters):
            try container.encode(RendererFamily.cityLightsBokeh, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .cityLightsBokeh)
        case .closedFlowParticles(let parameters):
            try container.encode(RendererFamily.closedFlowParticles, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .closedFlowParticles)
        case .constellationDrift(let parameters):
            try container.encode(RendererFamily.constellationDrift, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .constellationDrift)
        case .crystalLattice(let parameters):
            try container.encode(RendererFamily.crystalLattice, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .crystalLattice)
        case .dataMesh(let parameters):
            try container.encode(RendererFamily.dataMesh, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .dataMesh)
        case .digitalSand(let parameters):
            try container.encode(RendererFamily.digitalSand, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .digitalSand)
        case .electricStorm(let parameters):
            try container.encode(RendererFamily.electricStorm, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .electricStorm)
        case .sdfTunnel(let parameters):
            try container.encode(RendererFamily.sdfTunnel, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .sdfTunnel)
        case .feedbackSynth(let parameters):
            try container.encode(RendererFamily.feedbackSynth, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .feedbackSynth)
        case .fireworksShow(let parameters):
            try container.encode(RendererFamily.fireworksShow, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .fireworksShow)
        case .fluidNodes(let parameters):
            try container.encode(RendererFamily.fluidNodes, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .fluidNodes)
        case .fourierKnots(let parameters):
            try container.encode(RendererFamily.fourierKnots, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .fourierKnots)
        case .guillocheRose(let parameters):
            try container.encode(RendererFamily.guillocheRose, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .guillocheRose)
        case .growingNetwork(let parameters):
            try container.encode(RendererFamily.growingNetwork, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .growingNetwork)
        case .instancedGeometry(let parameters):
            try container.encode(RendererFamily.instancedGeometry, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .instancedGeometry)
        case .inkInWater(let parameters):
            try container.encode(RendererFamily.inkInWater, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .inkInWater)
        case .laserRibbons(let parameters):
            try container.encode(RendererFamily.laserRibbons, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .laserRibbons)
        case .luminousBubbles(let parameters):
            try container.encode(RendererFamily.luminousBubbles, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .luminousBubbles)
        case .metaballField(let parameters):
            try container.encode(RendererFamily.metaballField, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .metaballField)
        case .moireRings(let parameters):
            try container.encode(RendererFamily.moireRings, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .moireRings)
        case .neonVortex(let parameters):
            try container.encode(RendererFamily.neonVortex, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .neonVortex)
        case .origamiTessellation(let parameters):
            try container.encode(RendererFamily.origamiTessellation, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .origamiTessellation)
        case .particleFountain(let parameters):
            try container.encode(RendererFamily.particleFountain, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .particleFountain)
        case .penroseTiling(let parameters):
            try container.encode(RendererFamily.penroseTiling, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .penroseTiling)
        case .pulseNetwork(let parameters):
            try container.encode(RendererFamily.pulseNetwork, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .pulseNetwork)
        case .radialOscilloscope(let parameters):
            try container.encode(RendererFamily.radialOscilloscope, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .radialOscilloscope)
        case .rainCurtain(let parameters):
            try container.encode(RendererFamily.rainCurtain, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .rainCurtain)
        case .ribbonCascade(let parameters):
            try container.encode(RendererFamily.ribbonCascade, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .ribbonCascade)
        case .sakuraDrift(let parameters):
            try container.encode(RendererFamily.sakuraDrift, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .sakuraDrift)
        case .scanlineTopography(let parameters):
            try container.encode(RendererFamily.scanlineTopography, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .scanlineTopography)
        case .schoolingSwarm(let parameters):
            try container.encode(RendererFamily.schoolingSwarm, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .schoolingSwarm)
        case .snowfallDepth(let parameters):
            try container.encode(RendererFamily.snowfallDepth, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .snowfallDepth)
        case .solarCorona(let parameters):
            try container.encode(RendererFamily.solarCorona, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .solarCorona)
        case .truchetFlow(let parameters):
            try container.encode(RendererFamily.truchetFlow, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .truchetFlow)
        case .underwaterCaustics(let parameters):
            try container.encode(RendererFamily.underwaterCaustics, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .underwaterCaustics)
        case .volumetricNebula(let parameters):
            try container.encode(RendererFamily.volumetricNebula, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .volumetricNebula)
        case .waveTerrain(let parameters):
            try container.encode(RendererFamily.waveTerrain, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .waveTerrain)
        case .wireframeMorph(let parameters):
            try container.encode(RendererFamily.wireframeMorph, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .wireframeMorph)
        case .proceduralPattern(let family, let parameters):
            try container.encode(family, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .proceduralPattern)
        }
    }

    var rendererFamily: RendererFamily {
        switch self {
        case .fieldLines:
            return .fieldLines
        case .orbital:
            return .orbital
        case .softVolumetric:
            return .softVolumetric
        case .gridCity:
            return .gridCity
        case .interferenceField:
            return .interferenceField
        case .periodicNoise:
            return .periodicNoise
        case .cyclicAutomata:
            return .cyclicAutomata
        case .agentSwarm:
            return .agentSwarm
        case .kaleidoscope:
            return .kaleidoscope
        case .voronoiFlow:
            return .voronoiFlow
        case .reactionDiffusion:
            return .reactionDiffusion
        case .plasmaField:
            return .plasmaField
        case .harmonicTunnel:
            return .harmonicTunnel
        case .lissajousWeave:
            return .lissajousWeave
        case .phyllotaxisBloom:
            return .phyllotaxisBloom
        case .hexPulseLattice:
            return .hexPulseLattice
        case .superformulaMorph:
            return .superformulaMorph
        case .bloomingCircuits:
            return .bloomingCircuits
        case .auroraCurtain:
            return .auroraCurtain
        case .cellularBloom:
            return .cellularBloom
        case .chladniPlate:
            return .chladniPlate
        case .circuitTracer:
            return .circuitTracer
        case .cityLightsBokeh:
            return .cityLightsBokeh
        case .closedFlowParticles:
            return .closedFlowParticles
        case .constellationDrift:
            return .constellationDrift
        case .crystalLattice:
            return .crystalLattice
        case .dataMesh:
            return .dataMesh
        case .digitalSand:
            return .digitalSand
        case .electricStorm:
            return .electricStorm
        case .sdfTunnel:
            return .sdfTunnel
        case .feedbackSynth:
            return .feedbackSynth
        case .fireworksShow:
            return .fireworksShow
        case .fluidNodes:
            return .fluidNodes
        case .fourierKnots:
            return .fourierKnots
        case .guillocheRose:
            return .guillocheRose
        case .growingNetwork:
            return .growingNetwork
        case .instancedGeometry:
            return .instancedGeometry
        case .inkInWater:
            return .inkInWater
        case .laserRibbons:
            return .laserRibbons
        case .luminousBubbles:
            return .luminousBubbles
        case .metaballField:
            return .metaballField
        case .moireRings:
            return .moireRings
        case .neonVortex:
            return .neonVortex
        case .origamiTessellation:
            return .origamiTessellation
        case .particleFountain:
            return .particleFountain
        case .penroseTiling:
            return .penroseTiling
        case .pulseNetwork:
            return .pulseNetwork
        case .radialOscilloscope:
            return .radialOscilloscope
        case .rainCurtain:
            return .rainCurtain
        case .ribbonCascade:
            return .ribbonCascade
        case .sakuraDrift:
            return .sakuraDrift
        case .scanlineTopography:
            return .scanlineTopography
        case .schoolingSwarm:
            return .schoolingSwarm
        case .snowfallDepth:
            return .snowfallDepth
        case .solarCorona:
            return .solarCorona
        case .truchetFlow:
            return .truchetFlow
        case .underwaterCaustics:
            return .underwaterCaustics
        case .volumetricNebula:
            return .volumetricNebula
        case .waveTerrain:
            return .waveTerrain
        case .wireframeMorph:
            return .wireframeMorph
        case .proceduralPattern(let family, _):
            return family
        }
    }

    var speed: Double {
        switch self {
        case .fieldLines(let parameters):
            return parameters.speed
        case .orbital(let parameters):
            return parameters.speed
        case .softVolumetric(let parameters):
            return parameters.speed
        case .gridCity(let parameters):
            return parameters.speed
        case .interferenceField(let parameters):
            return parameters.speed
        case .periodicNoise(let parameters):
            return parameters.speed
        case .cyclicAutomata(let parameters):
            return parameters.speed
        case .agentSwarm(let parameters):
            return parameters.speed
        case .kaleidoscope(let parameters):
            return parameters.speed
        case .voronoiFlow(let parameters):
            return parameters.speed
        case .reactionDiffusion(let parameters):
            return parameters.speed
        case .plasmaField(let parameters):
            return parameters.speed
        case .harmonicTunnel(let parameters):
            return parameters.speed
        case .lissajousWeave(let parameters):
            return parameters.speed
        case .phyllotaxisBloom(let parameters):
            return parameters.speed
        case .hexPulseLattice(let parameters):
            return parameters.speed
        case .superformulaMorph(let parameters):
            return parameters.speed
        case .bloomingCircuits(let parameters):
            return parameters.speed
        case .auroraCurtain(let parameters):
            return parameters.speed
        case .cellularBloom(let parameters):
            return parameters.speed
        case .chladniPlate(let parameters):
            return parameters.speed
        case .circuitTracer(let parameters):
            return parameters.speed
        case .cityLightsBokeh(let parameters):
            return parameters.speed
        case .closedFlowParticles(let parameters):
            return parameters.speed
        case .constellationDrift(let parameters):
            return parameters.speed
        case .crystalLattice(let parameters):
            return parameters.speed
        case .dataMesh(let parameters):
            return parameters.speed
        case .digitalSand(let parameters):
            return parameters.speed
        case .electricStorm(let parameters):
            return parameters.speed
        case .sdfTunnel(let parameters):
            return parameters.speed
        case .feedbackSynth(let parameters):
            return parameters.speed
        case .fireworksShow(let parameters):
            return parameters.speed
        case .fluidNodes(let parameters):
            return parameters.speed
        case .fourierKnots(let parameters):
            return parameters.speed
        case .guillocheRose(let parameters):
            return parameters.speed
        case .growingNetwork(let parameters):
            return parameters.speed
        case .instancedGeometry(let parameters):
            return parameters.speed
        case .inkInWater(let parameters):
            return parameters.speed
        case .laserRibbons(let parameters):
            return parameters.speed
        case .luminousBubbles(let parameters):
            return parameters.speed
        case .metaballField(let parameters):
            return parameters.speed
        case .moireRings(let parameters):
            return parameters.speed
        case .neonVortex(let parameters):
            return parameters.speed
        case .origamiTessellation(let parameters):
            return parameters.speed
        case .particleFountain(let parameters):
            return parameters.speed
        case .penroseTiling(let parameters):
            return parameters.speed
        case .pulseNetwork(let parameters):
            return parameters.speed
        case .radialOscilloscope(let parameters):
            return parameters.speed
        case .rainCurtain(let parameters):
            return parameters.speed
        case .ribbonCascade(let parameters):
            return parameters.speed
        case .sakuraDrift(let parameters):
            return parameters.speed
        case .scanlineTopography(let parameters):
            return parameters.speed
        case .schoolingSwarm(let parameters):
            return parameters.speed
        case .snowfallDepth(let parameters):
            return parameters.speed
        case .solarCorona(let parameters):
            return parameters.speed
        case .truchetFlow(let parameters):
            return parameters.speed
        case .underwaterCaustics(let parameters):
            return parameters.speed
        case .volumetricNebula(let parameters):
            return parameters.speed
        case .waveTerrain(let parameters):
            return parameters.speed
        case .wireframeMorph(let parameters):
            return parameters.speed
        case .proceduralPattern(_, let parameters):
            return parameters.speed
        }
    }

    func settingSpeed(_ speed: Double) -> RenderParameters {
        switch self {
        case .fieldLines(var parameters):
            parameters.speed = speed
            return .fieldLines(parameters)
        case .orbital(var parameters):
            parameters.speed = speed
            return .orbital(parameters)
        case .softVolumetric(var parameters):
            parameters.speed = speed
            return .softVolumetric(parameters)
        case .gridCity(var parameters):
            parameters.speed = speed
            return .gridCity(parameters)
        case .interferenceField(var parameters):
            parameters.speed = speed
            return .interferenceField(parameters)
        case .periodicNoise(var parameters):
            parameters.speed = speed
            return .periodicNoise(parameters)
        case .cyclicAutomata(var parameters):
            parameters.speed = speed
            return .cyclicAutomata(parameters)
        case .agentSwarm(var parameters):
            parameters.speed = speed
            return .agentSwarm(parameters)
        case .kaleidoscope(var parameters):
            parameters.speed = speed
            return .kaleidoscope(parameters)
        case .voronoiFlow(var parameters):
            parameters.speed = speed
            return .voronoiFlow(parameters)
        case .reactionDiffusion(var parameters):
            parameters.speed = speed
            return .reactionDiffusion(parameters)
        case .plasmaField(var parameters):
            parameters.speed = speed
            return .plasmaField(parameters)
        case .harmonicTunnel(var parameters):
            parameters.speed = speed
            return .harmonicTunnel(parameters)
        case .lissajousWeave(var parameters):
            parameters.speed = speed
            return .lissajousWeave(parameters)
        case .phyllotaxisBloom(var parameters):
            parameters.speed = speed
            return .phyllotaxisBloom(parameters)
        case .hexPulseLattice(var parameters):
            parameters.speed = speed
            return .hexPulseLattice(parameters)
        case .superformulaMorph(var parameters):
            parameters.speed = speed
            return .superformulaMorph(parameters)
        case .bloomingCircuits(var parameters):
            parameters.speed = speed
            return .bloomingCircuits(parameters)
        case .auroraCurtain(var parameters):
            parameters.speed = speed
            return .auroraCurtain(parameters)
        case .cellularBloom(var parameters):
            parameters.speed = speed
            return .cellularBloom(parameters)
        case .chladniPlate(var parameters):
            parameters.speed = speed
            return .chladniPlate(parameters)
        case .circuitTracer(var parameters):
            parameters.speed = speed
            return .circuitTracer(parameters)
        case .cityLightsBokeh(var parameters):
            parameters.speed = speed
            return .cityLightsBokeh(parameters)
        case .closedFlowParticles(var parameters):
            parameters.speed = speed
            return .closedFlowParticles(parameters)
        case .constellationDrift(var parameters):
            parameters.speed = speed
            return .constellationDrift(parameters)
        case .crystalLattice(var parameters):
            parameters.speed = speed
            return .crystalLattice(parameters)
        case .dataMesh(var parameters):
            parameters.speed = speed
            return .dataMesh(parameters)
        case .digitalSand(var parameters):
            parameters.speed = speed
            return .digitalSand(parameters)
        case .electricStorm(var parameters):
            parameters.speed = speed
            return .electricStorm(parameters)
        case .sdfTunnel(var parameters):
            parameters.speed = speed
            return .sdfTunnel(parameters)
        case .feedbackSynth(var parameters):
            parameters.speed = speed
            return .feedbackSynth(parameters)
        case .fireworksShow(var parameters):
            parameters.speed = speed
            return .fireworksShow(parameters)
        case .fluidNodes(var parameters):
            parameters.speed = speed
            return .fluidNodes(parameters)
        case .fourierKnots(var parameters):
            parameters.speed = speed
            return .fourierKnots(parameters)
        case .guillocheRose(var parameters):
            parameters.speed = speed
            return .guillocheRose(parameters)
        case .growingNetwork(var parameters):
            parameters.speed = speed
            return .growingNetwork(parameters)
        case .instancedGeometry(var parameters):
            parameters.speed = speed
            return .instancedGeometry(parameters)
        case .inkInWater(var parameters):
            parameters.speed = speed
            return .inkInWater(parameters)
        case .laserRibbons(var parameters):
            parameters.speed = speed
            return .laserRibbons(parameters)
        case .luminousBubbles(var parameters):
            parameters.speed = speed
            return .luminousBubbles(parameters)
        case .metaballField(var parameters):
            parameters.speed = speed
            return .metaballField(parameters)
        case .moireRings(var parameters):
            parameters.speed = speed
            return .moireRings(parameters)
        case .neonVortex(var parameters):
            parameters.speed = speed
            return .neonVortex(parameters)
        case .origamiTessellation(var parameters):
            parameters.speed = speed
            return .origamiTessellation(parameters)
        case .particleFountain(var parameters):
            parameters.speed = speed
            return .particleFountain(parameters)
        case .penroseTiling(var parameters):
            parameters.speed = speed
            return .penroseTiling(parameters)
        case .pulseNetwork(var parameters):
            parameters.speed = speed
            return .pulseNetwork(parameters)
        case .radialOscilloscope(var parameters):
            parameters.speed = speed
            return .radialOscilloscope(parameters)
        case .rainCurtain(var parameters):
            parameters.speed = speed
            return .rainCurtain(parameters)
        case .ribbonCascade(var parameters):
            parameters.speed = speed
            return .ribbonCascade(parameters)
        case .sakuraDrift(var parameters):
            parameters.speed = speed
            return .sakuraDrift(parameters)
        case .scanlineTopography(var parameters):
            parameters.speed = speed
            return .scanlineTopography(parameters)
        case .schoolingSwarm(var parameters):
            parameters.speed = speed
            return .schoolingSwarm(parameters)
        case .snowfallDepth(var parameters):
            parameters.speed = speed
            return .snowfallDepth(parameters)
        case .solarCorona(var parameters):
            parameters.speed = speed
            return .solarCorona(parameters)
        case .truchetFlow(var parameters):
            parameters.speed = speed
            return .truchetFlow(parameters)
        case .underwaterCaustics(var parameters):
            parameters.speed = speed
            return .underwaterCaustics(parameters)
        case .volumetricNebula(var parameters):
            parameters.speed = speed
            return .volumetricNebula(parameters)
        case .waveTerrain(var parameters):
            parameters.speed = speed
            return .waveTerrain(parameters)
        case .wireframeMorph(var parameters):
            parameters.speed = speed
            return .wireframeMorph(parameters)
        case .proceduralPattern(let family, var parameters):
            parameters.speed = speed
            return .proceduralPattern(family, parameters)
        }
    }

    static func defaultParameters(for rendererFamily: RendererFamily) -> RenderParameters {
        switch rendererFamily {
        case .fieldLines:
            return .fieldLines(.feasibilityStudyDefault)
        case .orbital:
            return .orbital(.defaultParameters)
        case .softVolumetric:
            return .softVolumetric(.defaultParameters)
        case .gridCity:
            return .gridCity(.defaultParameters)
        case .interferenceField:
            return .interferenceField(.defaultParameters)
        case .periodicNoise:
            return .periodicNoise(.defaultParameters)
        case .cyclicAutomata:
            return .cyclicAutomata(.defaultParameters)
        case .agentSwarm:
            return .agentSwarm(.defaultParameters)
        case .kaleidoscope:
            return .kaleidoscope(.defaultParameters)
        case .voronoiFlow:
            return .voronoiFlow(.defaultParameters)
        case .reactionDiffusion:
            return .reactionDiffusion(.defaultParameters)
        case .plasmaField:
            return .plasmaField(.defaultParameters)
        case .harmonicTunnel:
            return .harmonicTunnel(.defaultParameters)
        case .lissajousWeave:
            return .lissajousWeave(.defaultParameters)
        case .phyllotaxisBloom:
            return .phyllotaxisBloom(.defaultParameters)
        case .hexPulseLattice:
            return .hexPulseLattice(.defaultParameters)
        case .superformulaMorph:
            return .superformulaMorph(.defaultParameters)
        case .bloomingCircuits:
            return .bloomingCircuits(.defaultParameters(for: .bloomingCircuits))
        case .auroraCurtain:
            return .auroraCurtain(.defaultParameters(for: .auroraCurtain))
        case .cellularBloom:
            return .cellularBloom(.defaultParameters(for: .cellularBloom))
        case .chladniPlate:
            return .chladniPlate(.defaultParameters(for: .chladniPlate))
        case .circuitTracer:
            return .circuitTracer(.defaultParameters(for: .circuitTracer))
        case .cityLightsBokeh:
            return .cityLightsBokeh(.defaultParameters(for: .cityLightsBokeh))
        case .closedFlowParticles:
            return .closedFlowParticles(.defaultParameters(for: .closedFlowParticles))
        case .constellationDrift:
            return .constellationDrift(.defaultParameters(for: .constellationDrift))
        case .crystalLattice:
            return .crystalLattice(.defaultParameters(for: .crystalLattice))
        case .dataMesh:
            return .dataMesh(.defaultParameters(for: .dataMesh))
        case .digitalSand:
            return .digitalSand(.defaultParameters(for: .digitalSand))
        case .electricStorm:
            return .electricStorm(.defaultParameters(for: .electricStorm))
        case .sdfTunnel:
            return .sdfTunnel(.defaultParameters(for: .sdfTunnel))
        case .feedbackSynth:
            return .feedbackSynth(.defaultParameters(for: .feedbackSynth))
        case .fireworksShow:
            return .fireworksShow(.defaultParameters(for: .fireworksShow))
        case .fluidNodes:
            return .fluidNodes(.defaultParameters(for: .fluidNodes))
        case .fourierKnots:
            return .fourierKnots(.defaultParameters(for: .fourierKnots))
        case .guillocheRose:
            return .guillocheRose(.defaultParameters(for: .guillocheRose))
        case .growingNetwork:
            return .growingNetwork(.defaultParameters(for: .growingNetwork))
        case .instancedGeometry:
            return .instancedGeometry(.defaultParameters(for: .instancedGeometry))
        case .inkInWater:
            return .inkInWater(.defaultParameters(for: .inkInWater))
        case .laserRibbons:
            return .laserRibbons(.defaultParameters(for: .laserRibbons))
        case .luminousBubbles:
            return .luminousBubbles(.defaultParameters(for: .luminousBubbles))
        case .metaballField:
            return .metaballField(.defaultParameters(for: .metaballField))
        case .moireRings:
            return .moireRings(.defaultParameters(for: .moireRings))
        case .neonVortex:
            return .neonVortex(.defaultParameters(for: .neonVortex))
        case .origamiTessellation:
            return .origamiTessellation(.defaultParameters(for: .origamiTessellation))
        case .particleFountain:
            return .particleFountain(.defaultParameters(for: .particleFountain))
        case .penroseTiling:
            return .penroseTiling(.defaultParameters(for: .penroseTiling))
        case .pulseNetwork:
            return .pulseNetwork(.defaultParameters(for: .pulseNetwork))
        case .radialOscilloscope:
            return .radialOscilloscope(.defaultParameters(for: .radialOscilloscope))
        case .rainCurtain:
            return .rainCurtain(.defaultParameters(for: .rainCurtain))
        case .ribbonCascade:
            return .ribbonCascade(.defaultParameters(for: .ribbonCascade))
        case .sakuraDrift:
            return .sakuraDrift(.defaultParameters(for: .sakuraDrift))
        case .scanlineTopography:
            return .scanlineTopography(.defaultParameters(for: .scanlineTopography))
        case .schoolingSwarm:
            return .schoolingSwarm(.defaultParameters(for: .schoolingSwarm))
        case .snowfallDepth:
            return .snowfallDepth(.defaultParameters(for: .snowfallDepth))
        case .solarCorona:
            return .solarCorona(.defaultParameters(for: .solarCorona))
        case .truchetFlow:
            return .truchetFlow(.defaultParameters(for: .truchetFlow))
        case .underwaterCaustics:
            return .underwaterCaustics(.defaultParameters(for: .underwaterCaustics))
        case .volumetricNebula:
            return .volumetricNebula(.defaultParameters(for: .volumetricNebula))
        case .waveTerrain:
            return .waveTerrain(.defaultParameters(for: .waveTerrain))
        case .wireframeMorph:
            return .wireframeMorph(.defaultParameters(for: .wireframeMorph))
        case .chromaticBloom,
             .labyrinthTrace,
             .photonStreams,
             .luminousStrings,
             .quantumFoam,
             .stardustVortex,
             .vortexLattice:
            return .proceduralPattern(rendererFamily, .defaultParameters(for: rendererFamily))
        }
    }
}
