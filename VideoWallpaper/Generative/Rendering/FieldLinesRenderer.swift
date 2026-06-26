//
//  FieldLinesRenderer.swift
//  VideoWallpaper
//

import Foundation
import MetalKit
import simd

struct FieldLinesVertex {
    var position: SIMD2<Float>
    var color: SIMD4<Float>
    var pointSize: Float
}

final class FieldLinesRenderer {
    private let device: MTLDevice
    private let pointPipelineState: MTLRenderPipelineState
    private let fadePipelineState: MTLRenderPipelineState
    private let copyPipelineState: MTLRenderPipelineState
    private let samplerState: MTLSamplerState
    private var previousTexture: MTLTexture?
    private var currentTexture: MTLTexture?
    private var textureSize: CGSize = .zero
    private var resetAccumulationOnNextFrame = true

    init(device: MTLDevice, colorPixelFormat: MTLPixelFormat) throws {
        self.device = device

        let library = try device.makeDefaultLibrary(bundle: .main)
        guard let vertexFunction = library.makeFunction(name: "fieldLinesVertex"),
              let fragmentFunction = library.makeFunction(name: "fieldLinesFragment"),
              let fullscreenVertexFunction = library.makeFunction(name: "fieldLinesFullscreenVertex"),
              let fadeFragmentFunction = library.makeFunction(name: "fieldLinesFadeFragment"),
              let copyFragmentFunction = library.makeFunction(name: "fieldLinesCopyFragment") else {
            throw RendererError.missingShaderFunction
        }

        let pointDescriptor = MTLRenderPipelineDescriptor()
        pointDescriptor.vertexFunction = vertexFunction
        pointDescriptor.fragmentFunction = fragmentFunction
        pointDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat
        pointDescriptor.colorAttachments[0].isBlendingEnabled = true
        pointDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pointDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pointDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pointDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        pointDescriptor.colorAttachments[0].destinationRGBBlendFactor = .one
        pointDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .one

        let fadeDescriptor = MTLRenderPipelineDescriptor()
        fadeDescriptor.vertexFunction = fullscreenVertexFunction
        fadeDescriptor.fragmentFunction = fadeFragmentFunction
        fadeDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat

        let copyDescriptor = MTLRenderPipelineDescriptor()
        copyDescriptor.vertexFunction = fullscreenVertexFunction
        copyDescriptor.fragmentFunction = copyFragmentFunction
        copyDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat

        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.sAddressMode = .clampToEdge
        samplerDescriptor.tAddressMode = .clampToEdge

        pointPipelineState = try device.makeRenderPipelineState(descriptor: pointDescriptor)
        fadePipelineState = try device.makeRenderPipelineState(descriptor: fadeDescriptor)
        copyPipelineState = try device.makeRenderPipelineState(descriptor: copyDescriptor)
        guard let samplerState = device.makeSamplerState(descriptor: samplerDescriptor) else {
            throw RendererError.samplerCreationFailed
        }
        self.samplerState = samplerState
    }

    func resetAccumulation() {
        resetAccumulationOnNextFrame = true
    }

    func render(
        parameters: FieldLinesParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        in view: MTKView,
        commandBuffer: MTLCommandBuffer,
        renderPassDescriptor: MTLRenderPassDescriptor
    ) {
        let drawableSize = view.drawableSize
        render(
            parameters: parameters,
            seed: seed,
            frameIndex: frameIndex,
            clock: clock,
            drawableSize: drawableSize,
            commandBuffer: commandBuffer,
            finalRenderPassDescriptor: renderPassDescriptor
        )
    }

    func render(
        parameters: FieldLinesParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        drawableSize: CGSize,
        outputTexture: MTLTexture,
        commandBuffer: MTLCommandBuffer
    ) {
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = outputTexture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)

        render(
            parameters: parameters,
            seed: seed,
            frameIndex: frameIndex,
            clock: clock,
            drawableSize: drawableSize,
            commandBuffer: commandBuffer,
            finalRenderPassDescriptor: renderPassDescriptor
        )
    }

    private func render(
        parameters: FieldLinesParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        drawableSize: CGSize,
        commandBuffer: MTLCommandBuffer,
        finalRenderPassDescriptor: MTLRenderPassDescriptor
    ) {
        guard drawableSize.width > 1, drawableSize.height > 1 else { return }
        guard let outputTexture = finalRenderPassDescriptor.colorAttachments[0].texture,
              ensureAccumulationTextures(size: drawableSize, pixelFormat: outputTexture.pixelFormat),
              let currentTexture,
              let previousTexture else {
            return
        }

        let vertices = makeVertices(
            parameters: parameters,
            seed: seed,
            frameIndex: frameIndex,
            clock: clock,
            drawableSize: drawableSize
        )
        guard !vertices.isEmpty else { return }
        guard let vertexBuffer = device.makeBuffer(
            bytes: vertices,
            length: MemoryLayout<FieldLinesVertex>.stride * vertices.count,
            options: [.storageModeShared]
        ) else {
            return
        }

        let offscreenDescriptor = MTLRenderPassDescriptor()
        offscreenDescriptor.colorAttachments[0].texture = currentTexture
        offscreenDescriptor.colorAttachments[0].loadAction = .clear
        offscreenDescriptor.colorAttachments[0].storeAction = .store
        offscreenDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)

        guard let offscreenEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: offscreenDescriptor) else {
            return
        }

        if resetAccumulationOnNextFrame {
            resetAccumulationOnNextFrame = false
        } else {
            var fadeFactor = Float(1.0 - clamp(parameters.fadeAlpha, 0.02, 0.98))
            offscreenEncoder.setRenderPipelineState(fadePipelineState)
            offscreenEncoder.setFragmentTexture(previousTexture, index: 0)
            offscreenEncoder.setFragmentSamplerState(samplerState, index: 0)
            offscreenEncoder.setFragmentBytes(&fadeFactor, length: MemoryLayout<Float>.stride, index: 0)
            offscreenEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        }

        offscreenEncoder.setRenderPipelineState(pointPipelineState)
        offscreenEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        offscreenEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: vertices.count)
        offscreenEncoder.endEncoding()

        guard let drawableEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: finalRenderPassDescriptor) else {
            return
        }
        drawableEncoder.setRenderPipelineState(copyPipelineState)
        drawableEncoder.setFragmentTexture(currentTexture, index: 0)
        drawableEncoder.setFragmentSamplerState(samplerState, index: 0)
        drawableEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        drawableEncoder.endEncoding()

        swap(&self.previousTexture, &self.currentTexture)
    }

    private func ensureAccumulationTextures(size: CGSize, pixelFormat: MTLPixelFormat) -> Bool {
        let pixelWidth = max(1, Int(size.width.rounded(.toNearestOrAwayFromZero)))
        let pixelHeight = max(1, Int(size.height.rounded(.toNearestOrAwayFromZero)))
        let roundedSize = CGSize(width: pixelWidth, height: pixelHeight)

        guard previousTexture == nil || currentTexture == nil || textureSize != roundedSize else {
            return true
        }

        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: pixelFormat,
            width: pixelWidth,
            height: pixelHeight,
            mipmapped: false
        )
        descriptor.usage = [.renderTarget, .shaderRead]
        descriptor.storageMode = .private

        previousTexture = device.makeTexture(descriptor: descriptor)
        currentTexture = device.makeTexture(descriptor: descriptor)
        textureSize = roundedSize
        resetAccumulation()
        return previousTexture != nil && currentTexture != nil
    }

    private func makeVertices(
        parameters: FieldLinesParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        drawableSize: CGSize
    ) -> [FieldLinesVertex] {
        let width = Float(drawableSize.width)
        let height = Float(drawableSize.height)
        let center = SIMD2<Float>(width * 0.5, height * 0.5)
        let scale = min(width, height) / 1080.0
        let phase = Float(clock.phase(frameIndex: frameIndex))
        let seedPhase = Float(Double(seed % 10_000) / 10_000.0) * .pi * 2.0
        let bandCount = max(1, min(parameters.bandCount, 32))
        let pointsPerBand = max(60, min(parameters.pointsPerBand, 2_400))
        let particleCount = max(0, min(parameters.particleCount, 20_000))
        let speed = Float(max(0.0, parameters.speed))
        let turbulence = Float(max(0.0, parameters.turbulence))
        let saturation = Float(clamp(parameters.saturation, 0.0, 1.0))
        let brightness = Float(clamp(parameters.brightness, 0.0, 1.5))
        let lineAlpha = Float(clamp(parameters.lineAlpha, 0.0, 1.0))
        let particleAlpha = Float(clamp(parameters.particleAlpha, 0.0, 1.0))
        let hueBase = Float(parameters.hueBaseDegrees)
        let hueDrift = Float(parameters.hueDriftDegrees)
        let lineStep = Float(clamp(parameters.lineStep, 0.4, 4.0))

        var vertices: [FieldLinesVertex] = []
        vertices.reserveCapacity(bandCount * pointsPerBand + particleCount)

        for band in 0..<bandCount {
            let b = Float(band)
            let hue = hueBase + b * 18.0 + hueDrift * sin(phase + b + seedPhase * 0.11)
            let color = hsvToRGB(hueDegrees: hue, saturation: saturation, value: brightness)
            let alpha = lineAlpha * (0.72 + 0.28 * sin(phase + b * 0.5))
            let pointSize = Float(2.2 + Double(band) * 0.18) * Float(parameters.lineWeight) * max(1.0, scale)
            let baseRadius = (260.0 + b * 75.0) * scale
            let amplitude = (120.0 + 60.0 * sin(phase + b)) * scale * max(0.2, turbulence)

            for pointIndex in 0..<pointsPerBand {
                let a = Float(pointIndex) / Float(pointsPerBand) * .pi * 2.0
                let n1 = sin(a * (2.2 + lineStep) + phase * 2.0 + b + seedPhase)
                let n2 = sin(a * (4.8 + lineStep * 1.7) - phase * 3.0 + b * 1.7 + seedPhase * 0.31)
                let n3 = cos(a * (8.5 + lineStep * 1.9) + phase + b * 2.3)
                let radius = baseRadius + amplitude * n1 + 65.0 * scale * turbulence * n2 + 35.0 * scale * n3
                let rotation = 0.22 * max(0.2, speed) * sin(phase + b)
                let screen = SIMD2<Float>(
                    center.x + cos(a + rotation) * radius,
                    center.y + sin(a + rotation) * radius
                )
                vertices.append(
                    FieldLinesVertex(
                        position: normalizedPosition(screen, width: width, height: height),
                        color: SIMD4<Float>(color.x, color.y, color.z, alpha),
                        pointSize: pointSize
                    )
                )
            }
        }

        for particleID in 0..<particleCount {
            let id = Float(particleID)
            let noise = fract(sin(id * 12.9898 + seedPhase) * 43_758.547)
            let angle = Float.pi * 2.0 * fract(id * 0.017 + Float(clock.normalizedLoopTime(frameIndex: frameIndex)))
            let ring = (220.0 + 820.0 * noise) * scale
            let wobble = 80.0 * scale * sin(phase * 2.0 + id * 0.13 + seedPhase * 0.17)
            let radius = ring + wobble
            let screen = SIMD2<Float>(
                center.x + cos(angle * 1.7 + phase + id) * radius,
                center.y + sin(angle * 1.3 - phase + id * 0.7) * radius
            )
            let hue = hueBase - 20.0 + 90.0 * sin(phase + id * 0.01 + seedPhase * 0.07)
            let color = hsvToRGB(hueDegrees: hue, saturation: saturation * 0.9, value: brightness)
            vertices.append(
                FieldLinesVertex(
                    position: normalizedPosition(screen, width: width, height: height),
                    color: SIMD4<Float>(color.x, color.y, color.z, particleAlpha),
                    pointSize: 2.4 * max(1.0, scale)
                )
            )
        }

        return vertices
    }

    private func normalizedPosition(_ position: SIMD2<Float>, width: Float, height: Float) -> SIMD2<Float> {
        SIMD2<Float>(
            (position.x / width) * 2.0 - 1.0,
            1.0 - (position.y / height) * 2.0
        )
    }

    private func hsvToRGB(hueDegrees: Float, saturation: Float, value: Float) -> SIMD3<Float> {
        let h = (hueDegrees.truncatingRemainder(dividingBy: 360.0) + 360.0)
            .truncatingRemainder(dividingBy: 360.0) / 60.0
        let c = value * saturation
        let x = c * (1.0 - abs(h.truncatingRemainder(dividingBy: 2.0) - 1.0))

        let rgb: SIMD3<Float>
        switch h {
        case 0..<1:
            rgb = SIMD3<Float>(c, x, 0)
        case 1..<2:
            rgb = SIMD3<Float>(x, c, 0)
        case 2..<3:
            rgb = SIMD3<Float>(0, c, x)
        case 3..<4:
            rgb = SIMD3<Float>(0, x, c)
        case 4..<5:
            rgb = SIMD3<Float>(x, 0, c)
        default:
            rgb = SIMD3<Float>(c, 0, x)
        }

        let m = value - c
        return rgb + SIMD3<Float>(repeating: m)
    }

    private func fract(_ value: Float) -> Float {
        value - floor(value)
    }

    private func clamp(_ value: Double, _ lower: Double, _ upper: Double) -> Double {
        min(max(value, lower), upper)
    }
}

final class GenerativeFrameRenderer {
    private let fieldLinesRenderer: FieldLinesRenderer
    private let orbitalRenderer: OrbitalRenderer
    private let softVolumetricRenderer: SoftVolumetricRenderer
    private let gridCityRenderer: GridCityRenderer
    private let interferenceFieldRenderer: InterferenceFieldRenderer
    private let periodicNoiseRenderer: PeriodicNoiseRenderer
    private let cyclicAutomataRenderer: CyclicAutomataRenderer
    private let agentSwarmRenderer: AgentSwarmRenderer
    private let kaleidoscopeRenderer: KaleidoscopeRenderer
    private let voronoiFlowRenderer: VoronoiFlowRenderer
    private let reactionDiffusionRenderer: ReactionDiffusionRenderer
    private let plasmaFieldRenderer: PlasmaFieldRenderer
    private let harmonicTunnelRenderer: HarmonicTunnelRenderer
    private let lissajousWeaveRenderer: LissajousWeaveRenderer
    private let phyllotaxisBloomRenderer: PhyllotaxisBloomRenderer
    private let hexPulseLatticeRenderer: HexPulseLatticeRenderer
    private let superformulaMorphRenderer: SuperformulaMorphRenderer
    private let proceduralPatternRenderer: ProceduralPatternRenderer

    init(device: MTLDevice, colorPixelFormat: MTLPixelFormat) throws {
        fieldLinesRenderer = try FieldLinesRenderer(device: device, colorPixelFormat: colorPixelFormat)
        orbitalRenderer = try OrbitalRenderer(device: device, colorPixelFormat: colorPixelFormat)
        softVolumetricRenderer = try SoftVolumetricRenderer(device: device, colorPixelFormat: colorPixelFormat)
        gridCityRenderer = try GridCityRenderer(device: device, colorPixelFormat: colorPixelFormat)
        interferenceFieldRenderer = try InterferenceFieldRenderer(device: device, colorPixelFormat: colorPixelFormat)
        periodicNoiseRenderer = try PeriodicNoiseRenderer(device: device, colorPixelFormat: colorPixelFormat)
        cyclicAutomataRenderer = try CyclicAutomataRenderer(device: device, colorPixelFormat: colorPixelFormat)
        agentSwarmRenderer = try AgentSwarmRenderer(device: device, colorPixelFormat: colorPixelFormat)
        kaleidoscopeRenderer = try KaleidoscopeRenderer(device: device, colorPixelFormat: colorPixelFormat)
        voronoiFlowRenderer = try VoronoiFlowRenderer(device: device, colorPixelFormat: colorPixelFormat)
        reactionDiffusionRenderer = try ReactionDiffusionRenderer(device: device, colorPixelFormat: colorPixelFormat)
        plasmaFieldRenderer = try PlasmaFieldRenderer(device: device, colorPixelFormat: colorPixelFormat)
        harmonicTunnelRenderer = try HarmonicTunnelRenderer(device: device, colorPixelFormat: colorPixelFormat)
        lissajousWeaveRenderer = try LissajousWeaveRenderer(device: device, colorPixelFormat: colorPixelFormat)
        phyllotaxisBloomRenderer = try PhyllotaxisBloomRenderer(device: device, colorPixelFormat: colorPixelFormat)
        hexPulseLatticeRenderer = try HexPulseLatticeRenderer(device: device, colorPixelFormat: colorPixelFormat)
        superformulaMorphRenderer = try SuperformulaMorphRenderer(device: device, colorPixelFormat: colorPixelFormat)
        proceduralPatternRenderer = try ProceduralPatternRenderer(device: device, colorPixelFormat: colorPixelFormat)
    }

    func resetAccumulation() {
        fieldLinesRenderer.resetAccumulation()
        orbitalRenderer.resetAccumulation()
    }

    func render(
        parameters: RenderParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        in view: MTKView,
        commandBuffer: MTLCommandBuffer,
        renderPassDescriptor: MTLRenderPassDescriptor
    ) {
        switch parameters {
        case .fieldLines(let fieldLinesParameters):
            fieldLinesRenderer.render(
                parameters: fieldLinesParameters,
                seed: seed,
                frameIndex: frameIndex,
                clock: clock,
                in: view,
                commandBuffer: commandBuffer,
                renderPassDescriptor: renderPassDescriptor
            )
        case .orbital(let orbitalParameters):
            orbitalRenderer.render(
                parameters: orbitalParameters,
                seed: seed,
                frameIndex: frameIndex,
                clock: clock,
                in: view,
                commandBuffer: commandBuffer,
                renderPassDescriptor: renderPassDescriptor
            )
        case .softVolumetric(let softVolumetricParameters):
            softVolumetricRenderer.render(
                parameters: softVolumetricParameters,
                seed: seed,
                frameIndex: frameIndex,
                clock: clock,
                in: view,
                commandBuffer: commandBuffer,
                renderPassDescriptor: renderPassDescriptor
            )
        case .gridCity(let gridCityParameters):
            gridCityRenderer.render(
                parameters: gridCityParameters,
                seed: seed,
                frameIndex: frameIndex,
                clock: clock,
                in: view,
                commandBuffer: commandBuffer,
                renderPassDescriptor: renderPassDescriptor
            )
        case .interferenceField(let interferenceFieldParameters):
            interferenceFieldRenderer.render(
                parameters: interferenceFieldParameters,
                seed: seed,
                frameIndex: frameIndex,
                clock: clock,
                in: view,
                commandBuffer: commandBuffer,
                renderPassDescriptor: renderPassDescriptor
            )
        case .periodicNoise(let periodicNoiseParameters):
            periodicNoiseRenderer.render(
                parameters: periodicNoiseParameters,
                seed: seed,
                frameIndex: frameIndex,
                clock: clock,
                in: view,
                commandBuffer: commandBuffer,
                renderPassDescriptor: renderPassDescriptor
            )
        case .cyclicAutomata(let cyclicAutomataParameters):
            cyclicAutomataRenderer.render(
                parameters: cyclicAutomataParameters,
                seed: seed,
                frameIndex: frameIndex,
                clock: clock,
                in: view,
                commandBuffer: commandBuffer,
                renderPassDescriptor: renderPassDescriptor
            )
        case .agentSwarm(let agentSwarmParameters):
            agentSwarmRenderer.render(
                parameters: agentSwarmParameters,
                seed: seed,
                frameIndex: frameIndex,
                clock: clock,
                in: view,
                commandBuffer: commandBuffer,
                renderPassDescriptor: renderPassDescriptor
            )
        case .kaleidoscope(let kaleidoscopeParameters):
            kaleidoscopeRenderer.render(
                parameters: kaleidoscopeParameters,
                seed: seed,
                frameIndex: frameIndex,
                clock: clock,
                in: view,
                commandBuffer: commandBuffer,
                renderPassDescriptor: renderPassDescriptor
            )
        case .voronoiFlow(let voronoiFlowParameters):
            voronoiFlowRenderer.render(
                parameters: voronoiFlowParameters,
                seed: seed,
                frameIndex: frameIndex,
                clock: clock,
                in: view,
                commandBuffer: commandBuffer,
                renderPassDescriptor: renderPassDescriptor
            )
        case .reactionDiffusion(let reactionDiffusionParameters):
            reactionDiffusionRenderer.render(
                parameters: reactionDiffusionParameters,
                seed: seed,
                frameIndex: frameIndex,
                clock: clock,
                in: view,
                commandBuffer: commandBuffer,
                renderPassDescriptor: renderPassDescriptor
            )
        case .plasmaField(let plasmaFieldParameters):
            plasmaFieldRenderer.render(
                parameters: plasmaFieldParameters,
                seed: seed,
                frameIndex: frameIndex,
                clock: clock,
                in: view,
                commandBuffer: commandBuffer,
                renderPassDescriptor: renderPassDescriptor
            )
        case .harmonicTunnel(let harmonicTunnelParameters):
            harmonicTunnelRenderer.render(
                parameters: harmonicTunnelParameters,
                seed: seed,
                frameIndex: frameIndex,
                clock: clock,
                in: view,
                commandBuffer: commandBuffer,
                renderPassDescriptor: renderPassDescriptor
            )
        case .lissajousWeave(let lissajousWeaveParameters):
            lissajousWeaveRenderer.render(
                parameters: lissajousWeaveParameters,
                seed: seed,
                frameIndex: frameIndex,
                clock: clock,
                in: view,
                commandBuffer: commandBuffer,
                renderPassDescriptor: renderPassDescriptor
            )
        case .phyllotaxisBloom(let phyllotaxisBloomParameters):
            phyllotaxisBloomRenderer.render(
                parameters: phyllotaxisBloomParameters,
                seed: seed,
                frameIndex: frameIndex,
                clock: clock,
                in: view,
                commandBuffer: commandBuffer,
                renderPassDescriptor: renderPassDescriptor
            )
        case .hexPulseLattice(let hexPulseLatticeParameters):
            hexPulseLatticeRenderer.render(
                parameters: hexPulseLatticeParameters,
                seed: seed,
                frameIndex: frameIndex,
                clock: clock,
                in: view,
                commandBuffer: commandBuffer,
                renderPassDescriptor: renderPassDescriptor
            )
        case .superformulaMorph(let superformulaMorphParameters):
            superformulaMorphRenderer.render(
                parameters: superformulaMorphParameters,
                seed: seed,
                frameIndex: frameIndex,
                clock: clock,
                in: view,
                commandBuffer: commandBuffer,
                renderPassDescriptor: renderPassDescriptor
            )
        case .closedFlowParticles(let proceduralParameters):
            renderProceduralPattern(
                family: .closedFlowParticles,
                parameters: proceduralParameters,
                seed: seed,
                frameIndex: frameIndex,
                clock: clock,
                in: view,
                commandBuffer: commandBuffer,
                renderPassDescriptor: renderPassDescriptor
            )
        case .sdfTunnel(let proceduralParameters):
            renderProceduralPattern(
                family: .sdfTunnel,
                parameters: proceduralParameters,
                seed: seed,
                frameIndex: frameIndex,
                clock: clock,
                in: view,
                commandBuffer: commandBuffer,
                renderPassDescriptor: renderPassDescriptor
            )
        case .feedbackSynth(let proceduralParameters):
            renderProceduralPattern(
                family: .feedbackSynth,
                parameters: proceduralParameters,
                seed: seed,
                frameIndex: frameIndex,
                clock: clock,
                in: view,
                commandBuffer: commandBuffer,
                renderPassDescriptor: renderPassDescriptor
            )
        case .guillocheRose(let proceduralParameters):
            renderProceduralPattern(
                family: .guillocheRose,
                parameters: proceduralParameters,
                seed: seed,
                frameIndex: frameIndex,
                clock: clock,
                in: view,
                commandBuffer: commandBuffer,
                renderPassDescriptor: renderPassDescriptor
            )
        case .instancedGeometry(let proceduralParameters):
            renderProceduralPattern(
                family: .instancedGeometry,
                parameters: proceduralParameters,
                seed: seed,
                frameIndex: frameIndex,
                clock: clock,
                in: view,
                commandBuffer: commandBuffer,
                renderPassDescriptor: renderPassDescriptor
            )
        case .metaballField(let proceduralParameters):
            renderProceduralPattern(
                family: .metaballField,
                parameters: proceduralParameters,
                seed: seed,
                frameIndex: frameIndex,
                clock: clock,
                in: view,
                commandBuffer: commandBuffer,
                renderPassDescriptor: renderPassDescriptor
            )
        case .penroseTiling(let proceduralParameters):
            renderProceduralPattern(
                family: .penroseTiling,
                parameters: proceduralParameters,
                seed: seed,
                frameIndex: frameIndex,
                clock: clock,
                in: view,
                commandBuffer: commandBuffer,
                renderPassDescriptor: renderPassDescriptor
            )
        case .waveTerrain(let proceduralParameters):
            renderProceduralPattern(
                family: .waveTerrain,
                parameters: proceduralParameters,
                seed: seed,
                frameIndex: frameIndex,
                clock: clock,
                in: view,
                commandBuffer: commandBuffer,
                renderPassDescriptor: renderPassDescriptor
            )
        }
    }

