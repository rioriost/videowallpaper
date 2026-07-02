//
//  GenerativeVideoExporter.swift
//  RioVideoWallpaper
//

import AVFoundation
import CoreVideo
import Foundation
import Metal

enum GenerativeVideoExporter {
    static func export(
        project: WallpaperProject,
        to outputURL: URL,
        progress: @escaping (Double) -> Void
    ) async throws -> URL {
        let exportTask = Task.detached(priority: .userInitiated) {
            try exportSynchronously(project: project, to: outputURL, progress: progress)
        }

        let exportedURL = try await withTaskCancellationHandler {
            try await exportTask.value
        } onCancel: {
            exportTask.cancel()
        }

        _ = try await ExportedVideoValidator.validate(
            url: exportedURL,
            expected: project.exportSettings.normalizedForExport()
        )
        return exportedURL
    }

    private static func exportSynchronously(
        project: WallpaperProject,
        to outputURL: URL,
        progress: (Double) -> Void
    ) throws -> URL {
        try Task.checkCancellation()

        let settings = project.exportSettings.normalizedForExport()
        let clock = RenderClock(fps: settings.fps, loopSeconds: settings.loopSeconds)

        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }

        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue() else {
            throw ExportError.metalUnavailable
        }

        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings.videoOutputSettings)
        input.expectsMediaDataInRealTime = false

        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: settings.pixelBufferAttributes
        )

        guard writer.canAdd(input) else {
            throw ExportError.writerInputRejected
        }
        writer.add(input)

        guard writer.startWriting() else {
            throw ExportError.writerFailed(writer.error)
        }
        writer.startSession(atSourceTime: .zero)

        guard let pixelBufferPool = adaptor.pixelBufferPool else {
            throw ExportError.pixelBufferPoolUnavailable
        }

        var textureCache: CVMetalTextureCache?
        let cacheStatus = CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &textureCache)
        guard cacheStatus == kCVReturnSuccess, let textureCache else {
            throw ExportError.textureCacheCreationFailed(cacheStatus)
        }

        let renderer = try GenerativeFrameRenderer(device: device, colorPixelFormat: .bgra8Unorm)
        renderer.resetAccumulation()

        let drawableSize = CGSize(width: settings.width, height: settings.height)
        let warmupFrames = Array(clock.warmupFrameIndices(warmupLoops: settings.warmupLoops))
        let exportFrames = Array(clock.exportFrameIndices())
        let totalWork = max(1, warmupFrames.count + exportFrames.count)
        var completedWork = 0

        do {
            for frameIndex in warmupFrames {
                try Task.checkCancellation()
                _ = try autoreleasepool {
                    try renderFrame(
                        parameters: project.renderParameters,
                        seed: project.seed,
                        frameIndex: frameIndex,
                        clock: clock,
                        drawableSize: drawableSize,
                        pixelBufferPool: pixelBufferPool,
                        textureCache: textureCache,
                        renderer: renderer,
                        commandQueue: commandQueue
                    )
                }
                completedWork += 1
                progress(Double(completedWork) / Double(totalWork))
            }

            for (outputFrameIndex, frameIndex) in exportFrames.enumerated() {
                try Task.checkCancellation()
                while !input.isReadyForMoreMediaData {
                    try Task.checkCancellation()
                    Thread.sleep(forTimeInterval: 0.01)
                }

                let pixelBuffer = try autoreleasepool {
                    try renderFrame(
                        parameters: project.renderParameters,
                        seed: project.seed,
                        frameIndex: frameIndex,
                        clock: clock,
                        drawableSize: drawableSize,
                        pixelBufferPool: pixelBufferPool,
                        textureCache: textureCache,
                        renderer: renderer,
                        commandQueue: commandQueue
                    )
                }

                let presentationTime = CMTime(value: CMTimeValue(outputFrameIndex), timescale: CMTimeScale(settings.fps))
                guard adaptor.append(pixelBuffer, withPresentationTime: presentationTime) else {
                    throw ExportError.appendFailed(writer.error)
                }

                completedWork += 1
                progress(Double(completedWork) / Double(totalWork))
            }
        } catch is CancellationError {
            writer.cancelWriting()
            try? FileManager.default.removeItem(at: outputURL)
            throw CancellationError()
        } catch {
            writer.cancelWriting()
            throw error
        }

        input.markAsFinished()

        let semaphore = DispatchSemaphore(value: 0)
        writer.finishWriting {
            semaphore.signal()
        }
        semaphore.wait()

        if writer.status == .failed || writer.status == .cancelled {
            throw ExportError.writerFailed(writer.error)
        }

        progress(1.0)
        return outputURL
    }

    @discardableResult
    private static func renderFrame(
        parameters: RenderParameters,
        seed: UInt64,
        frameIndex: Int,
        clock: RenderClock,
        drawableSize: CGSize,
        pixelBufferPool: CVPixelBufferPool,
        textureCache: CVMetalTextureCache,
        renderer: GenerativeFrameRenderer,
        commandQueue: MTLCommandQueue
    ) throws -> CVPixelBuffer {
        try Task.checkCancellation()

        var maybePixelBuffer: CVPixelBuffer?
        let bufferStatus = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool, &maybePixelBuffer)
        guard bufferStatus == kCVReturnSuccess, let pixelBuffer = maybePixelBuffer else {
            throw ExportError.pixelBufferCreationFailed(bufferStatus)
        }

        var maybeTexture: CVMetalTexture?
        let textureStatus = CVMetalTextureCacheCreateTextureFromImage(
            kCFAllocatorDefault,
            textureCache,
            pixelBuffer,
            nil,
            .bgra8Unorm,
            Int(drawableSize.width),
            Int(drawableSize.height),
            0,
            &maybeTexture
        )
        guard textureStatus == kCVReturnSuccess,
              let cvTexture = maybeTexture,
              let texture = CVMetalTextureGetTexture(cvTexture) else {
            throw ExportError.pixelBufferTextureCreationFailed(textureStatus)
        }

        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            throw ExportError.commandBufferCreationFailed
        }

        renderer.render(
            parameters: parameters,
            seed: seed,
            frameIndex: frameIndex,
            clock: clock,
            drawableSize: drawableSize,
            outputTexture: texture,
            commandBuffer: commandBuffer
        )

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        if let error = commandBuffer.error {
            throw ExportError.gpuFailed(error)
        }

        return pixelBuffer
    }
}

