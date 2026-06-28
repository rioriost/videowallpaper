//
//  MetalPreviewView.swift
//  VideoWallpaper
//

import MetalKit
import QuartzCore
import SwiftUI

struct MetalPreviewView: NSViewRepresentable {
    var clearColor: MTLClearColor
    var parameters: RenderParameters
    var seed: UInt64
    var exportSettings: ExportSettings
    var isPlaying: Bool
    var requestedFrameIndex: Int?

    init(
        parameters: RenderParameters,
        seed: UInt64,
        exportSettings: ExportSettings,
        isPlaying: Bool = true,
        requestedFrameIndex: Int? = nil,
        clearColor: MTLClearColor = MTLClearColor(red: 0.03, green: 0.06, blue: 0.09, alpha: 1.0)
    ) {
        self.parameters = parameters
        self.seed = seed
        self.exportSettings = exportSettings
        self.isPlaying = isPlaying
        self.requestedFrameIndex = requestedFrameIndex
        self.clearColor = clearColor
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> MTKView {
        let view = MTKView()
        view.device = context.coordinator.device
        view.delegate = context.coordinator
        view.clearColor = clearColor
        view.colorPixelFormat = .bgra8Unorm
        view.framebufferOnly = true
        view.enableSetNeedsDisplay = false
        view.isPaused = false
        view.preferredFramesPerSecond = 60
        context.coordinator.update(
            parameters: parameters,
            seed: seed,
            exportSettings: exportSettings,
            isPlaying: isPlaying,
            requestedFrameIndex: requestedFrameIndex
        )
        context.coordinator.attach(to: view)
        return view
    }

    func updateNSView(_ view: MTKView, context: Context) {
        view.clearColor = clearColor
        context.coordinator.attach(to: view)
        context.coordinator.update(
            parameters: parameters,
            seed: seed,
            exportSettings: exportSettings,
            isPlaying: isPlaying,
            requestedFrameIndex: requestedFrameIndex
        )
    }
}

extension MetalPreviewView {
    final class Coordinator: NSObject, MTKViewDelegate {
        let device: MTLDevice?
        private let commandQueue: MTLCommandQueue?
        private var renderer: GenerativeFrameRenderer?
        private var parameters = RenderParameters.fieldLines(.feasibilityStudyDefault)
        private var seed: UInt64 = 1
        private var exportSettings = ExportSettings.standard
        private var isPlaying = true
        private var requestedFrameIndex: Int?
        private var lastAppliedRequestedFrameIndex: Int?
        private var frameIndex = 0
        private var playbackFrameOffset = 0
        private var playbackStartTime = CACurrentMediaTime()
        private weak var view: MTKView?
        private weak var observedWindow: NSWindow?
        private var windowObservers: [NSObjectProtocol] = []

        override init() {
            device = MTLCreateSystemDefaultDevice()
            commandQueue = device?.makeCommandQueue()
            super.init()
        }

        deinit {
            removeWindowObservers()
        }

        func attach(to view: MTKView) {
            self.view = view
            refreshWindowObserversIfNeeded()
            updatePausedState(redrawPausedFrame: false)
        }

        func update(
            parameters: RenderParameters,
            seed: UInt64,
            exportSettings: ExportSettings,
            isPlaying: Bool,
            requestedFrameIndex: Int?
        ) {
            let wasPlaying = self.isPlaying
            if seed != self.seed ||
                parameters.rendererFamily != self.parameters.rendererFamily ||
                exportSettings.fps != self.exportSettings.fps ||
                exportSettings.loopSeconds != self.exportSettings.loopSeconds {
                renderer?.resetAccumulation()
                frameIndex = 0
                playbackFrameOffset = 0
                playbackStartTime = CACurrentMediaTime()
                lastAppliedRequestedFrameIndex = nil
            }
            self.parameters = parameters
            self.seed = seed
            self.exportSettings = exportSettings
            self.isPlaying = isPlaying
            self.requestedFrameIndex = requestedFrameIndex
            if wasPlaying != isPlaying {
                let clock = RenderClock(fps: exportSettings.fps, loopSeconds: exportSettings.loopSeconds)
                if isPlaying {
                    playbackFrameOffset = frameIndex
                    playbackStartTime = CACurrentMediaTime()
                } else {
                    frameIndex = currentPlaybackFrame(clock: clock)
                    playbackFrameOffset = frameIndex
                }
            }
            updatePausedState(redrawPausedFrame: true)
        }

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

