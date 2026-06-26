//
//  RendererFamily.swift
//  VideoWallpaper
//

import Foundation

enum RendererFamily: String, Codable, CaseIterable, Hashable, Identifiable {
    case agentSwarm
    case closedFlowParticles
    case cyclicAutomata
    case feedbackSynth
    case fieldLines
    case gridCity
    case guillocheRose
    case harmonicTunnel
    case hexPulseLattice
    case instancedGeometry
    case interferenceField
    case kaleidoscope
    case lissajousWeave
    case metaballField
    case orbital
    case penroseTiling
    case periodicNoise
    case phyllotaxisBloom
    case plasmaField
    case reactionDiffusion
    case sdfTunnel
    case softVolumetric
    case superformulaMorph
    case voronoiFlow
    case waveTerrain

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fieldLines:
            return "Field Lines"
        case .orbital:
            return "Orbital"
        case .softVolumetric:
            return "Soft Volumetric"
        case .gridCity:
            return "Grid City"
        case .interferenceField:
            return "Interference Field"
        case .periodicNoise:
            return "Periodic Noise"
        case .cyclicAutomata:
            return "Cyclic Automata"
        case .agentSwarm:
            return "Agent Swarm"
        case .kaleidoscope:
            return "Kaleidoscope"
        case .voronoiFlow:
            return "Voronoi Flow"
        case .reactionDiffusion:
            return "Reaction Diffusion"
        case .plasmaField:
            return "Plasma Field"
        case .harmonicTunnel:
            return "Harmonic Tunnel"
        case .lissajousWeave:
            return "Lissajous Weave"
        case .phyllotaxisBloom:
            return "Phyllotaxis Bloom"
        case .hexPulseLattice:
            return "Hex Pulse Lattice"
        case .superformulaMorph:
            return "Superformula Morph"
        case .closedFlowParticles:
            return "Closed Flow Particles"
        case .sdfTunnel:
            return "SDF Tunnel"
        case .feedbackSynth:
            return "Feedback Synth"
        case .guillocheRose:
            return "Guilloche Rose"
        case .instancedGeometry:
            return "Instanced Geometry"
        case .metaballField:
            return "Metaball Field"
        case .penroseTiling:
            return "Penrose Tiling"
        case .waveTerrain:
            return "Wave Terrain"
        }
    }
}