    func render(
        parameters: RenderParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        drawableSize: CGSize,
        outputTexture: MTLTexture,
        commandBuffer: MTLCommandBuffer
    ) {
        switch parameters {
        case .fieldLines(let fieldLinesParameters):
            fieldLinesRenderer.render(
                parameters: fieldLinesParameters,
                seed: seed,
                frameIndex: frameIndex,
                clock: clock,
                drawableSize: drawableSize,
                outputTexture: outputTexture,
                commandBuffer: commandBuffer
            )
        case .orbital(let orbitalParameters):
            orbitalRenderer.render(
                parameters: orbitalParameters,
                seed: seed,
                frameIndex: frameIndex,
                clock: clock,
                drawableSize: drawableSize,
                outputTexture: outputTexture,
                commandBuffer: commandBuffer
            )
        case .softVolumetric(let softVolumetricParameters):
            softVolumetricRenderer.render(
                parameters: softVolumetricParameters,
                seed: seed,
                frameIndex: frameIndex,
                clock: clock,
                drawableSize: drawableSize,
                outputTexture: outputTexture,
                commandBuffer: commandBuffer
            )
        case .gridCity(let gridCityParameters):
            gridCityRenderer.render(
                parameters: gridCityParameters,
                seed: seed,
                frameIndex: frameIndex,
                clock: clock,
                drawableSize: drawableSize,
                outputTexture: outputTexture,
                commandBuffer: commandBuffer
            )
        case .interferenceField(let interferenceFieldParameters):
            interferenceFieldRenderer.render(
                parameters: interferenceFieldParameters,
                seed: seed,
                frameIndex: frameIndex,
                clock: clock,
                drawableSize: drawableSize,
                outputTexture: outputTexture,
                commandBuffer: commandBuffer
            )
        case .periodicNoise(let periodicNoiseParameters):
            periodicNoiseRenderer.render(
                parameters: periodicNoiseParameters,
                seed: seed,
                frameIndex: frameIndex,
                clock: clock,
                drawableSize: drawableSize,
                outputTexture: outputTexture,
                commandBuffer: commandBuffer
            )
        case .cyclicAutomata(let cyclicAutomataParameters):
            cyclicAutomataRenderer.render(
                parameters: cyclicAutomataParameters,
                seed: seed,
                frameIndex: frameIndex,
                clock: clock,
                drawableSize: drawableSize,
                outputTexture: outputTexture,
                commandBuffer: commandBuffer
            )
        case .agentSwarm(let agentSwarmParameters):
            agentSwarmRenderer.render(
                parameters: agentSwarmParameters,
                seed: seed,
                frameIndex: frameIndex,
                clock: clock,
                drawableSize: drawableSize,
                outputTexture: outputTexture,
                commandBuffer: commandBuffer
            )
        case .kaleidoscope(let kaleidoscopeParameters):
            kaleidoscopeRenderer.render(
                parameters: kaleidoscopeParameters,
                seed: seed,
                frameIndex: frameIndex,
                clock: clock,
                drawableSize: drawableSize,
                outputTexture: outputTexture,
                commandBuffer: commandBuffer
            )
        case .voronoiFlow(let voronoiFlowParameters):
            voronoiFlowRenderer.render(
                parameters: voronoiFlowParameters,
                seed: seed,
                frameIndex: frameIndex,
                clock: clock,
                drawableSize: drawableSize,
                outputTexture: outputTexture,
                commandBuffer: commandBuffer
            )
        case .reactionDiffusion(let reactionDiffusionParameters):
            reactionDiffusionRenderer.render(
                parameters: reactionDiffusionParameters,
                seed: seed,
                frameIndex: frameIndex,
                clock: clock,
                drawableSize: drawableSize,
                outputTexture: outputTexture,
                commandBuffer: commandBuffer
            )
        case .plasmaField(let plasmaFieldParameters):
            plasmaFieldRenderer.render(
                parameters: plasmaFieldParameters,
                seed: seed,
                frameIndex: frameIndex,
                clock: clock,
                drawableSize: drawableSize,
                outputTexture: outputTexture,
                commandBuffer: commandBuffer
            )
        case .harmonicTunnel(let harmonicTunnelParameters):
            harmonicTunnelRenderer.render(
                parameters: harmonicTunnelParameters,
                seed: seed,
                frameIndex: frameIndex,
                clock: clock,
                drawableSize: drawableSize,
                outputTexture: outputTexture,
                commandBuffer: commandBuffer
            )
        case .lissajousWeave(let lissajousWeaveParameters):
            lissajousWeaveRenderer.render(
                parameters: lissajousWeaveParameters,
                seed: seed,
                frameIndex: frameIndex,
                clock: clock,
                drawableSize: drawableSize,
                outputTexture: outputTexture,
                commandBuffer: commandBuffer
            )
        case .phyllotaxisBloom(let phyllotaxisBloomParameters):
            phyllotaxisBloomRenderer.render(
                parameters: phyllotaxisBloomParameters,
                seed: seed,
                frameIndex: frameIndex,
                clock: clock,
                drawableSize: drawableSize,
                outputTexture: outputTexture,
                commandBuffer: commandBuffer
            )
        case .hexPulseLattice(let hexPulseLatticeParameters):
            hexPulseLatticeRenderer.render(
                parameters: hexPulseLatticeParameters,
                seed: seed,
                frameIndex: frameIndex,
                clock: clock,
                drawableSize: drawableSize,
                outputTexture: outputTexture,
                commandBuffer: commandBuffer
            )
        case .superformulaMorph(let superformulaMorphParameters):
            superformulaMorphRenderer.render(
                parameters: superformulaMorphParameters,
                seed: seed,
                frameIndex: frameIndex,
                clock: clock,
                drawableSize: drawableSize,
                outputTexture: outputTexture,
                commandBuffer: commandBuffer
            )
        case .closedFlowParticles(let proceduralParameters):
            renderProceduralPattern(
                family: .closedFlowParticles,
                parameters: proceduralParameters,
                seed: seed,
                frameIndex: frameIndex,
                clock: clock,
                drawableSize: drawableSize,
                outputTexture: outputTexture,
                commandBuffer: commandBuffer
            )
        case .sdfTunnel(let proceduralParameters):
            renderProceduralPattern(
                family: .sdfTunnel,
                parameters: proceduralParameters,
                seed: seed,
                frameIndex: frameIndex,
                clock: clock,
                drawableSize: drawableSize,
                outputTexture: outputTexture,
                commandBuffer: commandBuffer
            )
        case .feedbackSynth(let proceduralParameters):
            renderProceduralPattern(
                family: .feedbackSynth,
                parameters: proceduralParameters,
                seed: seed,
                frameIndex: frameIndex,
                clock: clock,
                drawableSize: drawableSize,
                outputTexture: outputTexture,
                commandBuffer: commandBuffer
            )
        case .guillocheRose(let proceduralParameters):
            renderProceduralPattern(
                family: .guillocheRose,
                parameters: proceduralParameters,
                seed: seed,
                frameIndex: frameIndex,
                clock: clock,
                drawableSize: drawableSize,
                outputTexture: outputTexture,
                commandBuffer: commandBuffer
            )
        case .instancedGeometry(let proceduralParameters):
            renderProceduralPattern(
                family: .instancedGeometry,
                parameters: proceduralParameters,
                seed: seed,
                frameIndex: frameIndex,
                clock: clock,
                drawableSize: drawableSize,
                outputTexture: outputTexture,
                commandBuffer: commandBuffer
            )
        case .metaballField(let proceduralParameters):
            renderProceduralPattern(
                family: .metaballField,
                parameters: proceduralParameters,
                seed: seed,
                frameIndex: frameIndex,
                clock: clock,
                drawableSize: drawableSize,
                outputTexture: outputTexture,
                commandBuffer: commandBuffer
            )
        case .penroseTiling(let proceduralParameters):
            renderProceduralPattern(
                family: .penroseTiling,
                parameters: proceduralParameters,
                seed: seed,
                frameIndex: frameIndex,
                clock: clock,
                drawableSize: drawableSize,
                outputTexture: outputTexture,
                commandBuffer: commandBuffer
            )
        case .waveTerrain(let proceduralParameters):
            renderProceduralPattern(
                family: .waveTerrain,
                parameters: proceduralParameters,
                seed: seed,
                frameIndex: frameIndex,
                clock: clock,
                drawableSize: drawableSize,
                outputTexture: outputTexture,
                commandBuffer: commandBuffer
            )
        }
    }

    private func renderProceduralPattern(
        family: RendererFamily,
        parameters: ProceduralPatternParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        in view: MTKView,
        commandBuffer: MTLCommandBuffer,
        renderPassDescriptor: MTLRenderPassDescriptor
    ) {
        proceduralPatternRenderer.render(
            family: family,
            parameters: parameters,
            seed: seed,
            frameIndex: frameIndex,
            clock: clock,
            in: view,
            commandBuffer: commandBuffer,
            renderPassDescriptor: renderPassDescriptor
        )
    }

    private func renderProceduralPattern(
        family: RendererFamily,
        parameters: ProceduralPatternParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        drawableSize: CGSize,
        outputTexture: MTLTexture,
        commandBuffer: MTLCommandBuffer
    ) {
        proceduralPatternRenderer.render(
            family: family,
            parameters: parameters,
            seed: seed,
            frameIndex: frameIndex,
            clock: clock,
            drawableSize: drawableSize,
            outputTexture: outputTexture,
            commandBuffer: commandBuffer
        )
    }
}

final class OrbitalRenderer {
    private let device: MTLDevice
    private let pointPipelineState: MTLRenderPipelineState
    private let fadePipelineState: MTLRenderPipelineState
    private let copyPipelineState: MTLRenderPipelineState
    private let samplerState: MTLSamplerState
    private var previousTexture: MTLTexture?
    private var currentTexture: MTLTexture?
    private var textureSize: CGSize = .zero
    private var resetAccumulationOnNextFrame = true

    init(device: MTLDevice, colorPixelFormat: MTLPixelFormat) throws {
        self.device = device

        let library = try device.makeDefaultLibrary(bundle: .main)
        guard let vertexFunction = library.makeFunction(name: "fieldLinesVertex"),
              let fragmentFunction = library.makeFunction(name: "fieldLinesFragment"),
              let fullscreenVertexFunction = library.makeFunction(name: "fieldLinesFullscreenVertex"),
              let fadeFragmentFunction = library.makeFunction(name: "fieldLinesFadeFragment"),
              let copyFragmentFunction = library.makeFunction(name: "fieldLinesCopyFragment") else {
            throw RendererError.missingShaderFunction
        }

        let pointDescriptor = MTLRenderPipelineDescriptor()
        pointDescriptor.vertexFunction = vertexFunction
        pointDescriptor.fragmentFunction = fragmentFunction
        pointDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat
        pointDescriptor.colorAttachments[0].isBlendingEnabled = true
        pointDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pointDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pointDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pointDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        pointDescriptor.colorAttachments[0].destinationRGBBlendFactor = .one
        pointDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .one

        let fadeDescriptor = MTLRenderPipelineDescriptor()
        fadeDescriptor.vertexFunction = fullscreenVertexFunction
        fadeDescriptor.fragmentFunction = fadeFragmentFunction
        fadeDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat

        let copyDescriptor = MTLRenderPipelineDescriptor()
        copyDescriptor.vertexFunction = fullscreenVertexFunction
        copyDescriptor.fragmentFunction = copyFragmentFunction
        copyDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat

        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.sAddressMode = .clampToEdge
        samplerDescriptor.tAddressMode = .clampToEdge

        pointPipelineState = try device.makeRenderPipelineState(descriptor: pointDescriptor)
        fadePipelineState = try device.makeRenderPipelineState(descriptor: fadeDescriptor)
        copyPipelineState = try device.makeRenderPipelineState(descriptor: copyDescriptor)
        guard let samplerState = device.makeSamplerState(descriptor: samplerDescriptor) else {
            throw RendererError.samplerCreationFailed
        }
        self.samplerState = samplerState
    }

    func resetAccumulation() {
        resetAccumulationOnNextFrame = true
    }

    func render(
        parameters: OrbitalParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        in view: MTKView,
        commandBuffer: MTLCommandBuffer,
        renderPassDescriptor: MTLRenderPassDescriptor
    ) {
        render(
            parameters: parameters,
            seed: seed,
            frameIndex: frameIndex,
            clock: clock,
            drawableSize: view.drawableSize,
            commandBuffer: commandBuffer,
            finalRenderPassDescriptor: renderPassDescriptor
        )
    }

    func render(
        parameters: OrbitalParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        drawableSize: CGSize,
        outputTexture: MTLTexture,
        commandBuffer: MTLCommandBuffer
    ) {
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = outputTexture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)

        render(
            parameters: parameters,
            seed: seed,
            frameIndex: frameIndex,
            clock: clock,
            drawableSize: drawableSize,
            commandBuffer: commandBuffer,
            finalRenderPassDescriptor: renderPassDescriptor
        )
    }

    private func render(
        parameters: OrbitalParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        drawableSize: CGSize,
        commandBuffer: MTLCommandBuffer,
        finalRenderPassDescriptor: MTLRenderPassDescriptor
    ) {
        guard drawableSize.width > 1, drawableSize.height > 1 else { return }
        guard let outputTexture = finalRenderPassDescriptor.colorAttachments[0].texture,
              ensureAccumulationTextures(size: drawableSize, pixelFormat: outputTexture.pixelFormat),
              let currentTexture,
              let previousTexture else {
            return
        }

        let vertices = makeVertices(
            parameters: parameters,
            seed: seed,
            frameIndex: frameIndex,
            clock: clock,
            drawableSize: drawableSize
        )
        guard !vertices.isEmpty else { return }
        guard let vertexBuffer = device.makeBuffer(
            bytes: vertices,
            length: MemoryLayout<FieldLinesVertex>.stride * vertices.count,
            options: [.storageModeShared]
        ) else {
            return
        }

        let offscreenDescriptor = MTLRenderPassDescriptor()
        offscreenDescriptor.colorAttachments[0].texture = currentTexture
        offscreenDescriptor.colorAttachments[0].loadAction = .clear
        offscreenDescriptor.colorAttachments[0].storeAction = .store
        offscreenDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)

        guard let offscreenEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: offscreenDescriptor) else {
            return
        }

        if resetAccumulationOnNextFrame {
            resetAccumulationOnNextFrame = false
        } else {
            var fadeFactor = Float(1.0 - clamp(parameters.fadeAlpha, 0.02, 0.98))
            offscreenEncoder.setRenderPipelineState(fadePipelineState)
            offscreenEncoder.setFragmentTexture(previousTexture, index: 0)
            offscreenEncoder.setFragmentSamplerState(samplerState, index: 0)
            offscreenEncoder.setFragmentBytes(&fadeFactor, length: MemoryLayout<Float>.stride, index: 0)
            offscreenEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        }

        offscreenEncoder.setRenderPipelineState(pointPipelineState)
        offscreenEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        offscreenEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: vertices.count)
        offscreenEncoder.endEncoding()

        guard let drawableEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: finalRenderPassDescriptor) else {
            return
        }
        drawableEncoder.setRenderPipelineState(copyPipelineState)
        drawableEncoder.setFragmentTexture(currentTexture, index: 0)
        drawableEncoder.setFragmentSamplerState(samplerState, index: 0)
        drawableEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        drawableEncoder.endEncoding()

        swap(&self.previousTexture, &self.currentTexture)
    }

    private func ensureAccumulationTextures(size: CGSize, pixelFormat: MTLPixelFormat) -> Bool {
        let pixelWidth = max(1, Int(size.width.rounded(.toNearestOrAwayFromZero)))
        let pixelHeight = max(1, Int(size.height.rounded(.toNearestOrAwayFromZero)))
        let roundedSize = CGSize(width: pixelWidth, height: pixelHeight)

        guard previousTexture == nil || currentTexture == nil || textureSize != roundedSize else {
            return true
        }

        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: pixelFormat,
            width: pixelWidth,
            height: pixelHeight,
            mipmapped: false
        )
        descriptor.usage = [.renderTarget, .shaderRead]
        descriptor.storageMode = .private

        previousTexture = device.makeTexture(descriptor: descriptor)
        currentTexture = device.makeTexture(descriptor: descriptor)
        textureSize = roundedSize
        resetAccumulation()
        return previousTexture != nil && currentTexture != nil
    }

    private func makeVertices(
        parameters: OrbitalParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        drawableSize: CGSize
    ) -> [FieldLinesVertex] {
        let width = Float(drawableSize.width)
        let height = Float(drawableSize.height)
        let center = SIMD2<Float>(width * 0.5, height * 0.5)
        let scale = min(width, height) / 1080.0
        let phase = Float(clock.phase(frameIndex: frameIndex))
        let loopTime = Float(clock.normalizedLoopTime(frameIndex: frameIndex))
        let seedPhase = Float(Double(seed % 10_000) / 10_000.0) * .pi * 2.0
        let orbitCount = max(1, min(parameters.orbitCount, 24))
        let pointsPerOrbit = max(120, min(parameters.pointsPerOrbit, 2_000))
        let satelliteCount = max(0, min(parameters.satelliteCount, 360))
        let speed = Float(max(0.0, parameters.speed))
        let cycleCount = Float(max(1, min(5, Int((parameters.speed * 2.0).rounded()))))
        let radiusScale = Float(clamp(parameters.radiusScale, 0.3, 1.8))
        let eccentricity = Float(clamp(parameters.eccentricity, 0.0, 0.9))
        let saturation = Float(clamp(parameters.saturation, 0.0, 1.0))
        let brightness = Float(clamp(parameters.brightness, 0.0, 1.5))
        let orbitAlpha = Float(clamp(parameters.orbitAlpha, 0.0, 1.0))
        let satelliteAlpha = Float(clamp(parameters.satelliteAlpha, 0.0, 1.0))
        let glowSize = Float(clamp(parameters.glowSize, 0.4, 6.0))
        let hueBase = Float(parameters.hueBaseDegrees)
        let hueSpread = Float(parameters.hueSpreadDegrees)

        var vertices: [FieldLinesVertex] = []
        vertices.reserveCapacity(orbitCount * pointsPerOrbit + satelliteCount * 3)

        for orbit in 0..<orbitCount {
            let index = Float(orbit)
            let progress = Float(orbit + 1) / Float(orbitCount + 1)
            let baseRadius = (145.0 + progress * 780.0) * scale * radiusScale
            let ellipseX = baseRadius * (1.0 + eccentricity * 0.55)
            let ellipseY = baseRadius * (1.0 - eccentricity * 0.42)
            let tilt = seedPhase * 0.18 + index * 0.52 + phase * cycleCount
            let wobble = 0.055 + eccentricity * 0.06
            let hue = hueBase + hueSpread * sin(index * 0.73 + seedPhase)
            let color = hsvToRGB(hueDegrees: hue, saturation: saturation, value: brightness)
            let alpha = orbitAlpha * (0.58 + 0.42 * progress)
            let pointSize = (1.4 + glowSize * 0.42 + progress * 0.6) * max(1.0, scale)

            for pointIndex in 0..<pointsPerOrbit {
                let a = Float(pointIndex) / Float(pointsPerOrbit) * .pi * 2.0
                let precess = phase * cycleCount
                let radialPulse = 1.0 + wobble * sin(a * 3.0 + phase * cycleCount + index + seedPhase)
                let local = SIMD2<Float>(
                    cos(a + precess) * ellipseX * radialPulse,
                    sin(a - precess) * ellipseY * radialPulse
                )
                let screen = rotate(local, by: tilt) + center
                vertices.append(FieldLinesVertex(
                    position: normalizedPosition(screen, width: width, height: height),
                    color: SIMD4<Float>(color.x, color.y, color.z, alpha),
                    pointSize: pointSize
                ))
            }
        }

        for satellite in 0..<satelliteCount {
            let id = Float(satellite)
            let orbit = Float(satellite % orbitCount)
            let progress = (orbit + 1.0) / Float(orbitCount + 1)
            let baseRadius = (145.0 + progress * 780.0) * scale * radiusScale
            let ellipseX = baseRadius * (1.0 + eccentricity * 0.55)
            let ellipseY = baseRadius * (1.0 - eccentricity * 0.42)
            let tilt = seedPhase * 0.18 + orbit * 0.52 + phase * cycleCount
            let direction: Float = satellite % 2 == 0 ? 1.0 : -1.0
            let a = .pi * 2.0 * fract(id * 0.173 + loopTime * cycleCount * direction)
            let local = SIMD2<Float>(
                cos(a) * ellipseX,
                sin(a) * ellipseY
            )
            let screen = rotate(local, by: tilt) + center
            let hue = hueBase + hueSpread * cos(id * 0.31 + phase + seedPhase)
            let color = hsvToRGB(hueDegrees: hue, saturation: saturation, value: brightness)
            let pointSize = (2.6 + glowSize * 1.1 + progress * 2.0) * max(1.0, scale)
            vertices.append(FieldLinesVertex(
                position: normalizedPosition(screen, width: width, height: height),
                color: SIMD4<Float>(color.x, color.y, color.z, satelliteAlpha),
                pointSize: pointSize
            ))

            let trailColor = SIMD4<Float>(color.x, color.y, color.z, satelliteAlpha * 0.38)
            for trailStep in 1...2 {
                let trailAngle = a - direction * Float(trailStep) * 0.035 * (1.0 + speed)
                let trailLocal = SIMD2<Float>(
                    cos(trailAngle) * ellipseX,
                    sin(trailAngle) * ellipseY
                )
                vertices.append(FieldLinesVertex(
                    position: normalizedPosition(rotate(trailLocal, by: tilt) + center, width: width, height: height),
                    color: trailColor,
                    pointSize: pointSize * (1.0 - Float(trailStep) * 0.22)
                ))
            }
        }

        return vertices
    }

    private func rotate(_ point: SIMD2<Float>, by angle: Float) -> SIMD2<Float> {
        let c = cos(angle)
        let s = sin(angle)
        return SIMD2<Float>(
            point.x * c - point.y * s,
            point.x * s + point.y * c
        )
    }

    private func normalizedPosition(_ position: SIMD2<Float>, width: Float, height: Float) -> SIMD2<Float> {
        SIMD2<Float>(
            (position.x / width) * 2.0 - 1.0,
            1.0 - (position.y / height) * 2.0
        )
    }

    private func hsvToRGB(hueDegrees: Float, saturation: Float, value: Float) -> SIMD3<Float> {
        let h = (hueDegrees.truncatingRemainder(dividingBy: 360.0) + 360.0)
            .truncatingRemainder(dividingBy: 360.0) / 60.0
        let c = value * saturation
        let x = c * (1.0 - abs(h.truncatingRemainder(dividingBy: 2.0) - 1.0))

        let rgb: SIMD3<Float>
        switch h {
        case 0..<1:
            rgb = SIMD3<Float>(c, x, 0)
        case 1..<2:
            rgb = SIMD3<Float>(x, c, 0)
        case 2..<3:
            rgb = SIMD3<Float>(0, c, x)
        case 3..<4:
            rgb = SIMD3<Float>(0, x, c)
        case 4..<5:
            rgb = SIMD3<Float>(x, 0, c)
        default:
            rgb = SIMD3<Float>(c, 0, x)
        }

        let m = value - c
        return rgb + SIMD3<Float>(repeating: m)
    }

    private func fract(_ value: Float) -> Float {
        value - floor(value)
    }

    private func clamp(_ value: Double, _ lower: Double, _ upper: Double) -> Double {
        min(max(value, lower), upper)
    }
}

final class SoftVolumetricRenderer {
    private let device: MTLDevice
    private let pointPipelineState: MTLRenderPipelineState

    init(device: MTLDevice, colorPixelFormat: MTLPixelFormat) throws {
        self.device = device

        let library = try device.makeDefaultLibrary(bundle: .main)
        guard let vertexFunction = library.makeFunction(name: "fieldLinesVertex"),
              let fragmentFunction = library.makeFunction(name: "fieldLinesFragment") else {
            throw RendererError.missingShaderFunction
        }

        let pointDescriptor = MTLRenderPipelineDescriptor()
        pointDescriptor.vertexFunction = vertexFunction
        pointDescriptor.fragmentFunction = fragmentFunction
        pointDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat
        pointDescriptor.colorAttachments[0].isBlendingEnabled = true
        pointDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pointDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pointDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pointDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        pointDescriptor.colorAttachments[0].destinationRGBBlendFactor = .one
        pointDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .one
        pointPipelineState = try device.makeRenderPipelineState(descriptor: pointDescriptor)
    }

    func render(
        parameters: SoftVolumetricParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        in view: MTKView,
        commandBuffer: MTLCommandBuffer,
        renderPassDescriptor: MTLRenderPassDescriptor
    ) {
        render(
            parameters: parameters,
            seed: seed,
            frameIndex: frameIndex,
            clock: clock,
            drawableSize: view.drawableSize,
            commandBuffer: commandBuffer,
            finalRenderPassDescriptor: renderPassDescriptor
        )
    }

    func render(
        parameters: SoftVolumetricParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        drawableSize: CGSize,
        outputTexture: MTLTexture,
        commandBuffer: MTLCommandBuffer
    ) {
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = outputTexture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)

