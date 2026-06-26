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
        fadeAlpha: 0.11,
        cellScale: 1.0,
        phaseOffset: 0.0,
        hueBaseDegrees: 300.0,
        hueSpreadDegrees: 110.0,
        saturation: 0.92,
        brightness: 1.0,
        cellAlpha: 0.28,
        cellSize: 7.0,
        speed: 1.0,
        neighborhood: 0.58,
        mutation: 0.42,
        edgeSharpness: 0.72
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
        samplesPerAxis: 132,
        octaveCount: 5,
        fadeAlpha: 0.10,
        waveScale: 1.18,
        warpAmount: 0.74,
        hueBaseDegrees: 314.0,
        hueSpreadDegrees: 118.0,
        saturation: 0.92,
        brightness: 1.02,
        pointAlpha: 0.24,
        pointSize: 5.0,
        speed: 1.0,
        contrast: 0.62,
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
        pointCount: 5200,
        armCount: 5,
        fadeAlpha: 0.10,
        spiralTightness: 0.64,
        bloomAmount: 0.48,
        pulseAmount: 0.42,
        hueBaseDegrees: 42.0,
        hueSpreadDegrees: 116.0,
        saturation: 0.88,
        brightness: 1.0,
        pointAlpha: 0.22,
        pointSize: 2.4,
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
        case .instancedGeometry:
            return ProceduralPatternParameters(
                elementCount: 90,
                samplesPerElement: 6,
                harmonicA: 5,
                harmonicB: 8,
                fadeAlpha: 0.10,
                scale: 1.00,
                modulation: 0.64,
                depth: 0.70,
                feedback: 0.26,
                hueBaseDegrees: 206,
                hueSpreadDegrees: 92,
                saturation: 0.88,
                brightness: 1.0,
                pointAlpha: 0.30,
                pointSize: 7.4,
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
        case .waveTerrain:
            return ProceduralPatternParameters(
                elementCount: 36,
                samplesPerElement: 260,
                harmonicA: 4,
                harmonicB: 7,
                fadeAlpha: 0.10,
                scale: 1.35,
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
    case kaleidoscope(KaleidoscopeParameters)
    case voronoiFlow(VoronoiFlowParameters)
    case reactionDiffusion(ReactionDiffusionParameters)
    case plasmaField(PlasmaFieldParameters)
    case harmonicTunnel(HarmonicTunnelParameters)
    case lissajousWeave(LissajousWeaveParameters)
    case phyllotaxisBloom(PhyllotaxisBloomParameters)
    case hexPulseLattice(HexPulseLatticeParameters)
    case superformulaMorph(SuperformulaMorphParameters)
    case closedFlowParticles(ProceduralPatternParameters)
    case sdfTunnel(ProceduralPatternParameters)
    case feedbackSynth(ProceduralPatternParameters)
    case guillocheRose(ProceduralPatternParameters)
    case instancedGeometry(ProceduralPatternParameters)
    case metaballField(ProceduralPatternParameters)
    case penroseTiling(ProceduralPatternParameters)
    case waveTerrain(ProceduralPatternParameters)

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
        case kaleidoscope
        case voronoiFlow
        case reactionDiffusion
        case plasmaField
        case harmonicTunnel
        case lissajousWeave
        case phyllotaxisBloom
        case hexPulseLattice
        case superformulaMorph
        case closedFlowParticles
        case sdfTunnel
        case feedbackSynth
        case guillocheRose
        case instancedGeometry
        case metaballField
        case penroseTiling
        case waveTerrain
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
        case .closedFlowParticles:
            self = .closedFlowParticles(try container.decode(ProceduralPatternParameters.self, forKey: .closedFlowParticles))
        case .sdfTunnel:
            self = .sdfTunnel(try container.decode(ProceduralPatternParameters.self, forKey: .sdfTunnel))
        case .feedbackSynth:
            self = .feedbackSynth(try container.decode(ProceduralPatternParameters.self, forKey: .feedbackSynth))
        case .guillocheRose:
            self = .guillocheRose(try container.decode(ProceduralPatternParameters.self, forKey: .guillocheRose))
        case .instancedGeometry:
            self = .instancedGeometry(try container.decode(ProceduralPatternParameters.self, forKey: .instancedGeometry))
        case .metaballField:
            self = .metaballField(try container.decode(ProceduralPatternParameters.self, forKey: .metaballField))
        case .penroseTiling:
            self = .penroseTiling(try container.decode(ProceduralPatternParameters.self, forKey: .penroseTiling))
        case .waveTerrain:
            self = .waveTerrain(try container.decode(ProceduralPatternParameters.self, forKey: .waveTerrain))
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
        case .closedFlowParticles(let parameters):
            try container.encode(RendererFamily.closedFlowParticles, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .closedFlowParticles)
        case .sdfTunnel(let parameters):
            try container.encode(RendererFamily.sdfTunnel, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .sdfTunnel)
        case .feedbackSynth(let parameters):
            try container.encode(RendererFamily.feedbackSynth, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .feedbackSynth)
        case .guillocheRose(let parameters):
            try container.encode(RendererFamily.guillocheRose, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .guillocheRose)
        case .instancedGeometry(let parameters):
            try container.encode(RendererFamily.instancedGeometry, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .instancedGeometry)
        case .metaballField(let parameters):
            try container.encode(RendererFamily.metaballField, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .metaballField)
        case .penroseTiling(let parameters):
            try container.encode(RendererFamily.penroseTiling, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .penroseTiling)
        case .waveTerrain(let parameters):
            try container.encode(RendererFamily.waveTerrain, forKey: .rendererFamily)
            try container.encode(parameters, forKey: .waveTerrain)
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
        case .closedFlowParticles:
            return .closedFlowParticles
        case .sdfTunnel:
            return .sdfTunnel
        case .feedbackSynth:
            return .feedbackSynth
        case .guillocheRose:
            return .guillocheRose
        case .instancedGeometry:
            return .instancedGeometry
        case .metaballField:
            return .metaballField
        case .penroseTiling:
            return .penroseTiling
        case .waveTerrain:
            return .waveTerrain
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
        case .closedFlowParticles:
            return .closedFlowParticles(.defaultParameters(for: .closedFlowParticles))
        case .sdfTunnel:
            return .sdfTunnel(.defaultParameters(for: .sdfTunnel))
        case .feedbackSynth:
            return .feedbackSynth(.defaultParameters(for: .feedbackSynth))
        case .guillocheRose:
            return .guillocheRose(.defaultParameters(for: .guillocheRose))
        case .instancedGeometry:
            return .instancedGeometry(.defaultParameters(for: .instancedGeometry))
        case .metaballField:
            return .metaballField(.defaultParameters(for: .metaballField))
        case .penroseTiling:
            return .penroseTiling(.defaultParameters(for: .penroseTiling))
        case .waveTerrain:
            return .waveTerrain(.defaultParameters(for: .waveTerrain))
        }
    }
}
