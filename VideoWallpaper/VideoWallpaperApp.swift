//
//  VideoWallpaperApp.swift
//  VideoWallpaper
//
//  Created by Rio Fujita on 2025/06/02.
//

import SwiftUI
import AppKit
import AVFoundation
import ServiceManagement
import UniformTypeIdentifiers
import os

@main
struct VideoWallpaperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.openSettings) private var openSettings
    
    var body: some Scene {
        MenuBarExtra("Video Wallpaper", systemImage: "film") {
            Button(AppLocalization.string("About VideoWallpaper...")) {
                NSApp.orderFrontStandardAboutPanel(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
            Divider()
            Button(AppLocalization.string("Settings...")) {
                openSettings()
                NSApp.activate(ignoringOtherApps: true)
            }
            .keyboardShortcut(",", modifiers: [.command])
            Divider()
            Button(AppLocalization.string("Quit VideoWallpaper")) {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: [.command])
        }
        .menuBarExtraStyle(.menu)

        Settings {
            VideoWallpaperSettingsView(
                appDelegate: appDelegate,
                generatedAssetLibrary: appDelegate.generatedWallpaperLibrary,
                setWallpaper: appDelegate.setGeneratedWallpaper,
                setWallpaperForDisplay: appDelegate.setGeneratedWallpaperForDisplay
            )
        }
        .defaultSize(width: 1240, height: 820)
        .windowResizability(.contentMinSize)
    }

// 既存の AppDelegate のロジックをそのまま流用
class AppDelegate: NSObject, NSApplicationDelegate {
    var videoWindowController: VideoWindowController?
    private let favoriteVideoKey = "FavoriteVideoURL"
    private let favoriteVideoBookmarkKey = "FavoriteVideoBookmark"
    private let generatedAssetLibrary = GeneratedAssetLibrary()
    var generatedWallpaperLibrary: GeneratedAssetLibrary {
        generatedAssetLibrary
    }
    private let displayAssignmentStore = DisplayWallpaperAssignmentStore()
    private var accessedVideoResources: [URL: Bool] = [:]
    private var screensAreSleeping = false
    private var playbackSuspensionWorkItem: DispatchWorkItem?
    private var diagnosticsTask: Task<Void, Never>?
    private var uiTestingWindow: NSWindow?
    private var generativeEditorWindow: NSWindow?
    private var isUITesting: Bool {
        ProcessInfo.processInfo.environment["VIDEO_WALLPAPER_UI_TESTING"] == "1"
    }
    private var shouldOpenGenerativeEditorOnLaunch: Bool {
        ProcessInfo.processInfo.environment["VIDEO_WALLPAPER_OPEN_GENERATIVE_EDITOR"] == "1"
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        if isUITesting {
            NSApp.setActivationPolicy(.regular)
            showUITestingWindow()
        }

        launchVideoWindow()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleScreenConfigurationChange(_:)),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        registerPlaybackSuspensionObservers()
        schedulePlaybackSuspensionUpdate()

        if shouldOpenGenerativeEditorOnLaunch {
            DispatchQueue.main.async { [weak self] in
                self?.openGenerativeEditor()
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        playbackSuspensionWorkItem?.cancel()
        diagnosticsTask?.cancel()
        stopAccessingSavedVideo()
        NotificationCenter.default.removeObserver(self)
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    private func launchVideoWindow() {
        // 動画URLの取得およびキャンセル時のハンドリング
        let assignments: StoredDisplayWallpaperAssignments
        let shouldShowDiagnosticsWarning: Bool
        if let savedAssignments = restoreSavedDisplayAssignments() {
            assignments = savedAssignments
            shouldShowDiagnosticsWarning = false
        } else if isUITesting {
            os_log("UIテスト中のため動画選択ダイアログをスキップします")
            return
        } else if let chosen = promptForVideo() {
            guard let chosenAssignments = saveVideoSelection(chosen) else { return }
            assignments = chosenAssignments
            shouldShowDiagnosticsWarning = true
        } else {
            os_log("動画ファイルの選択がキャンセルされました")
            showAlert(message: AppLocalization.string("No video file was selected. The app will quit."))
            NSApp.terminate(nil)
            return
        }
        // VideoWindowController の生成と動画再生開始
        videoWindowController = VideoWindowController(assignment: assignments.videoAssignment)
        videoWindowController?.showWindows()
        inspectVideoForEfficiency(assignments.defaultSelection.url, showsWarnings: shouldShowDiagnosticsWarning)
    }

    func openGenerativeEditor() {
        openGenerativeEditor(projectURL: nil)
    }

    func openGenerativeEditor(projectURL: URL?) {
        if projectURL != nil, let window = generativeEditorWindow {
            window.close()
            generativeEditorWindow = nil
        }

        if let window = generativeEditorWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let contentView = GenerativeEditorView(
            initialProjectURL: projectURL,
            setWallpaper: setGeneratedWallpaper,
            setWallpaperForDisplay: setGeneratedWallpaperForDisplay
        )
        let hostingController = NSHostingController(rootView: contentView)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1180, height: 760),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "RioVideoWallpaper"
        window.contentViewController = hostingController
        window.minSize = NSSize(width: 940, height: 620)
        window.center()
        window.isReleasedWhenClosed = false
        window.delegate = self
        generativeEditorWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        guard let projectURL = urls.first(where: { $0.pathExtension == WallpaperProjectFileStore.fileExtension }) else {
            return
        }

        openGenerativeEditor(projectURL: projectURL)
    }

    func changeVideo() {
        // 動画変更ダイアログで選択されたURLを取得
        guard let newURL = promptForVideo() else {
            os_log("動画変更ダイアログがキャンセルされました")
            return
        }
        // コントローラ未初期化時のハンドリング
        guard let controller = videoWindowController else {
            os_log("VideoWindowController が未初期化のため URL 更新できません")
            showAlert(message: AppLocalization.string("The video window has not been initialized yet."))
            return
        }
        guard let assignments = saveVideoSelection(newURL) else { return }
        controller.updateAssignment(assignments.videoAssignment)
        inspectVideoForEfficiency(newURL, showsWarnings: true)
    }

    func setGeneratedWallpaper(_ url: URL) {
        guard let assignments = saveVideoSelection(url) else { return }

        if let controller = videoWindowController {
            controller.updateAssignment(assignments.videoAssignment)
        } else {
            videoWindowController = VideoWindowController(assignment: assignments.videoAssignment)
            videoWindowController?.showWindows()
        }

        inspectVideoForEfficiency(url, showsWarnings: false)
    }

    func setGeneratedWallpaperForDisplay(_ url: URL) {
        guard let assignments = assignVideo(url, promptsForDisplay: true) else {
            return
        }
        if let controller = videoWindowController {
            controller.updateAssignment(assignments.videoAssignment)
        } else {
            videoWindowController = VideoWindowController(assignment: assignments.videoAssignment)
            videoWindowController?.showWindows()
        }
        inspectVideoForEfficiency(url, showsWarnings: false)
    }

    func changeVideoForDisplay() {
        let screens = NSScreen.screens
        guard !screens.isEmpty else {
            showAlert(message: AppLocalization.string("No available displays were found."))
            return
        }
        guard let selectedScreen = promptForDisplay(screens) else {
            return
        }
        guard let newURL = promptForVideo() else {
            os_log("ディスプレイ別の動画変更ダイアログがキャンセルされました")
            return
        }
        guard let assignments = assignVideo(newURL, to: selectedScreen) else { return }
        videoWindowController?.updateAssignment(assignments.videoAssignment)
        inspectVideoForEfficiency(newURL, showsWarnings: true)
    }

    func resetDisplayAssignments() {
        guard var assignments = currentDisplayAssignments() else {
            return
        }
        guard !assignments.perDisplaySelections.isEmpty else {
            showAlert(message: AppLocalization.string("There are no per-display assignments."))
            return
        }
        assignments.perDisplaySelections.removeAll()
        guard persistDisplayAssignments(assignments) else {
            return
        }
        videoWindowController?.updateAssignment(assignments.videoAssignment)
    }

    func settingsDisplayAssignments() -> StoredDisplayWallpaperAssignments? {
        currentDisplayAssignments()
    }

    func settingsUseSameVideoOnAllDisplays() {
        guard var assignments = currentDisplayAssignments() else {
            return
        }
        assignments.perDisplaySelections.removeAll()
        guard persistDisplayAssignments(assignments) else {
            return
        }
        videoWindowController?.updateAssignment(assignments.videoAssignment)
        inspectVideoForEfficiency(assignments.defaultSelection.url, showsWarnings: false)
    }

    func settingsUseSeparateVideosOnConnectedDisplays() {
        guard var assignments = currentDisplayAssignments() else {
            return
        }

        let screens = NSScreen.screens
        guard !screens.isEmpty else {
            showAlert(message: AppLocalization.string("No available displays were found."))
            return
        }

        let connectedDisplayIDs = Set(screens.map(DisplayIdentifier.id(for:)))
        assignments.perDisplaySelections = assignments.perDisplaySelections.filter { displayID, _ in
            connectedDisplayIDs.contains(displayID)
        }

        for displayID in connectedDisplayIDs where assignments.perDisplaySelections[displayID] == nil {
            assignments.perDisplaySelections[displayID] = assignments.defaultSelection
        }

        guard persistDisplayAssignments(assignments) else {
            return
        }

        videoWindowController?.updateAssignment(assignments.videoAssignment)
        inspectVideoForEfficiency(assignments.defaultSelection.url, showsWarnings: false)
    }

    func settingsChooseDefaultVideo() {
        guard let newURL = promptForVideo(),
              let assignments = saveVideoSelection(newURL) else {
            return
        }
        updatePlayback(with: assignments, inspectedURL: newURL, showsWarnings: true)
    }

    func settingsChooseVideo(forDisplayID displayID: String) {
        guard let newURL = promptForVideo(),
              let assignments = assignVideo(newURL, toDisplayID: displayID) else {
            return
        }
        updatePlayback(with: assignments, inspectedURL: newURL, showsWarnings: true)
    }

    private func promptForVideo() -> URL? {
        let panel = NSOpenPanel()
        panel.title = AppLocalization.string("Choose a video file")
        if #available(macOS 12.0, *) {
            panel.allowedContentTypes = [.movie]
        } else {
            panel.allowedFileTypes = ["mp4","mov","m4v","avi","mpg","mpeg"]
        }
        panel.allowsMultipleSelection = false
        return panel.runModal() == .OK ? panel.url : nil
    }

    private func promptForDisplay(_ screens: [NSScreen]) -> NSScreen? {
        let alert = NSAlert()
        alert.messageText = AppLocalization.string("Choose Display")
        alert.informativeText = AppLocalization.string("Choose the display where this video will be set.")
        alert.addButton(withTitle: AppLocalization.string("Choose"))
        alert.addButton(withTitle: AppLocalization.string("Cancel"))

        let popup = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 320, height: 28), pullsDown: false)
        for (index, screen) in screens.enumerated() {
            popup.addItem(withTitle: DisplayIdentifier.label(for: screen, index: index))
            popup.item(at: index)?.representedObject = DisplayIdentifier.id(for: screen)
        }
        alert.accessoryView = popup

        guard alert.runModal() == .alertFirstButtonReturn,
              let selectedID = popup.selectedItem?.representedObject as? String else {
            return nil
        }

        return screens.first { DisplayIdentifier.id(for: $0) == selectedID }
    }

    private func assignVideo(_ url: URL, promptsForDisplay: Bool) -> StoredDisplayWallpaperAssignments? {
        let screens = NSScreen.screens
        guard !screens.isEmpty else {
            showAlert(message: AppLocalization.string("No available displays were found."))
            return nil
        }
        guard let selectedScreen = promptsForDisplay ? promptForDisplay(screens) : screens.first else {
            return nil
        }
        return assignVideo(url, to: selectedScreen)
    }

    private func assignVideo(_ url: URL, to screen: NSScreen) -> StoredDisplayWallpaperAssignments? {
        assignVideo(url, toDisplayID: DisplayIdentifier.id(for: screen))
    }

    private func assignVideo(_ url: URL, toDisplayID displayID: String) -> StoredDisplayWallpaperAssignments? {
        guard var assignments = currentDisplayAssignments() else {
            showAlert(message: AppLocalization.string("Choose a video for all displays first."))
            return nil
        }
        guard let selection = makeStoredSelection(for: url) else {
            return nil
        }

        assignments.perDisplaySelections[displayID] = selection
        guard persistDisplayAssignments(assignments) else {
            return nil
        }
        return assignments
    }

    private func updatePlayback(
        with assignments: StoredDisplayWallpaperAssignments,
        inspectedURL: URL,
        showsWarnings: Bool
    ) {
        if let controller = videoWindowController {
            controller.updateAssignment(assignments.videoAssignment)
        } else {
            videoWindowController = VideoWindowController(assignment: assignments.videoAssignment)
            videoWindowController?.showWindows()
        }
        inspectVideoForEfficiency(inspectedURL, showsWarnings: showsWarnings)
    }

    private func currentDisplayAssignments() -> StoredDisplayWallpaperAssignments? {
        restoreSavedDisplayAssignments() ?? {
            guard let url = restoreSavedVideoURL(),
                  let selection = makeStoredSelection(for: url) else {
                return nil
            }
            let assignments = StoredDisplayWallpaperAssignments(
                defaultSelection: selection,
                perDisplaySelections: [:]
            )
            _ = persistDisplayAssignments(assignments)
            return assignments
        }()
    }

    private func restoreSavedDisplayAssignments() -> StoredDisplayWallpaperAssignments? {
        guard var assignments = displayAssignmentStore.load() else {
            return nil
        }
        var didResolveStaleBookmark = false

        guard let defaultSelection = resolvedSelection(assignments.defaultSelection, didResolveStaleBookmark: &didResolveStaleBookmark) else {
            return nil
        }
        assignments.defaultSelection = defaultSelection

        for (displayID, selection) in assignments.perDisplaySelections {
            guard let resolved = resolvedSelection(selection, didResolveStaleBookmark: &didResolveStaleBookmark) else {
                assignments.perDisplaySelections.removeValue(forKey: displayID)
                didResolveStaleBookmark = true
                continue
            }
            assignments.perDisplaySelections[displayID] = resolved
        }

        guard startAccessingVideoSelections(assignments.allSelections()) else {
            return nil
        }

        if didResolveStaleBookmark {
            _ = persistDisplayAssignments(assignments)
        }
        return assignments
    }

    private func restoreSavedVideoURL() -> URL? {
        if let savedURL = UserDefaults.standard.url(forKey: favoriteVideoKey),
           generatedAssetLibrary.containsGeneratedVideo(savedURL) {
            guard startAccessingVideo(savedURL) else {
                return nil
            }
            return savedURL
        }

        if let bookmarkData = UserDefaults.standard.data(forKey: favoriteVideoBookmarkKey) {
            do {
                var isStale = false
                let url = try URL(
                    resolvingBookmarkData: bookmarkData,
                    options: [.withSecurityScope],
                    relativeTo: nil,
                    bookmarkDataIsStale: &isStale
                )
                guard startAccessingVideo(url) else { return nil }
                if isStale {
                    persistBookmark(for: url)
                }
                return url
            } catch {
                os_log("保存済み動画ブックマークの復元に失敗: %{public}@", String(describing: error))
            }
        }

        guard let legacyURL = UserDefaults.standard.url(forKey: favoriteVideoKey),
              startAccessingVideo(legacyURL) else {
            return nil
        }
        persistBookmark(for: legacyURL)
        return legacyURL
    }

    private func saveVideoSelection(_ url: URL) -> StoredDisplayWallpaperAssignments? {
        guard let selection = makeStoredSelection(for: url) else {
            return nil
        }
        let assignments = StoredDisplayWallpaperAssignments(
            defaultSelection: selection,
            perDisplaySelections: [:]
        )
        guard persistDisplayAssignments(assignments) else {
            return nil
        }
        return assignments
    }

    private func makeStoredSelection(for url: URL) -> StoredWallpaperSelection? {
        let isGenerated = generatedAssetLibrary.containsGeneratedVideo(url)
        if isGenerated {
            return StoredWallpaperSelection(url: url, bookmarkData: nil, isGenerated: true)
        }

        do {
            let bookmarkData = try url.bookmarkData(
                options: [.withSecurityScope],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            return StoredWallpaperSelection(url: url, bookmarkData: bookmarkData, isGenerated: false)
        } catch {
            os_log("動画ブックマークの保存に失敗: %{public}@", String(describing: error))
            showAlert(message: AppLocalization.string("Failed to save the selected video file. Choose another video."))
            return nil
        }
    }

    private func persistDisplayAssignments(_ assignments: StoredDisplayWallpaperAssignments) -> Bool {
        guard startAccessingVideoSelections(assignments.allSelections()) else {
            showAlert(message: AppLocalization.string("The selected video file could not be accessed. Choose another video."))
            return false
        }

        do {
            try displayAssignmentStore.save(assignments)
        } catch {
            os_log("ディスプレイ別動画割り当ての保存に失敗: %{public}@", String(describing: error))
            showAlert(message: AppLocalization.string("Failed to save video assignments."))
            return false
        }

        let defaultURL = assignments.defaultSelection.url
        UserDefaults.standard.set(defaultURL, forKey: favoriteVideoKey)
        if assignments.defaultSelection.isGenerated {
            UserDefaults.standard.removeObject(forKey: favoriteVideoBookmarkKey)
        } else if let bookmarkData = assignments.defaultSelection.bookmarkData {
            UserDefaults.standard.set(bookmarkData, forKey: favoriteVideoBookmarkKey)
        } else {
            persistBookmark(for: defaultURL)
        }
        return true
    }

    private func resolvedSelection(
        _ selection: StoredWallpaperSelection,
        didResolveStaleBookmark: inout Bool
    ) -> StoredWallpaperSelection? {
        guard let bookmarkData = selection.bookmarkData, !selection.isGenerated else {
            return selection
        }

        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

            guard isStale else {
                return StoredWallpaperSelection(url: url, bookmarkData: bookmarkData, isGenerated: false)
            }

            didResolveStaleBookmark = true
            return makeStoredSelection(for: url)
        } catch {
            os_log("保存済み動画ブックマークの復元に失敗: %{public}@", String(describing: error))
            return nil
        }
    }

    private func persistBookmark(for url: URL) {
        do {
            let bookmarkData = try url.bookmarkData(
                options: [.withSecurityScope],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            UserDefaults.standard.set(bookmarkData, forKey: favoriteVideoBookmarkKey)
        } catch {
            os_log("動画ブックマークの保存に失敗: %{public}@", String(describing: error))
        }
    }

    private func startAccessingVideo(_ url: URL) -> Bool {
        if accessedVideoResources[url] != nil {
            return true
        }

        let started = url.startAccessingSecurityScopedResource()
        guard started || FileManager.default.isReadableFile(atPath: url.path) else {
            os_log("動画ファイルへのアクセス権がありません: %@", url.path)
            return false
        }

        accessedVideoResources[url] = started
        return true
    }

    private func startAccessingVideoSelections(_ selections: [StoredWallpaperSelection]) -> Bool {
        let uniqueURLs = Set(selections.map(\.url))
        var newlyAccessedURLs: [URL] = []

        for url in uniqueURLs {
            if accessedVideoResources[url] != nil {
                continue
            }
            guard startAccessingVideo(url) else {
                for accessedURL in newlyAccessedURLs {
                    stopAccessingVideo(accessedURL)
                }
                return false
            }
            newlyAccessedURLs.append(url)
        }

        let staleURLs = Set(accessedVideoResources.keys).subtracting(uniqueURLs)
        for staleURL in staleURLs {
            stopAccessingVideo(staleURL)
        }
        return true
    }

    private func stopAccessingSavedVideo() {
        for url in Array(accessedVideoResources.keys) {
            stopAccessingVideo(url)
        }
    }

    private func stopAccessingVideo(_ url: URL) {
        if accessedVideoResources[url] == true {
            url.stopAccessingSecurityScopedResource()
        }
        accessedVideoResources.removeValue(forKey: url)
    }

    func isLoginItemEnabled() -> Bool {
        SMAppService.mainApp.status == .enabled
    }

    func setLoginItemEnabled(_ isEnabled: Bool) throws {
        if isEnabled {
            guard SMAppService.mainApp.status != .enabled else { return }
            try SMAppService.mainApp.register()
        } else {
            guard SMAppService.mainApp.status == .enabled else { return }
            try SMAppService.mainApp.unregister()
        }
    }

    /// ユーザー向けの簡易アラート表示
    private func showAlert(title: String = "VideoWallpaper", message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = message
            alert.addButton(withTitle: AppLocalization.string("OK"))
            alert.runModal()
        }
    }

    @objc private func handleScreenConfigurationChange(_ n: Notification) {
        os_log("画面構成変更を受信、最新の動画を再読み込みします")
        guard let assignments = restoreSavedDisplayAssignments() ?? currentDisplayAssignments() else {
            os_log("保存された動画割り当てが見つかりません")
            return
        }
        if let controller = videoWindowController {
            controller.updateAssignment(assignments.videoAssignment)
        } else {
            videoWindowController = VideoWindowController(assignment: assignments.videoAssignment)
            videoWindowController?.showWindows()
        }
        schedulePlaybackSuspensionUpdate()
        inspectVideoForEfficiency(assignments.defaultSelection.url, showsWarnings: false)
    }

    private func showUITestingWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 240, height: 120),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "RioVideoWallpaper"
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate()
        uiTestingWindow = window
    }

    private func registerPlaybackSuspensionObservers() {
        let workspaceCenter = NSWorkspace.shared.notificationCenter
        workspaceCenter.addObserver(
            self,
            selector: #selector(handleScreensDidSleep(_:)),
            name: NSWorkspace.screensDidSleepNotification,
            object: nil
        )
        workspaceCenter.addObserver(
            self,
            selector: #selector(handleScreensDidWake(_:)),
            name: NSWorkspace.screensDidWakeNotification,
            object: nil
        )
        workspaceCenter.addObserver(
            self,
            selector: #selector(handleActiveSpaceOrAppChange(_:)),
            name: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil
        )
        workspaceCenter.addObserver(
            self,
            selector: #selector(handleActiveSpaceOrAppChange(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }

    @objc private func handleScreensDidSleep(_ notification: Notification) {
        screensAreSleeping = true
        updatePlaybackSuspension()
    }

    @objc private func handleScreensDidWake(_ notification: Notification) {
        screensAreSleeping = false
        schedulePlaybackSuspensionUpdate()
    }

    @objc private func handleActiveSpaceOrAppChange(_ notification: Notification) {
        schedulePlaybackSuspensionUpdate()
    }

    private func schedulePlaybackSuspensionUpdate() {
        playbackSuspensionWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.updatePlaybackSuspension()
        }
        playbackSuspensionWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: workItem)
    }

    private func updatePlaybackSuspension() {
        let shouldSuspend = PlaybackSuspensionPolicy.shouldSuspend(
            screensAreSleeping: screensAreSleeping,
            frontmostPID: NSWorkspace.shared.frontmostApplication?.processIdentifier,
            currentPID: ProcessInfo.processInfo.processIdentifier,
            windows: currentWindowSnapshots(),
            screens: currentScreenSnapshots()
        )
        videoWindowController?.setPlaybackSuspended(shouldSuspend)
    }

    private func currentWindowSnapshots() -> [PlaybackSuspensionPolicy.WindowSnapshot] {
        guard let windowInfoList = CGWindowListCopyWindowInfo(
                [.optionOnScreenOnly, .excludeDesktopElements],
                kCGNullWindowID
              ) as? [[String: Any]] else {
            return []
        }

        return windowInfoList.compactMap { windowInfo in
            guard let ownerPID = (windowInfo[kCGWindowOwnerPID as String] as? NSNumber)?.int32Value,
                  let layer = (windowInfo[kCGWindowLayer as String] as? NSNumber)?.intValue,
                  let bounds = windowInfo[kCGWindowBounds as String] as? [String: Any],
                  let width = (bounds["Width"] as? NSNumber)?.doubleValue,
                  let height = (bounds["Height"] as? NSNumber)?.doubleValue else {
                return nil
            }

            return PlaybackSuspensionPolicy.WindowSnapshot(
                ownerPID: ownerPID,
                layer: layer,
                width: width,
                height: height
            )
        }
    }

    private func currentScreenSnapshots() -> [PlaybackSuspensionPolicy.ScreenSnapshot] {
        NSScreen.screens.map { screen in
            PlaybackSuspensionPolicy.ScreenSnapshot(
                width: Double(screen.frame.width),
                height: Double(screen.frame.height)
            )
        }
    }

    private func inspectVideoForEfficiency(_ videoURL: URL, showsWarnings: Bool) {
        diagnosticsTask?.cancel()
        let largestScreenPixelSize = largestScreenPixelSize()
        diagnosticsTask = Task { [weak self] in
            do {
                let diagnostics = try await VideoAssetDiagnostics.inspect(
                    videoURL: videoURL,
                    largestScreenPixelSize: largestScreenPixelSize
                )
                guard !Task.isCancelled else { return }
                os_log("動画診断: %{public}@", diagnostics.summary)

                guard showsWarnings, !diagnostics.warnings.isEmpty else { return }
                await MainActor.run { [weak self] in
                    self?.showAlert(
                        title: AppLocalization.string("This video may be expensive to play"),
                        message: diagnostics.warnings.joined(separator: "\n")
                    )
                }
            } catch {
                guard !Task.isCancelled else { return }
                os_log("動画診断に失敗しました: %{public}@", String(describing: error))
            }
        }
    }

    private func largestScreenPixelSize() -> CGSize {
        NSScreen.screens.reduce(.zero) { largestSize, screen in
            let scale = screen.backingScaleFactor
            let pixelSize = CGSize(
                width: screen.frame.width * scale,
                height: screen.frame.height * scale
            )
            return CGSize(
                width: max(largestSize.width, pixelSize.width),
                height: max(largestSize.height, pixelSize.height)
            )
        }
    }
}
}

extension VideoWallpaperApp.AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        if notification.object as? NSWindow === generativeEditorWindow {
            generativeEditorWindow = nil
        }
    }
}