        render(
            parameters: parameters,
            seed: seed,
            frameIndex: frameIndex,
            clock: clock,
            drawableSize: drawableSize,
            commandBuffer: commandBuffer,
            finalRenderPassDescriptor: renderPassDescriptor
        )
    }

    private func render(
        parameters: SoftVolumetricParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        drawableSize: CGSize,
        commandBuffer: MTLCommandBuffer,
        finalRenderPassDescriptor: MTLRenderPassDescriptor
    ) {
        guard drawableSize.width > 1, drawableSize.height > 1 else { return }
        let vertices = makeVertices(
            parameters: parameters,
            seed: seed,
            frameIndex: frameIndex,
            clock: clock,
            drawableSize: drawableSize
        )
        guard !vertices.isEmpty else { return }
        guard let vertexBuffer = device.makeBuffer(
            bytes: vertices,
            length: MemoryLayout<FieldLinesVertex>.stride * vertices.count,
            options: [.storageModeShared]
        ) else {
            return
        }

        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: finalRenderPassDescriptor) else {
            return
        }
        encoder.setRenderPipelineState(pointPipelineState)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: vertices.count)
        encoder.endEncoding()
    }

    private func makeVertices(
        parameters: SoftVolumetricParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        drawableSize: CGSize
    ) -> [FieldLinesVertex] {
        let width = Float(drawableSize.width)
        let height = Float(drawableSize.height)
        let center = SIMD2<Float>(width * 0.5, height * 0.5)
        let scale = min(width, height) / 1080.0
        let phase = Float(clock.phase(frameIndex: frameIndex))
        let seedPhase = Float(Double(seed % 10_000) / 10_000.0) * .pi * 2.0
        let cloudCount = max(1, min(parameters.cloudCount, 24))
        let pointsPerCloud = max(80, min(parameters.pointsPerCloud, 1_800))
        let layerCount = max(1, min(parameters.layerCount, 10))
        let cycleCount = Float(max(1, min(5, Int((parameters.speed * 2.0).rounded()))))
        let turbulence = Float(max(0.0, parameters.turbulence))
        let spread = Float(clamp(parameters.spread, 0.3, 2.0))
        let saturation = Float(clamp(parameters.saturation, 0.0, 1.0))
        let brightness = Float(clamp(parameters.brightness, 0.0, 1.3))
        let cloudAlpha = Float(clamp(parameters.cloudAlpha, 0.0, 1.0))
        let coreAlpha = Float(clamp(parameters.coreAlpha, 0.0, 1.0))
        let glowSize = Float(clamp(parameters.glowSize, 0.5, 10.0))
        let hueBase = Float(parameters.hueBaseDegrees)
        let hueSpread = Float(parameters.hueSpreadDegrees)
        let alphaBoost = Float(1.0 - clamp(parameters.fadeAlpha, 0.02, 0.98))

        var vertices: [FieldLinesVertex] = []
        vertices.reserveCapacity(cloudCount * pointsPerCloud + cloudCount * layerCount)

        for cloud in 0..<cloudCount {
            let c = Float(cloud)
            let cloudSeed = seedPhase + c * 1.731
            let baseAngle = .pi * 2.0 * fract(c * 0.271 + Float(seed % 97) * 0.003)
            let distance = (90.0 + 420.0 * fract(c * 0.619 + seedPhase * 0.17)) * scale * spread
            let drift = phase * cycleCount
            let anchor = center + SIMD2<Float>(
                cos(baseAngle + drift) * distance,
                sin(baseAngle * 0.7 - drift) * distance * 0.72
            )
            let cloudRadius = (120.0 + 280.0 * fract(c * 0.413 + seedPhase * 0.23)) * scale * spread
            let hue = hueBase + hueSpread * sin(c * 0.63 + seedPhase)
            let color = hsvToRGB(hueDegrees: hue, saturation: saturation, value: brightness)

            for layer in 0..<layerCount {
                let l = Float(layer)
                let layerProgress = Float(layer + 1) / Float(layerCount + 1)
                let layerAngle = cloudSeed + l * 0.81 + phase * cycleCount
                let local = SIMD2<Float>(
                    cos(layerAngle) * cloudRadius * 0.28 * layerProgress,
                    sin(layerAngle * 1.3) * cloudRadius * 0.18 * layerProgress
                )
                let screen = anchor + local
                vertices.append(FieldLinesVertex(
                    position: normalizedPosition(screen, width: width, height: height),
                    color: SIMD4<Float>(color.x, color.y, color.z, coreAlpha * alphaBoost * (1.0 - layerProgress * 0.25)),
                    pointSize: (cloudRadius * 0.18 + glowSize * 10.0 * scale) * (1.0 + layerProgress * 0.45)
                ))
            }

            for point in 0..<pointsPerCloud {
                let p = Float(point)
                let r = sqrt(fract(sin((p + c * 97.0) * 12.9898 + cloudSeed) * 43_758.547))
                let a = .pi * 2.0 * fract(p * 0.3819 + cloudSeed * 0.11)
                let swirl = phase * cycleCount + sin(phase + p * 0.031) * turbulence * 0.16
                let ellipse = SIMD2<Float>(
                    cos(a + swirl) * cloudRadius * r,
                    sin(a * 1.17 - swirl) * cloudRadius * r * (0.52 + turbulence * 0.22)
                )
                let wave = SIMD2<Float>(
                    sin(phase * cycleCount + p * 0.07 + cloudSeed),
                    cos(phase * cycleCount + p * 0.053 + cloudSeed * 0.7)
                ) * cloudRadius * 0.06 * turbulence
                let screen = anchor + ellipse + wave
                let particleHue = hue + hueSpread * 0.28 * sin(p * 0.021 + phase + cloudSeed)
                let particleColor = hsvToRGB(hueDegrees: particleHue, saturation: saturation, value: brightness)
                let edgeFalloff = 1.0 - r * 0.72
                vertices.append(FieldLinesVertex(
                    position: normalizedPosition(screen, width: width, height: height),
                    color: SIMD4<Float>(
                        particleColor.x,
                        particleColor.y,
                        particleColor.z,
                        cloudAlpha * alphaBoost * edgeFalloff
                    ),
                    pointSize: (glowSize * (1.0 + edgeFalloff * 0.9) + 2.0) * max(1.0, scale)
                ))
            }
        }

        return vertices
    }

    private func normalizedPosition(_ position: SIMD2<Float>, width: Float, height: Float) -> SIMD2<Float> {
        SIMD2<Float>(
            (position.x / width) * 2.0 - 1.0,
            1.0 - (position.y / height) * 2.0
        )
    }

    private func hsvToRGB(hueDegrees: Float, saturation: Float, value: Float) -> SIMD3<Float> {
        let h = (hueDegrees.truncatingRemainder(dividingBy: 360.0) + 360.0)
            .truncatingRemainder(dividingBy: 360.0) / 60.0
        let c = value * saturation
        let x = c * (1.0 - abs(h.truncatingRemainder(dividingBy: 2.0) - 1.0))

        let rgb: SIMD3<Float>
        switch h {
        case 0..<1:
            rgb = SIMD3<Float>(c, x, 0)
        case 1..<2:
            rgb = SIMD3<Float>(x, c, 0)
        case 2..<3:
            rgb = SIMD3<Float>(0, c, x)
        case 3..<4:
            rgb = SIMD3<Float>(0, x, c)
        case 4..<5:
            rgb = SIMD3<Float>(x, 0, c)
        default:
            rgb = SIMD3<Float>(c, 0, x)
        }

        let m = value - c
        return rgb + SIMD3<Float>(repeating: m)
    }

    private func fract(_ value: Float) -> Float {
        value - floor(value)
    }

    private func clamp(_ value: Double, _ lower: Double, _ upper: Double) -> Double {
        min(max(value, lower), upper)
    }
}

final class GridCityRenderer {
    private let device: MTLDevice
    private let pointPipelineState: MTLRenderPipelineState

    init(device: MTLDevice, colorPixelFormat: MTLPixelFormat) throws {
        self.device = device

        let library = try device.makeDefaultLibrary(bundle: .main)
        guard let vertexFunction = library.makeFunction(name: "fieldLinesVertex"),
              let fragmentFunction = library.makeFunction(name: "fieldLinesFragment") else {
            throw RendererError.missingShaderFunction
        }

        let pointDescriptor = MTLRenderPipelineDescriptor()
        pointDescriptor.vertexFunction = vertexFunction
        pointDescriptor.fragmentFunction = fragmentFunction
        pointDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat
        pointDescriptor.colorAttachments[0].isBlendingEnabled = true
        pointDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pointDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pointDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pointDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        pointDescriptor.colorAttachments[0].destinationRGBBlendFactor = .one
        pointDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .one
        pointPipelineState = try device.makeRenderPipelineState(descriptor: pointDescriptor)
    }

    func render(
        parameters: GridCityParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        in view: MTKView,
        commandBuffer: MTLCommandBuffer,
        renderPassDescriptor: MTLRenderPassDescriptor
    ) {
        render(
            parameters: parameters,
            seed: seed,
            frameIndex: frameIndex,
            clock: clock,
            drawableSize: view.drawableSize,
            commandBuffer: commandBuffer,
            finalRenderPassDescriptor: renderPassDescriptor
        )
    }

    func render(
        parameters: GridCityParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        drawableSize: CGSize,
        outputTexture: MTLTexture,
        commandBuffer: MTLCommandBuffer
    ) {
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = outputTexture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)

        render(
            parameters: parameters,
            seed: seed,
            frameIndex: frameIndex,
            clock: clock,
            drawableSize: drawableSize,
            commandBuffer: commandBuffer,
            finalRenderPassDescriptor: renderPassDescriptor
        )
    }

    private func render(
        parameters: GridCityParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        drawableSize: CGSize,
        commandBuffer: MTLCommandBuffer,
        finalRenderPassDescriptor: MTLRenderPassDescriptor
    ) {
        guard drawableSize.width > 1, drawableSize.height > 1 else { return }
        let vertices = makeVertices(
            parameters: parameters,
            seed: seed,
            frameIndex: frameIndex,
            clock: clock,
            drawableSize: drawableSize
        )
        guard !vertices.isEmpty else { return }
        guard let vertexBuffer = device.makeBuffer(
            bytes: vertices,
            length: MemoryLayout<FieldLinesVertex>.stride * vertices.count,
            options: [.storageModeShared]
        ) else {
            return
        }

        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: finalRenderPassDescriptor) else {
            return
        }
        encoder.setRenderPipelineState(pointPipelineState)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: vertices.count)
        encoder.endEncoding()
    }

    private func makeVertices(
        parameters: GridCityParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        drawableSize: CGSize
    ) -> [FieldLinesVertex] {
        let width = Float(drawableSize.width)
        let height = Float(drawableSize.height)
        let centerX = width * 0.5
        let horizonY = height * (0.36 - Float(clamp(parameters.perspective, 0.25, 1.0)) * 0.08)
        let groundY = height * 0.92
        let scale = min(width, height) / 1080.0
        let phase = Float(clock.phase(frameIndex: frameIndex))
        let loopTime = Float(clock.normalizedLoopTime(frameIndex: frameIndex))
        let seedPhase = Float(Double(seed % 10_000) / 10_000.0) * .pi * 2.0
        let laneCount = max(2, min(parameters.laneCount, 36))
        let pointsPerLane = max(40, min(parameters.pointsPerLane, 1_200))
        let towerCount = max(0, min(parameters.towerCount, 240))
        let perspective = Float(clamp(parameters.perspective, 0.25, 1.0))
        let depth = Float(clamp(parameters.depth, 0.2, 1.0))
        let cycleCount = Float(max(1, min(5, Int((parameters.speed * 2.0).rounded()))))
        let saturation = Float(clamp(parameters.saturation, 0.0, 1.0))
        let brightness = Float(clamp(parameters.brightness, 0.0, 1.3))
        let gridAlpha = Float(clamp(parameters.gridAlpha, 0.0, 1.0))
        let towerAlpha = Float(clamp(parameters.towerAlpha, 0.0, 1.0))
        let glowSize = Float(clamp(parameters.glowSize, 0.4, 8.0))
        let hueBase = Float(parameters.hueBaseDegrees)
        let hueSpread = Float(parameters.hueSpreadDegrees)
        let alphaBoost = Float(1.0 - clamp(parameters.fadeAlpha, 0.02, 0.98))

        var vertices: [FieldLinesVertex] = []
        vertices.reserveCapacity(laneCount * pointsPerLane + pointsPerLane * 10 + towerCount * 16)

        let gridColor = hsvToRGB(hueDegrees: hueBase, saturation: saturation, value: brightness)
        let roadHalfWidth = width * (0.24 + depth * 0.22)
        let laneTotal = laneCount * 2 + 1
        for lane in 0..<laneTotal {
            let normalizedLane = Float(lane - laneCount) / Float(max(1, laneCount))
            let groundX = centerX + normalizedLane * roadHalfWidth
            for point in 0..<pointsPerLane {
                let z = Float(point) / Float(max(1, pointsPerLane - 1))
                let curvedZ = pow(z, 1.65 + perspective * 0.85)
                let y = horizonY + (groundY - horizonY) * curvedZ
                let x = centerX + (groundX - centerX) * curvedZ
                let pulse = 0.64 + 0.36 * sin(phase * cycleCount + normalizedLane * 2.0 + z * 14.0)
                vertices.append(FieldLinesVertex(
                    position: normalizedPosition(SIMD2<Float>(x, y), width: width, height: height),
                    color: SIMD4<Float>(gridColor.x, gridColor.y, gridColor.z, gridAlpha * alphaBoost * pulse),
                    pointSize: (1.1 + glowSize * 0.26 + curvedZ * 1.8) * max(1.0, scale)
                ))
            }
        }

        let crossLineCount = max(6, laneCount)
        for cross in 0..<crossLineCount {
            let moving = fract(Float(cross) / Float(crossLineCount) + loopTime * cycleCount)
            let curvedZ = pow(moving, 1.65 + perspective * 0.85)
            let y = horizonY + (groundY - horizonY) * curvedZ
            let halfWidth = roadHalfWidth * curvedZ
            let pointCount = max(80, pointsPerLane / 2)
            for point in 0..<pointCount {
                let t = Float(point) / Float(max(1, pointCount - 1))
                let x = centerX - halfWidth + halfWidth * 2.0 * t
                vertices.append(FieldLinesVertex(
                    position: normalizedPosition(SIMD2<Float>(x, y), width: width, height: height),
                    color: SIMD4<Float>(gridColor.x, gridColor.y, gridColor.z, gridAlpha * alphaBoost * (0.55 + curvedZ * 0.45)),
                    pointSize: (1.0 + glowSize * 0.2 + curvedZ * 1.6) * max(1.0, scale)
                ))
            }
        }

        for tower in 0..<towerCount {
            let t = Float(tower)
            let side: Float = tower % 2 == 0 ? -1.0 : 1.0
            let row = fract(t * 0.3183 + seedPhase * 0.07)
            let curvedZ = pow(row, 1.55 + perspective * 0.75)
            let yBase = horizonY + (groundY - horizonY) * curvedZ
            let sideOffset = roadHalfWidth * curvedZ + (36.0 + 360.0 * fract(t * 0.217 + seedPhase)) * scale * curvedZ
            let x = centerX + side * sideOffset
            let towerHeight = (80.0 + 360.0 * fract(t * 0.713 + seedPhase * 0.13)) * scale * (0.35 + curvedZ)
            let towerHue = hueBase + hueSpread * sin(t * 0.41 + seedPhase)
            let color = hsvToRGB(hueDegrees: towerHue, saturation: saturation, value: brightness)
            let verticalPoints = 8
            for point in 0..<verticalPoints {
                let p = Float(point) / Float(verticalPoints - 1)
                let y = yBase - towerHeight * p
                let flicker = 0.72 + 0.28 * sin(phase * cycleCount + t * 0.73 + p * 8.0)
                vertices.append(FieldLinesVertex(
                    position: normalizedPosition(SIMD2<Float>(x, y), width: width, height: height),
                    color: SIMD4<Float>(color.x, color.y, color.z, towerAlpha * alphaBoost * flicker),
                    pointSize: (2.0 + glowSize * 0.55 + curvedZ * 2.2) * max(1.0, scale)
                ))
            }

            for window in 0..<8 {
                let wx = x + side * Float(window % 2 == 0 ? -1 : 1) * (6.0 + curvedZ * 16.0) * scale
                let wy = yBase - towerHeight * (0.12 + Float(window) * 0.095)
                let windowHue = towerHue + 18.0 * sin(Float(window) + seedPhase)
                let windowColor = hsvToRGB(hueDegrees: windowHue, saturation: saturation, value: brightness)
                vertices.append(FieldLinesVertex(
                    position: normalizedPosition(SIMD2<Float>(wx, wy), width: width, height: height),
                    color: SIMD4<Float>(windowColor.x, windowColor.y, windowColor.z, towerAlpha * alphaBoost * 0.78),
                    pointSize: (2.4 + glowSize * 0.42 + curvedZ * 1.8) * max(1.0, scale)
                ))
            }
        }

        let streamCount = max(6, laneCount / 2)
        for stream in 0..<streamCount {
            let lane = Float(stream - streamCount / 2) / Float(max(1, streamCount))
            let groundX = centerX + lane * roadHalfWidth * 0.72
            let movingZ = fract(Float(stream) * 0.137 + loopTime * cycleCount)
            let hue = hueBase + hueSpread * cos(Float(stream) * 0.59 + seedPhase)
            let color = hsvToRGB(hueDegrees: hue, saturation: saturation, value: brightness)
            for trail in 0..<18 {
                let z = fract(movingZ - Float(trail) * 0.012)
                let curvedZ = pow(z, 1.65 + perspective * 0.85)
                let y = horizonY + (groundY - horizonY) * curvedZ
                let x = centerX + (groundX - centerX) * curvedZ
                vertices.append(FieldLinesVertex(
                    position: normalizedPosition(SIMD2<Float>(x, y), width: width, height: height),
                    color: SIMD4<Float>(color.x, color.y, color.z, towerAlpha * alphaBoost * (1.0 - Float(trail) / 22.0)),
                    pointSize: (2.8 + glowSize * 0.95 + curvedZ * 3.0) * max(1.0, scale)
                ))
            }
        }

        return vertices
    }

    private func normalizedPosition(_ position: SIMD2<Float>, width: Float, height: Float) -> SIMD2<Float> {
        SIMD2<Float>(
            (position.x / width) * 2.0 - 1.0,
            1.0 - (position.y / height) * 2.0
        )
    }

    private func hsvToRGB(hueDegrees: Float, saturation: Float, value: Float) -> SIMD3<Float> {
        let h = (hueDegrees.truncatingRemainder(dividingBy: 360.0) + 360.0)
            .truncatingRemainder(dividingBy: 360.0) / 60.0
        let c = value * saturation
        let x = c * (1.0 - abs(h.truncatingRemainder(dividingBy: 2.0) - 1.0))

        let rgb: SIMD3<Float>
        switch h {
        case 0..<1:
            rgb = SIMD3<Float>(c, x, 0)
        case 1..<2:
            rgb = SIMD3<Float>(x, c, 0)
        case 2..<3:
            rgb = SIMD3<Float>(0, c, x)
        case 3..<4:
            rgb = SIMD3<Float>(0, x, c)
        case 4..<5:
            rgb = SIMD3<Float>(x, 0, c)
        default:
            rgb = SIMD3<Float>(c, 0, x)
        }

        let m = value - c
        return rgb + SIMD3<Float>(repeating: m)
    }

    private func fract(_ value: Float) -> Float {
        value - floor(value)
    }

    private func clamp(_ value: Double, _ lower: Double, _ upper: Double) -> Double {
        min(max(value, lower), upper)
    }
}

final class InterferenceFieldRenderer {
    private let device: MTLDevice
    private let pointPipelineState: MTLRenderPipelineState

    init(device: MTLDevice, colorPixelFormat: MTLPixelFormat) throws {
        self.device = device

        let library = try device.makeDefaultLibrary(bundle: .main)
        guard let vertexFunction = library.makeFunction(name: "fieldLinesVertex"),
              let fragmentFunction = library.makeFunction(name: "fieldLinesFragment") else {
            throw RendererError.missingShaderFunction
        }

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.colorAttachments[0].pixelFormat = colorPixelFormat
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].rgbBlendOperation = .add
        descriptor.colorAttachments[0].alphaBlendOperation = .add
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .one
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .one
        pointPipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
    }

    func render(
        parameters: InterferenceFieldParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        in view: MTKView,
        commandBuffer: MTLCommandBuffer,
        renderPassDescriptor: MTLRenderPassDescriptor
    ) {
        render(
            parameters: parameters,
            seed: seed,
            frameIndex: frameIndex,
            clock: clock,
            drawableSize: view.drawableSize,
            commandBuffer: commandBuffer,
            finalRenderPassDescriptor: renderPassDescriptor
        )
    }

    func render(
        parameters: InterferenceFieldParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        drawableSize: CGSize,
        outputTexture: MTLTexture,
        commandBuffer: MTLCommandBuffer
    ) {
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = outputTexture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)

        render(
            parameters: parameters,
            seed: seed,
            frameIndex: frameIndex,
            clock: clock,
            drawableSize: drawableSize,
            commandBuffer: commandBuffer,
            finalRenderPassDescriptor: renderPassDescriptor
        )
    }

    private func render(
        parameters: InterferenceFieldParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        drawableSize: CGSize,
        commandBuffer: MTLCommandBuffer,
        finalRenderPassDescriptor: MTLRenderPassDescriptor
    ) {
        guard drawableSize.width > 1, drawableSize.height > 1 else { return }

        let vertices = makeVertices(
            parameters: parameters,
            seed: seed,
            frameIndex: frameIndex,
            clock: clock,
            drawableSize: drawableSize
        )
        guard !vertices.isEmpty else { return }
        guard let vertexBuffer = device.makeBuffer(
            bytes: vertices,
            length: MemoryLayout<FieldLinesVertex>.stride * vertices.count,
            options: [.storageModeShared]
        ) else {
            return
        }
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: finalRenderPassDescriptor) else {
            return
        }

        encoder.setRenderPipelineState(pointPipelineState)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: vertices.count)
        encoder.endEncoding()
    }

    private func makeVertices(
        parameters: InterferenceFieldParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        drawableSize: CGSize
    ) -> [FieldLinesVertex] {
        let width = Float(drawableSize.width)
        let height = Float(drawableSize.height)
        let scale = min(width, height) / 1080.0
        let samples = max(24, min(parameters.samplesPerAxis, 180))
        let waveCount = max(3, min(parameters.waveCount, 18))
        let cycleCount = max(1, min(4, Int((parameters.speed * 2.0).rounded())))
        let phase = Float(clock.phase(frameIndex: frameIndex)) * Float(cycleCount) +
            Float(parameters.phaseOffset / 180.0 * Double.pi)
        let seedPhase = Float(Double(seed % 10_000) / 10_000.0) * .pi * 2.0
        let frequency = Float(max(0.1, parameters.spatialFrequency)) * .pi * 2.0
        let symmetry = Float(clamp(parameters.symmetry, 0.0, 1.0))
        let contrast = Float(clamp(parameters.contrast, 0.01, 0.98))
        let threshold = 0.24 + contrast * 0.20
        let saturation = Float(clamp(parameters.saturation, 0.0, 1.0))
        let brightness = Float(clamp(parameters.brightness, 0.0, 1.5))
        let pointAlpha = Float(clamp(parameters.pointAlpha, 0.0, 1.0))
        let pointSize = Float(parameters.pointSize) * max(1.0, scale)
        let hueBase = Float(parameters.hueBaseDegrees)
        let hueSpread = Float(parameters.hueSpreadDegrees)
        let aspect = width / max(1.0, height)
        let step = 2.0 / Float(max(1, samples - 1))

        var directions: [SIMD2<Float>] = []
        directions.reserveCapacity(waveCount)
        for wave in 0..<waveCount {
            let regularAngle = Float(wave) / Float(waveCount) * .pi * 2.0
            let jitter = (fract(sin(Float(wave) * 19.19 + seedPhase) * 43758.547) - 0.5) * (1.0 - symmetry) * 1.2
            let angle = regularAngle + jitter + seedPhase * 0.03
            directions.append(SIMD2<Float>(cos(angle), sin(angle)))
        }

        var vertices: [FieldLinesVertex] = []
        vertices.reserveCapacity(samples * samples / 2)

        for yIndex in 0..<samples {
            let y = -1.0 + Float(yIndex) * step
            for xIndex in 0..<samples {
                let x = -1.0 + Float(xIndex) * step
                let p = SIMD2<Float>(x * aspect, y)
                let radius = length(p)
                let edgeDistance = min(1.0 - abs(x), 1.0 - abs(y))
                let edgeFade = max(0.0, min(1.0, edgeDistance / 0.10))
                guard edgeFade > 0.01 else { continue }

                var field: Float = 0.0
                var fieldGradient = SIMD2<Float>(repeating: 0)
                for wave in 0..<waveCount {
                    let direction = directions[wave]
                    let harmonic = 1.0 + Float(wave % 3) * 0.18
                    let wavePhase = phase * Float(1 + wave % 3) + Float(wave) * 0.61 + seedPhase * 0.11
                    let value = dot(p, direction) * frequency * harmonic + wavePhase
                    field += cos(value)
                    fieldGradient += direction * sin(value) * harmonic
                }

                let normalized = field / Float(waveCount)
                let ridge = pow(max(0.0, abs(normalized) - threshold) / max(0.001, 1.0 - threshold), 0.55 + contrast)
                let lattice = pow(max(0.0, 1.0 - length(fieldGradient) / Float(waveCount) * 0.72), 1.6)
                let banding = pow(abs(sin((normalized + 1.0) * .pi * Float(waveCount) * 0.55)), 1.25)
                let pulse = 0.78 + 0.22 * sin(phase + radius * .pi * 3.0 + normalized * .pi)
                let intensity = max(max(ridge, lattice * 0.50), banding * 0.36) * edgeFade * pulse
                guard intensity > 0.025 else { continue }

                let swirl = SIMD2<Float>(
                    -p.y * sin(phase + radius * 2.0),
                    p.x * cos(phase - radius * 1.7)
                ) * 0.014
                let drift = fieldGradient * (0.018 + symmetry * 0.028) * intensity + swirl * intensity
                let screen = SIMD2<Float>(
                    (x + drift.x) * width * 0.5 + width * 0.5,
                    (y + drift.y) * height * 0.5 + height * 0.5
                )
                let hue = hueBase + hueSpread * (0.5 + normalized * 0.5) + 24.0 * sin(phase + radius * 2.4)
                let color = hsvToRGB(hueDegrees: hue, saturation: saturation, value: brightness)
                vertices.append(FieldLinesVertex(
                    position: normalizedPosition(screen, width: width, height: height),
                    color: SIMD4<Float>(color.x, color.y, color.z, pointAlpha * min(1.0, intensity * 1.35)),
                    pointSize: pointSize * (0.85 + intensity * 2.4)
                ))
            }
        }

        return vertices
    }

    private func normalizedPosition(_ position: SIMD2<Float>, width: Float, height: Float) -> SIMD2<Float> {
        SIMD2<Float>(
            (position.x / width) * 2.0 - 1.0,
            1.0 - (position.y / height) * 2.0
        )
    }

    private func hsvToRGB(hueDegrees: Float, saturation: Float, value: Float) -> SIMD3<Float> {
        let h = (hueDegrees.truncatingRemainder(dividingBy: 360.0) + 360.0)
            .truncatingRemainder(dividingBy: 360.0) / 60.0
        let c = value * saturation
        let x = c * (1.0 - abs(h.truncatingRemainder(dividingBy: 2.0) - 1.0))

        let rgb: SIMD3<Float>
        switch h {
        case 0..<1:
            rgb = SIMD3<Float>(c, x, 0)
        case 1..<2:
            rgb = SIMD3<Float>(x, c, 0)
        case 2..<3:
            rgb = SIMD3<Float>(0, c, x)
        case 3..<4:
            rgb = SIMD3<Float>(0, x, c)
        case 4..<5:
            rgb = SIMD3<Float>(x, 0, c)
        default:
            rgb = SIMD3<Float>(c, 0, x)
        }

        let m = value - c
        return rgb + SIMD3<Float>(repeating: m)
    }

    private func fract(_ value: Float) -> Float {
        value - floor(value)
    }

    private func clamp(_ value: Double, _ lower: Double, _ upper: Double) -> Double {
        min(max(value, lower), upper)
    }
}

