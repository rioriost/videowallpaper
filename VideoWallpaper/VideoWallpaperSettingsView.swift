//
//  VideoWallpaperSettingsView.swift
//  VideoWallpaper
//

import AppKit
import SwiftUI

struct VideoWallpaperSettingsView: View {
    let appDelegate: VideoWallpaperApp.AppDelegate
    let generatedAssetLibrary: GeneratedAssetLibrary
    var setWallpaper: (URL) -> Void
    var setWallpaperForDisplay: (URL) -> Void

    @State private var selectedPane: SettingsPane = .general
    @State private var assignments: StoredDisplayWallpaperAssignments?
    @State private var selectedDisplayID: String?
    @State private var startsAtLogin = false
    @State private var loginItemStatusMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            tabBar
            Divider()
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 1040, minHeight: 720)
        .background(WindowTitleSetter(title: "RioVideoWallpaper"))
        .onAppear {
            refreshDisplayAssignments()
            startsAtLogin = appDelegate.isLoginItemEnabled()
        }
    }

    private var tabBar: some View {
        HStack(spacing: 16) {
            Spacer()
            ForEach(SettingsPane.allCases) { pane in
                Button {
                    selectedPane = pane
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: pane.systemImage)
                            .font(.system(size: 20, weight: selectedPane == pane ? .semibold : .regular))
                        Text(pane.title)
                            .font(.caption)
                    }
                    .frame(width: 104, height: 56)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .focusable(false)
                .focusEffectDisabled()
                .foregroundStyle(selectedPane == pane ? .primary : .secondary)
                .overlay(alignment: .bottom) {
                    if selectedPane == pane {
                        Capsule()
                            .fill(Color.accentColor)
                            .frame(width: 44, height: 3)
                    }
                }
            }
            Spacer()
        }
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(.regularMaterial)
    }

    @ViewBuilder
    private var content: some View {
        switch selectedPane {
        case .general:
            GeneralSettingsPane(
                startsAtLogin: Binding(
                    get: { startsAtLogin },
                    set: { newValue in
                        setStartsAtLogin(newValue)
                    }
                ),
                statusMessage: loginItemStatusMessage
            )
        case .displayVideos:
            DisplayVideoSettingsPane(
                assignments: assignments,
                selectedDisplayID: $selectedDisplayID,
                useSameVideo: Binding(
                    get: { assignments?.perDisplaySelections.isEmpty ?? true },
                    set: { newValue in
                        if newValue {
                            appDelegate.settingsUseSameVideoOnAllDisplays()
                            refreshDisplayAssignments()
                            return
                        }

                        appDelegate.settingsUseSeparateVideosOnConnectedDisplays()
                        refreshDisplayAssignments()
                        if selectedDisplayID == nil {
                            selectedDisplayID = NSScreen.screens.first.map(DisplayIdentifier.id(for:))
                        }
                    }
                ),
                chooseDefaultVideo: {
                    appDelegate.settingsChooseDefaultVideo()
                    refreshDisplayAssignments()
                },
                chooseVideoForDisplay: { displayID in
                    appDelegate.settingsChooseVideo(forDisplayID: displayID)
                    refreshDisplayAssignments()
                }
            )
        case .generation:
            GenerativeEditorView(
                assetLibrary: generatedAssetLibrary,
                setWallpaper: setWallpaper,
                setWallpaperForDisplay: setWallpaperForDisplay
            )
        }
    }

    private func refreshDisplayAssignments() {
        assignments = appDelegate.settingsDisplayAssignments()
        if assignments?.perDisplaySelections.isEmpty == true {
            selectedDisplayID = nil
        } else if selectedDisplayID == nil {
            selectedDisplayID = NSScreen.screens.first.map(DisplayIdentifier.id(for:))
        }
    }

    private func setStartsAtLogin(_ isEnabled: Bool) {
        do {
            try appDelegate.setLoginItemEnabled(isEnabled)
            startsAtLogin = appDelegate.isLoginItemEnabled()
            loginItemStatusMessage = nil
        } catch {
            startsAtLogin = appDelegate.isLoginItemEnabled()
            loginItemStatusMessage = error.localizedDescription
        }
    }
}