        func draw(in view: MTKView) {
            refreshWindowObserversIfNeeded()
            guard isVisibleForRendering(view) else {
                updatePausedState(redrawPausedFrame: false)
                return
            }

            guard let commandQueue,
                  let commandBuffer = commandQueue.makeCommandBuffer(),
                  let renderPassDescriptor = view.currentRenderPassDescriptor,
                  let drawable = view.currentDrawable else {
                return
            }

            if renderer == nil, let device = view.device {
                renderer = try? GenerativeFrameRenderer(device: device, colorPixelFormat: view.colorPixelFormat)
            }

            let clock = RenderClock(fps: exportSettings.fps, loopSeconds: exportSettings.loopSeconds)
            if requestedFrameIndex != lastAppliedRequestedFrameIndex, let requestedFrameIndex {
                frameIndex = clock.wrappedFrameIndex(requestedFrameIndex)
                playbackFrameOffset = frameIndex
                playbackStartTime = CACurrentMediaTime()
                renderer?.resetAccumulation()
                lastAppliedRequestedFrameIndex = requestedFrameIndex
            } else if isPlaying {
                frameIndex = currentPlaybackFrame(clock: clock)
            }

            renderer?.render(
                parameters: parameters,
                seed: seed,
                frameIndex: frameIndex,
                clock: clock,
                in: view,
                commandBuffer: commandBuffer,
                renderPassDescriptor: renderPassDescriptor
            )
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }

        private func currentPlaybackFrame(clock: RenderClock) -> Int {
            let elapsedSeconds = max(0, CACurrentMediaTime() - playbackStartTime)
            let elapsedFrames = Int((elapsedSeconds * Double(clock.fps)).rounded(.down))
            return clock.wrappedFrameIndex(playbackFrameOffset + elapsedFrames)
        }

        private func refreshWindowObserversIfNeeded() {
            guard let view, observedWindow !== view.window else {
                return
            }

            removeWindowObservers()
            observedWindow = view.window

            guard let window = view.window else {
                return
            }

            let notificationCenter = NotificationCenter.default
            let notifications: [Notification.Name] = [
                NSWindow.didChangeOcclusionStateNotification,
                NSWindow.didMiniaturizeNotification,
                NSWindow.didDeminiaturizeNotification
            ]

            windowObservers = notifications.map { name in
                notificationCenter.addObserver(forName: name, object: window, queue: .main) { [weak self] _ in
                    self?.updatePausedState(redrawPausedFrame: false)
                }
            }
        }

        private func removeWindowObservers() {
            let notificationCenter = NotificationCenter.default
            for observer in windowObservers {
                notificationCenter.removeObserver(observer)
            }
            windowObservers.removeAll()
        }

        private func updatePausedState(redrawPausedFrame: Bool) {
            guard let view else {
                return
            }

            let shouldRenderContinuously = isPlaying && isVisibleForRendering(view)
            view.isPaused = !shouldRenderContinuously
            view.preferredFramesPerSecond = ProcessInfo.processInfo.isLowPowerModeEnabled ? 30 : 60

            if redrawPausedFrame, view.isPaused, isVisibleForRendering(view) {
                view.draw()
            }
        }

        private func isVisibleForRendering(_ view: MTKView) -> Bool {
            guard let window = view.window else {
                return true
            }

            return window.isVisible &&
                !window.isMiniaturized &&
                window.occlusionState.contains(.visible)
        }
    }
}