final class PeriodicNoiseRenderer {
    private let device: MTLDevice
    private let pointPipelineState: MTLRenderPipelineState

    init(device: MTLDevice, colorPixelFormat: MTLPixelFormat) throws {
        self.device = device

        let library = try device.makeDefaultLibrary(bundle: .main)
        guard let vertexFunction = library.makeFunction(name: "fieldLinesVertex"),
              let fragmentFunction = library.makeFunction(name: "fieldLinesFragment") else {
            throw RendererError.missingShaderFunction
        }

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.colorAttachments[0].pixelFormat = colorPixelFormat
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].rgbBlendOperation = .add
        descriptor.colorAttachments[0].alphaBlendOperation = .add
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .one
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .one
        pointPipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
    }

    func render(
        parameters: PeriodicNoiseParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        in view: MTKView,
        commandBuffer: MTLCommandBuffer,
        renderPassDescriptor: MTLRenderPassDescriptor
    ) {
        render(
            parameters: parameters,
            seed: seed,
            frameIndex: frameIndex,
            clock: clock,
            drawableSize: view.drawableSize,
            commandBuffer: commandBuffer,
            finalRenderPassDescriptor: renderPassDescriptor
        )
    }

    func render(
        parameters: PeriodicNoiseParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        drawableSize: CGSize,
        outputTexture: MTLTexture,
        commandBuffer: MTLCommandBuffer
    ) {
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = outputTexture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)

        render(
            parameters: parameters,
            seed: seed,
            frameIndex: frameIndex,
            clock: clock,
            drawableSize: drawableSize,
            commandBuffer: commandBuffer,
            finalRenderPassDescriptor: renderPassDescriptor
        )
    }

    private func render(
        parameters: PeriodicNoiseParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        drawableSize: CGSize,
        commandBuffer: MTLCommandBuffer,
        finalRenderPassDescriptor: MTLRenderPassDescriptor
    ) {
        guard drawableSize.width > 1, drawableSize.height > 1 else { return }

        let vertices = makeVertices(
            parameters: parameters,
            seed: seed,
            frameIndex: frameIndex,
            clock: clock,
            drawableSize: drawableSize
        )
        guard !vertices.isEmpty else { return }
        guard let vertexBuffer = device.makeBuffer(
            bytes: vertices,
            length: MemoryLayout<FieldLinesVertex>.stride * vertices.count,
            options: [.storageModeShared]
        ) else {
            return
        }
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: finalRenderPassDescriptor) else {
            return
        }

        encoder.setRenderPipelineState(pointPipelineState)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: vertices.count)
        encoder.endEncoding()
    }

    private func makeVertices(
        parameters: PeriodicNoiseParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        drawableSize: CGSize
    ) -> [FieldLinesVertex] {
        let width = Float(drawableSize.width)
        let height = Float(drawableSize.height)
        let scale = min(width, height) / 1080.0
        let samples = max(24, min(parameters.samplesPerAxis, 180))
        let octaveCount = max(1, min(parameters.octaveCount, 8))
        let cycleCount = max(1, min(4, Int((parameters.speed * 2.0).rounded())))
        let loopPhase = Float(clock.phase(frameIndex: frameIndex)) * Float(cycleCount)
        let timeCircle = SIMD2<Float>(cos(loopPhase), sin(loopPhase))
        let seedPhase = Float(Double(seed % 10_000) / 10_000.0) * .pi * 2.0
        let noiseScale = Float(max(0.1, parameters.noiseScale))
        let warpAmount = Float(clamp(parameters.warpAmount, 0.0, 2.0))
        let turbulence = Float(max(0.0, parameters.turbulence))
        let contourSharpness = Float(clamp(parameters.contourSharpness, 0.0, 1.0))
        let saturation = Float(clamp(parameters.saturation, 0.0, 1.0))
        let brightness = Float(clamp(parameters.brightness, 0.0, 1.4))
        let pointAlpha = Float(clamp(parameters.pointAlpha, 0.0, 1.0))
        let pointSize = Float(parameters.pointSize) * max(1.0, scale)
        let hueBase = Float(parameters.hueBaseDegrees)
        let hueSpread = Float(parameters.hueSpreadDegrees)
        let alphaBoost = Float(1.0 - clamp(parameters.fadeAlpha, 0.02, 0.98))
        let aspect = width / max(1.0, height)
        let step = 2.0 / Float(max(1, samples - 1))

        var vertices: [FieldLinesVertex] = []
        vertices.reserveCapacity(samples * samples / 2)

        for yIndex in 0..<samples {
            let y = -1.0 + Float(yIndex) * step
            for xIndex in 0..<samples {
                let x = -1.0 + Float(xIndex) * step
                let p = SIMD2<Float>(x * aspect, y)
                let radius = length(p)
                let edgeDistance = min(1.0 - abs(x), 1.0 - abs(y))
                let edgeFade = max(0.0, min(1.0, edgeDistance / 0.10))
                guard edgeFade > 0.01 else { continue }

                let warp = periodicNoise(
                    p * (noiseScale * 0.7) + SIMD2<Float>(seedPhase * 0.03, -seedPhase * 0.02),
                    timeCircle: timeCircle,
                    seedPhase: seedPhase + 1.7,
                    octaveCount: max(1, octaveCount - 1),
                    turbulence: turbulence
                )
                let domain = p * noiseScale + SIMD2<Float>(
                    sin(warp * .pi + timeCircle.x * 1.6 + timeCircle.y * 0.7),
                    cos(warp * .pi * 0.9 - timeCircle.y * 1.4 + timeCircle.x * 0.8)
                ) * warpAmount
                let value = periodicNoise(
                    domain,
                    timeCircle: timeCircle,
                    seedPhase: seedPhase,
                    octaveCount: octaveCount,
                    turbulence: turbulence
                )

                let normalized = (value + 1.0) * 0.5
                let contour = abs(sin((normalized * (4.0 + contourSharpness * 10.0) + seedPhase * 0.03) * .pi))
                let softField = pow(max(0.0, normalized), 0.52)
                let contourField = pow(max(0.0, contour), 1.45 - contourSharpness * 0.95)
                let veinField = pow(abs(sin((value + warp * 0.45) * .pi * 5.0 + timeCircle.x * 1.2)), 2.0)
                let intensity = max(mix(softField, contourField, contourSharpness), veinField * 0.42) * edgeFade
                guard intensity > 0.03 else { continue }

                let drift = SIMD2<Float>(
                    sin(value * .pi + loopPhase) * 0.018,
                    cos(value * .pi * 0.82 - loopPhase) * 0.018
                ) * (0.8 + warpAmount * 1.45) * intensity
                let screen = SIMD2<Float>(
                    (x + drift.x) * width * 0.5 + width * 0.5,
                    (y + drift.y) * height * 0.5 + height * 0.5
                )
                let hue = hueBase + hueSpread * normalized + 22.0 * sin(loopPhase + radius * 2.8)
                let color = hsvToRGB(hueDegrees: hue, saturation: saturation, value: brightness)
                vertices.append(FieldLinesVertex(
                    position: normalizedPosition(screen, width: width, height: height),
                    color: SIMD4<Float>(color.x, color.y, color.z, pointAlpha * alphaBoost * min(1.0, intensity * 1.45)),
                    pointSize: pointSize * (0.86 + intensity * 2.45)
                ))
            }
        }

        return vertices
    }

    private func periodicNoise(
        _ point: SIMD2<Float>,
        timeCircle: SIMD2<Float>,
        seedPhase: Float,
        octaveCount: Int,
        turbulence: Float
    ) -> Float {
        var value: Float = 0
        var amplitude: Float = 0.58
        var amplitudeTotal: Float = 0
        var frequency: Float = 1.0

        for octave in 0..<octaveCount {
            let o = Float(octave)
            let angle = seedPhase * 0.19 + o * 1.173
            let direction = SIMD2<Float>(cos(angle), sin(angle))
            let crossDirection = SIMD2<Float>(-direction.y, direction.x)
            let phaseA = dot(point, direction) * frequency * .pi * 2.0 +
                timeCircle.x * (1.2 + o * 0.17) +
                timeCircle.y * (0.7 + o * 0.11) +
                seedPhase
            let phaseB = dot(point, crossDirection) * frequency * .pi * 2.0 -
                timeCircle.y * (1.0 + o * 0.13) +
                timeCircle.x * (0.8 + o * 0.09) +
                seedPhase * 0.63
            let octaveValue = sin(phaseA) * cos(phaseB)
            value += octaveValue * amplitude
            amplitudeTotal += amplitude
            frequency *= 1.85 + turbulence * 0.18
            amplitude *= 0.54
        }

        return amplitudeTotal > 0 ? value / amplitudeTotal : 0
    }

    private func mix(_ a: Float, _ b: Float, _ t: Float) -> Float {
        a * (1.0 - t) + b * t
    }

    private func normalizedPosition(_ position: SIMD2<Float>, width: Float, height: Float) -> SIMD2<Float> {
        SIMD2<Float>(
            (position.x / width) * 2.0 - 1.0,
            1.0 - (position.y / height) * 2.0
        )
    }

    private func hsvToRGB(hueDegrees: Float, saturation: Float, value: Float) -> SIMD3<Float> {
        let h = (hueDegrees.truncatingRemainder(dividingBy: 360.0) + 360.0)
            .truncatingRemainder(dividingBy: 360.0) / 60.0
        let c = value * saturation
        let x = c * (1.0 - abs(h.truncatingRemainder(dividingBy: 2.0) - 1.0))

        let rgb: SIMD3<Float>
        switch h {
        case 0..<1:
            rgb = SIMD3<Float>(c, x, 0)
        case 1..<2:
            rgb = SIMD3<Float>(x, c, 0)
        case 2..<3:
            rgb = SIMD3<Float>(0, c, x)
        case 3..<4:
            rgb = SIMD3<Float>(0, x, c)
        case 4..<5:
            rgb = SIMD3<Float>(x, 0, c)
        default:
            rgb = SIMD3<Float>(c, 0, x)
        }

        let m = value - c
        return rgb + SIMD3<Float>(repeating: m)
    }

    private func clamp(_ value: Double, _ lower: Double, _ upper: Double) -> Double {
        min(max(value, lower), upper)
    }
}

final class CyclicAutomataRenderer {
    private let device: MTLDevice
    private let pointPipelineState: MTLRenderPipelineState

    init(device: MTLDevice, colorPixelFormat: MTLPixelFormat) throws {
        self.device = device

        let library = try device.makeDefaultLibrary(bundle: .main)
        guard let vertexFunction = library.makeFunction(name: "fieldLinesVertex"),
              let fragmentFunction = library.makeFunction(name: "fieldLinesFragment") else {
            throw RendererError.missingShaderFunction
        }

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.colorAttachments[0].pixelFormat = colorPixelFormat
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].rgbBlendOperation = .add
        descriptor.colorAttachments[0].alphaBlendOperation = .add
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .one
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .one
        pointPipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
    }

    func render(
        parameters: CyclicAutomataParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        in view: MTKView,
        commandBuffer: MTLCommandBuffer,
        renderPassDescriptor: MTLRenderPassDescriptor
    ) {
        render(
            parameters: parameters,
            seed: seed,
            frameIndex: frameIndex,
            clock: clock,
            drawableSize: view.drawableSize,
            commandBuffer: commandBuffer,
            finalRenderPassDescriptor: renderPassDescriptor
        )
    }

    func render(
        parameters: CyclicAutomataParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        drawableSize: CGSize,
        outputTexture: MTLTexture,
        commandBuffer: MTLCommandBuffer
    ) {
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = outputTexture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)

        render(
            parameters: parameters,
            seed: seed,
            frameIndex: frameIndex,
            clock: clock,
            drawableSize: drawableSize,
            commandBuffer: commandBuffer,
            finalRenderPassDescriptor: renderPassDescriptor
        )
    }

    private func render(
        parameters: CyclicAutomataParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        drawableSize: CGSize,
        commandBuffer: MTLCommandBuffer,
        finalRenderPassDescriptor: MTLRenderPassDescriptor
    ) {
        guard drawableSize.width > 1, drawableSize.height > 1 else { return }
        let vertices = makeVertices(
            parameters: parameters,
            seed: seed,
            frameIndex: frameIndex,
            clock: clock,
            drawableSize: drawableSize
        )
        guard !vertices.isEmpty else { return }
        guard let vertexBuffer = device.makeBuffer(
            bytes: vertices,
            length: MemoryLayout<FieldLinesVertex>.stride * vertices.count,
            options: [.storageModeShared]
        ) else {
            return
        }
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: finalRenderPassDescriptor) else {
            return
        }

        encoder.setRenderPipelineState(pointPipelineState)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: vertices.count)
        encoder.endEncoding()
    }

    private func makeVertices(
        parameters: CyclicAutomataParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        drawableSize: CGSize
    ) -> [FieldLinesVertex] {
        let width = Float(drawableSize.width)
        let height = Float(drawableSize.height)
        let scale = min(width, height) / 1080.0
        let aspect = width / max(1.0, height)
        let cells = max(24, min(parameters.cellsPerAxis, 180))
        let stateCount = max(3, min(parameters.stateCount, 14))
        let cycleCount = max(1, min(5, Int((parameters.speed * 2.0).rounded())))
        let phase = Float(clock.phase(frameIndex: frameIndex)) * Float(cycleCount) +
            Float(parameters.phaseOffset / 180.0 * Double.pi)
        let seedPhase = Float(Double(seed % 10_000) / 10_000.0) * .pi * 2.0
        let cellScale = Float(max(0.2, parameters.cellScale))
        let saturation = Float(clamp(parameters.saturation, 0.0, 1.0))
        let brightness = Float(clamp(parameters.brightness, 0.0, 1.4))
        let alpha = Float(clamp(parameters.cellAlpha, 0.0, 1.0))
        let cellSize = Float(parameters.cellSize) * max(1.0, scale)
        let neighborhood = Float(clamp(parameters.neighborhood, 0.0, 1.0))
        let mutation = Float(clamp(parameters.mutation, 0.0, 1.0))
        let edgeSharpness = Float(clamp(parameters.edgeSharpness, 0.0, 1.0))
        let hueBase = Float(parameters.hueBaseDegrees)
        let hueSpread = Float(parameters.hueSpreadDegrees)
        let alphaBoost = Float(1.0 - clamp(parameters.fadeAlpha, 0.02, 0.98))
        let step = 2.0 / Float(max(1, cells - 1))

        var vertices: [FieldLinesVertex] = []
        vertices.reserveCapacity(cells * cells)

        for yIndex in 0..<cells {
            let y = -1.0 + Float(yIndex) * step
            for xIndex in 0..<cells {
                let x = -1.0 + Float(xIndex) * step
                let p = SIMD2<Float>(x * aspect, y)
                let lattice = SIMD2<Float>(Float(xIndex), Float(yIndex))
                let base = cyclicField(
                    point: p * cellScale,
                    lattice: lattice,
                    phase: phase,
                    seedPhase: seedPhase,
                    neighborhood: neighborhood,
                    mutation: mutation
                )
                let neighborA = cyclicField(
                    point: (p + SIMD2<Float>(step * aspect, 0)) * cellScale,
                    lattice: lattice + SIMD2<Float>(1, 0),
                    phase: phase,
                    seedPhase: seedPhase,
                    neighborhood: neighborhood,
                    mutation: mutation
                )
                let neighborB = cyclicField(
                    point: (p + SIMD2<Float>(0, step)) * cellScale,
                    lattice: lattice + SIMD2<Float>(0, 1),
                    phase: phase,
                    seedPhase: seedPhase,
                    neighborhood: neighborhood,
                    mutation: mutation
                )

                let state = floor(fract(base) * Float(stateCount))
                let stateProgress = state / Float(max(1, stateCount - 1))
                let edge = min(1.0, abs(base - neighborA) * 3.0 + abs(base - neighborB) * 3.0)
                let reactionFront = pow(abs(sin((base * Float(stateCount) + phase) * .pi)), 1.15)
                let intensity = mix(0.32 + reactionFront * 0.42, edge, edgeSharpness)
                guard intensity > 0.04 else { continue }

                let jitter = SIMD2<Float>(
                    sin(base * .pi * 2.0 + phase) * 0.006,
                    cos(base * .pi * 2.0 - phase) * 0.006
                ) * mutation
                let screen = SIMD2<Float>(
                    (x + jitter.x) * width * 0.5 + width * 0.5,
                    (y + jitter.y) * height * 0.5 + height * 0.5
                )
                let hue = hueBase + hueSpread * stateProgress + 18.0 * sin(phase + base * .pi)
                let color = hsvToRGB(hueDegrees: hue, saturation: saturation, value: brightness)
                vertices.append(FieldLinesVertex(
                    position: normalizedPosition(screen, width: width, height: height),
                    color: SIMD4<Float>(color.x, color.y, color.z, alpha * alphaBoost * min(1.0, intensity * 1.45)),
                    pointSize: cellSize * (0.72 + intensity * 1.35)
                ))
            }
        }

        return vertices
    }

    private func cyclicField(
        point: SIMD2<Float>,
        lattice: SIMD2<Float>,
        phase: Float,
        seedPhase: Float,
        neighborhood: Float,
        mutation: Float
    ) -> Float {
        let waveA = sin(point.x * .pi * 2.0 + phase + seedPhase * 0.31)
        let waveB = cos(point.y * .pi * 2.0 - phase + seedPhase * 0.47)
        let waveC = sin((point.x + point.y) * .pi * (1.15 + neighborhood) + phase * 2.0)
        let cellular = sin((lattice.x * 0.37 + lattice.y * 0.61 + seedPhase) * (1.0 + mutation * 0.7))
        let value = waveA * 0.30 + waveB * 0.26 + waveC * (0.22 + neighborhood * 0.16) + cellular * mutation * 0.22
        return fract(value * 0.5 + 0.5)
    }

    private func mix(_ a: Float, _ b: Float, _ t: Float) -> Float {
        a * (1.0 - t) + b * t
    }

    private func normalizedPosition(_ position: SIMD2<Float>, width: Float, height: Float) -> SIMD2<Float> {
        SIMD2<Float>(
            (position.x / width) * 2.0 - 1.0,
            1.0 - (position.y / height) * 2.0
        )
    }

    private func hsvToRGB(hueDegrees: Float, saturation: Float, value: Float) -> SIMD3<Float> {
        let h = (hueDegrees.truncatingRemainder(dividingBy: 360.0) + 360.0)
            .truncatingRemainder(dividingBy: 360.0) / 60.0
        let c = value * saturation
        let x = c * (1.0 - abs(h.truncatingRemainder(dividingBy: 2.0) - 1.0))

        let rgb: SIMD3<Float>
        switch h {
        case 0..<1:
            rgb = SIMD3<Float>(c, x, 0)
        case 1..<2:
            rgb = SIMD3<Float>(x, c, 0)
        case 2..<3:
            rgb = SIMD3<Float>(0, c, x)
        case 3..<4:
            rgb = SIMD3<Float>(0, x, c)
        case 4..<5:
            rgb = SIMD3<Float>(x, 0, c)
        default:
            rgb = SIMD3<Float>(c, 0, x)
        }

        let m = value - c
        return rgb + SIMD3<Float>(repeating: m)
    }

    private func fract(_ value: Float) -> Float {
        value - floor(value)
    }

    private func clamp(_ value: Double, _ lower: Double, _ upper: Double) -> Double {
        min(max(value, lower), upper)
    }
}

final class AgentSwarmRenderer {
    private let device: MTLDevice
    private let pointPipelineState: MTLRenderPipelineState

    init(device: MTLDevice, colorPixelFormat: MTLPixelFormat) throws {
        self.device = device

        let library = try device.makeDefaultLibrary(bundle: .main)
        guard let vertexFunction = library.makeFunction(name: "fieldLinesVertex"),
              let fragmentFunction = library.makeFunction(name: "fieldLinesFragment") else {
            throw RendererError.missingShaderFunction
        }

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.colorAttachments[0].pixelFormat = colorPixelFormat
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].rgbBlendOperation = .add
        descriptor.colorAttachments[0].alphaBlendOperation = .add
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .one
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .one
        pointPipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
    }

    func render(
        parameters: AgentSwarmParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        in view: MTKView,
        commandBuffer: MTLCommandBuffer,
        renderPassDescriptor: MTLRenderPassDescriptor
    ) {
        render(
            parameters: parameters,
            seed: seed,
            frameIndex: frameIndex,
            clock: clock,
            drawableSize: view.drawableSize,
            commandBuffer: commandBuffer,
            finalRenderPassDescriptor: renderPassDescriptor
        )
    }

    func render(
        parameters: AgentSwarmParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        drawableSize: CGSize,
        outputTexture: MTLTexture,
        commandBuffer: MTLCommandBuffer
    ) {
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = outputTexture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)

        render(
            parameters: parameters,
            seed: seed,
            frameIndex: frameIndex,
            clock: clock,
            drawableSize: drawableSize,
            commandBuffer: commandBuffer,
            finalRenderPassDescriptor: renderPassDescriptor
        )
    }

    private func render(
        parameters: AgentSwarmParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        drawableSize: CGSize,
        commandBuffer: MTLCommandBuffer,
        finalRenderPassDescriptor: MTLRenderPassDescriptor
    ) {
        guard drawableSize.width > 1, drawableSize.height > 1 else { return }
        let vertices = makeVertices(
            parameters: parameters,
            seed: seed,
            frameIndex: frameIndex,
            clock: clock,
            drawableSize: drawableSize
        )
        guard !vertices.isEmpty else { return }
        guard let vertexBuffer = device.makeBuffer(
            bytes: vertices,
            length: MemoryLayout<FieldLinesVertex>.stride * vertices.count,
            options: [.storageModeShared]
        ) else {
            return
        }
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: finalRenderPassDescriptor) else {
            return
        }

        encoder.setRenderPipelineState(pointPipelineState)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: vertices.count)
        encoder.endEncoding()
    }

    private func makeVertices(
        parameters: AgentSwarmParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        drawableSize: CGSize
    ) -> [FieldLinesVertex] {
        let width = Float(drawableSize.width)
        let height = Float(drawableSize.height)
        let scale = min(width, height) / 1080.0
        let agentCount = max(1, min(parameters.agentCount, 1_200))
        let trailCount = max(0, min(parameters.trailCount, 16))
        let cycleCount = max(1, min(5, Int((parameters.speed * 2.0).rounded())))
        let phase = Float(clock.phase(frameIndex: frameIndex)) * Float(cycleCount)
        let seedPhase = Float(Double(seed % 10_000) / 10_000.0) * .pi * 2.0
        let orbitRadius = Float(clamp(parameters.orbitRadius, 0.05, 1.4))
        let cohesion = Float(clamp(parameters.cohesion, 0.0, 1.0))
        let wander = Float(clamp(parameters.wander, 0.0, 1.0))
        let separation = Float(clamp(parameters.separation, 0.0, 1.0))
        let saturation = Float(clamp(parameters.saturation, 0.0, 1.0))
        let brightness = Float(clamp(parameters.brightness, 0.0, 1.4))
        let agentAlpha = Float(clamp(parameters.agentAlpha, 0.0, 1.0))
        let trailAlpha = Float(clamp(parameters.trailAlpha, 0.0, 1.0))
        let agentSize = Float(parameters.agentSize) * max(1.0, scale)
        let hueBase = Float(parameters.hueBaseDegrees)
        let hueSpread = Float(parameters.hueSpreadDegrees)
        let alphaBoost = Float(1.0 - clamp(parameters.fadeAlpha, 0.02, 0.98))

        var vertices: [FieldLinesVertex] = []
        vertices.reserveCapacity(agentCount * (trailCount + 1))

        for agent in 0..<agentCount {
            let id = Float(agent)
            let group = Float(agent % 7)
            let groupAngle = group / 7.0 * .pi * 2.0 + seedPhase * 0.13
            let groupAnchor = SIMD2<Float>(
                cos(groupAngle + phase),
                sin(groupAngle - phase)
            ) * cohesion * 0.44
            let base = fract(id * 0.618_034 + seedPhase * 0.017)
            let localSeed = seedPhase + id * 0.137
            let trailSteps = trailCount + 1

            for trail in 0..<trailSteps {
                let trailProgress = Float(trail) / Float(max(1, trailSteps))
                let localPhase = phase - trailProgress * 0.42 * Float(cycleCount)
                let normalizedPhase = localPhase / (.pi * 2.0)
                let pathA = localPhase + localSeed + Float(agent % 5) * 0.12
                let pathB = localPhase - localSeed * 0.71 + Float(agent % 7) * 0.09
                let wandering = SIMD2<Float>(
                    sin(pathA) + sin(pathB + id * 0.11) * wander,
                    cos(pathB) + cos(pathA - id * 0.09) * wander
                ) * orbitRadius * 0.42
                let lane = SIMD2<Float>(
                    fract(base + normalizedPhase + sin(id) * 0.03) * 2.0 - 1.0,
                    fract(base * 1.7 - normalizedPhase + cos(id * 0.7) * 0.04) * 2.0 - 1.0
                ) * separation
                let position = wrap(groupAnchor + wandering + lane * 0.52)
                let screen = SIMD2<Float>(
                    (position.x * 0.5 + 0.5) * width,
                    (position.y * 0.5 + 0.5) * height
                )
                let intensity = 1.0 - trailProgress * 0.78
                let hue = hueBase + hueSpread * fract(base + group * 0.071) + 22.0 * sin(localPhase + id * 0.03)
                let color = hsvToRGB(hueDegrees: hue, saturation: saturation, value: brightness)
                let alpha = (trail == 0 ? agentAlpha : trailAlpha) * alphaBoost * intensity
                vertices.append(FieldLinesVertex(
                    position: normalizedPosition(screen, width: width, height: height),
                    color: SIMD4<Float>(color.x, color.y, color.z, alpha),
                    pointSize: agentSize * (trail == 0 ? 1.0 : 0.72 + intensity * 0.26)
                ))
            }
        }

        return vertices
    }

    private func wrap(_ point: SIMD2<Float>) -> SIMD2<Float> {
        SIMD2<Float>(
            fract((point.x + 1.0) * 0.5) * 2.0 - 1.0,
            fract((point.y + 1.0) * 0.5) * 2.0 - 1.0
        )
    }

    private func normalizedPosition(_ position: SIMD2<Float>, width: Float, height: Float) -> SIMD2<Float> {
        SIMD2<Float>(
            (position.x / width) * 2.0 - 1.0,
            1.0 - (position.y / height) * 2.0
        )
    }

    private func hsvToRGB(hueDegrees: Float, saturation: Float, value: Float) -> SIMD3<Float> {
        let h = (hueDegrees.truncatingRemainder(dividingBy: 360.0) + 360.0)
            .truncatingRemainder(dividingBy: 360.0) / 60.0
        let c = value * saturation
        let x = c * (1.0 - abs(h.truncatingRemainder(dividingBy: 2.0) - 1.0))

        let rgb: SIMD3<Float>
        switch h {
        case 0..<1:
            rgb = SIMD3<Float>(c, x, 0)
        case 1..<2:
            rgb = SIMD3<Float>(x, c, 0)
        case 2..<3:
            rgb = SIMD3<Float>(0, c, x)
        case 3..<4:
            rgb = SIMD3<Float>(0, x, c)
        case 4..<5:
            rgb = SIMD3<Float>(x, 0, c)
        default:
            rgb = SIMD3<Float>(c, 0, x)
        }

        let m = value - c
        return rgb + SIMD3<Float>(repeating: m)
    }

    private func fract(_ value: Float) -> Float {
        value - floor(value)
    }

    private func clamp(_ value: Double, _ lower: Double, _ upper: Double) -> Double {
        min(max(value, lower), upper)
    }
}

