//
//  RendererFamily.swift
//  RioVideoWallpaper
//

import Foundation

enum RendererFamily: String, Codable, CaseIterable, Hashable, Identifiable {
    case agentSwarm
    case auroraCurtain
    case bloomingCircuits
    case cellularBloom
    case chladniPlate
    case chromaticBloom
    case circuitTracer
    case cityLightsBokeh
    case closedFlowParticles
    case constellationDrift
    case crystalLattice
    case cyclicAutomata
    case dataMesh
    case digitalSand
    case electricStorm
    case feedbackSynth
    case fieldLines
    case fireworksShow
    case fluidNodes
    case fourierKnots
    case gridCity
    case growingNetwork
    case guillocheRose
    case harmonicTunnel
    case hexPulseLattice
    case instancedGeometry
    case interferenceField
    case inkInWater
    case kaleidoscope
    case labyrinthTrace
    case laserRibbons
    case lissajousWeave
    case luminousBubbles
    case luminousStrings
    case metaballField
    case moireRings
    case neonVortex
    case orbital
    case origamiTessellation
    case particleFountain
    case penroseTiling
    case photonStreams
    case periodicNoise
    case phyllotaxisBloom
    case plasmaField
    case pulseNetwork
    case quantumFoam
    case radialOscilloscope
    case rainCurtain
    case reactionDiffusion
    case ribbonCascade
    case sakuraDrift
    case scanlineTopography
    case schoolingSwarm
    case sdfTunnel
    case snowfallDepth
    case softVolumetric
    case solarCorona
    case stardustVortex
    case superformulaMorph
    case truchetFlow
    case underwaterCaustics
    case voronoiFlow
    case volumetricNebula
    case vortexLattice
    case waveTerrain
    case wireframeMorph

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
        case .electricStorm:
            return "Electric Storm"
        case .agentSwarm:
            return "Agent Swarm"
        case .auroraCurtain:
            return "Aurora Curtain"
        case .bloomingCircuits:
            return "Blooming Circuits"
        case .cellularBloom:
            return "Cellular Bloom"
        case .chladniPlate:
            return "Chladni Plate"
        case .chromaticBloom:
            return "Chromatic Bloom"
        case .circuitTracer:
            return "Circuit Tracer"
        case .cityLightsBokeh:
            return "City Lights Bokeh"
        case .kaleidoscope:
            return "Kaleidoscope"
        case .labyrinthTrace:
            return "Labyrinth Trace"
        case .laserRibbons:
            return "Laser Ribbons"
        case .voronoiFlow:
            return "Voronoi Flow"
        case .reactionDiffusion:
            return "Reaction Diffusion"
        case .plasmaField:
            return "Plasma Field"
        case .radialOscilloscope:
            return "Radial Oscilloscope"
        case .rainCurtain:
            return "Rain Curtain"
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
        case .truchetFlow:
            return "Truchet Flow"
        case .closedFlowParticles:
            return "Closed Flow Particles"
        case .constellationDrift:
            return "Constellation Drift"
        case .crystalLattice:
            return "Crystal Lattice"
        case .dataMesh:
            return "Data Mesh"
        case .digitalSand:
            return "Digital Sand"
        case .sdfTunnel:
            return "SDF Tunnel"
        case .feedbackSynth:
            return "Feedback Synth"
        case .fireworksShow:
            return "Fireworks Show"
        case .fluidNodes:
            return "Fluid Nodes"
        case .fourierKnots:
            return "Fourier Knots"
        case .guillocheRose:
            return "Guilloche Rose"
        case .growingNetwork:
            return "Growing Network"
        case .instancedGeometry:
            return "Instanced Geometry"
        case .inkInWater:
            return "Ink in Water"
        case .luminousBubbles:
            return "Luminous Bubbles"
        case .luminousStrings:
            return "Luminous Strings"
        case .metaballField:
            return "Metaball Field"
        case .moireRings:
            return "Moire Rings"
        case .neonVortex:
            return "Neon Vortex"
        case .origamiTessellation:
            return "Origami Tessellation"
        case .particleFountain:
            return "Particle Fountain"
        case .penroseTiling:
            return "Penrose Tiling"
        case .photonStreams:
            return "Photon Streams"
        case .pulseNetwork:
            return "Pulse Network"
        case .quantumFoam:
            return "Quantum Foam"
        case .waveTerrain:
            return "Wave Terrain"
        case .ribbonCascade:
            return "Ribbon Cascade"
        case .sakuraDrift:
            return "Sakura Drift"
        case .scanlineTopography:
            return "Scanline Topography"
        case .schoolingSwarm:
            return "Schooling Swarm"
        case .snowfallDepth:
            return "Snowfall Depth"
        case .solarCorona:
            return "Solar Corona"
        case .stardustVortex:
            return "Stardust Vortex"
        case .underwaterCaustics:
            return "Underwater Caustics"
        case .volumetricNebula:
            return "Volumetric Nebula"
        case .vortexLattice:
            return "Vortex Lattice"
        case .wireframeMorph:
            return "Wireframe Morph"
        }
    }
}
