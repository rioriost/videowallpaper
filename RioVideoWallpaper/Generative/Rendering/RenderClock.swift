//
//  RenderClock.swift
//  RioVideoWallpaper
//

import Foundation

struct RenderClock: Equatable {
    let fps: Int
    let loopSeconds: Double

    init(fps: Int, loopSeconds: Double) {
        self.fps = max(1, fps)
        self.loopSeconds = max(0.1, loopSeconds)
    }

    var totalFrames: Int {
        max(1, Int((Double(fps) * loopSeconds).rounded()))
    }

    func normalizedLoopTime(frameIndex: Int) -> Double {
        let frame = wrappedFrameIndex(frameIndex)
        return Double(frame) / Double(totalFrames)
    }

    func phase(frameIndex: Int) -> Double {
        Double.pi * 2.0 * normalizedLoopTime(frameIndex: frameIndex)
    }

    func wrappedFrameIndex(_ frameIndex: Int) -> Int {
        let total = totalFrames
        let remainder = frameIndex % total
        return remainder >= 0 ? remainder : remainder + total
    }

    func exportFrameIndices() -> Range<Int> {
        0..<totalFrames
    }

    func warmupFrameIndices(warmupLoops: Int) -> Range<Int> {
        let warmupFrames = max(0, warmupLoops) * totalFrames
        return -warmupFrames..<0
    }
}