final class KaleidoscopeRenderer {
    private let device: MTLDevice
    private let pointPipelineState: MTLRenderPipelineState

    init(device: MTLDevice, colorPixelFormat: MTLPixelFormat) throws {
        self.device = device

        let library = try device.makeDefaultLibrary(bundle: .main)
        guard let vertexFunction = library.makeFunction(name: "fieldLinesVertex"),
              let fragmentFunction = library.makeFunction(name: "fieldLinesFragment") else {
            throw RendererError.missingShaderFunction
        }

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.colorAttachments[0].pixelFormat = colorPixelFormat
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].rgbBlendOperation = .add
        descriptor.colorAttachments[0].alphaBlendOperation = .add
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .one
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .one
        pointPipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
    }

    func render(
        parameters: KaleidoscopeParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        in view: MTKView,
        commandBuffer: MTLCommandBuffer,
        renderPassDescriptor: MTLRenderPassDescriptor
    ) {
        render(
            parameters: parameters,
            seed: seed,
            frameIndex: frameIndex,
            clock: clock,
            drawableSize: view.drawableSize,
            commandBuffer: commandBuffer,
            finalRenderPassDescriptor: renderPassDescriptor
        )
    }

    func render(
        parameters: KaleidoscopeParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        drawableSize: CGSize,
        outputTexture: MTLTexture,
        commandBuffer: MTLCommandBuffer
    ) {
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = outputTexture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)

        render(
            parameters: parameters,
            seed: seed,
            frameIndex: frameIndex,
            clock: clock,
            drawableSize: drawableSize,
            commandBuffer: commandBuffer,
            finalRenderPassDescriptor: renderPassDescriptor
        )
    }

    private func render(
        parameters: KaleidoscopeParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        drawableSize: CGSize,
        commandBuffer: MTLCommandBuffer,
        finalRenderPassDescriptor: MTLRenderPassDescriptor
    ) {
        guard drawableSize.width > 1, drawableSize.height > 1 else { return }
        let vertices = makeVertices(
            parameters: parameters,
            seed: seed,
            frameIndex: frameIndex,
            clock: clock,
            drawableSize: drawableSize
        )
        guard !vertices.isEmpty else { return }
        guard let vertexBuffer = device.makeBuffer(
            bytes: vertices,
            length: MemoryLayout<FieldLinesVertex>.stride * vertices.count,
            options: [.storageModeShared]
        ) else {
            return
        }
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: finalRenderPassDescriptor) else {
            return
        }

        encoder.setRenderPipelineState(pointPipelineState)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: vertices.count)
        encoder.endEncoding()
    }

    private func makeVertices(
        parameters: KaleidoscopeParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        drawableSize: CGSize
    ) -> [FieldLinesVertex] {
        let width = Float(drawableSize.width)
        let height = Float(drawableSize.height)
        let scale = min(width, height) / 1080.0
        let rings = max(1, min(parameters.ringCount, 24))
        let segments = max(3, min(parameters.segments, 32))
        let pointsPerRing = max(60, min(parameters.pointsPerRing, 1_200))
        let cycleCount = max(1, min(5, Int((parameters.speed * 2.0).rounded())))
        let phase = Float(clock.phase(frameIndex: frameIndex)) * Float(cycleCount)
        let seedPhase = Float(Double(seed % 10_000) / 10_000.0) * .pi * 2.0
        let radiusScale = Float(clamp(parameters.radiusScale, 0.1, 1.4))
        let twist = Float(clamp(parameters.twist, 0.0, 1.0))
        let petalAmount = Float(clamp(parameters.petalAmount, 0.0, 1.0))
        let complexity = Float(clamp(parameters.complexity, 0.0, 1.0))
        let saturation = Float(clamp(parameters.saturation, 0.0, 1.0))
        let brightness = Float(clamp(parameters.brightness, 0.0, 1.4))
        let alpha = Float(clamp(parameters.pointAlpha, 0.0, 1.0))
        let pointSize = Float(parameters.pointSize) * max(1.0, scale)
        let hueBase = Float(parameters.hueBaseDegrees)
        let hueSpread = Float(parameters.hueSpreadDegrees)
        let alphaBoost = Float(1.0 - clamp(parameters.fadeAlpha, 0.02, 0.98))
        let wedgeAngle = (.pi * 2.0) / Float(segments)

        var vertices: [FieldLinesVertex] = []
        vertices.reserveCapacity(rings * pointsPerRing * 2)

        for ring in 0..<rings {
            let ringProgress = Float(ring + 1) / Float(rings)
            let baseRadius = pow(ringProgress, 0.72) * radiusScale
            let ringPhase = seedPhase + Float(ring) * 0.47
            let ringHue = hueBase + hueSpread * ringProgress

            for index in 0..<pointsPerRing {
                let sample = Float(index) / Float(pointsPerRing)
                let mirroredSample = sample < 0.5 ? sample * 2.0 : (1.0 - sample) * 2.0
                let localAngle = mirroredSample * wedgeAngle
                let fold = Float(index % 2 == 0 ? 1.0 : -1.0)
                let segment = (index * segments) / pointsPerRing
                let segmentAngle = Float(segment % segments) * wedgeAngle
                let harmonicA = sin(sample * .pi * 2.0 * Float(segments) + phase + ringPhase)
                let harmonicB = cos(sample * .pi * 2.0 * Float(segments / 2 + 2) - phase + ringPhase)
                let petal = 1.0 + petalAmount * 0.22 *
                    sin(localAngle * Float(segments) + phase + ringProgress * .pi)
                let lace = 1.0 + complexity * 0.14 * harmonicA + complexity * 0.10 * harmonicB
                let radius = baseRadius * petal * lace
                let angle = segmentAngle + localAngle * fold + twist * ringProgress * phase +
                    sin(ringPhase + phase) * twist * 0.08
                let x = cos(angle) * radius
                let y = sin(angle) * radius
                let screen = SIMD2<Float>(
                    x * width * 0.46 + width * 0.5,
                    y * height * 0.46 + height * 0.5
                )
                let edgeFade = min(1.0, max(0.0, 1.18 - radius * 0.28))
                let sparkle = 0.64 + 0.36 * abs(sin(phase + sample * .pi * 2.0 + ringPhase))
                let hue = ringHue + 34.0 * harmonicA + 18.0 * harmonicB
                let color = hsvToRGB(hueDegrees: hue, saturation: saturation, value: brightness)

                vertices.append(FieldLinesVertex(
                    position: normalizedPosition(screen, width: width, height: height),
                    color: SIMD4<Float>(color.x, color.y, color.z, alpha * alphaBoost * edgeFade * sparkle),
                    pointSize: pointSize * (0.74 + ringProgress * 0.56 + abs(harmonicA) * 0.34)
                ))

                if complexity > 0.35 {
                    let counterAngle = segmentAngle - localAngle * fold - twist * ringProgress * phase
                    let counterRadius = radius * (0.70 + complexity * 0.22)
                    let counterScreen = SIMD2<Float>(
                        cos(counterAngle) * counterRadius * width * 0.46 + width * 0.5,
                        sin(counterAngle) * counterRadius * height * 0.46 + height * 0.5
                    )
                    vertices.append(FieldLinesVertex(
                        position: normalizedPosition(counterScreen, width: width, height: height),
                        color: SIMD4<Float>(color.x, color.y, color.z, alpha * alphaBoost * edgeFade * 0.56),
                        pointSize: pointSize * 0.72
                    ))
                }
            }
        }

        return vertices
    }

    private func normalizedPosition(_ position: SIMD2<Float>, width: Float, height: Float) -> SIMD2<Float> {
        SIMD2<Float>(
            (position.x / width) * 2.0 - 1.0,
            1.0 - (position.y / height) * 2.0
        )
    }

    private func hsvToRGB(hueDegrees: Float, saturation: Float, value: Float) -> SIMD3<Float> {
        let h = (hueDegrees.truncatingRemainder(dividingBy: 360.0) + 360.0)
            .truncatingRemainder(dividingBy: 360.0) / 60.0
        let c = value * saturation
        let x = c * (1.0 - abs(h.truncatingRemainder(dividingBy: 2.0) - 1.0))

        let rgb: SIMD3<Float>
        switch h {
        case 0..<1:
            rgb = SIMD3<Float>(c, x, 0)
        case 1..<2:
            rgb = SIMD3<Float>(x, c, 0)
        case 2..<3:
            rgb = SIMD3<Float>(0, c, x)
        case 3..<4:
            rgb = SIMD3<Float>(0, x, c)
        case 4..<5:
            rgb = SIMD3<Float>(x, 0, c)
        default:
            rgb = SIMD3<Float>(c, 0, x)
        }

        let m = value - c
        return rgb + SIMD3<Float>(repeating: m)
    }

    private func clamp(_ value: Double, _ lower: Double, _ upper: Double) -> Double {
        min(max(value, lower), upper)
    }
}

final class VoronoiFlowRenderer {
    private let device: MTLDevice
    private let pointPipelineState: MTLRenderPipelineState

    init(device: MTLDevice, colorPixelFormat: MTLPixelFormat) throws {
        self.device = device

        let library = try device.makeDefaultLibrary(bundle: .main)
        guard let vertexFunction = library.makeFunction(name: "fieldLinesVertex"),
              let fragmentFunction = library.makeFunction(name: "fieldLinesFragment") else {
            throw RendererError.missingShaderFunction
        }

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.colorAttachments[0].pixelFormat = colorPixelFormat
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].rgbBlendOperation = .add
        descriptor.colorAttachments[0].alphaBlendOperation = .add
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .one
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .one
        pointPipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
    }

    func render(
        parameters: VoronoiFlowParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        in view: MTKView,
        commandBuffer: MTLCommandBuffer,
        renderPassDescriptor: MTLRenderPassDescriptor
    ) {
        render(
            parameters: parameters,
            seed: seed,
            frameIndex: frameIndex,
            clock: clock,
            drawableSize: view.drawableSize,
            commandBuffer: commandBuffer,
            finalRenderPassDescriptor: renderPassDescriptor
        )
    }

    func render(
        parameters: VoronoiFlowParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        drawableSize: CGSize,
        outputTexture: MTLTexture,
        commandBuffer: MTLCommandBuffer
    ) {
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = outputTexture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)

        render(
            parameters: parameters,
            seed: seed,
            frameIndex: frameIndex,
            clock: clock,
            drawableSize: drawableSize,
            commandBuffer: commandBuffer,
            finalRenderPassDescriptor: renderPassDescriptor
        )
    }

    private func render(
        parameters: VoronoiFlowParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        drawableSize: CGSize,
        commandBuffer: MTLCommandBuffer,
        finalRenderPassDescriptor: MTLRenderPassDescriptor
    ) {
        guard drawableSize.width > 1, drawableSize.height > 1 else { return }
        let vertices = makeVertices(
            parameters: parameters,
            seed: seed,
            frameIndex: frameIndex,
            clock: clock,
            drawableSize: drawableSize
        )
        guard !vertices.isEmpty else { return }
        guard let vertexBuffer = device.makeBuffer(
            bytes: vertices,
            length: MemoryLayout<FieldLinesVertex>.stride * vertices.count,
            options: [.storageModeShared]
        ) else {
            return
        }
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: finalRenderPassDescriptor) else {
            return
        }

        encoder.setRenderPipelineState(pointPipelineState)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: vertices.count)
        encoder.endEncoding()
    }

    private func makeVertices(
        parameters: VoronoiFlowParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        drawableSize: CGSize
    ) -> [FieldLinesVertex] {
        let width = Float(drawableSize.width)
        let height = Float(drawableSize.height)
        let aspect = width / max(1.0, height)
        let scale = min(width, height) / 1080.0
        let siteCount = max(4, min(parameters.siteCount, 96))
        let samples = max(32, min(parameters.samplesPerAxis, 180))
        let cycleCount = max(1, min(5, Int((parameters.speed * 2.0).rounded())))
        let phase = Float(clock.phase(frameIndex: frameIndex)) * Float(cycleCount)
        let seedPhase = Float(Double(seed % 10_000) / 10_000.0) * .pi * 2.0
        let cellScale = Float(clamp(parameters.cellScale, 0.2, 3.0))
        let edgeWidth = Float(clamp(parameters.edgeWidth, 0.02, 1.0))
        let pulseAmount = Float(clamp(parameters.pulseAmount, 0.0, 1.0))
        let drift = Float(clamp(parameters.drift, 0.0, 1.0))
        let saturation = Float(clamp(parameters.saturation, 0.0, 1.0))
        let brightness = Float(clamp(parameters.brightness, 0.0, 1.4))
        let edgeAlpha = Float(clamp(parameters.edgeAlpha, 0.0, 1.0))
        let fillAlpha = Float(clamp(parameters.fillAlpha, 0.0, 1.0))
        let pointSize = Float(parameters.pointSize) * max(1.0, scale)
        let hueBase = Float(parameters.hueBaseDegrees)
        let hueSpread = Float(parameters.hueSpreadDegrees)
        let alphaBoost = Float(1.0 - clamp(parameters.fadeAlpha, 0.02, 0.98))
        let step = 2.0 / Float(max(1, samples - 1))
        let threshold = 0.010 + edgeWidth * 0.070
        let sites = makeSites(
            count: siteCount,
            seedPhase: seedPhase,
            phase: phase,
            drift: drift
        )

        var vertices: [FieldLinesVertex] = []
        vertices.reserveCapacity(samples * samples)

        for yIndex in 0..<samples {
            let y = -1.0 + Float(yIndex) * step
            for xIndex in 0..<samples {
                let x = -1.0 + Float(xIndex) * step
                let p = SIMD2<Float>(x * aspect * cellScale, y * cellScale)
                var nearestDistance = Float.greatestFiniteMagnitude
                var secondDistance = Float.greatestFiniteMagnitude
                var nearestIndex = 0

                for siteIndex in 0..<sites.count {
                    let site = SIMD2<Float>(sites[siteIndex].x * aspect * cellScale, sites[siteIndex].y * cellScale)
                    let distance = simd_length_squared(p - site)
                    if distance < nearestDistance {
                        secondDistance = nearestDistance
                        nearestDistance = distance
                        nearestIndex = siteIndex
                    } else if distance < secondDistance {
                        secondDistance = distance
                    }
                }

                let gap = sqrt(max(0.0, secondDistance)) - sqrt(max(0.0, nearestDistance))
                let edge = 1.0 - smoothstep(0.0, threshold, gap)
                let cellPulse = 0.5 + 0.5 * sin(
                    phase + Float(nearestIndex) * 0.73 + sqrt(nearestDistance) * 9.0
                )
                let fill = fillAlpha * (0.42 + cellPulse * pulseAmount * 0.58)
                let intensity = max(edge * edgeAlpha, fill)
                guard intensity > 0.01 else { continue }

                let screen = SIMD2<Float>(
                    (x * 0.5 + 0.5) * width,
                    (y * 0.5 + 0.5) * height
                )
                let siteProgress = Float(nearestIndex) / Float(max(1, siteCount - 1))
                let hue = hueBase + hueSpread * siteProgress + 20.0 * cellPulse + 12.0 * sin(phase)
                let color = hsvToRGB(hueDegrees: hue, saturation: saturation, value: brightness)
                vertices.append(FieldLinesVertex(
                    position: normalizedPosition(screen, width: width, height: height),
                    color: SIMD4<Float>(color.x, color.y, color.z, intensity * alphaBoost),
                    pointSize: pointSize * (0.82 + edge * 0.78 + cellPulse * pulseAmount * 0.24)
                ))
            }
        }

        return vertices
    }

    private func makeSites(
        count: Int,
        seedPhase: Float,
        phase: Float,
        drift: Float
    ) -> [SIMD2<Float>] {
        var sites: [SIMD2<Float>] = []
        sites.reserveCapacity(count)

        for index in 0..<count {
            let id = Float(index)
            let baseX = fract(0.137 + id * 0.618_034 + seedPhase * 0.011) * 2.0 - 1.0
            let baseY = fract(0.431 + id * 0.414_214 + seedPhase * 0.017) * 2.0 - 1.0
            let local = seedPhase + id * 0.379
            let offset = SIMD2<Float>(
                sin(phase + local + Float(index % 5) * 0.08),
                cos(phase - local * 0.83 + Float(index % 7) * 0.07)
            ) * drift * 0.26
            sites.append(wrap(SIMD2<Float>(baseX, baseY) + offset))
        }

        return sites
    }

    private func wrap(_ point: SIMD2<Float>) -> SIMD2<Float> {
        SIMD2<Float>(
            fract((point.x + 1.0) * 0.5) * 2.0 - 1.0,
            fract((point.y + 1.0) * 0.5) * 2.0 - 1.0
        )
    }

    private func smoothstep(_ edge0: Float, _ edge1: Float, _ x: Float) -> Float {
        let t = min(max((x - edge0) / max(0.0001, edge1 - edge0), 0.0), 1.0)
        return t * t * (3.0 - 2.0 * t)
    }

    private func normalizedPosition(_ position: SIMD2<Float>, width: Float, height: Float) -> SIMD2<Float> {
        SIMD2<Float>(
            (position.x / width) * 2.0 - 1.0,
            1.0 - (position.y / height) * 2.0
        )
    }

    private func hsvToRGB(hueDegrees: Float, saturation: Float, value: Float) -> SIMD3<Float> {
        let h = (hueDegrees.truncatingRemainder(dividingBy: 360.0) + 360.0)
            .truncatingRemainder(dividingBy: 360.0) / 60.0
        let c = value * saturation
        let x = c * (1.0 - abs(h.truncatingRemainder(dividingBy: 2.0) - 1.0))

        let rgb: SIMD3<Float>
        switch h {
        case 0..<1:
            rgb = SIMD3<Float>(c, x, 0)
        case 1..<2:
            rgb = SIMD3<Float>(x, c, 0)
        case 2..<3:
            rgb = SIMD3<Float>(0, c, x)
        case 3..<4:
            rgb = SIMD3<Float>(0, x, c)
        case 4..<5:
            rgb = SIMD3<Float>(x, 0, c)
        default:
            rgb = SIMD3<Float>(c, 0, x)
        }

        let m = value - c
        return rgb + SIMD3<Float>(repeating: m)
    }

    private func fract(_ value: Float) -> Float {
        value - floor(value)
    }

    private func clamp(_ value: Double, _ lower: Double, _ upper: Double) -> Double {
        min(max(value, lower), upper)
    }
}

final class ReactionDiffusionRenderer {
    private let device: MTLDevice
    private let pointPipelineState: MTLRenderPipelineState

