//
//  PlaybackSuspensionPolicy.swift
//  RioVideoWallpaper
//

import Foundation

struct PlaybackSuspensionPolicy {
    struct ScreenSnapshot: Equatable {
        var width: Double
        var height: Double
    }

    struct WindowSnapshot: Equatable {
        var ownerPID: pid_t
        var layer: Int
        var width: Double
        var height: Double
    }

    static func shouldSuspend(
        screensAreSleeping: Bool,
        frontmostPID: pid_t?,
        currentPID: pid_t,
        windows: [WindowSnapshot],
        screens: [ScreenSnapshot],
        sizeTolerance: Double = 2.0
    ) -> Bool {
        screensAreSleeping || frontmostAppCoversAnyScreen(
            frontmostPID: frontmostPID,
            currentPID: currentPID,
            windows: windows,
            screens: screens,
            sizeTolerance: sizeTolerance
        )
    }

    static func frontmostAppCoversAnyScreen(
        frontmostPID: pid_t?,
        currentPID: pid_t,
        windows: [WindowSnapshot],
        screens: [ScreenSnapshot],
        sizeTolerance: Double = 2.0
    ) -> Bool {
        guard let frontmostPID, frontmostPID != currentPID else {
            return false
        }

        return windows.contains { window in
            guard window.ownerPID == frontmostPID, window.layer == 0 else {
                return false
            }

            return screens.contains { screen in
                window.width >= screen.width - sizeTolerance &&
                    window.height >= screen.height - sizeTolerance
            }
        }
    }
}