private extension ExportSettings {
    var videoOutputSettings: [String: Any] {
        [
            AVVideoCodecKey: codec.avVideoCodecType,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: averageBitRate,
                AVVideoExpectedSourceFrameRateKey: fps
            ]
        ]
    }

    var pixelBufferAttributes: [String: Any] {
        [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height,
            kCVPixelBufferMetalCompatibilityKey as String: true,
            kCVPixelBufferIOSurfacePropertiesKey as String: [:]
        ]
    }

    private var averageBitRate: Int {
        let pixels = max(1, width * height)
        let bitsPerPixel: Double
        switch quality {
        case .draft:
            bitsPerPixel = 0.08
        case .high:
            bitsPerPixel = 0.16
        case .archive:
            bitsPerPixel = 0.28
        }
        return max(2_000_000, Int(Double(pixels * fps) * bitsPerPixel))
    }
}

private extension VideoCodec {
    var avVideoCodecType: AVVideoCodecType {
        switch self {
        case .h264:
            return .h264
        case .hevc:
            return .hevc
        }
    }
}

enum ExportError: LocalizedError {
    case unsupportedRenderer
    case metalUnavailable
    case writerInputRejected
    case writerFailed(Error?)
    case pixelBufferPoolUnavailable
    case textureCacheCreationFailed(CVReturn)
    case pixelBufferCreationFailed(CVReturn)
    case pixelBufferTextureCreationFailed(CVReturn)
    case commandBufferCreationFailed
    case gpuFailed(Error)
    case appendFailed(Error?)

    var errorDescription: String? {
        switch self {
        case .unsupportedRenderer:
            return "This renderer is not supported for export yet."
        case .metalUnavailable:
            return "Metal is not available on this Mac."
        case .writerInputRejected:
            return "The video writer rejected the requested output settings."
        case .writerFailed(let error):
            return error?.localizedDescription ?? "The video writer failed."
        case .pixelBufferPoolUnavailable:
            return "The video pixel buffer pool could not be created."
        case .textureCacheCreationFailed(let status):
            return "The Metal texture cache could not be created. CVReturn: \(status)"
        case .pixelBufferCreationFailed(let status):
            return "A video pixel buffer could not be created. CVReturn: \(status)"
        case .pixelBufferTextureCreationFailed(let status):
            return "A Metal texture could not be created for the video pixel buffer. CVReturn: \(status)"
        case .commandBufferCreationFailed:
            return "A Metal command buffer could not be created."
        case .gpuFailed(let error):
            return error.localizedDescription
        case .appendFailed(let error):
            return error?.localizedDescription ?? "A rendered frame could not be appended to the video."
        }
    }
}