    init(device: MTLDevice, colorPixelFormat: MTLPixelFormat) throws {
        self.device = device

        let library = try device.makeDefaultLibrary(bundle: .main)
        guard let vertexFunction = library.makeFunction(name: "fieldLinesVertex"),
              let fragmentFunction = library.makeFunction(name: "fieldLinesFragment") else {
            throw RendererError.missingShaderFunction
        }

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.colorAttachments[0].pixelFormat = colorPixelFormat
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].rgbBlendOperation = .add
        descriptor.colorAttachments[0].alphaBlendOperation = .add
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .one
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .one
        pointPipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
    }

    func render(
        parameters: ReactionDiffusionParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        in view: MTKView,
        commandBuffer: MTLCommandBuffer,
        renderPassDescriptor: MTLRenderPassDescriptor
    ) {
        render(
            parameters: parameters,
            seed: seed,
            frameIndex: frameIndex,
            clock: clock,
            drawableSize: view.drawableSize,
            commandBuffer: commandBuffer,
            finalRenderPassDescriptor: renderPassDescriptor
        )
    }

    func render(
        parameters: ReactionDiffusionParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        drawableSize: CGSize,
        outputTexture: MTLTexture,
        commandBuffer: MTLCommandBuffer
    ) {
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = outputTexture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)

        render(
            parameters: parameters,
            seed: seed,
            frameIndex: frameIndex,
            clock: clock,
            drawableSize: drawableSize,
            commandBuffer: commandBuffer,
            finalRenderPassDescriptor: renderPassDescriptor
        )
    }

    private func render(
        parameters: ReactionDiffusionParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        drawableSize: CGSize,
        commandBuffer: MTLCommandBuffer,
        finalRenderPassDescriptor: MTLRenderPassDescriptor
    ) {
        guard drawableSize.width > 1, drawableSize.height > 1 else { return }
        let vertices = makeVertices(
            parameters: parameters,
            seed: seed,
            frameIndex: frameIndex,
            clock: clock,
            drawableSize: drawableSize
        )
        guard !vertices.isEmpty else { return }
        guard let vertexBuffer = device.makeBuffer(
            bytes: vertices,
            length: MemoryLayout<FieldLinesVertex>.stride * vertices.count,
            options: [.storageModeShared]
        ) else {
            return
        }
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: finalRenderPassDescriptor) else {
            return
        }

        encoder.setRenderPipelineState(pointPipelineState)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: vertices.count)
        encoder.endEncoding()
    }

    private func makeVertices(
        parameters: ReactionDiffusionParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        drawableSize: CGSize
    ) -> [FieldLinesVertex] {
        let width = Float(drawableSize.width)
        let height = Float(drawableSize.height)
        let aspect = width / max(1.0, height)
        let scale = min(width, height) / 1080.0
        let samples = max(32, min(parameters.samplesPerAxis, 180))
        let layerCount = max(1, min(parameters.layerCount, 10))
        let cycleCount = max(1, min(5, Int((parameters.speed * 2.0).rounded())))
        let phase = Float(clock.phase(frameIndex: frameIndex)) * Float(cycleCount)
        let seedPhase = Float(Double(seed % 10_000) / 10_000.0) * .pi * 2.0
        let patternScale = Float(clamp(parameters.patternScale, 0.2, 3.5))
        let stripeSharpness = Float(clamp(parameters.stripeSharpness, 0.0, 1.0))
        let diffusion = Float(clamp(parameters.diffusion, 0.0, 1.0))
        let turbulence = Float(clamp(parameters.turbulence, 0.0, 2.2))
        let symmetry = Float(clamp(parameters.symmetry, 0.0, 1.0))
        let saturation = Float(clamp(parameters.saturation, 0.0, 1.0))
        let brightness = Float(clamp(parameters.brightness, 0.0, 1.4))
        let alpha = Float(clamp(parameters.pointAlpha, 0.0, 1.0))
        let pointSize = Float(parameters.pointSize) * max(1.0, scale)
        let hueBase = Float(parameters.hueBaseDegrees)
        let hueSpread = Float(parameters.hueSpreadDegrees)
        let alphaBoost = Float(1.0 - clamp(parameters.fadeAlpha, 0.02, 0.98))
        let step = 2.0 / Float(max(1, samples - 1))

        var vertices: [FieldLinesVertex] = []
        vertices.reserveCapacity(samples * samples)

        for yIndex in 0..<samples {
            let y = -1.0 + Float(yIndex) * step
            for xIndex in 0..<samples {
                let x = -1.0 + Float(xIndex) * step
                let point = SIMD2<Float>(x * aspect, y)
                let value = reactionField(
                    point: point * patternScale,
                    phase: phase,
                    seedPhase: seedPhase,
                    layerCount: layerCount,
                    diffusion: diffusion,
                    turbulence: turbulence,
                    symmetry: symmetry
                )
                let stripe = pow(abs(sin(value * .pi)), 0.72 + stripeSharpness * 2.1)
                let spot = pow(max(0.0, cos(value * .pi * 1.7)), 1.2 + diffusion * 2.4)
                let front = max(stripe * (1.0 - diffusion * 0.42), spot * diffusion)
                guard front > 0.035 else { continue }

                let screen = SIMD2<Float>(
                    (x * 0.5 + 0.5) * width,
                    (y * 0.5 + 0.5) * height
                )
                let hue = hueBase + hueSpread * fract(value * 0.17 + front * 0.23) + 18.0 * sin(phase)
                let color = hsvToRGB(hueDegrees: hue, saturation: saturation, value: brightness)
                vertices.append(FieldLinesVertex(
                    position: normalizedPosition(screen, width: width, height: height),
                    color: SIMD4<Float>(color.x, color.y, color.z, alpha * alphaBoost * min(1.0, front * 1.25)),
                    pointSize: pointSize * (0.72 + front * 1.25)
                ))
            }
        }

        return vertices
    }

    private func reactionField(
        point: SIMD2<Float>,
        phase: Float,
        seedPhase: Float,
        layerCount: Int,
        diffusion: Float,
        turbulence: Float,
        symmetry: Float
    ) -> Float {
        var value: Float = 0
        var weight: Float = 0
        let radius = simd_length(point)
        let angle = atan2(point.y, point.x)

        for layer in 0..<layerCount {
            let fLayer = Float(layer + 1)
            let localPhase = phase + seedPhase * (0.17 + fLayer * 0.03) + fLayer * 0.09
            let direction = seedPhase + fLayer * 1.256
            let basis = point.x * cos(direction) + point.y * sin(direction)
            let cross = point.x * sin(direction * 0.73) - point.y * cos(direction * 0.91)
            let radial = sin(radius * (.pi * (1.2 + fLayer * 0.28)) - localPhase)
            let stripe = sin(basis * .pi * (1.6 + fLayer * 0.42) + localPhase)
            let cells = cos((basis + cross) * .pi * (0.9 + fLayer * 0.33) - localPhase)
            let symmetric = sin(angle * (3.0 + symmetry * 9.0) + localPhase) * symmetry
            let layerValue = stripe * (0.42 + turbulence * 0.08) +
                cells * (0.22 + diffusion * 0.25) +
                radial * (0.18 + turbulence * 0.10) +
                symmetric * 0.18
            let layerWeight = 1.0 / fLayer
            value += layerValue * layerWeight
            weight += layerWeight
        }

        return value / max(0.001, weight)
    }

    private func normalizedPosition(_ position: SIMD2<Float>, width: Float, height: Float) -> SIMD2<Float> {
        SIMD2<Float>(
            (position.x / width) * 2.0 - 1.0,
            1.0 - (position.y / height) * 2.0
        )
    }

    private func hsvToRGB(hueDegrees: Float, saturation: Float, value: Float) -> SIMD3<Float> {
        let h = (hueDegrees.truncatingRemainder(dividingBy: 360.0) + 360.0)
            .truncatingRemainder(dividingBy: 360.0) / 60.0
        let c = value * saturation
        let x = c * (1.0 - abs(h.truncatingRemainder(dividingBy: 2.0) - 1.0))

        let rgb: SIMD3<Float>
        switch h {
        case 0..<1:
            rgb = SIMD3<Float>(c, x, 0)
        case 1..<2:
            rgb = SIMD3<Float>(x, c, 0)
        case 2..<3:
            rgb = SIMD3<Float>(0, c, x)
        case 3..<4:
            rgb = SIMD3<Float>(0, x, c)
        case 4..<5:
            rgb = SIMD3<Float>(x, 0, c)
        default:
            rgb = SIMD3<Float>(c, 0, x)
        }

        let m = value - c
        return rgb + SIMD3<Float>(repeating: m)
    }

    private func fract(_ value: Float) -> Float {
        value - floor(value)
    }

    private func clamp(_ value: Double, _ lower: Double, _ upper: Double) -> Double {
        min(max(value, lower), upper)
    }
}

final class PlasmaFieldRenderer {
    private let device: MTLDevice
    private let pointPipelineState: MTLRenderPipelineState

    init(device: MTLDevice, colorPixelFormat: MTLPixelFormat) throws {
        self.device = device

        let library = try device.makeDefaultLibrary(bundle: .main)
        guard let vertexFunction = library.makeFunction(name: "fieldLinesVertex"),
              let fragmentFunction = library.makeFunction(name: "fieldLinesFragment") else {
            throw RendererError.missingShaderFunction
        }

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.colorAttachments[0].pixelFormat = colorPixelFormat
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].rgbBlendOperation = .add
        descriptor.colorAttachments[0].alphaBlendOperation = .add
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .one
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .one
        pointPipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
    }

    func render(
        parameters: PlasmaFieldParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        in view: MTKView,
        commandBuffer: MTLCommandBuffer,
        renderPassDescriptor: MTLRenderPassDescriptor
    ) {
        render(
            parameters: parameters,
            seed: seed,
            frameIndex: frameIndex,
            clock: clock,
            drawableSize: view.drawableSize,
            commandBuffer: commandBuffer,
            finalRenderPassDescriptor: renderPassDescriptor
        )
    }

    func render(
        parameters: PlasmaFieldParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        drawableSize: CGSize,
        outputTexture: MTLTexture,
        commandBuffer: MTLCommandBuffer
    ) {
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = outputTexture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)

        render(
            parameters: parameters,
            seed: seed,
            frameIndex: frameIndex,
            clock: clock,
            drawableSize: drawableSize,
            commandBuffer: commandBuffer,
            finalRenderPassDescriptor: renderPassDescriptor
        )
    }

    private func render(
        parameters: PlasmaFieldParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        drawableSize: CGSize,
        commandBuffer: MTLCommandBuffer,
        finalRenderPassDescriptor: MTLRenderPassDescriptor
    ) {
        guard drawableSize.width > 1, drawableSize.height > 1 else { return }
        let vertices = makeVertices(
            parameters: parameters,
            seed: seed,
            frameIndex: frameIndex,
            clock: clock,
            drawableSize: drawableSize
        )
        guard !vertices.isEmpty else { return }
        guard let vertexBuffer = device.makeBuffer(
            bytes: vertices,
            length: MemoryLayout<FieldLinesVertex>.stride * vertices.count,
            options: [.storageModeShared]
        ) else {
            return
        }
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: finalRenderPassDescriptor) else {
            return
        }

        encoder.setRenderPipelineState(pointPipelineState)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: vertices.count)
        encoder.endEncoding()
    }

    private func makeVertices(
        parameters: PlasmaFieldParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        drawableSize: CGSize
    ) -> [FieldLinesVertex] {
        let width = Float(drawableSize.width)
        let height = Float(drawableSize.height)
        let aspect = width / max(1.0, height)
        let scale = min(width, height) / 1080.0
        let samples = max(32, min(parameters.samplesPerAxis, 190))
        let octaves = max(1, min(parameters.octaveCount, 9))
        let cycleCount = max(1, min(5, Int((parameters.speed * 2.0).rounded())))
        let phase = Float(clock.phase(frameIndex: frameIndex)) * Float(cycleCount)
        let seedPhase = Float(Double(seed % 10_000) / 10_000.0) * .pi * 2.0
        let waveScale = Float(clamp(parameters.waveScale, 0.2, 3.5))
        let warpAmount = Float(clamp(parameters.warpAmount, 0.0, 1.6))
        let contrast = Float(clamp(parameters.contrast, 0.0, 1.0))
        let saturation = Float(clamp(parameters.saturation, 0.0, 1.0))
        let brightness = Float(clamp(parameters.brightness, 0.0, 1.4))
        let alpha = Float(clamp(parameters.pointAlpha, 0.0, 1.0))
        let pointSize = Float(parameters.pointSize) * max(1.0, scale)
        let hueBase = Float(parameters.hueBaseDegrees)
        let hueSpread = Float(parameters.hueSpreadDegrees)
        let flowAngle = Float(parameters.flowAngle / 180.0 * Double.pi)
        let alphaBoost = Float(1.0 - clamp(parameters.fadeAlpha, 0.02, 0.98))
        let step = 2.0 / Float(max(1, samples - 1))

        var vertices: [FieldLinesVertex] = []
        vertices.reserveCapacity(samples * samples)

        for yIndex in 0..<samples {
            let y = -1.0 + Float(yIndex) * step
            for xIndex in 0..<samples {
                let x = -1.0 + Float(xIndex) * step
                let point = SIMD2<Float>(x * aspect, y)
                let value = plasmaValue(
                    point: point * waveScale,
                    phase: phase,
                    seedPhase: seedPhase,
                    flowAngle: flowAngle,
                    octaves: octaves,
                    warpAmount: warpAmount
                )
                let shaped = mix(value, smoothstep(0.18, 0.92, value), contrast)
                let pulse = 0.82 + 0.18 * sin(phase + value * .pi * 2.0)
                let screen = SIMD2<Float>(
                    (x * 0.5 + 0.5) * width,
                    (y * 0.5 + 0.5) * height
                )
                let hue = hueBase + hueSpread * shaped + 24.0 * sin(phase + shaped * .pi)
                let color = hsvToRGB(hueDegrees: hue, saturation: saturation, value: brightness)
                vertices.append(FieldLinesVertex(
                    position: normalizedPosition(screen, width: width, height: height),
                    color: SIMD4<Float>(color.x, color.y, color.z, alpha * alphaBoost * pulse),
                    pointSize: pointSize * (0.82 + shaped * 0.54)
                ))
            }
        }

        return vertices
    }

    private func plasmaValue(
        point: SIMD2<Float>,
        phase: Float,
        seedPhase: Float,
        flowAngle: Float,
        octaves: Int,
        warpAmount: Float
    ) -> Float {
        var p = point
        let flow = SIMD2<Float>(cos(flowAngle), sin(flowAngle))
        p += flow * sin(phase + seedPhase) * warpAmount * 0.22
        var value: Float = 0
        var weight: Float = 0

        for octave in 0..<octaves {
            let fOctave = Float(octave + 1)
            let localPhase = phase + seedPhase * (0.19 + fOctave * 0.03) + fOctave * 0.11
            let direction = flowAngle + seedPhase * 0.21 + fOctave * 1.137
            let axis = p.x * cos(direction) + p.y * sin(direction)
            let cross = p.x * sin(direction * 0.77) - p.y * cos(direction * 0.91)
            let warp = SIMD2<Float>(
                sin(cross * .pi * (0.7 + fOctave * 0.17) + localPhase),
                cos(axis * .pi * (0.8 + fOctave * 0.19) - localPhase)
            ) * warpAmount * 0.16 / fOctave
            let q = p + warp
            let waveA = sin((q.x + q.y) * .pi * (0.9 + fOctave * 0.28) + localPhase)
            let waveB = cos(simd_length(q) * .pi * (1.2 + fOctave * 0.22) - localPhase)
            let waveC = sin((q.x - q.y) * .pi * (0.6 + fOctave * 0.33) - localPhase)
            let octaveWeight = 1.0 / fOctave
            value += (waveA * 0.42 + waveB * 0.36 + waveC * 0.22) * octaveWeight
            weight += octaveWeight
        }

        return fract(value / max(0.001, weight) * 0.5 + 0.5)
    }

    private func smoothstep(_ edge0: Float, _ edge1: Float, _ x: Float) -> Float {
        let t = min(max((x - edge0) / max(0.0001, edge1 - edge0), 0.0), 1.0)
        return t * t * (3.0 - 2.0 * t)
    }

    private func mix(_ a: Float, _ b: Float, _ t: Float) -> Float {
        a * (1.0 - t) + b * t
    }

    private func normalizedPosition(_ position: SIMD2<Float>, width: Float, height: Float) -> SIMD2<Float> {
        SIMD2<Float>(
            (position.x / width) * 2.0 - 1.0,
            1.0 - (position.y / height) * 2.0
        )
    }

    private func hsvToRGB(hueDegrees: Float, saturation: Float, value: Float) -> SIMD3<Float> {
        let h = (hueDegrees.truncatingRemainder(dividingBy: 360.0) + 360.0)
            .truncatingRemainder(dividingBy: 360.0) / 60.0
        let c = value * saturation
        let x = c * (1.0 - abs(h.truncatingRemainder(dividingBy: 2.0) - 1.0))

        let rgb: SIMD3<Float>
        switch h {
        case 0..<1:
            rgb = SIMD3<Float>(c, x, 0)
        case 1..<2:
            rgb = SIMD3<Float>(x, c, 0)
        case 2..<3:
            rgb = SIMD3<Float>(0, c, x)
        case 3..<4:
            rgb = SIMD3<Float>(0, x, c)
        case 4..<5:
            rgb = SIMD3<Float>(x, 0, c)
        default:
            rgb = SIMD3<Float>(c, 0, x)
        }

        let m = value - c
        return rgb + SIMD3<Float>(repeating: m)
    }

    private func fract(_ value: Float) -> Float {
        value - floor(value)
    }

    private func clamp(_ value: Double, _ lower: Double, _ upper: Double) -> Double {
        min(max(value, lower), upper)
    }
}

final class HarmonicTunnelRenderer {
    private let device: MTLDevice
    private let pointPipelineState: MTLRenderPipelineState

    init(device: MTLDevice, colorPixelFormat: MTLPixelFormat) throws {
        self.device = device

        let library = try device.makeDefaultLibrary(bundle: .main)
        guard let vertexFunction = library.makeFunction(name: "fieldLinesVertex"),
              let fragmentFunction = library.makeFunction(name: "fieldLinesFragment") else {
            throw RendererError.missingShaderFunction
        }

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.colorAttachments[0].pixelFormat = colorPixelFormat
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].rgbBlendOperation = .add
        descriptor.colorAttachments[0].alphaBlendOperation = .add
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .one
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .one
        pointPipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
    }

    func render(
        parameters: HarmonicTunnelParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        in view: MTKView,
        commandBuffer: MTLCommandBuffer,
        renderPassDescriptor: MTLRenderPassDescriptor
    ) {
        render(
            parameters: parameters,
            seed: seed,
            frameIndex: frameIndex,
            clock: clock,
            drawableSize: view.drawableSize,
            commandBuffer: commandBuffer,
            finalRenderPassDescriptor: renderPassDescriptor
        )
    }

    func render(
        parameters: HarmonicTunnelParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        drawableSize: CGSize,
        outputTexture: MTLTexture,
        commandBuffer: MTLCommandBuffer
    ) {
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = outputTexture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)

        render(
            parameters: parameters,
            seed: seed,
            frameIndex: frameIndex,
            clock: clock,
            drawableSize: drawableSize,
            commandBuffer: commandBuffer,
            finalRenderPassDescriptor: renderPassDescriptor
        )
    }

    private func render(
        parameters: HarmonicTunnelParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        drawableSize: CGSize,
        commandBuffer: MTLCommandBuffer,
        finalRenderPassDescriptor: MTLRenderPassDescriptor
    ) {
        guard drawableSize.width > 1, drawableSize.height > 1 else { return }
        let vertices = makeVertices(
            parameters: parameters,
            seed: seed,
            frameIndex: frameIndex,
            clock: clock,
            drawableSize: drawableSize
        )
        guard !vertices.isEmpty else { return }
        guard let vertexBuffer = device.makeBuffer(
            bytes: vertices,
            length: MemoryLayout<FieldLinesVertex>.stride * vertices.count,
            options: [.storageModeShared]
        ) else {
            return
        }
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: finalRenderPassDescriptor) else {
            return
        }

        encoder.setRenderPipelineState(pointPipelineState)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: vertices.count)
        encoder.endEncoding()
    }

    private func makeVertices(
        parameters: HarmonicTunnelParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        drawableSize: CGSize
    ) -> [FieldLinesVertex] {
        let width = Float(drawableSize.width)
        let height = Float(drawableSize.height)
        let scale = min(width, height) / 1080.0
        let rings = max(6, min(parameters.ringCount, 80))
        let points = max(36, min(parameters.pointsPerRing, 440))
        let cycleCount = max(1, min(5, Int((parameters.speed * 2.0).rounded())))
        let phase = Float(clock.phase(frameIndex: frameIndex)) * Float(cycleCount)
        let seedPhase = Float(Double(seed % 10_000) / 10_000.0) * .pi * 2.0
        let depth = Float(clamp(parameters.tunnelDepth, 0.0, 1.0))
        let waveAmplitude = Float(clamp(parameters.waveAmplitude, 0.0, 0.9))
        let twist = Float(clamp(parameters.twist, 0.0, 1.0))
        let spokeAmount = Float(clamp(parameters.spokeAmount, 0.0, 1.0))
        let saturation = Float(clamp(parameters.saturation, 0.0, 1.0))
        let brightness = Float(clamp(parameters.brightness, 0.0, 1.4))
        let alpha = Float(clamp(parameters.pointAlpha, 0.0, 1.0))
        let pointSize = Float(parameters.pointSize) * max(1.0, scale)
        let perspective = Float(clamp(parameters.perspective, 0.0, 1.0))
        let centerDrift = Float(clamp(parameters.centerDrift, 0.0, 0.75))
        let alphaBoost = Float(1.0 - clamp(parameters.fadeAlpha, 0.02, 0.98))
        let minSide = min(width, height)
        let maxRadius = minSide * 0.82
        let center = SIMD2<Float>(
            width * (0.5 + centerDrift * 0.18 * sin(phase + seedPhase)),
            height * (0.5 + centerDrift * 0.18 * cos(phase - seedPhase))
        )

        var vertices: [FieldLinesVertex] = []
        vertices.reserveCapacity(rings * points)

        for ringIndex in 0..<rings {
            let ringT = Float(ringIndex) / Float(max(1, rings - 1))
            let travel = fract(ringT + phase / (.pi * 2.0))
            let depthEase = pow(max(0.001, travel), 0.55 + perspective * 0.85)
            let radius = maxRadius * (0.12 + depthEase * (1.18 + depth * 0.46))
            let ringAlpha = alpha * alphaBoost * (0.26 + travel * 0.86)
            let ringPhase = phase + ringT * .pi * 2.0

            for pointIndex in 0..<points {
                let pointT = Float(pointIndex) / Float(points)
                let angle = pointT * .pi * 2.0 +
                    twist * (1.0 - travel) * .pi * 2.4 +
                    seedPhase * 0.17
                let wave = sin(angle * (3.0 + spokeAmount * 10.0) + ringPhase) *
                    cos(angle * 2.0 - ringPhase + seedPhase)
                let spoke = 0.5 + 0.5 * cos(angle * (6.0 + spokeAmount * 18.0) - phase)
                let rippleRadius = radius * (1.0 + waveAmplitude * 0.24 * wave + spokeAmount * 0.045 * spoke)
                let direction = SIMD2<Float>(cos(angle), sin(angle))
                let screen = center + SIMD2<Float>(
                    direction.x * rippleRadius,
                    direction.y * rippleRadius * 0.78
                )

                guard screen.x > -width * 0.12,
                      screen.x < width * 1.12,
                      screen.y > -height * 0.12,
                      screen.y < height * 1.12 else {
                    continue
                }

                let hue = Float(parameters.hueBaseDegrees) +
                    Float(parameters.hueSpreadDegrees) * travel +
                    20.0 * sin(angle + phase)
                let value = brightness * (0.54 + 0.30 * travel + 0.22 * spoke)
                let color = hsvToRGB(hueDegrees: hue, saturation: saturation, value: value)
                vertices.append(FieldLinesVertex(
                    position: normalizedPosition(screen, width: width, height: height),
                    color: SIMD4<Float>(color.x, color.y, color.z, ringAlpha),
                    pointSize: pointSize * (0.62 + travel * 0.72 + spoke * 0.28)
                ))
            }
        }

        return vertices
    }

    private func normalizedPosition(_ position: SIMD2<Float>, width: Float, height: Float) -> SIMD2<Float> {
        SIMD2<Float>(
            (position.x / width) * 2.0 - 1.0,
            1.0 - (position.y / height) * 2.0
        )
    }

    private func hsvToRGB(hueDegrees: Float, saturation: Float, value: Float) -> SIMD3<Float> {
        let h = (hueDegrees.truncatingRemainder(dividingBy: 360.0) + 360.0)
            .truncatingRemainder(dividingBy: 360.0) / 60.0
        let c = value * saturation
        let x = c * (1.0 - abs(h.truncatingRemainder(dividingBy: 2.0) - 1.0))

        let rgb: SIMD3<Float>
        switch h {
        case 0..<1:
            rgb = SIMD3<Float>(c, x, 0)
        case 1..<2:
            rgb = SIMD3<Float>(x, c, 0)
        case 2..<3:
            rgb = SIMD3<Float>(0, c, x)
        case 3..<4:
            rgb = SIMD3<Float>(0, x, c)
        case 4..<5:
            rgb = SIMD3<Float>(x, 0, c)
        default:
            rgb = SIMD3<Float>(c, 0, x)
        }

        let m = value - c
        return rgb + SIMD3<Float>(repeating: m)
    }

    private func fract(_ value: Float) -> Float {
        value - floor(value)
    }

    private func clamp(_ value: Double, _ lower: Double, _ upper: Double) -> Double {
        min(max(value, lower), upper)
    }
}

final class LissajousWeaveRenderer {
    private let device: MTLDevice
    private let pointPipelineState: MTLRenderPipelineState

