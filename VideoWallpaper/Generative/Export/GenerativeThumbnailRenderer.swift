//
//  GenerativeThumbnailRenderer.swift
//  VideoWallpaper
//

import AppKit
import Foundation
import MetalKit

enum GenerativeThumbnailRenderer {
    enum ThumbnailError: Error {
        case metalUnavailable
        case commandQueueCreationFailed
        case commandBufferCreationFailed
        case textureCreationFailed
        case imageCreationFailed
    }

    static func renderPNG(
        project: WallpaperProject,
        size: CGSize = CGSize(width: 320, height: 200)
    ) throws -> Data {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw ThumbnailError.metalUnavailable
        }
        guard let commandQueue = device.makeCommandQueue() else {
            throw ThumbnailError.commandQueueCreationFailed
        }

        let pixelWidth = max(1, Int(size.width.rounded(.toNearestOrAwayFromZero)))
        let pixelHeight = max(1, Int(size.height.rounded(.toNearestOrAwayFromZero)))
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: pixelWidth,
            height: pixelHeight,
            mipmapped: false
        )
        descriptor.usage = [.renderTarget, .shaderRead]
        descriptor.storageMode = .shared

        guard let outputTexture = device.makeTexture(descriptor: descriptor) else {
            throw ThumbnailError.textureCreationFailed
        }

        let renderer = try GenerativeFrameRenderer(device: device, colorPixelFormat: .bgra8Unorm)
        let clock = RenderClock(fps: 30, loopSeconds: max(4.0, project.exportSettings.loopSeconds))

        let warmupStep = max(1, clock.totalFrames / 30)
        let warmupFrames = stride(from: -clock.totalFrames, to: 0, by: warmupStep)
        let frameIndices = Array(warmupFrames) + [max(0, clock.totalFrames / 3)]
        for frameIndex in frameIndices {
            guard let commandBuffer = commandQueue.makeCommandBuffer() else {
                throw ThumbnailError.commandBufferCreationFailed
            }
            renderer.render(
                parameters: project.renderParameters,
                seed: project.seed,
                frameIndex: frameIndex,
                clock: clock,
                drawableSize: size,
                outputTexture: outputTexture,
                commandBuffer: commandBuffer
            )
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
        }

        return try pngData(from: outputTexture, width: pixelWidth, height: pixelHeight)
    }

    static func renderPNG(project: WallpaperProject, to outputURL: URL) throws {
        let data = try renderPNG(project: project)
        try data.write(to: outputURL, options: .atomic)
    }

    private static func pngData(from texture: MTLTexture, width: Int, height: Int) throws -> Data {
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var bytes = [UInt8](repeating: 0, count: bytesPerRow * height)

        texture.getBytes(
            &bytes,
            bytesPerRow: bytesPerRow,
            from: MTLRegionMake2D(0, 0, width, height),
            mipmapLevel: 0
        )

        guard let provider = CGDataProvider(data: Data(bytes) as CFData),
              let cgImage = CGImage(
                width: width,
                height: height,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: bytesPerRow,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue),
                provider: provider,
                decode: nil,
                shouldInterpolate: true,
                intent: .defaultIntent
              ) else {
            throw ThumbnailError.imageCreationFailed
        }

        let bitmap = NSBitmapImageRep(cgImage: cgImage)
        guard let data = bitmap.representation(using: .png, properties: [:]) else {
            throw ThumbnailError.imageCreationFailed
        }
        return data
    }
}