private enum SettingsPane: String, CaseIterable, Identifiable {
    case general
    case displayVideos
    case generation

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general:
            return "General"
        case .displayVideos:
            return "Displays"
        case .generation:
            return "Video Generation"
        }
    }

    var systemImage: String {
        switch self {
        case .general:
            return "gearshape"
        case .displayVideos:
            return "display"
        case .generation:
            return "film.stack"
        }
    }
}

private struct GeneralSettingsPane: View {
    @Binding var startsAtLogin: Bool
    var statusMessage: String?

    var body: some View {
        Form {
            Toggle("ログインで起動", isOn: $startsAtLogin)
                .toggleStyle(.checkbox)

            if let statusMessage {
                Text(statusMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .textSelection(.enabled)
            }
        }
        .formStyle(.grouped)
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct DisplayVideoSettingsPane: View {
    var assignments: StoredDisplayWallpaperAssignments?
    @Binding var selectedDisplayID: String?
    @Binding var useSameVideo: Bool
    var chooseDefaultVideo: () -> Void
    var chooseVideoForDisplay: (String) -> Void

    private var screens: [NSScreen] {
        NSScreen.screens
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Toggle("全てのモニタで同じ動画を再生", isOn: $useSameVideo)
                    .toggleStyle(.checkbox)

                monitorPicker

                selectedVideoPanel
            }
            .padding(28)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var monitorPicker: some View {
        if useSameVideo {
            HStack(alignment: .top, spacing: 16) {
                DisplayTile(
                    title: "All Displays",
                    subtitle: assignments?.defaultSelection.url.lastPathComponent ?? "No video selected",
                    isSelected: true,
                    aspectRatio: representativeAspectRatio
                )
            }
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(Array(screens.enumerated()), id: \.offset) { index, screen in
                        let displayID = DisplayIdentifier.id(for: screen)
                        DisplayTile(
                            title: screen.localizedName,
                            subtitle: "\(Int(screen.frame.width)) x \(Int(screen.frame.height))",
                            isSelected: selectedDisplayID == displayID,
                            aspectRatio: displayAspectRatio(for: screen)
                        )
                        .onTapGesture {
                            selectedDisplayID = displayID
                        }
                        .accessibilityAddTraits(selectedDisplayID == displayID ? .isSelected : [])
                        .accessibilityLabel(DisplayIdentifier.label(for: screen, index: index))
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var selectedVideoPanel: some View {
        HStack(spacing: 12) {
            Text("\(useSameVideo ? "Video for All Displays" : "Video for Selected Display"): \(currentVideoURL?.lastPathComponent ?? "No video selected")")
                .font(.headline)
                .lineLimit(2)
                .truncationMode(.middle)

            Spacer()

            Button("Choose Video...") {
                if useSameVideo {
                    chooseDefaultVideo()
                } else if let selectedDisplayID {
                    chooseVideoForDisplay(selectedDisplayID)
                }
            }
            .disabled(!useSameVideo && selectedDisplayID == nil)
        }
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor))
        }
    }

    private var currentVideoURL: URL? {
        guard let assignments else { return nil }
        guard !useSameVideo, let selectedDisplayID else {
            return assignments.defaultSelection.url
        }
        return assignments.perDisplaySelections[selectedDisplayID]?.url ?? assignments.defaultSelection.url
    }

    private var representativeAspectRatio: Double {
        screens.first.map(displayAspectRatio(for:)) ?? 16.0 / 10.0
    }

    private func displayAspectRatio(for screen: NSScreen) -> Double {
        guard screen.frame.height > 0 else {
            return 16.0 / 10.0
        }
        return max(1.2, min(2.4, screen.frame.width / screen.frame.height))
    }
}

private struct DisplayTile: View {
    var title: String
    var subtitle: String
    var isSelected: Bool
    var aspectRatio: Double

    var body: some View {
        VStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(nsColor: .controlAccentColor).opacity(isSelected ? 0.62 : 0.22),
                            Color(nsColor: .textBackgroundColor)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.35), lineWidth: isSelected ? 3 : 1)
                }
                .aspectRatio(aspectRatio, contentMode: .fit)
                .frame(width: 128)

            VStack(spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .frame(width: 150)
        }
        .padding(6)
        .contentShape(Rectangle())
    }
}

private struct WindowTitleSetter: NSViewRepresentable {
    var title: String

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            view.window?.title = title
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            nsView.window?.title = title
        }
    }
}