    init(device: MTLDevice, colorPixelFormat: MTLPixelFormat) throws {
        self.device = device

        let library = try device.makeDefaultLibrary(bundle: .main)
        guard let vertexFunction = library.makeFunction(name: "fieldLinesVertex"),
              let fragmentFunction = library.makeFunction(name: "fieldLinesFragment") else {
            throw RendererError.missingShaderFunction
        }

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.colorAttachments[0].pixelFormat = colorPixelFormat
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].rgbBlendOperation = .add
        descriptor.colorAttachments[0].alphaBlendOperation = .add
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .one
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .one
        pointPipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
    }

    func render(
        parameters: LissajousWeaveParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        in view: MTKView,
        commandBuffer: MTLCommandBuffer,
        renderPassDescriptor: MTLRenderPassDescriptor
    ) {
        render(
            parameters: parameters,
            seed: seed,
            frameIndex: frameIndex,
            clock: clock,
            drawableSize: view.drawableSize,
            commandBuffer: commandBuffer,
            finalRenderPassDescriptor: renderPassDescriptor
        )
    }

    func render(
        parameters: LissajousWeaveParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        drawableSize: CGSize,
        outputTexture: MTLTexture,
        commandBuffer: MTLCommandBuffer
    ) {
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = outputTexture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)

        render(
            parameters: parameters,
            seed: seed,
            frameIndex: frameIndex,
            clock: clock,
            drawableSize: drawableSize,
            commandBuffer: commandBuffer,
            finalRenderPassDescriptor: renderPassDescriptor
        )
    }

    private func render(
        parameters: LissajousWeaveParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        drawableSize: CGSize,
        commandBuffer: MTLCommandBuffer,
        finalRenderPassDescriptor: MTLRenderPassDescriptor
    ) {
        guard drawableSize.width > 1, drawableSize.height > 1 else { return }
        let vertices = makeVertices(
            parameters: parameters,
            seed: seed,
            frameIndex: frameIndex,
            clock: clock,
            drawableSize: drawableSize
        )
        guard !vertices.isEmpty else { return }
        guard let vertexBuffer = device.makeBuffer(
            bytes: vertices,
            length: MemoryLayout<FieldLinesVertex>.stride * vertices.count,
            options: [.storageModeShared]
        ) else {
            return
        }
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: finalRenderPassDescriptor) else {
            return
        }

        encoder.setRenderPipelineState(pointPipelineState)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: vertices.count)
        encoder.endEncoding()
    }

    private func makeVertices(
        parameters: LissajousWeaveParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        drawableSize: CGSize
    ) -> [FieldLinesVertex] {
        let width = Float(drawableSize.width)
        let height = Float(drawableSize.height)
        let scale = min(width, height) / 1080.0
        let curves = max(1, min(parameters.curveCount, 26))
        let points = max(80, min(parameters.pointsPerCurve, 1400))
        let frequencyX = Float(max(1, min(parameters.frequencyX, 14)))
        let frequencyY = Float(max(1, min(parameters.frequencyY, 14)))
        let cycleCount = max(1, min(5, Int((parameters.speed * 2.0).rounded())))
        let phase = Float(clock.phase(frameIndex: frameIndex)) * Float(cycleCount)
        let seedPhase = Float(Double(seed % 10_000) / 10_000.0) * .pi * 2.0
        let phaseSpread = Float(clamp(parameters.phaseSpread, 0.0, 1.0))
        let weaveAmount = Float(clamp(parameters.weaveAmount, 0.0, 1.0))
        let modulation = Float(clamp(parameters.modulation, 0.0, 1.0))
        let saturation = Float(clamp(parameters.saturation, 0.0, 1.0))
        let brightness = Float(clamp(parameters.brightness, 0.0, 1.4))
        let alpha = Float(clamp(parameters.pointAlpha, 0.0, 1.0))
        let pointSize = Float(parameters.pointSize) * max(1.0, scale)
        let alphaBoost = Float(1.0 - clamp(parameters.fadeAlpha, 0.02, 0.98))
        let rotation = Float(parameters.rotation / 180.0 * Double.pi)
        let cosRotation = cos(rotation)
        let sinRotation = sin(rotation)
        let center = SIMD2<Float>(width * 0.5, height * 0.5)
        let radius = SIMD2<Float>(width * 0.43, height * 0.42)

        var vertices: [FieldLinesVertex] = []
        vertices.reserveCapacity(curves * points)

        for curveIndex in 0..<curves {
            let curveT = curves == 1 ? 0.0 : Float(curveIndex) / Float(curves - 1)
            let curvePhase = seedPhase * 0.19 +
                curveT * phaseSpread * .pi * 2.0 +
                phase + curveT * 0.09
            let curveAlpha = alpha * alphaBoost * (0.72 + 0.28 * sin(curvePhase + phase))

            for pointIndex in 0..<points {
                let pointT = Float(pointIndex) / Float(points)
                let theta = pointT * .pi * 2.0
                let braid = sin(theta * (frequencyX + frequencyY) + phase + curvePhase)
                let modulatedTheta = theta + braid * weaveAmount * 0.22
                var x = sin(frequencyX * modulatedTheta + curvePhase)
                var y = sin(frequencyY * modulatedTheta + phase + curvePhase * 1.37)
                x += weaveAmount * 0.22 * sin((frequencyY + 1.0) * theta - phase + seedPhase)
                y += weaveAmount * 0.22 * cos((frequencyX + 1.0) * theta + phase - seedPhase)
                let envelope = 0.78 + modulation * 0.20 * sin(theta * 2.0 + phase + curveT * .pi)
                let rotated = SIMD2<Float>(
                    x * cosRotation - y * sinRotation,
                    x * sinRotation + y * cosRotation
                ) * envelope
                let screen = center + SIMD2<Float>(
                    rotated.x * radius.x,
                    rotated.y * radius.y
                )

                let hue = Float(parameters.hueBaseDegrees) +
                    Float(parameters.hueSpreadDegrees) * pointT +
                    32.0 * curveT +
                    16.0 * sin(phase + braid)
                let value = brightness * (0.60 + 0.26 * abs(braid) + 0.18 * curveT)
                let color = hsvToRGB(hueDegrees: hue, saturation: saturation, value: value)
                vertices.append(FieldLinesVertex(
                    position: normalizedPosition(screen, width: width, height: height),
                    color: SIMD4<Float>(color.x, color.y, color.z, curveAlpha),
                    pointSize: pointSize * (0.72 + 0.45 * abs(braid))
                ))
            }
        }

        return vertices
    }

    private func normalizedPosition(_ position: SIMD2<Float>, width: Float, height: Float) -> SIMD2<Float> {
        SIMD2<Float>(
            (position.x / width) * 2.0 - 1.0,
            1.0 - (position.y / height) * 2.0
        )
    }

    private func hsvToRGB(hueDegrees: Float, saturation: Float, value: Float) -> SIMD3<Float> {
        let h = (hueDegrees.truncatingRemainder(dividingBy: 360.0) + 360.0)
            .truncatingRemainder(dividingBy: 360.0) / 60.0
        let c = value * saturation
        let x = c * (1.0 - abs(h.truncatingRemainder(dividingBy: 2.0) - 1.0))

        let rgb: SIMD3<Float>
        switch h {
        case 0..<1:
            rgb = SIMD3<Float>(c, x, 0)
        case 1..<2:
            rgb = SIMD3<Float>(x, c, 0)
        case 2..<3:
            rgb = SIMD3<Float>(0, c, x)
        case 3..<4:
            rgb = SIMD3<Float>(0, x, c)
        case 4..<5:
            rgb = SIMD3<Float>(x, 0, c)
        default:
            rgb = SIMD3<Float>(c, 0, x)
        }

        let m = value - c
        return rgb + SIMD3<Float>(repeating: m)
    }

    private func clamp(_ value: Double, _ lower: Double, _ upper: Double) -> Double {
        min(max(value, lower), upper)
    }
}

final class PhyllotaxisBloomRenderer {
    private let device: MTLDevice
    private let pointPipelineState: MTLRenderPipelineState

    init(device: MTLDevice, colorPixelFormat: MTLPixelFormat) throws {
        self.device = device

        let library = try device.makeDefaultLibrary(bundle: .main)
        guard let vertexFunction = library.makeFunction(name: "fieldLinesVertex"),
              let fragmentFunction = library.makeFunction(name: "fieldLinesFragment") else {
            throw RendererError.missingShaderFunction
        }

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.colorAttachments[0].pixelFormat = colorPixelFormat
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].rgbBlendOperation = .add
        descriptor.colorAttachments[0].alphaBlendOperation = .add
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .one
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .one
        pointPipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
    }

    func render(
        parameters: PhyllotaxisBloomParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        in view: MTKView,
        commandBuffer: MTLCommandBuffer,
        renderPassDescriptor: MTLRenderPassDescriptor
    ) {
        render(
            parameters: parameters,
            seed: seed,
            frameIndex: frameIndex,
            clock: clock,
            drawableSize: view.drawableSize,
            commandBuffer: commandBuffer,
            finalRenderPassDescriptor: renderPassDescriptor
        )
    }

    func render(
        parameters: PhyllotaxisBloomParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        drawableSize: CGSize,
        outputTexture: MTLTexture,
        commandBuffer: MTLCommandBuffer
    ) {
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = outputTexture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)

        render(
            parameters: parameters,
            seed: seed,
            frameIndex: frameIndex,
            clock: clock,
            drawableSize: drawableSize,
            commandBuffer: commandBuffer,
            finalRenderPassDescriptor: renderPassDescriptor
        )
    }

    private func render(
        parameters: PhyllotaxisBloomParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        drawableSize: CGSize,
        commandBuffer: MTLCommandBuffer,
        finalRenderPassDescriptor: MTLRenderPassDescriptor
    ) {
        guard drawableSize.width > 1, drawableSize.height > 1 else { return }
        let vertices = makeVertices(
            parameters: parameters,
            seed: seed,
            frameIndex: frameIndex,
            clock: clock,
            drawableSize: drawableSize
        )
        guard !vertices.isEmpty else { return }
        guard let vertexBuffer = device.makeBuffer(
            bytes: vertices,
            length: MemoryLayout<FieldLinesVertex>.stride * vertices.count,
            options: [.storageModeShared]
        ) else {
            return
        }
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: finalRenderPassDescriptor) else {
            return
        }

        encoder.setRenderPipelineState(pointPipelineState)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: vertices.count)
        encoder.endEncoding()
    }

    private func makeVertices(
        parameters: PhyllotaxisBloomParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        drawableSize: CGSize
    ) -> [FieldLinesVertex] {
        let width = Float(drawableSize.width)
        let height = Float(drawableSize.height)
        let scale = min(width, height) / 1080.0
        let pointCount = max(200, min(parameters.pointCount, 14_000))
        let armCount = Float(max(1, min(parameters.armCount, 16)))
        let cycleCount = max(1, min(5, Int((parameters.speed * 2.0).rounded())))
        let phase = Float(clock.phase(frameIndex: frameIndex)) * Float(cycleCount)
        let seedPhase = Float(Double(seed % 10_000) / 10_000.0) * .pi * 2.0
        let spiralTightness = Float(clamp(parameters.spiralTightness, 0.0, 1.0))
        let bloomAmount = Float(clamp(parameters.bloomAmount, 0.0, 1.0))
        let pulseAmount = Float(clamp(parameters.pulseAmount, 0.0, 1.0))
        let saturation = Float(clamp(parameters.saturation, 0.0, 1.0))
        let brightness = Float(clamp(parameters.brightness, 0.0, 1.4))
        let alpha = Float(clamp(parameters.pointAlpha, 0.0, 1.0))
        let pointSize = Float(parameters.pointSize) * max(1.0, scale)
        let alphaBoost = Float(1.0 - clamp(parameters.fadeAlpha, 0.02, 0.98))
        let rotation = Float(parameters.rotation / 180.0 * Double.pi) + phase
        let centerDrift = Float(clamp(parameters.centerDrift, 0.0, 0.75))
        let center = SIMD2<Float>(
            width * (0.5 + centerDrift * 0.16 * sin(phase + seedPhase)),
            height * (0.5 + centerDrift * 0.16 * cos(phase - seedPhase))
        )
        let maxRadius = min(width, height) * (0.18 + spiralTightness * 0.34 + bloomAmount * 0.16)
        let goldenAngle = Float.pi * (3.0 - sqrt(5.0))

        var vertices: [FieldLinesVertex] = []
        vertices.reserveCapacity(pointCount)

        for index in 0..<pointCount {
            let i = Float(index)
            let t = i / Float(max(1, pointCount - 1))
            let armWave = sin(t * armCount * .pi * 2.0 + phase + seedPhase)
            let bloom = 1.0 + bloomAmount * 0.26 * sin(phase + t * .pi * 2.0)
            let radius = sqrt(t) * maxRadius * bloom * (0.82 + 0.18 * spiralTightness)
            let angle = i * goldenAngle + rotation + armWave * bloomAmount * 0.18
            let petal = 1.0 + 0.10 * bloomAmount * sin(angle * armCount - phase)
            let screen = center + SIMD2<Float>(
                cos(angle) * radius * petal,
                sin(angle) * radius * petal
            )
            let pulse = 0.72 + pulseAmount * 0.28 * (0.5 + 0.5 * sin(phase + t * .pi * 8.0))
            let hue = Float(parameters.hueBaseDegrees) +
                Float(parameters.hueSpreadDegrees) * t +
                24.0 * armWave
            let color = hsvToRGB(hueDegrees: hue, saturation: saturation, value: brightness * pulse)
            vertices.append(FieldLinesVertex(
                position: normalizedPosition(screen, width: width, height: height),
                color: SIMD4<Float>(color.x, color.y, color.z, alpha * alphaBoost * pulse),
                pointSize: pointSize * (0.62 + pulse * 0.54 + (1.0 - t) * 0.20)
            ))
        }

        return vertices
    }

    private func normalizedPosition(_ position: SIMD2<Float>, width: Float, height: Float) -> SIMD2<Float> {
        SIMD2<Float>(
            (position.x / width) * 2.0 - 1.0,
            1.0 - (position.y / height) * 2.0
        )
    }

    private func hsvToRGB(hueDegrees: Float, saturation: Float, value: Float) -> SIMD3<Float> {
        let h = (hueDegrees.truncatingRemainder(dividingBy: 360.0) + 360.0)
            .truncatingRemainder(dividingBy: 360.0) / 60.0
        let c = value * saturation
        let x = c * (1.0 - abs(h.truncatingRemainder(dividingBy: 2.0) - 1.0))

        let rgb: SIMD3<Float>
        switch h {
        case 0..<1:
            rgb = SIMD3<Float>(c, x, 0)
        case 1..<2:
            rgb = SIMD3<Float>(x, c, 0)
        case 2..<3:
            rgb = SIMD3<Float>(0, c, x)
        case 3..<4:
            rgb = SIMD3<Float>(0, x, c)
        case 4..<5:
            rgb = SIMD3<Float>(x, 0, c)
        default:
            rgb = SIMD3<Float>(c, 0, x)
        }

        let m = value - c
        return rgb + SIMD3<Float>(repeating: m)
    }

    private func clamp(_ value: Double, _ lower: Double, _ upper: Double) -> Double {
        min(max(value, lower), upper)
    }
}

final class HexPulseLatticeRenderer {
    private let device: MTLDevice
    private let pointPipelineState: MTLRenderPipelineState

    init(device: MTLDevice, colorPixelFormat: MTLPixelFormat) throws {
        self.device = device

        let library = try device.makeDefaultLibrary(bundle: .main)
        guard let vertexFunction = library.makeFunction(name: "fieldLinesVertex"),
              let fragmentFunction = library.makeFunction(name: "fieldLinesFragment") else {
            throw RendererError.missingShaderFunction
        }

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.colorAttachments[0].pixelFormat = colorPixelFormat
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].rgbBlendOperation = .add
        descriptor.colorAttachments[0].alphaBlendOperation = .add
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .one
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .one
        pointPipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
    }

    func render(
        parameters: HexPulseLatticeParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        in view: MTKView,
        commandBuffer: MTLCommandBuffer,
        renderPassDescriptor: MTLRenderPassDescriptor
    ) {
        render(
            parameters: parameters,
            seed: seed,
            frameIndex: frameIndex,
            clock: clock,
            drawableSize: view.drawableSize,
            commandBuffer: commandBuffer,
            finalRenderPassDescriptor: renderPassDescriptor
        )
    }

    func render(
        parameters: HexPulseLatticeParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        drawableSize: CGSize,
        outputTexture: MTLTexture,
        commandBuffer: MTLCommandBuffer
    ) {
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = outputTexture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)

        render(
            parameters: parameters,
            seed: seed,
            frameIndex: frameIndex,
            clock: clock,
            drawableSize: drawableSize,
            commandBuffer: commandBuffer,
            finalRenderPassDescriptor: renderPassDescriptor
        )
    }

    private func render(
        parameters: HexPulseLatticeParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        drawableSize: CGSize,
        commandBuffer: MTLCommandBuffer,
        finalRenderPassDescriptor: MTLRenderPassDescriptor
    ) {
        guard drawableSize.width > 1, drawableSize.height > 1 else { return }
        let vertices = makeVertices(
            parameters: parameters,
            seed: seed,
            frameIndex: frameIndex,
            clock: clock,
            drawableSize: drawableSize
        )
        guard !vertices.isEmpty else { return }
        guard let vertexBuffer = device.makeBuffer(
            bytes: vertices,
            length: MemoryLayout<FieldLinesVertex>.stride * vertices.count,
            options: [.storageModeShared]
        ) else {
            return
        }
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: finalRenderPassDescriptor) else {
            return
        }

        encoder.setRenderPipelineState(pointPipelineState)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: vertices.count)
        encoder.endEncoding()
    }

    private func makeVertices(
        parameters: HexPulseLatticeParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        drawableSize: CGSize
    ) -> [FieldLinesVertex] {
        let width = Float(drawableSize.width)
        let height = Float(drawableSize.height)
        let center = SIMD2<Float>(width * 0.5, height * 0.5)
        let scale = min(width, height) / 1080.0
        let columns = max(4, min(parameters.columnCount, 56))
        let rows = max(4, min(parameters.rowCount, 42))
        let pointsPerEdge = max(2, min(parameters.pointsPerEdge, 18))
        let sqrt3 = Float(sqrt(3.0))
        let horizontalSpan = Float(columns) * 1.5 + 0.5
        let verticalSpan = (Float(rows) + 0.75) * sqrt3
        let radius = min(width / horizontalSpan, height / verticalSpan) * 1.06
        let gridWidth = horizontalSpan * radius
        let gridHeight = verticalSpan * radius
        let origin = SIMD2<Float>((width - gridWidth) * 0.5, (height - gridHeight) * 0.5)
        let cycleCount = max(1, min(5, Int((parameters.speed * 2.0).rounded())))
        let phase = Float(clock.phase(frameIndex: frameIndex)) * Float(cycleCount)
        let seedPhase = Float(Double(seed % 10_000) / 10_000.0) * .pi * 2.0
        let pulseAmount = Float(clamp(parameters.pulseAmount, 0.0, 1.0))
        let waveScale = Float(clamp(parameters.waveScale, 0.0, 1.0))
        let lineThickness = Float(clamp(parameters.lineThickness, 0.0, 1.0))
        let saturation = Float(clamp(parameters.saturation, 0.0, 1.0))
        let brightness = Float(clamp(parameters.brightness, 0.0, 1.4))
        let alpha = Float(clamp(parameters.pointAlpha, 0.0, 1.0))
        let alphaBoost = Float(1.0 - clamp(parameters.fadeAlpha, 0.02, 0.98))
        let basePointSize = Float(parameters.pointSize) * max(1.0, scale)
        let geometryRotation = Float(parameters.rotation / 180.0 * Double.pi)

        var vertices: [FieldLinesVertex] = []
        vertices.reserveCapacity(columns * rows * 6 * pointsPerEdge)

        for column in 0..<columns {
            for row in 0..<rows {
                let centerX = origin.x + (Float(column) * 1.5 + 0.75) * radius
                let centerY = origin.y + (Float(row) + 0.5 + (column.isMultiple(of: 2) ? 0.0 : 0.5)) * sqrt3 * radius
                let cellCenter = SIMD2<Float>(centerX, centerY)
                let cellPhase = phase +
                    Float(column) * (0.34 + waveScale * 0.54) +
                    Float(row) * (0.29 + waveScale * 0.47) +
                    seedPhase * 0.31
                let cellPulse = 0.5 + 0.5 * sin(cellPhase)
                let edgeGlow = 0.58 + pulseAmount * 0.42 * cellPulse

                for edge in 0..<6 {
                    let startAngle = Float.pi / 6.0 + Float(edge) * Float.pi / 3.0
                    let endAngle = Float.pi / 6.0 + Float(edge + 1) * Float.pi / 3.0
                    let start = cellCenter + SIMD2<Float>(cos(startAngle) * radius, sin(startAngle) * radius)
                    let end = cellCenter + SIMD2<Float>(cos(endAngle) * radius, sin(endAngle) * radius)

                    for sample in 0..<pointsPerEdge {
                        let t = Float(sample) / Float(max(1, pointsPerEdge - 1))
                        let edgeWave = sin(cellPhase + t * .pi * 2.0 + Float(edge) * 0.71)
                        let localPulse = 0.68 + pulseAmount * 0.32 * (0.5 + 0.5 * edgeWave)
                        let screen = rotate(mix(start, end, t) - center, by: geometryRotation) + center
                        let hue = Float(parameters.hueBaseDegrees) +
                            Float(parameters.hueSpreadDegrees) * (0.5 + 0.5 * edgeWave) +
                            Float(edge) * 6.0
                        let color = hsvToRGB(hueDegrees: hue, saturation: saturation, value: brightness * localPulse)
                        vertices.append(FieldLinesVertex(
                            position: normalizedPosition(screen, width: width, height: height),
                            color: SIMD4<Float>(color.x, color.y, color.z, alpha * alphaBoost * edgeGlow),
                            pointSize: basePointSize * (0.72 + lineThickness * 0.68 + localPulse * 0.34)
                        ))
                    }
                }
            }
        }

        return vertices
    }

    private func mix(_ lhs: SIMD2<Float>, _ rhs: SIMD2<Float>, _ amount: Float) -> SIMD2<Float> {
        lhs + (rhs - lhs) * amount
    }

    private func rotate(_ point: SIMD2<Float>, by angle: Float) -> SIMD2<Float> {
        let c = cos(angle)
        let s = sin(angle)
        return SIMD2<Float>(
            point.x * c - point.y * s,
            point.x * s + point.y * c
        )
    }

    private func normalizedPosition(_ position: SIMD2<Float>, width: Float, height: Float) -> SIMD2<Float> {
        SIMD2<Float>(
            (position.x / width) * 2.0 - 1.0,
            1.0 - (position.y / height) * 2.0
        )
    }

    private func hsvToRGB(hueDegrees: Float, saturation: Float, value: Float) -> SIMD3<Float> {
        let h = (hueDegrees.truncatingRemainder(dividingBy: 360.0) + 360.0)
            .truncatingRemainder(dividingBy: 360.0) / 60.0
        let c = value * saturation
        let x = c * (1.0 - abs(h.truncatingRemainder(dividingBy: 2.0) - 1.0))

        let rgb: SIMD3<Float>
        switch h {
        case 0..<1:
            rgb = SIMD3<Float>(c, x, 0)
        case 1..<2:
            rgb = SIMD3<Float>(x, c, 0)
        case 2..<3:
            rgb = SIMD3<Float>(0, c, x)
        case 3..<4:
            rgb = SIMD3<Float>(0, x, c)
        case 4..<5:
            rgb = SIMD3<Float>(x, 0, c)
        default:
            rgb = SIMD3<Float>(c, 0, x)
        }

        let m = value - c
        return rgb + SIMD3<Float>(repeating: m)
    }

    private func clamp(_ value: Double, _ lower: Double, _ upper: Double) -> Double {
        min(max(value, lower), upper)
    }
}

final class SuperformulaMorphRenderer {
    private let device: MTLDevice
    private let pointPipelineState: MTLRenderPipelineState

    init(device: MTLDevice, colorPixelFormat: MTLPixelFormat) throws {
        self.device = device

        let library = try device.makeDefaultLibrary(bundle: .main)
        guard let vertexFunction = library.makeFunction(name: "fieldLinesVertex"),
              let fragmentFunction = library.makeFunction(name: "fieldLinesFragment") else {
            throw RendererError.missingShaderFunction
        }

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.colorAttachments[0].pixelFormat = colorPixelFormat
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].rgbBlendOperation = .add
        descriptor.colorAttachments[0].alphaBlendOperation = .add
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .one
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .one
        pointPipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
    }

    func render(
        parameters: SuperformulaMorphParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        in view: MTKView,
        commandBuffer: MTLCommandBuffer,
        renderPassDescriptor: MTLRenderPassDescriptor
    ) {
        render(
            parameters: parameters,
            seed: seed,
            frameIndex: frameIndex,
            clock: clock,
            drawableSize: view.drawableSize,
            commandBuffer: commandBuffer,
            finalRenderPassDescriptor: renderPassDescriptor
        )
    }

    func render(
        parameters: SuperformulaMorphParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        drawableSize: CGSize,
        outputTexture: MTLTexture,
        commandBuffer: MTLCommandBuffer
    ) {
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = outputTexture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)

        render(
            parameters: parameters,
            seed: seed,
            frameIndex: frameIndex,
            clock: clock,
            drawableSize: drawableSize,
            commandBuffer: commandBuffer,
            finalRenderPassDescriptor: renderPassDescriptor
        )
    }

    private func render(
        parameters: SuperformulaMorphParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        drawableSize: CGSize,
        commandBuffer: MTLCommandBuffer,
        finalRenderPassDescriptor: MTLRenderPassDescriptor
    ) {
        guard drawableSize.width > 1, drawableSize.height > 1 else { return }
        let vertices = makeVertices(
            parameters: parameters,
            seed: seed,
            frameIndex: frameIndex,
            clock: clock,
            drawableSize: drawableSize
        )
        guard !vertices.isEmpty else { return }
        guard let vertexBuffer = device.makeBuffer(
            bytes: vertices,
            length: MemoryLayout<FieldLinesVertex>.stride * vertices.count,
            options: [.storageModeShared]
        ) else {
            return
        }
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: finalRenderPassDescriptor) else {
            return
        }

        encoder.setRenderPipelineState(pointPipelineState)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: vertices.count)
        encoder.endEncoding()
    }

    private func makeVertices(
        parameters: SuperformulaMorphParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        drawableSize: CGSize
    ) -> [FieldLinesVertex] {
        let width = Float(drawableSize.width)
        let height = Float(drawableSize.height)
        let scale = min(width, height) / 1080.0
        let contourCount = max(2, min(parameters.contourCount, 28))
        let pointsPerContour = max(120, min(parameters.pointsPerContour, 1_600))
        let harmonicA = Float(max(2, min(parameters.harmonicA, 24)))
        let harmonicB = Float(max(2, min(parameters.harmonicB, 24)))
        let cycleCount = max(1, min(5, Int((parameters.speed * 2.0).rounded())))
        let phase = Float(clock.phase(frameIndex: frameIndex)) * Float(cycleCount)
        let seedPhase = Float(Double(seed % 10_000) / 10_000.0) * .pi * 2.0
        let morphAmount = Float(clamp(parameters.morphAmount, 0.0, 1.0))
        let radialScale = Float(clamp(parameters.radialScale, 0.20, 1.35))
        let contourSpread = Float(clamp(parameters.contourSpread, 0.0, 1.0))
        let saturation = Float(clamp(parameters.saturation, 0.0, 1.0))
        let brightness = Float(clamp(parameters.brightness, 0.0, 1.4))
        let alpha = Float(clamp(parameters.pointAlpha, 0.0, 1.0))
        let alphaBoost = Float(1.0 - clamp(parameters.fadeAlpha, 0.02, 0.98))
        let basePointSize = Float(parameters.pointSize) * max(1.0, scale)
        let rotation = Float(parameters.rotation / 180.0 * Double.pi) + phase
        let centerDrift = Float(clamp(parameters.centerDrift, 0.0, 0.75))
        let center = SIMD2<Float>(
            width * (0.5 + centerDrift * 0.14 * sin(phase + seedPhase)),
            height * (0.5 + centerDrift * 0.14 * cos(phase - seedPhase))
        )
        let maxRadius = min(width, height) * 0.48 * radialScale

        var vertices: [FieldLinesVertex] = []
        vertices.reserveCapacity(contourCount * pointsPerContour)

        for contour in 0..<contourCount {
            let layer = Float(contour) / Float(max(1, contourCount - 1))
            let layerScale = 0.18 + (0.82 * pow(layer, 0.72)) * (0.55 + contourSpread * 0.45)
            let layerPhase = phase + layer * .pi * 2.0 + seedPhase * 0.19
            let m = harmonicA + (harmonicB - harmonicA) * (0.5 + 0.5 * sin(layerPhase)) * morphAmount
            let n1 = 0.34 + 1.20 * (0.5 + 0.5 * sin(layerPhase * 0.73 + 0.8))
            let n2 = 0.42 + 1.36 * (0.5 + 0.5 * cos(layerPhase * 0.61 + 1.3))
            let n3 = 0.42 + 1.36 * (0.5 + 0.5 * sin(layerPhase * 0.53 - 0.4))
            let layerRotation = rotation + layer * 0.38 + 0.16 * morphAmount * sin(layerPhase)
            let hue = Float(parameters.hueBaseDegrees) +
                Float(parameters.hueSpreadDegrees) * layer +
                18.0 * sin(layerPhase)
            let color = hsvToRGB(hueDegrees: hue, saturation: saturation, value: brightness)
            let layerAlpha = alpha * alphaBoost * (0.55 + 0.45 * layer)
            let pointSize = basePointSize * (0.78 + layer * 0.46 + morphAmount * 0.20)

            for pointIndex in 0..<pointsPerContour {
                let t = Float(pointIndex) / Float(pointsPerContour)
                let theta = t * .pi * 2.0
                let radius = superformulaRadius(theta: theta, m: m, n1: n1, n2: n2, n3: n3)
                let ripple = 1.0 + morphAmount * 0.10 * sin(theta * harmonicB + phase + layer)
                let localRadius = maxRadius * layerScale * radius * ripple
                let local = SIMD2<Float>(
                    cos(theta) * localRadius,
                    sin(theta) * localRadius
                )
                let screen = rotate(local, by: layerRotation) + center
                let pulse = 0.74 + morphAmount * 0.26 * (0.5 + 0.5 * sin(phase + theta * harmonicA + layer))
                vertices.append(FieldLinesVertex(
                    position: normalizedPosition(screen, width: width, height: height),
                    color: SIMD4<Float>(color.x, color.y, color.z, layerAlpha * pulse),
                    pointSize: pointSize * pulse
                ))
            }
        }

        return vertices
    }

    private func superformulaRadius(theta: Float, m: Float, n1: Float, n2: Float, n3: Float) -> Float {
        let a: Float = 1.0
        let b: Float = 1.0
        let partA = pow(abs(cos(m * theta / 4.0) / a), n2)
        let partB = pow(abs(sin(m * theta / 4.0) / b), n3)
        let denominator = max(0.0001, partA + partB)
        return min(1.85, pow(denominator, -1.0 / max(0.08, n1)))
    }

    private func rotate(_ point: SIMD2<Float>, by angle: Float) -> SIMD2<Float> {
        let c = cos(angle)
        let s = sin(angle)
        return SIMD2<Float>(
            point.x * c - point.y * s,
            point.x * s + point.y * c
        )
    }

    private func normalizedPosition(_ position: SIMD2<Float>, width: Float, height: Float) -> SIMD2<Float> {
        SIMD2<Float>(
            (position.x / width) * 2.0 - 1.0,
            1.0 - (position.y / height) * 2.0
        )
    }

    private func hsvToRGB(hueDegrees: Float, saturation: Float, value: Float) -> SIMD3<Float> {
        let h = (hueDegrees.truncatingRemainder(dividingBy: 360.0) + 360.0)
            .truncatingRemainder(dividingBy: 360.0) / 60.0
        let c = value * saturation
        let x = c * (1.0 - abs(h.truncatingRemainder(dividingBy: 2.0) - 1.0))

        let rgb: SIMD3<Float>
        switch h {
        case 0..<1:
            rgb = SIMD3<Float>(c, x, 0)
        case 1..<2:
            rgb = SIMD3<Float>(x, c, 0)
        case 2..<3:
            rgb = SIMD3<Float>(0, c, x)
        case 3..<4:
            rgb = SIMD3<Float>(0, x, c)
        case 4..<5:
            rgb = SIMD3<Float>(x, 0, c)
        default:
            rgb = SIMD3<Float>(c, 0, x)
        }

        let m = value - c
        return rgb + SIMD3<Float>(repeating: m)
    }

    private func clamp(_ value: Double, _ lower: Double, _ upper: Double) -> Double {
        min(max(value, lower), upper)
    }
}

final class ProceduralPatternRenderer {
    private let device: MTLDevice
    private let pointPipelineState: MTLRenderPipelineState

    init(device: MTLDevice, colorPixelFormat: MTLPixelFormat) throws {
        self.device = device

        let library = try device.makeDefaultLibrary(bundle: .main)
        guard let vertexFunction = library.makeFunction(name: "fieldLinesVertex"),
              let fragmentFunction = library.makeFunction(name: "fieldLinesFragment") else {
            throw RendererError.missingShaderFunction
        }

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.colorAttachments[0].pixelFormat = colorPixelFormat
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].rgbBlendOperation = .add
        descriptor.colorAttachments[0].alphaBlendOperation = .add
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .one
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .one
        pointPipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
    }

    func render(
        family: RendererFamily,
        parameters: ProceduralPatternParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        in view: MTKView,
        commandBuffer: MTLCommandBuffer,
        renderPassDescriptor: MTLRenderPassDescriptor
    ) {
        render(
            family: family,
            parameters: parameters,
            seed: seed,
            frameIndex: frameIndex,
            clock: clock,
            drawableSize: view.drawableSize,
            commandBuffer: commandBuffer,
            finalRenderPassDescriptor: renderPassDescriptor
        )
    }

    func render(
        family: RendererFamily,
        parameters: ProceduralPatternParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        drawableSize: CGSize,
        outputTexture: MTLTexture,
        commandBuffer: MTLCommandBuffer
    ) {
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = outputTexture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)

        render(
            family: family,
            parameters: parameters,
            seed: seed,
            frameIndex: frameIndex,
            clock: clock,
            drawableSize: drawableSize,
            commandBuffer: commandBuffer,
            finalRenderPassDescriptor: renderPassDescriptor
        )
    }

    private func render(
        family: RendererFamily,
        parameters: ProceduralPatternParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        drawableSize: CGSize,
        commandBuffer: MTLCommandBuffer,
        finalRenderPassDescriptor: MTLRenderPassDescriptor
    ) {
        guard drawableSize.width > 1, drawableSize.height > 1 else { return }
        let vertices = makeVertices(
            family: family,
            parameters: parameters,
            seed: seed,
            frameIndex: frameIndex,
            clock: clock,
            drawableSize: drawableSize
        )
        guard !vertices.isEmpty else { return }
        guard let vertexBuffer = device.makeBuffer(
            bytes: vertices,
            length: MemoryLayout<FieldLinesVertex>.stride * vertices.count,
            options: [.storageModeShared]
        ) else {
            return
        }
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: finalRenderPassDescriptor) else {
            return
        }

        encoder.setRenderPipelineState(pointPipelineState)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: vertices.count)
        encoder.endEncoding()
    }

    private func makeVertices(
        family: RendererFamily,
        parameters: ProceduralPatternParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        drawableSize: CGSize
    ) -> [FieldLinesVertex] {
        let width = Float(drawableSize.width)
        let height = Float(drawableSize.height)
        let center = SIMD2<Float>(width * 0.5, height * 0.5)
        let scale = min(width, height) / 1080.0
        let elementCount = max(1, min(parameters.elementCount, 160))
        let samplesPerElement = max(2, min(parameters.samplesPerElement, 1600))
        let harmonicA = Float(max(1, min(parameters.harmonicA, 32)))
        let harmonicB = Float(max(1, min(parameters.harmonicB, 40)))
        let cycleCount = max(1, min(5, Int((parameters.speed * 2.0).rounded())))
        let phase = Float(clock.phase(frameIndex: frameIndex)) * Float(cycleCount)
        let seedPhase = Float(Double(seed % 10_000) / 10_000.0) * .pi * 2.0
        let maxRadius = min(width, height) * 0.64 * Float(clamp(parameters.scale, 0.1, 1.5))
        let modulation = Float(clamp(parameters.modulation, 0.0, 1.0))
        let depth = Float(clamp(parameters.depth, 0.0, 1.0))
        let feedback = Float(clamp(parameters.feedback, 0.0, 1.0))
        let alpha = Float(clamp(parameters.pointAlpha, 0.0, 1.0)) *
            Float(1.0 - clamp(parameters.fadeAlpha, 0.02, 0.98))
        let pointSize = Float(parameters.pointSize) * max(1.0, scale)
        let rotation = Float(parameters.rotation / 180.0 * Double.pi)
        let saturation = Float(clamp(parameters.saturation, 0.0, 1.0))
        let brightness = Float(clamp(parameters.brightness, 0.0, 1.4))

        var vertices: [FieldLinesVertex] = []
        vertices.reserveCapacity(elementCount * samplesPerElement)

        func appendVertex(_ screen: SIMD2<Float>, layer: Float, pulse: Float, sizeScale: Float = 1.0) {
            let hue = Float(parameters.hueBaseDegrees) +
                Float(parameters.hueSpreadDegrees) * layer +
                18.0 * sin(phase + layer * .pi * 2.0)
            let color = hsvToRGB(hueDegrees: hue, saturation: saturation, value: brightness * pulse)
            vertices.append(FieldLinesVertex(
                position: normalizedPosition(screen, width: width, height: height),
                color: SIMD4<Float>(color.x, color.y, color.z, alpha * (0.55 + 0.45 * pulse)),
                pointSize: pointSize * sizeScale * (0.72 + pulse * 0.38)
            ))
        }

        switch family {
        case .closedFlowParticles:
            makeClosedFlowVertices(
                append: appendVertex,
                elementCount: elementCount,
                samplesPerElement: samplesPerElement,
                center: center,
                maxRadius: maxRadius,
                phase: phase,
                seedPhase: seedPhase,
                harmonicA: harmonicA,
                harmonicB: harmonicB,
                modulation: modulation,
                rotation: rotation
            )
        case .sdfTunnel:
            makeSDFTunnelVertices(
                append: appendVertex,
                elementCount: elementCount,
                samplesPerElement: samplesPerElement,
                center: center,
                maxRadius: maxRadius,
                phase: phase,
                seedPhase: seedPhase,
                harmonicA: harmonicA,
                harmonicB: harmonicB,
                modulation: modulation,
                depth: depth,
                rotation: rotation
            )
        case .feedbackSynth:
            makeFeedbackSynthVertices(
                append: appendVertex,
                elementCount: elementCount,
                samplesPerElement: samplesPerElement,
                center: center,
                maxRadius: maxRadius,
                phase: phase,
                harmonicA: harmonicA,
                harmonicB: harmonicB,
                modulation: modulation,
                feedback: feedback,
                rotation: rotation
            )
        case .guillocheRose:
            makeGuillocheVertices(
                append: appendVertex,
                elementCount: elementCount,
                samplesPerElement: samplesPerElement,
                center: center,
                maxRadius: maxRadius,
                phase: phase,
                harmonicA: harmonicA,
                harmonicB: harmonicB,
                modulation: modulation,
                rotation: rotation
            )
        case .instancedGeometry:
            makeInstancedGeometryVertices(
                append: appendVertex,
                elementCount: elementCount,
                samplesPerElement: samplesPerElement,
                center: center,
                maxRadius: maxRadius,
                phase: phase,
                seedPhase: seedPhase,
                harmonicA: harmonicA,
                harmonicB: harmonicB,
                modulation: modulation,
                depth: depth,
                rotation: rotation
            )
        case .metaballField:
            makeMetaballVertices(
                append: appendVertex,
                elementCount: elementCount,
                samplesPerElement: samplesPerElement,
                center: center,
                maxRadius: maxRadius,
                phase: phase,
                seedPhase: seedPhase,
                harmonicA: harmonicA,
                harmonicB: harmonicB,
                modulation: modulation,
                rotation: rotation
            )
        case .penroseTiling:
            makePenroseVertices(
                append: appendVertex,
                elementCount: elementCount,
                samplesPerElement: samplesPerElement,
                center: center,
                maxRadius: maxRadius,
                phase: phase,
                seedPhase: seedPhase,
                harmonicA: harmonicA,
                modulation: modulation,
                rotation: rotation
            )
        case .waveTerrain:
            makeWaveTerrainVertices(
                append: appendVertex,
                elementCount: elementCount,
                samplesPerElement: samplesPerElement,
                center: center,
                maxRadius: maxRadius,
                phase: phase,
                harmonicA: harmonicA,
                harmonicB: harmonicB,
                modulation: modulation,
                depth: depth,
                rotation: rotation
            )
        default:
            break
        }

        return vertices
    }

    private func makeClosedFlowVertices(
        append: (SIMD2<Float>, Float, Float, Float) -> Void,
        elementCount: Int,
        samplesPerElement: Int,
        center: SIMD2<Float>,
        maxRadius: Float,
        phase: Float,
        seedPhase: Float,
        harmonicA: Float,
        harmonicB: Float,
        modulation: Float,
        rotation: Float
    ) {
        for element in 0..<elementCount {
            let layer = Float(element) / Float(max(1, elementCount - 1))
            let offset = layer * .pi * 2.0 + seedPhase
            let baseRadius = maxRadius * (0.12 + 0.86 * layer)
            for sample in 0..<samplesPerElement {
                let t = Float(sample) / Float(max(1, samplesPerElement - 1))
                let theta = t * .pi * 2.0
                let curl = modulation * 0.22 * sin(theta * harmonicA + phase + offset)
                let angle = theta + offset * 0.13 + curl + phase
                let radius = baseRadius * (0.78 + 0.22 * sin(theta * harmonicB - phase + offset))
                let drift = SIMD2<Float>(
                    cos(theta * 2.0 + phase + offset),
                    sin(theta * 3.0 - phase + offset)
                ) * maxRadius * modulation * 0.10
                let screen = rotate(SIMD2<Float>(cos(angle) * radius, sin(angle) * radius) + drift, by: rotation) + center
                append(screen, layer, 0.65 + 0.35 * sin(theta + phase + offset) * 0.5 + 0.35, 1.0)
            }
        }
    }

    private func makeSDFTunnelVertices(
        append: (SIMD2<Float>, Float, Float, Float) -> Void,
        elementCount: Int,
        samplesPerElement: Int,
        center: SIMD2<Float>,
        maxRadius: Float,
        phase: Float,
        seedPhase: Float,
        harmonicA: Float,
        harmonicB: Float,
        modulation: Float,
        depth: Float,
        rotation: Float
    ) {
        for ring in 0..<elementCount {
            let layer = Float(ring) / Float(max(1, elementCount - 1))
            let zPulse = 0.5 + 0.5 * sin(phase + layer * .pi * 2.0)
            let perspective = 0.16 + pow(layer, 1.25) * (0.70 + depth * 0.35)
            let ringRadius = maxRadius * perspective * (0.82 + 0.18 * zPulse)
            let ringRotation = rotation + phase + layer * 0.7 + seedPhase * 0.03
            for sample in 0..<samplesPerElement {
                let t = Float(sample) / Float(samplesPerElement)
                let theta = t * .pi * 2.0
                let facets = 1.0 + modulation * 0.12 * sin(theta * harmonicA + phase + layer * harmonicB)
                let local = SIMD2<Float>(
                    cos(theta) * ringRadius * facets,
                    sin(theta) * ringRadius * facets * (0.74 + depth * 0.26)
                )
                append(rotate(local, by: ringRotation) + center, layer, 0.62 + 0.38 * zPulse, 0.8 + layer * 0.8)
            }
        }
    }

    private func makeFeedbackSynthVertices(
        append: (SIMD2<Float>, Float, Float, Float) -> Void,
        elementCount: Int,
        samplesPerElement: Int,
        center: SIMD2<Float>,
        maxRadius: Float,
        phase: Float,
        harmonicA: Float,
        harmonicB: Float,
        modulation: Float,
        feedback: Float,
        rotation: Float
    ) {
        for echo in 0..<elementCount {
            let layer = Float(echo) / Float(max(1, elementCount - 1))
            let echoScale = pow(1.0 - layer * 0.74, 1.0 + feedback)
            let echoRotation = rotation + layer * (.pi * 1.8 + feedback * .pi) + phase
            for sample in 0..<samplesPerElement {
                let t = Float(sample) / Float(samplesPerElement)
                let theta = t * .pi * 2.0
                let rose = 0.55 + 0.45 * sin(theta * harmonicA + phase)
                let fold = 1.0 + modulation * 0.28 * sin(theta * harmonicB - phase + layer * .pi)
                let radius = maxRadius * echoScale * rose * fold
                let local = SIMD2<Float>(cos(theta) * radius, sin(theta) * radius)
                append(rotate(local, by: echoRotation) + center, layer, 0.62 + 0.38 * rose, 1.0 + feedback * 0.6)
            }
        }
    }

    private func makeGuillocheVertices(
        append: (SIMD2<Float>, Float, Float, Float) -> Void,
        elementCount: Int,
        samplesPerElement: Int,
        center: SIMD2<Float>,
        maxRadius: Float,
        phase: Float,
        harmonicA: Float,
        harmonicB: Float,
        modulation: Float,
        rotation: Float
    ) {
        for curve in 0..<elementCount {
            let layer = Float(curve) / Float(max(1, elementCount - 1))
            let curvePhase = layer * .pi * 2.0
            for sample in 0..<samplesPerElement {
                let t = Float(sample) / Float(max(1, samplesPerElement - 1))
                let theta = t * .pi * 2.0
                let x = cos(theta * harmonicA + curvePhase + phase) * 0.55 +
                    cos(theta * harmonicB - phase) * modulation * 0.32
                let y = sin(theta * (harmonicA + 1.0) - curvePhase) * 0.55 +
                    sin(theta * (harmonicB - 1.0) + phase) * modulation * 0.32
                let local = SIMD2<Float>(x, y) * maxRadius * (0.68 + layer * 0.50)
                append(rotate(local, by: rotation + layer * 0.25) + center, layer, 0.78 + 0.22 * sin(theta + phase), 0.86)
            }
        }
    }

    private func makeInstancedGeometryVertices(
        append: (SIMD2<Float>, Float, Float, Float) -> Void,
        elementCount: Int,
        samplesPerElement: Int,
        center: SIMD2<Float>,
        maxRadius: Float,
        phase: Float,
        seedPhase: Float,
        harmonicA: Float,
        harmonicB: Float,
        modulation: Float,
        depth: Float,
        rotation: Float
    ) {
        let polygonSides = max(3, min(9, samplesPerElement))
        for instance in 0..<elementCount {
            let layer = Float(instance) / Float(max(1, elementCount - 1))
            let orbit = sqrt(layer) * maxRadius
            let angle = layer * .pi * 2.0 * harmonicA + seedPhase
            let wobble = modulation * maxRadius * 0.12 * sin(phase + layer * harmonicB)
            let instanceCenter = rotate(SIMD2<Float>(
                cos(angle + phase) * (orbit + wobble),
                sin(angle - phase) * (orbit * (0.72 + depth * 0.28))
            ), by: rotation) + center
            let size = maxRadius * (0.028 + 0.058 * (1.0 - layer) + modulation * 0.022)
            for vertex in 0..<polygonSides {
                let t = Float(vertex) / Float(polygonSides)
                let theta = t * .pi * 2.0 + phase + layer * .pi
                let local = SIMD2<Float>(cos(theta) * size, sin(theta) * size)
                append(instanceCenter + local, layer, 0.72 + 0.28 * sin(phase + layer), 1.1)
            }
        }
    }

    private func makeMetaballVertices(
        append: (SIMD2<Float>, Float, Float, Float) -> Void,
        elementCount: Int,
        samplesPerElement: Int,
        center: SIMD2<Float>,
        maxRadius: Float,
        phase: Float,
        seedPhase: Float,
        harmonicA: Float,
        harmonicB: Float,
        modulation: Float,
        rotation: Float
    ) {
        for blob in 0..<elementCount {
            let layer = Float(blob) / Float(max(1, elementCount - 1))
            let orbitAngle = layer * .pi * 2.0 + seedPhase
            let blobCenter = rotate(SIMD2<Float>(
                cos(orbitAngle + phase) * maxRadius * 0.70,
                sin(orbitAngle * 2.0 - phase) * maxRadius * 0.52
            ), by: rotation) + center
            let baseRadius = maxRadius * (0.10 + 0.12 * (0.5 + 0.5 * sin(layer * harmonicA + phase)))
            for sample in 0..<samplesPerElement {
                let t = Float(sample) / Float(samplesPerElement)
                let theta = t * .pi * 2.0
                let merge = 1.0 + modulation * 0.34 * sin(theta * harmonicB + phase + layer * .pi)
                let local = SIMD2<Float>(cos(theta) * baseRadius * merge, sin(theta) * baseRadius * merge)
                append(blobCenter + local, layer, 0.66 + 0.34 * merge, 1.15)
            }
        }
    }

    private func makePenroseVertices(
        append: (SIMD2<Float>, Float, Float, Float) -> Void,
        elementCount: Int,
        samplesPerElement: Int,
        center: SIMD2<Float>,
        maxRadius: Float,
        phase: Float,
        seedPhase: Float,
        harmonicA: Float,
        modulation: Float,
        rotation: Float
    ) {
        let goldenAngle = Float.pi * (3.0 - sqrt(5.0))
        for index in 0..<elementCount {
            let layer = Float(index) / Float(max(1, elementCount - 1))
            let radius = sqrt(layer) * maxRadius
            let angle = Float(index) * goldenAngle + seedPhase
            let a = rotate(SIMD2<Float>(cos(angle) * radius, sin(angle) * radius), by: rotation) + center
            let edgeAngle = angle + Float(Int(harmonicA) % 5) * .pi / 5.0 + phase
            let edgeLength = maxRadius * (0.10 + 0.08 * sin(phase + layer * .pi * 2.0) * modulation + 0.08)
            let b = a + SIMD2<Float>(cos(edgeAngle) * edgeLength, sin(edgeAngle) * edgeLength)
            for sample in 0..<samplesPerElement {
                let t = Float(sample) / Float(max(1, samplesPerElement - 1))
                append(a + (b - a) * t, layer, 0.72 + 0.28 * sin(phase + layer * .pi), 0.92)
            }
        }
    }

    private func makeWaveTerrainVertices(
        append: (SIMD2<Float>, Float, Float, Float) -> Void,
        elementCount: Int,
        samplesPerElement: Int,
        center: SIMD2<Float>,
        maxRadius: Float,
        phase: Float,
        harmonicA: Float,
        harmonicB: Float,
        modulation: Float,
        depth: Float,
        rotation: Float
    ) {
        for row in 0..<elementCount {
            let layer = Float(row) / Float(max(1, elementCount - 1))
            let yBase = (layer - 0.5) * maxRadius * 2.08
            for sample in 0..<samplesPerElement {
                let t = Float(sample) / Float(max(1, samplesPerElement - 1))
                let x = (t - 0.5) * maxRadius * 3.10
                let waveA = sin(t * .pi * 2.0 * harmonicA + phase + layer * .pi)
                let waveB = sin(t * .pi * 2.0 * harmonicB - phase + layer * .pi * 2.0)
                let y = yBase + (waveA * 0.55 + waveB * 0.45) * maxRadius * modulation * 0.16
                let perspective = 0.90 + depth * 0.16 * layer
                let local = SIMD2<Float>(x * perspective, y * perspective)
                append(rotate(local, by: rotation) + center, layer, 0.66 + 0.34 * abs(waveA), 0.9 + depth * 0.5)
            }
        }
    }

    private func rotate(_ point: SIMD2<Float>, by angle: Float) -> SIMD2<Float> {
        let c = cos(angle)
        let s = sin(angle)
        return SIMD2<Float>(
            point.x * c - point.y * s,
            point.x * s + point.y * c
        )
    }

    private func normalizedPosition(_ position: SIMD2<Float>, width: Float, height: Float) -> SIMD2<Float> {
        SIMD2<Float>(
            (position.x / width) * 2.0 - 1.0,
            1.0 - (position.y / height) * 2.0
        )
    }

    private func hsvToRGB(hueDegrees: Float, saturation: Float, value: Float) -> SIMD3<Float> {
        let h = (hueDegrees.truncatingRemainder(dividingBy: 360.0) + 360.0)
            .truncatingRemainder(dividingBy: 360.0) / 60.0
        let c = value * saturation
        let x = c * (1.0 - abs(h.truncatingRemainder(dividingBy: 2.0) - 1.0))

        let rgb: SIMD3<Float>
        switch h {
        case 0..<1:
            rgb = SIMD3<Float>(c, x, 0)
        case 1..<2:
            rgb = SIMD3<Float>(x, c, 0)
        case 2..<3:
            rgb = SIMD3<Float>(0, c, x)
        case 3..<4:
            rgb = SIMD3<Float>(0, x, c)
        case 4..<5:
            rgb = SIMD3<Float>(x, 0, c)
        default:
            rgb = SIMD3<Float>(c, 0, x)
        }

        let m = value - c
        return rgb + SIMD3<Float>(repeating: m)
    }

    private func clamp(_ value: Double, _ lower: Double, _ upper: Double) -> Double {
        min(max(value, lower), upper)
    }

    private func fract(_ value: Float) -> Float {
        value - floor(value)
    }
}

enum RendererError: Error {
    case missingShaderFunction
    case samplerCreationFailed
}
