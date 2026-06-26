//
//  GenerativeEditorView.swift
//  VideoWallpaper
//

import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct GenerativeEditorView: View {
    private let initialProjectURL: URL?
    private let assetLibrary: GeneratedAssetLibrary
    var setWallpaper: (URL) -> Void
    var setWallpaperForDisplay: (URL) -> Void

    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @State private var project = WallpaperProject.newFieldLinesProject()
    @State private var prompt = ""
    @State private var promptResolutionMessage: String?
    @State private var isResolvingPrompt = false
    @State private var promptResolutionTask: Task<Void, Never>?
    @State private var isExporting = false
    @State private var exportProgress = 0.0
    @State private var exportErrorMessage: String?
    @State private var exportTask: Task<Void, Never>?
    @State private var editAutosaveTask: Task<Void, Never>?
    @State private var projectFileErrorMessage: String?
    @State private var currentProjectURL: URL?
    @State private var lastExportURL: URL?
    @State private var libraryEntries: [ProjectLibraryEntry] = []
    @State private var entryPendingDeletion: ProjectLibraryEntry?
    @State private var selectedStylePreset: StylePreset?
    @State private var isPreviewPlaying = true
    @State private var requestedPreviewFrameIndex: Int?
    @State private var isSeamPreviewing = false
    @State private var seamPreviewTask: Task<Void, Never>?
    @State private var didLoadInitialProject = false
    @State private var showsRendererDetails = true
    @State private var showsExportDetails = true

    init(
        initialProjectURL: URL? = nil,
        assetLibrary: GeneratedAssetLibrary = GeneratedAssetLibrary(),
        setWallpaper: @escaping (URL) -> Void = { _ in },
        setWallpaperForDisplay: @escaping (URL) -> Void = { _ in }
    ) {
        self.initialProjectURL = initialProjectURL
        self.assetLibrary = assetLibrary
        self.setWallpaper = setWallpaper
        self.setWallpaperForDisplay = setWallpaperForDisplay
    }

    private var fieldLinesBinding: Binding<FieldLinesParameters> {
        Binding(
            get: {
                guard case .fieldLines(let parameters) = project.renderParameters else {
                    return .feasibilityStudyDefault
                }
                return parameters
            },
            set: { newValue in
                project.renderParameters = .fieldLines(newValue)
                markProjectEdited(regenerateThumbnail: true)
            }
        )
    }

    private var orbitalBinding: Binding<OrbitalParameters> {
        Binding(
            get: {
                guard case .orbital(let parameters) = project.renderParameters else {
                    return .defaultParameters
                }
                return parameters
            },
            set: { newValue in
                project.renderParameters = .orbital(newValue)
                markProjectEdited(regenerateThumbnail: true)
            }
        )
    }

    private var softVolumetricBinding: Binding<SoftVolumetricParameters> {
        Binding(
            get: {
                guard case .softVolumetric(let parameters) = project.renderParameters else {
                    return .defaultParameters
                }
                return parameters
            },
            set: { newValue in
                project.renderParameters = .softVolumetric(newValue)
                markProjectEdited(regenerateThumbnail: true)
            }
        )
    }

    private var gridCityBinding: Binding<GridCityParameters> {
        Binding(
            get: {
                guard case .gridCity(let parameters) = project.renderParameters else {
                    return .defaultParameters
                }
                return parameters
            },
            set: { newValue in
                project.renderParameters = .gridCity(newValue)
                markProjectEdited(regenerateThumbnail: true)
            }
        )
    }

    private var interferenceFieldBinding: Binding<InterferenceFieldParameters> {
        Binding(
            get: {
                guard case .interferenceField(let parameters) = project.renderParameters else {
                    return .defaultParameters
                }
                return parameters
            },
            set: { newValue in
                project.renderParameters = .interferenceField(newValue)
                markProjectEdited(regenerateThumbnail: true)
            }
        )
    }

    private var periodicNoiseBinding: Binding<PeriodicNoiseParameters> {
        Binding(
            get: {
                guard case .periodicNoise(let parameters) = project.renderParameters else {
                    return .defaultParameters
                }
                return parameters
            },
            set: { newValue in
                project.renderParameters = .periodicNoise(newValue)
                markProjectEdited(regenerateThumbnail: true)
            }
        )
    }

    private var cyclicAutomataBinding: Binding<CyclicAutomataParameters> {
        Binding(
            get: {
                guard case .cyclicAutomata(let parameters) = project.renderParameters else {
                    return .defaultParameters
                }
                return parameters
            },
            set: { newValue in
                project.renderParameters = .cyclicAutomata(newValue)
                markProjectEdited(regenerateThumbnail: true)
            }
        )
    }

    private var agentSwarmBinding: Binding<AgentSwarmParameters> {
        Binding(
            get: {
                guard case .agentSwarm(let parameters) = project.renderParameters else {
                    return .defaultParameters
                }
                return parameters
            },
            set: { newValue in
                project.renderParameters = .agentSwarm(newValue)
                markProjectEdited(regenerateThumbnail: true)
            }
        )
    }

    private var kaleidoscopeBinding: Binding<KaleidoscopeParameters> {
        Binding(
            get: {
                guard case .kaleidoscope(let parameters) = project.renderParameters else {
                    return .defaultParameters
                }
                return parameters
            },
            set: { newValue in
                project.renderParameters = .kaleidoscope(newValue)
                markProjectEdited(regenerateThumbnail: true)
            }
        )
    }

    private var voronoiFlowBinding: Binding<VoronoiFlowParameters> {
        Binding(
            get: {
                guard case .voronoiFlow(let parameters) = project.renderParameters else {
                    return .defaultParameters
                }
                return parameters
            },
            set: { newValue in
                project.renderParameters = .voronoiFlow(newValue)
                markProjectEdited(regenerateThumbnail: true)
            }
        )
    }

    private var reactionDiffusionBinding: Binding<ReactionDiffusionParameters> {
        Binding(
            get: {
                guard case .reactionDiffusion(let parameters) = project.renderParameters else {
                    return .defaultParameters
                }
                return parameters
            },
            set: { newValue in
                project.renderParameters = .reactionDiffusion(newValue)
                markProjectEdited(regenerateThumbnail: true)
            }
        )
    }

    private var plasmaFieldBinding: Binding<PlasmaFieldParameters> {
        Binding(
            get: {
                guard case .plasmaField(let parameters) = project.renderParameters else {
                    return .defaultParameters
                }
                return parameters
            },
            set: { newValue in
                project.renderParameters = .plasmaField(newValue)
                markProjectEdited(regenerateThumbnail: true)
            }
        )
    }

    private var harmonicTunnelBinding: Binding<HarmonicTunnelParameters> {
        Binding(
            get: {
                guard case .harmonicTunnel(let parameters) = project.renderParameters else {
                    return .defaultParameters
                }
                return parameters
            },
            set: { newValue in
                project.renderParameters = .harmonicTunnel(newValue)
                markProjectEdited(regenerateThumbnail: true)
            }
        )
    }

    private var lissajousWeaveBinding: Binding<LissajousWeaveParameters> {
        Binding(
            get: {
                guard case .lissajousWeave(let parameters) = project.renderParameters else {
                    return .defaultParameters
                }
                return parameters
            },
            set: { newValue in
                project.renderParameters = .lissajousWeave(newValue)
                markProjectEdited(regenerateThumbnail: true)
            }
        )
    }

    private var phyllotaxisBloomBinding: Binding<PhyllotaxisBloomParameters> {
        Binding(
            get: {
                guard case .phyllotaxisBloom(let parameters) = project.renderParameters else {
                    return .defaultParameters
                }
                return parameters
            },
            set: { newValue in
                project.renderParameters = .phyllotaxisBloom(newValue)
                markProjectEdited(regenerateThumbnail: true)
            }
        )
    }

    private var hexPulseLatticeBinding: Binding<HexPulseLatticeParameters> {
        Binding(
            get: {
                guard case .hexPulseLattice(let parameters) = project.renderParameters else {
                    return .defaultParameters
                }
                return parameters
            },
            set: { newValue in
                project.renderParameters = .hexPulseLattice(newValue)
                markProjectEdited(regenerateThumbnail: true)
            }
        )
    }

    private var superformulaMorphBinding: Binding<SuperformulaMorphParameters> {
        Binding(
            get: {
                guard case .superformulaMorph(let parameters) = project.renderParameters else {
                    return .defaultParameters
                }
                return parameters
            },
            set: { newValue in
                project.renderParameters = .superformulaMorph(newValue)
                markProjectEdited(regenerateThumbnail: true)
            }
        )
    }

    private var proceduralPatternBinding: Binding<ProceduralPatternParameters> {
        Binding(
            get: {
                switch project.renderParameters {
                case .closedFlowParticles(let parameters),
                     .sdfTunnel(let parameters),
                     .feedbackSynth(let parameters),
                     .guillocheRose(let parameters),
                     .instancedGeometry(let parameters),
                     .metaballField(let parameters),
                     .penroseTiling(let parameters),
                     .waveTerrain(let parameters):
                    return parameters
                default:
                    return .defaultParameters(for: project.rendererFamily)
                }
            },
            set: { newValue in
                switch project.rendererFamily {
                case .closedFlowParticles:
                    project.renderParameters = .closedFlowParticles(newValue)
                case .sdfTunnel:
                    project.renderParameters = .sdfTunnel(newValue)
                case .feedbackSynth:
                    project.renderParameters = .feedbackSynth(newValue)
                case .guillocheRose:
                    project.renderParameters = .guillocheRose(newValue)
                case .instancedGeometry:
                    project.renderParameters = .instancedGeometry(newValue)
                case .metaballField:
                    project.renderParameters = .metaballField(newValue)
                case .penroseTiling:
                    project.renderParameters = .penroseTiling(newValue)
                case .waveTerrain:
                    project.renderParameters = .waveTerrain(newValue)
                default:
                    break
                }
                markProjectEdited(regenerateThumbnail: true)
            }
        )
    }

    private var rendererFamilyBinding: Binding<RendererFamily> {
        Binding(
            get: { project.rendererFamily },
            set: { rendererFamily in
                switchRendererFamily(rendererFamily)
            }
        )
    }

    private var exportedWallpaperURL: URL? {
        if let lastExportURL {
            return lastExportURL
        }
        guard let outputVideoPath = project.assets.outputVideoPath else {
            return nil
        }
        return URL(fileURLWithPath: outputVideoPath)
    }

    private var exportPresetBinding: Binding<ExportPreset> {
        Binding(
            get: {
                ExportPreset.matching(project.exportSettings)
            },
            set: { preset in
                guard let settings = preset.exportSettings(preservingCodec: project.exportSettings.codec) else {
                    return
                }
                updateExportSettings { exportSettings in
                    exportSettings = settings
                }
            }
        )
    }

    private var exportWidthBinding: Binding<Int> {
        exportSettingsBinding(\.width) { max(ExportSettings.minimumWidth, $0) }
    }

    private var exportHeightBinding: Binding<Int> {
        exportSettingsBinding(\.height) { max(ExportSettings.minimumHeight, $0) }
    }

    private var exportFPSBinding: Binding<Int> {
        exportSettingsBinding(\.fps) { max(ExportSettings.minimumFPS, $0) }
    }

    private var exportWarmupLoopsBinding: Binding<Int> {
        exportSettingsBinding(\.warmupLoops) { max(ExportSettings.minimumWarmupLoops, $0) }
    }

    private var exportLoopSecondsBinding: Binding<Double> {
        exportSettingsBinding(\.loopSeconds) { max(ExportSettings.minimumLoopSeconds, $0) }
    }

    private var exportCodecBinding: Binding<VideoCodec> {
        exportSettingsBinding(\.codec) { $0 }
    }

    private var exportQualityBinding: Binding<ExportQuality> {
        exportSettingsBinding(\.quality) { $0 }
    }

    private var effectivePrompt: String {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        return selectedStylePreset?.combinedPrompt(with: trimmedPrompt) ?? trimmedPrompt
    }

    var body: some View {
        HSplitView {
            sidebar
                .frame(minWidth: 280, idealWidth: 300, maxWidth: 360)

            HSplitView {
                previewPane
                    .frame(minWidth: 480)
                inspector
                    .frame(width: 340)
            }
        }
        .frame(minWidth: 1080, minHeight: 700)
        .navigationTitle("RioVideoWallpaper")
        .onAppear(perform: handleAppear)
        .onDisappear {
            promptResolutionTask?.cancel()
            editAutosaveTask?.cancel()
            stopSeamPreview()
        }
        .confirmationDialog(
            "Delete this generated wallpaper?",
            isPresented: Binding(
                get: { entryPendingDeletion != nil },
                set: { isPresented in
                    if !isPresented {
                        entryPendingDeletion = nil
                    }
                }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                guard let entry = entryPendingDeletion else { return }
                deleteLibraryEntry(entry)
            }
            Button("Cancel", role: .cancel) {
                entryPendingDeletion = nil
            }
        } message: {
            Text("The project file and generated library assets will be removed.")
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Button("Open Project") {
                    openProject()
                }
                Button("Save Project") {
                    saveProject()
                }
            }

            if let currentProjectURL {
                Text(currentProjectURL.lastPathComponent)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            if let projectFileErrorMessage {
                Text(projectFileErrorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .textSelection(.enabled)
            }

            Divider()

            TextEditor(text: $prompt)
                .font(.body)
                .frame(minHeight: 120)
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(.separator, lineWidth: 1)
                }

            stylePresetPicker

            Divider()

            HStack(spacing: 8) {
                Button("Randomize Seed") {
                    project.seed = UInt64.random(in: UInt64.min...UInt64.max)
                    if prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, selectedStylePreset == nil {
                        markProjectEdited(regenerateThumbnail: true)
                    } else {
                        applyPromptIfPresent()
                    }
                }

                Button("Generate") {
                    generateFromPrompt()
                }
                .disabled(effectivePrompt.isEmpty || isResolvingPrompt)
                .keyboardShortcut(.return, modifiers: [.command])
            }

            if let promptResolutionMessage {
                Text(promptResolutionMessage)
                    .font(.caption)
                    .foregroundStyle(promptResolutionMessage.contains("failed") || promptResolutionMessage.contains("fallback") ? .orange : .secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
            }

            Divider()

            LabeledContent("Renderer", value: project.rendererFamily.displayName)
            LabeledContent("Seed", value: String(project.seed))

            Divider()

            HStack {
                Text("History")
                    .font(.headline)
                Spacer()
                Button {
                    refreshLibraryEntries()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh history")

                Button {
                    cleanupLibraryAssets()
                } label: {
                    Image(systemName: "trash.slash")
                }
                .accessibilityLabel("Remove orphaned generated assets")
                .help("Remove orphaned generated assets")
            }

            historyList

            Spacer()
        }
        .padding(16)
        .frame(minWidth: 260)
    }

    private var historyList: some View {
        Group {
            if libraryEntries.isEmpty {
                Text("No saved projects")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(libraryEntries) { entry in
                            HStack(spacing: 6) {
                                Button {
                                    openLibraryEntry(entry)
                                } label: {
                                    historyEntryLabel(entry)
                                }
                                .buttonStyle(.plain)

                                if let outputURL = existingOutputVideoURL(for: entry) {
                                    Button {
                                        setWallpaper(outputURL)
                                    } label: {
                                        Image(systemName: "display")
                                    }
                                    .buttonStyle(.borderless)
                                    .help("Set as wallpaper")

                                    Button {
                                        setWallpaperForDisplay(outputURL)
                                    } label: {
                                        Image(systemName: "rectangle.on.rectangle")
                                    }
                                    .buttonStyle(.borderless)
                                    .accessibilityLabel("Set on Display")
                                    .help("Set on display")
                                }

                                Button {
                                    entryPendingDeletion = entry
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(.borderless)
                                .help("Delete from history")
                            }
                        }
                    }
                }
                .frame(minHeight: 96, maxHeight: 220)
            }
        }
    }

    private func historyEntryLabel(_ entry: ProjectLibraryEntry) -> some View {
        HStack(spacing: 8) {
            if let image = thumbnailImage(for: entry) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(16.0 / 10.0, contentMode: .fill)
                    .frame(width: 48, height: 30)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(.quaternary)
                    .frame(width: 48, height: 30)
                    .overlay {
                        Image(systemName: "waveform.path")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.title)
                    .font(.subheadline)
                    .lineLimit(1)
                Text(entry.promptPreview ?? entry.updatedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }

    private var stylePresetPicker: some View {
        HStack(spacing: 8) {
            Text("Style:")
            Menu(selectedStylePreset?.displayName ?? "Select") {
                Button("None") {
                    selectedStylePreset = nil
                }
                Divider()
                ForEach(StylePreset.allCases) { preset in
                    Button {
                        selectedStylePreset = preset
                    } label: {
                        Label(preset.displayName, systemImage: preset.systemImageName)
                    }
                }
            }
            .frame(width: 180, alignment: .leading)
        }
    }

    private var previewPane: some View {
        VStack(spacing: 0) {
            ZStack {
                MetalPreviewView(
                    parameters: project.renderParameters,
                    seed: project.seed,
                    exportSettings: project.exportSettings,
                    isPlaying: isPreviewPlaying,
                    requestedFrameIndex: requestedPreviewFrameIndex
                )
            }
            .aspectRatio(16.0 / 10.0, contentMode: .fit)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            HStack(spacing: 12) {
                Button {
                    stopSeamPreview()
                    isPreviewPlaying.toggle()
                } label: {
                    Image(systemName: isPreviewPlaying ? "pause.fill" : "play.fill")
                }
                .help(isPreviewPlaying ? "Pause" : "Play")

                Button {
                    stopSeamPreview()
                    isPreviewPlaying = false
                    requestedPreviewFrameIndex = 0
                } label: {
                    Image(systemName: "backward.end.fill")
                }
                .help("First frame")

                Button {
                    stopSeamPreview()
                    isPreviewPlaying = false
                    requestedPreviewFrameIndex = max(0, RenderClock(
                        fps: project.exportSettings.fps,
                        loopSeconds: project.exportSettings.loopSeconds
                    ).totalFrames - 1)
                } label: {
                    Image(systemName: "forward.end.fill")
                }
                .help("Last frame")

                Button {
                    toggleSeamPreview()
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }
                .accessibilityLabel("Preview Loop Seam")
                .help("Preview loop seam")
                .tint(isSeamPreviewing ? .accentColor : nil)

                Spacer()

                if let lastExportURL {
                    Button {
                        NSWorkspace.shared.activateFileViewerSelecting([lastExportURL])
                    } label: {
                        Image(systemName: "folder")
                    }
                    .help("Show exported video")
                }

                Button("Set on Display...") {
                    guard let url = exportedWallpaperURL else { return }
                    setWallpaperForDisplay(url)
                }
                .disabled(exportedWallpaperURL == nil || isExporting)
                Button("Set as Wallpaper") {
                    guard let url = exportedWallpaperURL else { return }
                    setWallpaper(url)
                }
                .disabled(exportedWallpaperURL == nil || isExporting)
            }
            .padding(12)
            .frame(height: 54)
        }
    }

    private var inspector: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Loop")
                    .font(.headline)
                Stepper(
                    "Seconds: \(project.exportSettings.loopSeconds, specifier: "%.0f")",
                    value: exportLoopSecondsBinding,
                    in: 4...30,
                    step: 1
                )
                Stepper("FPS: \(project.exportSettings.fps)", value: exportFPSBinding, in: 24...60, step: 6)

                Divider()

                Text("Intent")
                    .font(.headline)
                intentSummary

                Divider()

                Text("Renderer")
                    .font(.headline)
                Picker("Family", selection: rendererFamilyBinding) {
                    ForEach(RendererFamily.allCases) { rendererFamily in
                        Text(rendererFamily.displayName).tag(rendererFamily)
                    }
                }
                .pickerStyle(.menu)

                Divider()

                DisclosureGroup(project.rendererFamily.displayName, isExpanded: $showsRendererDetails) {
                    VStack(alignment: .leading, spacing: 12) {
            switch project.renderParameters {
            case .fieldLines:
                            fieldLinesControls
            case .orbital:
                            orbitalControls
            case .softVolumetric:
                            softVolumetricControls
            case .gridCity:
                            gridCityControls
            case .interferenceField:
                            interferenceFieldControls
            case .periodicNoise:
                            periodicNoiseControls
            case .cyclicAutomata:
                            cyclicAutomataControls
            case .agentSwarm:
                            agentSwarmControls
            case .kaleidoscope:
                            kaleidoscopeControls
            case .voronoiFlow:
                            voronoiFlowControls
            case .reactionDiffusion:
                            reactionDiffusionControls
            case .plasmaField:
                            plasmaFieldControls
            case .harmonicTunnel:
                            harmonicTunnelControls
            case .lissajousWeave:
                            lissajousWeaveControls
            case .phyllotaxisBloom:
                            phyllotaxisBloomControls
            case .hexPulseLattice:
                            hexPulseLatticeControls
            case .superformulaMorph:
                            superformulaMorphControls
            case .closedFlowParticles,
                 .sdfTunnel,
                 .feedbackSynth,
                 .guillocheRose,
                 .instancedGeometry,
                 .metaballField,
                 .penroseTiling,
                 .waveTerrain:
                            proceduralPatternControls
            }
                    }
                    .padding(.top, 8)
                }

                Divider()

                DisclosureGroup("Export", isExpanded: $showsExportDetails) {
                    VStack(alignment: .leading, spacing: 12) {
                Picker("Preset", selection: exportPresetBinding) {
                    ForEach(ExportPreset.allCases) { preset in
                        Text(preset.displayName).tag(preset)
                    }
                }
                Stepper("Width: \(project.exportSettings.width)", value: exportWidthBinding, in: 640...7680, step: 16)
                Stepper("Height: \(project.exportSettings.height)", value: exportHeightBinding, in: 400...4320, step: 16)
                Stepper("Warmup Loops: \(project.exportSettings.warmupLoops)", value: exportWarmupLoopsBinding, in: 0...4)
                Picker("Codec", selection: exportCodecBinding) {
                    ForEach(VideoCodec.allCases) { codec in
                        Text(codec.rawValue.uppercased()).tag(codec)
                    }
                }
                Picker("Quality", selection: exportQualityBinding) {
                    ForEach(ExportQuality.allCases) { quality in
                        Text(quality.rawValue.capitalized).tag(quality)
                    }
                }

                        if isExporting {
                            ProgressView(value: exportProgress)
                        }

                if let exportErrorMessage {
                    Text(exportErrorMessage)
                        .foregroundStyle(.red)
                        .textSelection(.enabled)
                }

                        HStack {
                            Spacer()

                            if isExporting {
                                Button("Cancel") {
                                    cancelExport()
                                }
                            }

                            Button(isExporting ? "Exporting..." : "Export...") {
                                startManualExport()
                            }
                            .disabled(isExporting)
                        }
                    }
                    .padding(.top, 8)
            }
        }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var intentSummary: some View {
        if let intent = project.visualIntent {
            LabeledContent("Title", value: intent.title)
            LabeledContent("Mood", value: intent.moodTags.joined(separator: ", "))
            LabeledContent("Palette", value: "\(Int(intent.palette.hueBaseDegrees.rounded())) deg")
            LabeledContent("Loop", value: "\(Int(intent.motion.loopSeconds.rounded()))s")
            Text(intent.summary)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
            ProgressView(value: intent.composition.density, total: 1.0) {
                Text("Density")
            }
            ProgressView(value: intent.elements.particleAmount, total: 1.0) {
                Text("Particles")
            }
            ProgressView(value: intent.elements.glowAmount, total: 1.0) {
                Text("Glow")
            }
        } else {
            LabeledContent("Status", value: "Not generated")
        }
    }

    private var fieldLinesControls: some View {
        let parameters = fieldLinesBinding

        return Group {
            Stepper("Bands: \(parameters.wrappedValue.bandCount)", value: parameters.bandCount, in: 1...24)
            Stepper("Particles: \(parameters.wrappedValue.particleCount)", value: parameters.particleCount, in: 0...10000, step: 100)
            SliderRow(title: "Trail", value: parameters.fadeAlpha, range: 0.02...0.50)
            SliderRow(title: "Structure", value: parameters.lineStep, range: 0.6...3.0)
            SliderRow(title: "Hue", value: parameters.hueBaseDegrees, range: 0...360)
            SliderRow(title: "Saturation", value: parameters.saturation, range: 0...1)
            SliderRow(title: "Brightness", value: parameters.brightness, range: 0...1)
            SliderRow(title: "Speed", value: parameters.speed, range: 0...2)
            SliderRow(title: "Turbulence", value: parameters.turbulence, range: 0...2)
        }
    }

    private var orbitalControls: some View {
        let parameters = orbitalBinding

        return Group {
            Stepper("Orbits: \(parameters.wrappedValue.orbitCount)", value: parameters.orbitCount, in: 2...18)
            Stepper("Satellites: \(parameters.wrappedValue.satelliteCount)", value: parameters.satelliteCount, in: 0...240, step: 8)
            SliderRow(title: "Trail", value: parameters.fadeAlpha, range: 0.04...0.42)
            SliderRow(title: "Radius", value: parameters.radiusScale, range: 0.45...1.55)
            SliderRow(title: "Hue", value: parameters.hueBaseDegrees, range: 0...360)
            SliderRow(title: "Saturation", value: parameters.saturation, range: 0...1)
            SliderRow(title: "Brightness", value: parameters.brightness, range: 0...1)
            SliderRow(title: "Speed", value: parameters.speed, range: 0...2)
            SliderRow(title: "Eccentricity", value: parameters.eccentricity, range: 0...0.82)
        }
    }

    private var softVolumetricControls: some View {
        let parameters = softVolumetricBinding

        return Group {
            Stepper("Clouds: \(parameters.wrappedValue.cloudCount)", value: parameters.cloudCount, in: 2...18)
            Stepper("Layers: \(parameters.wrappedValue.layerCount)", value: parameters.layerCount, in: 1...8)
            SliderRow(title: "Trail", value: parameters.fadeAlpha, range: 0.04...0.36)
            SliderRow(title: "Spread", value: parameters.spread, range: 0.45...1.65)
            SliderRow(title: "Hue", value: parameters.hueBaseDegrees, range: 0...360)
            SliderRow(title: "Saturation", value: parameters.saturation, range: 0...1)
            SliderRow(title: "Brightness", value: parameters.brightness, range: 0...1)
            SliderRow(title: "Glow", value: parameters.glowSize, range: 1.4...8.0)
            SliderRow(title: "Speed", value: parameters.speed, range: 0...1.65)
            SliderRow(title: "Turbulence", value: parameters.turbulence, range: 0...1.55)
        }
    }

    private var gridCityControls: some View {
        let parameters = gridCityBinding

        return Group {
            Stepper("Lanes: \(parameters.wrappedValue.laneCount)", value: parameters.laneCount, in: 4...28)
            Stepper("Towers: \(parameters.wrappedValue.towerCount)", value: parameters.towerCount, in: 0...180, step: 6)
            SliderRow(title: "Trail", value: parameters.fadeAlpha, range: 0.04...0.36)
            SliderRow(title: "Perspective", value: parameters.perspective, range: 0.25...1.0)
            SliderRow(title: "Hue", value: parameters.hueBaseDegrees, range: 0...360)
            SliderRow(title: "Saturation", value: parameters.saturation, range: 0...1)
            SliderRow(title: "Brightness", value: parameters.brightness, range: 0...1)
            SliderRow(title: "Glow", value: parameters.glowSize, range: 1.0...8.0)
            SliderRow(title: "Speed", value: parameters.speed, range: 0...1.8)
            SliderRow(title: "Depth", value: parameters.depth, range: 0.25...1.0)
        }
    }

    private var interferenceFieldControls: some View {
        let parameters = interferenceFieldBinding

        return Group {
            Stepper("Waves: \(parameters.wrappedValue.waveCount)", value: parameters.waveCount, in: 3...14)
            Stepper("Samples: \(parameters.wrappedValue.samplesPerAxis)", value: parameters.samplesPerAxis, in: 56...150, step: 4)
            SliderRow(title: "Trail", value: parameters.fadeAlpha, range: 0.04...0.34)
            SliderRow(title: "Frequency", value: parameters.spatialFrequency, range: 0.45...2.8)
            SliderRow(title: "Hue", value: parameters.hueBaseDegrees, range: 0...360)
            SliderRow(title: "Saturation", value: parameters.saturation, range: 0...1)
            SliderRow(title: "Brightness", value: parameters.brightness, range: 0...1)
            SliderRow(title: "Point Size", value: parameters.pointSize, range: 0.8...4.6)
            SliderRow(title: "Speed", value: parameters.speed, range: 0...1.6)
            SliderRow(title: "Symmetry", value: parameters.symmetry, range: 0...1)
            SliderRow(title: "Contrast", value: parameters.contrast, range: 0.15...0.85)
        }
    }

    private var periodicNoiseControls: some View {
        let parameters = periodicNoiseBinding

        return Group {
            Stepper("Samples: \(parameters.wrappedValue.samplesPerAxis)", value: parameters.samplesPerAxis, in: 56...160, step: 4)
            Stepper("Octaves: \(parameters.wrappedValue.octaveCount)", value: parameters.octaveCount, in: 1...7)
            SliderRow(title: "Trail", value: parameters.fadeAlpha, range: 0.04...0.34)
            SliderRow(title: "Scale", value: parameters.noiseScale, range: 0.35...3.2)
            SliderRow(title: "Warp", value: parameters.warpAmount, range: 0...1.2)
            SliderRow(title: "Hue", value: parameters.hueBaseDegrees, range: 0...360)
            SliderRow(title: "Saturation", value: parameters.saturation, range: 0...1)
            SliderRow(title: "Brightness", value: parameters.brightness, range: 0...1)
            SliderRow(title: "Point Size", value: parameters.pointSize, range: 0.8...4.8)
            SliderRow(title: "Speed", value: parameters.speed, range: 0...1.55)
            SliderRow(title: "Turbulence", value: parameters.turbulence, range: 0...1.65)
            SliderRow(title: "Contour", value: parameters.contourSharpness, range: 0...1)
        }
    }

    private var cyclicAutomataControls: some View {
        let parameters = cyclicAutomataBinding

        return Group {
            Stepper("Cells: \(parameters.wrappedValue.cellsPerAxis)", value: parameters.cellsPerAxis, in: 36...150, step: 4)
            Stepper("States: \(parameters.wrappedValue.stateCount)", value: parameters.stateCount, in: 3...12)
            SliderRow(title: "Trail", value: parameters.fadeAlpha, range: 0.04...0.34)
            SliderRow(title: "Scale", value: parameters.cellScale, range: 0.5...2.8)
            SliderRow(title: "Hue", value: parameters.hueBaseDegrees, range: 0...360)
            SliderRow(title: "Saturation", value: parameters.saturation, range: 0...1)
            SliderRow(title: "Brightness", value: parameters.brightness, range: 0...1)
            SliderRow(title: "Cell Size", value: parameters.cellSize, range: 1...10)
            SliderRow(title: "Speed", value: parameters.speed, range: 0...1.8)
            SliderRow(title: "Neighborhood", value: parameters.neighborhood, range: 0...1)
            SliderRow(title: "Mutation", value: parameters.mutation, range: 0...1)
            SliderRow(title: "Edges", value: parameters.edgeSharpness, range: 0...1)
        }
    }

    private var agentSwarmControls: some View {
        let parameters = agentSwarmBinding

        return Group {
            Stepper("Agents: \(parameters.wrappedValue.agentCount)", value: parameters.agentCount, in: 32...900, step: 16)
            Stepper("Trails: \(parameters.wrappedValue.trailCount)", value: parameters.trailCount, in: 0...12)
            SliderRow(title: "Trail", value: parameters.fadeAlpha, range: 0.04...0.34)
            SliderRow(title: "Radius", value: parameters.orbitRadius, range: 0.15...1.25)
            SliderRow(title: "Cohesion", value: parameters.cohesion, range: 0...1)
            SliderRow(title: "Wander", value: parameters.wander, range: 0...1)
            SliderRow(title: "Hue", value: parameters.hueBaseDegrees, range: 0...360)
            SliderRow(title: "Saturation", value: parameters.saturation, range: 0...1)
            SliderRow(title: "Brightness", value: parameters.brightness, range: 0...1)
            SliderRow(title: "Agent Size", value: parameters.agentSize, range: 1.2...10)
            SliderRow(title: "Speed", value: parameters.speed, range: 0...1.9)
            SliderRow(title: "Separation", value: parameters.separation, range: 0...1)
        }
    }

    private var kaleidoscopeControls: some View {
        let parameters = kaleidoscopeBinding

        return Group {
            Stepper("Rings: \(parameters.wrappedValue.ringCount)", value: parameters.ringCount, in: 3...18)
            Stepper("Segments: \(parameters.wrappedValue.segments)", value: parameters.segments, in: 4...24)
            Stepper("Points: \(parameters.wrappedValue.pointsPerRing)", value: parameters.pointsPerRing, in: 120...960, step: 40)
            SliderRow(title: "Trail", value: parameters.fadeAlpha, range: 0.04...0.34)
            SliderRow(title: "Radius", value: parameters.radiusScale, range: 0.35...1.22)
            SliderRow(title: "Twist", value: parameters.twist, range: 0...1)
            SliderRow(title: "Petals", value: parameters.petalAmount, range: 0...1)
            SliderRow(title: "Hue", value: parameters.hueBaseDegrees, range: 0...360)
            SliderRow(title: "Saturation", value: parameters.saturation, range: 0...1)
            SliderRow(title: "Brightness", value: parameters.brightness, range: 0...1)
            SliderRow(title: "Point Size", value: parameters.pointSize, range: 1.2...8.0)
            SliderRow(title: "Speed", value: parameters.speed, range: 0...1.65)
            SliderRow(title: "Complexity", value: parameters.complexity, range: 0...1)
        }
    }

    private var voronoiFlowControls: some View {
        let parameters = voronoiFlowBinding

        return Group {
            Stepper("Sites: \(parameters.wrappedValue.siteCount)", value: parameters.siteCount, in: 8...80, step: 2)
            Stepper("Samples: \(parameters.wrappedValue.samplesPerAxis)", value: parameters.samplesPerAxis, in: 48...150, step: 4)
            SliderRow(title: "Trail", value: parameters.fadeAlpha, range: 0.04...0.34)
            SliderRow(title: "Scale", value: parameters.cellScale, range: 0.45...2.2)
            SliderRow(title: "Edge", value: parameters.edgeWidth, range: 0.08...0.80)
            SliderRow(title: "Pulse", value: parameters.pulseAmount, range: 0...1)
            SliderRow(title: "Hue", value: parameters.hueBaseDegrees, range: 0...360)
            SliderRow(title: "Saturation", value: parameters.saturation, range: 0...1)
            SliderRow(title: "Brightness", value: parameters.brightness, range: 0...1)
            SliderRow(title: "Point Size", value: parameters.pointSize, range: 1.2...8.0)
            SliderRow(title: "Speed", value: parameters.speed, range: 0...1.65)
            SliderRow(title: "Drift", value: parameters.drift, range: 0...1)
        }
    }

    private var reactionDiffusionControls: some View {
        let parameters = reactionDiffusionBinding

        return Group {
            Stepper("Samples: \(parameters.wrappedValue.samplesPerAxis)", value: parameters.samplesPerAxis, in: 48...160, step: 4)
            Stepper("Layers: \(parameters.wrappedValue.layerCount)", value: parameters.layerCount, in: 2...8)
            SliderRow(title: "Trail", value: parameters.fadeAlpha, range: 0.04...0.34)
            SliderRow(title: "Scale", value: parameters.patternScale, range: 0.35...3.0)
            SliderRow(title: "Sharpness", value: parameters.stripeSharpness, range: 0...1)
            SliderRow(title: "Diffusion", value: parameters.diffusion, range: 0...1)
            SliderRow(title: "Hue", value: parameters.hueBaseDegrees, range: 0...360)
            SliderRow(title: "Saturation", value: parameters.saturation, range: 0...1)
            SliderRow(title: "Brightness", value: parameters.brightness, range: 0...1)
            SliderRow(title: "Point Size", value: parameters.pointSize, range: 1.2...8.0)
            SliderRow(title: "Speed", value: parameters.speed, range: 0...1.65)
            SliderRow(title: "Turbulence", value: parameters.turbulence, range: 0...1.8)
            SliderRow(title: "Symmetry", value: parameters.symmetry, range: 0...1)
        }
    }

    private var plasmaFieldControls: some View {
        let parameters = plasmaFieldBinding

        return Group {
            Stepper("Samples: \(parameters.wrappedValue.samplesPerAxis)", value: parameters.samplesPerAxis, in: 56...170, step: 4)
            Stepper("Octaves: \(parameters.wrappedValue.octaveCount)", value: parameters.octaveCount, in: 1...8)
            SliderRow(title: "Trail", value: parameters.fadeAlpha, range: 0.04...0.34)
            SliderRow(title: "Scale", value: parameters.waveScale, range: 0.35...3.0)
            SliderRow(title: "Warp", value: parameters.warpAmount, range: 0...1.3)
            SliderRow(title: "Hue", value: parameters.hueBaseDegrees, range: 0...360)
            SliderRow(title: "Saturation", value: parameters.saturation, range: 0...1)
            SliderRow(title: "Brightness", value: parameters.brightness, range: 0...1)
            SliderRow(title: "Point Size", value: parameters.pointSize, range: 1.2...8.0)
            SliderRow(title: "Speed", value: parameters.speed, range: 0...1.65)
            SliderRow(title: "Contrast", value: parameters.contrast, range: 0...1)
            SliderRow(title: "Flow", value: parameters.flowAngle, range: 0...360)
        }
    }

    private var harmonicTunnelControls: some View {
        let parameters = harmonicTunnelBinding

        return Group {
            Stepper("Rings: \(parameters.wrappedValue.ringCount)", value: parameters.ringCount, in: 10...72)
            Stepper("Points: \(parameters.wrappedValue.pointsPerRing)", value: parameters.pointsPerRing, in: 48...420, step: 12)
            SliderRow(title: "Trail", value: parameters.fadeAlpha, range: 0.04...0.34)
            SliderRow(title: "Depth", value: parameters.tunnelDepth, range: 0...1)
            SliderRow(title: "Wave", value: parameters.waveAmplitude, range: 0...0.75)
            SliderRow(title: "Twist", value: parameters.twist, range: 0...1)
            SliderRow(title: "Spokes", value: parameters.spokeAmount, range: 0...1)
            SliderRow(title: "Hue", value: parameters.hueBaseDegrees, range: 0...360)
            SliderRow(title: "Saturation", value: parameters.saturation, range: 0...1)
            SliderRow(title: "Brightness", value: parameters.brightness, range: 0...1)
            SliderRow(title: "Point Size", value: parameters.pointSize, range: 1.2...10.0)
            SliderRow(title: "Speed", value: parameters.speed, range: 0...1.65)
            SliderRow(title: "Perspective", value: parameters.perspective, range: 0...1)
            SliderRow(title: "Center Drift", value: parameters.centerDrift, range: 0...0.6)
        }
    }

    private var lissajousWeaveControls: some View {
        let parameters = lissajousWeaveBinding

        return Group {
            Stepper("Curves: \(parameters.wrappedValue.curveCount)", value: parameters.curveCount, in: 1...22)
            Stepper("Points: \(parameters.wrappedValue.pointsPerCurve)", value: parameters.pointsPerCurve, in: 160...1200, step: 40)
            SliderRow(title: "Trail", value: parameters.fadeAlpha, range: 0.04...0.34)
            Stepper("Frequency X: \(parameters.wrappedValue.frequencyX)", value: parameters.frequencyX, in: 1...12)
            Stepper("Frequency Y: \(parameters.wrappedValue.frequencyY)", value: parameters.frequencyY, in: 1...12)
            SliderRow(title: "Phase", value: parameters.phaseSpread, range: 0...1)
            SliderRow(title: "Weave", value: parameters.weaveAmount, range: 0...1)
            SliderRow(title: "Modulation", value: parameters.modulation, range: 0...1)
            SliderRow(title: "Hue", value: parameters.hueBaseDegrees, range: 0...360)
            SliderRow(title: "Saturation", value: parameters.saturation, range: 0...1)
            SliderRow(title: "Brightness", value: parameters.brightness, range: 0...1)
            SliderRow(title: "Point Size", value: parameters.pointSize, range: 1.2...8.0)
            SliderRow(title: "Speed", value: parameters.speed, range: 0...1.65)
            SliderRow(title: "Rotation", value: parameters.rotation, range: 0...360)
        }
    }

    private var phyllotaxisBloomControls: some View {
        let parameters = phyllotaxisBloomBinding

        return Group {
            Stepper("Points: \(parameters.wrappedValue.pointCount)", value: parameters.pointCount, in: 600...12000, step: 200)
            Stepper("Arms: \(parameters.wrappedValue.armCount)", value: parameters.armCount, in: 1...12)
            SliderRow(title: "Trail", value: parameters.fadeAlpha, range: 0.04...0.34)
            SliderRow(title: "Tightness", value: parameters.spiralTightness, range: 0...1)
            SliderRow(title: "Bloom", value: parameters.bloomAmount, range: 0...1)
            SliderRow(title: "Pulse", value: parameters.pulseAmount, range: 0...1)
            SliderRow(title: "Hue", value: parameters.hueBaseDegrees, range: 0...360)
            SliderRow(title: "Saturation", value: parameters.saturation, range: 0...1)
            SliderRow(title: "Brightness", value: parameters.brightness, range: 0...1)
            SliderRow(title: "Point Size", value: parameters.pointSize, range: 0.8...5.8)
            SliderRow(title: "Speed", value: parameters.speed, range: 0...1.65)
            SliderRow(title: "Rotation", value: parameters.rotation, range: 0...360)
            SliderRow(title: "Center Drift", value: parameters.centerDrift, range: 0...0.6)
        }
    }

    private var hexPulseLatticeControls: some View {
        let parameters = hexPulseLatticeBinding

        return Group {
            Stepper("Columns: \(parameters.wrappedValue.columnCount)", value: parameters.columnCount, in: 8...48)
            Stepper("Rows: \(parameters.wrappedValue.rowCount)", value: parameters.rowCount, in: 6...36)
            Stepper("Edge Points: \(parameters.wrappedValue.pointsPerEdge)", value: parameters.pointsPerEdge, in: 2...14)
            SliderRow(title: "Trail", value: parameters.fadeAlpha, range: 0.04...0.34)
            SliderRow(title: "Pulse", value: parameters.pulseAmount, range: 0...1)
            SliderRow(title: "Wave", value: parameters.waveScale, range: 0...1)
            SliderRow(title: "Thickness", value: parameters.lineThickness, range: 0...1)
            SliderRow(title: "Hue", value: parameters.hueBaseDegrees, range: 0...360)
            SliderRow(title: "Saturation", value: parameters.saturation, range: 0...1)
            SliderRow(title: "Brightness", value: parameters.brightness, range: 0...1)
            SliderRow(title: "Point Size", value: parameters.pointSize, range: 1.2...8.0)
            SliderRow(title: "Speed", value: parameters.speed, range: 0...1.65)
            SliderRow(title: "Rotation", value: parameters.rotation, range: 0...360)
        }
    }

    private var superformulaMorphControls: some View {
        let parameters = superformulaMorphBinding

        return Group {
            Stepper("Contours: \(parameters.wrappedValue.contourCount)", value: parameters.contourCount, in: 2...24)
            Stepper("Points: \(parameters.wrappedValue.pointsPerContour)", value: parameters.pointsPerContour, in: 160...1400, step: 40)
            Stepper("Harmonic A: \(parameters.wrappedValue.harmonicA)", value: parameters.harmonicA, in: 2...18)
            Stepper("Harmonic B: \(parameters.wrappedValue.harmonicB)", value: parameters.harmonicB, in: 2...18)
            SliderRow(title: "Morph", value: parameters.morphAmount, range: 0...1)
            SliderRow(title: "Scale", value: parameters.radialScale, range: 0.3...1.25)
            SliderRow(title: "Spread", value: parameters.contourSpread, range: 0...1)
            SliderRow(title: "Trail", value: parameters.fadeAlpha, range: 0.04...0.34)
            SliderRow(title: "Hue", value: parameters.hueBaseDegrees, range: 0...360)
            SliderRow(title: "Saturation", value: parameters.saturation, range: 0...1)
            SliderRow(title: "Brightness", value: parameters.brightness, range: 0...1)
            SliderRow(title: "Point Size", value: parameters.pointSize, range: 0.8...5.8)
            SliderRow(title: "Speed", value: parameters.speed, range: 0...1.65)
            SliderRow(title: "Rotation", value: parameters.rotation, range: 0...360)
            SliderRow(title: "Center Drift", value: parameters.centerDrift, range: 0...0.6)
        }
    }

    private var proceduralPatternControls: some View {
        let parameters = proceduralPatternBinding

        return Group {
            Stepper("Elements: \(parameters.wrappedValue.elementCount)", value: parameters.elementCount, in: 4...128)
            Stepper("Samples: \(parameters.wrappedValue.samplesPerElement)", value: parameters.samplesPerElement, in: 4...1400, step: 8)
            Stepper("Harmonic A: \(parameters.wrappedValue.harmonicA)", value: parameters.harmonicA, in: 1...24)
            Stepper("Harmonic B: \(parameters.wrappedValue.harmonicB)", value: parameters.harmonicB, in: 1...32)
            SliderRow(title: "Trail", value: parameters.fadeAlpha, range: 0.04...0.34)
            SliderRow(title: "Scale", value: parameters.scale, range: 0.18...1.35)
            SliderRow(title: "Modulation", value: parameters.modulation, range: 0...1)
            SliderRow(title: "Depth", value: parameters.depth, range: 0...1)
            SliderRow(title: "Feedback", value: parameters.feedback, range: 0...1)
            SliderRow(title: "Hue", value: parameters.hueBaseDegrees, range: 0...360)
            SliderRow(title: "Saturation", value: parameters.saturation, range: 0...1)
            SliderRow(title: "Brightness", value: parameters.brightness, range: 0...1)
            SliderRow(title: "Point Size", value: parameters.pointSize, range: 1.2...10.0)
            SliderRow(title: "Speed", value: parameters.speed, range: 0...1.65)
            SliderRow(title: "Rotation", value: parameters.rotation, range: 0...360)
        }
    }

    private func switchRendererFamily(_ rendererFamily: RendererFamily) {
        guard rendererFamily != project.rendererFamily else {
            return
        }

        project.rendererFamily = rendererFamily
        project.rendererVersion = 1
        if var intent = project.visualIntent {
            intent.rendererFamily = rendererFamily
            project.visualIntent = intent
            let capabilities = RendererCapabilities.capabilities(for: rendererFamily)
            project.renderParameters = IntentToRenderParametersMapper.renderParameters(
                from: intent,
                capabilities: capabilities,
                reducedMotion: accessibilityReduceMotion
            )
        } else {
            project.renderParameters = .defaultParameters(for: rendererFamily)
        }
        markProjectEdited(regenerateThumbnail: true)
    }

    private func generateFromPrompt() {
        let trimmedPrompt = effectivePrompt
        guard !trimmedPrompt.isEmpty else { return }

        project.seed = seed(for: trimmedPrompt, previousSeed: project.seed)
        resolvePrompt(trimmedPrompt, appendPromptHistory: true)
    }

    private func applyPromptIfPresent() {
        let trimmedPrompt = effectivePrompt
        guard !trimmedPrompt.isEmpty else { return }
        resolvePrompt(trimmedPrompt, appendPromptHistory: false)
    }

    private func resolvePrompt(_ prompt: String, appendPromptHistory: Bool) {
        guard !isResolvingPrompt else { return }

        let capabilities = RendererCapabilities.catalog(preferred: project.rendererFamily)
        let request = VisualIntentRequest(
            prompt: prompt,
            seed: project.seed,
            currentIntent: project.visualIntent,
            capabilities: capabilities
        )
        let currentExportSettings = project.exportSettings
        let reducedMotion = accessibilityReduceMotion

        isResolvingPrompt = true
        projectFileErrorMessage = nil
        promptResolutionMessage = "Generating..."
        promptResolutionTask?.cancel()
        promptResolutionTask = Task {
            let result = await Task.detached {
                do {
                    let intent = try VisualIntentValidator.normalized(
                        LocalVisualIntentProvider().intent(for: request),
                        capabilities: capabilities,
                        reducedMotion: reducedMotion
                    )
                    let resolvedCapabilities = RendererCapabilities.capabilities(for: intent.rendererFamily)
                    let renderParameters = IntentToRenderParametersMapper.renderParameters(
                        from: intent,
                        capabilities: resolvedCapabilities,
                        reducedMotion: reducedMotion
                    )
                    let exportSettings = IntentToRenderParametersMapper.exportSettings(
                        currentExportSettings,
                        applying: intent
                    )
                    return PromptResolutionResult.success(
                        intent: intent,
                        renderParameters: renderParameters,
                        exportSettings: exportSettings
                    )
                } catch {
                    return PromptResolutionResult.failure(error)
                }
            }.value

            guard !Task.isCancelled else { return }
            applyPromptResolutionResult(result, prompt: prompt, appendPromptHistory: appendPromptHistory)
        }
    }

    private func applyPromptResolutionResult(
        _ result: PromptResolutionResult,
        prompt: String,
        appendPromptHistory: Bool
    ) {
        isResolvingPrompt = false
        promptResolutionTask = nil

        switch result {
        case .success(let intent, let renderParameters, let exportSettings):
            project.visualIntent = intent
            project.rendererFamily = intent.rendererFamily
            project.rendererVersion = 1
            project.renderParameters = renderParameters
            project.exportSettings = exportSettings
            if appendPromptHistory {
                project.promptHistory.append(
                    PromptEntry(
                        id: UUID(),
                        createdAt: Date(),
                        prompt: prompt,
                        responseSummary: intent.summary
                    )
                )
            }
            project.updatedAt = Date()
            lastExportURL = nil
            project.assets.outputVideoPath = nil
            projectFileErrorMessage = nil
            promptResolutionMessage = "Generated locally."
            updateThumbnailForCurrentProject()
            autosaveCurrentProject()
            resetPreviewTransport()
        case .failure(let error):
            projectFileErrorMessage = error.localizedDescription
            promptResolutionMessage = nil
        }
    }

    private func resetPreviewTransport() {
        stopSeamPreview()
        isPreviewPlaying = true
        requestedPreviewFrameIndex = nil
    }

    private func toggleSeamPreview() {
        if isSeamPreviewing {
            stopSeamPreview()
            return
        }

        isSeamPreviewing = true
        isPreviewPlaying = false
        seamPreviewTask?.cancel()
        seamPreviewTask = Task { @MainActor in
            var showsLastFrame = true
            while !Task.isCancelled {
                let clock = RenderClock(
                    fps: project.exportSettings.fps,
                    loopSeconds: project.exportSettings.loopSeconds
                )
                requestedPreviewFrameIndex = showsLastFrame ? max(0, clock.totalFrames - 1) : 0
                showsLastFrame.toggle()
                try? await Task.sleep(nanoseconds: 650_000_000)
            }
        }
    }

    private func stopSeamPreview() {
        seamPreviewTask?.cancel()
        seamPreviewTask = nil
        isSeamPreviewing = false
    }

    private func exportSettingsBinding<Value>(
        _ keyPath: WritableKeyPath<ExportSettings, Value>,
        normalize: @escaping (Value) -> Value
    ) -> Binding<Value> {
        Binding(
            get: {
                project.exportSettings[keyPath: keyPath]
            },
            set: { newValue in
                updateExportSettings { settings in
                    settings[keyPath: keyPath] = normalize(newValue)
                }
            }
        )
    }

    private func updateExportSettings(_ update: (inout ExportSettings) -> Void) {
        update(&project.exportSettings)
        markProjectEdited(regenerateThumbnail: false)
    }

    private func markProjectEdited(regenerateThumbnail: Bool) {
        project.assets.outputVideoPath = nil
        project.updatedAt = Date()
        lastExportURL = nil
        resetPreviewTransport()
        scheduleAutosaveCurrentProject(regenerateThumbnail: regenerateThumbnail)
    }

    private func scheduleAutosaveCurrentProject(regenerateThumbnail: Bool) {
        editAutosaveTask?.cancel()
        editAutosaveTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 750_000_000)
            guard !Task.isCancelled else {
                return
            }

            if regenerateThumbnail {
                updateThumbnailForCurrentProject()
            }
            autosaveCurrentProject()
            editAutosaveTask = nil
        }
    }

    private func seed(for prompt: String, previousSeed: UInt64) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in prompt.utf8 {
            hash ^= UInt64(byte)
            hash &*= 0x100000001b3
        }
        hash ^= previousSeed
        return hash == 0 ? 0x9E3779B97F4A7C15 : hash
    }

    private func saveProject() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.videoWallpaperProject]
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        panel.nameFieldStringValue = currentProjectURL?.lastPathComponent ?? defaultProjectFilename

        guard panel.runModal() == .OK, let outputURL = panel.url else {
            return
        }

        do {
            var projectToSave = project
            projectToSave.updatedAt = Date()
            try WallpaperProjectFileStore.save(projectToSave, to: outputURL)
            project = projectToSave
            currentProjectURL = outputURL.pathExtension.isEmpty
                ? outputURL.appendingPathExtension(WallpaperProjectFileStore.fileExtension)
                : outputURL
            projectFileErrorMessage = nil
            refreshLibraryEntries()
        } catch {
            projectFileErrorMessage = error.localizedDescription
        }
    }

    private func openProject() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.videoWallpaperProject]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        guard panel.runModal() == .OK, let inputURL = panel.url else {
            return
        }

        do {
            let loadedProject = try WallpaperProjectFileStore.load(from: inputURL)
            loadProject(loadedProject, from: inputURL)
        } catch {
            projectFileErrorMessage = error.localizedDescription
        }
    }

    private func handleAppear() {
        loadInitialProjectIfNeeded()
        refreshLibraryEntries()
    }

    private func loadInitialProjectIfNeeded() {
        guard !didLoadInitialProject, let initialProjectURL else {
            return
        }

        didLoadInitialProject = true
        do {
            let loadedProject = try WallpaperProjectFileStore.load(from: initialProjectURL)
            loadProject(loadedProject, from: initialProjectURL)
        } catch {
            projectFileErrorMessage = error.localizedDescription
        }
    }

    private func loadProject(_ loadedProject: WallpaperProject, from url: URL) {
        let sanitizationResult = WallpaperProjectSanitizer.sanitize(
            loadedProject,
            reducedMotion: accessibilityReduceMotion
        )
        let sanitizedProject = sanitizationResult.project
        project = sanitizedProject
        prompt = sanitizedProject.promptHistory.last?.prompt ?? ""
        selectedStylePreset = nil
        currentProjectURL = url
        lastExportURL = existingOutputVideoURL(for: sanitizedProject)
        exportErrorMessage = nil
        projectFileErrorMessage = nil
        promptResolutionMessage = projectSanitizationMessage(for: sanitizationResult)
        resetPreviewTransport()
    }

    private func projectSanitizationMessage(for result: WallpaperProjectSanitizationResult) -> String? {
        guard result.madeChanges else {
            return nil
        }

        if result.invalidatedOutputVideo {
            return "Project settings were adjusted for current safety and export limits. Export again before setting as wallpaper."
        }

        return "Project settings were adjusted for current safety and export limits."
    }

    private func openLibraryEntry(_ entry: ProjectLibraryEntry) {
        do {
            let loadedProject = try assetLibrary.load(entry)
            loadProject(loadedProject, from: entry.projectURL)
        } catch {
            projectFileErrorMessage = error.localizedDescription
        }
    }

    private func autosaveCurrentProject() {
        do {
            let savedURL = try assetLibrary.save(project)
            currentProjectURL = savedURL
            projectFileErrorMessage = nil
            refreshLibraryEntries()
        } catch {
            projectFileErrorMessage = error.localizedDescription
        }
    }

    private func refreshLibraryEntries() {
        do {
            libraryEntries = try assetLibrary.listProjects()
            projectFileErrorMessage = nil
        } catch {
            libraryEntries = []
            projectFileErrorMessage = error.localizedDescription
        }
    }

    private func deleteLibraryEntry(_ entry: ProjectLibraryEntry) {
        do {
            try assetLibrary.delete(entry)
            entryPendingDeletion = nil
            if currentProjectURL == entry.projectURL {
                currentProjectURL = nil
                lastExportURL = nil
            }
            refreshLibraryEntries()
        } catch {
            entryPendingDeletion = nil
            projectFileErrorMessage = error.localizedDescription
        }
    }

    private func cleanupLibraryAssets() {
        do {
            let report = try assetLibrary.cleanupOrphanedAssets()
            promptResolutionMessage = "Removed \(report.removedAssetCount) orphaned generated asset(s)."
            projectFileErrorMessage = nil
            refreshLibraryEntries()
        } catch {
            projectFileErrorMessage = error.localizedDescription
        }
    }

    private func updateThumbnailForCurrentProject() {
        do {
            let thumbnailURL = try assetLibrary.thumbnailURL(for: project)
            try GenerativeThumbnailRenderer.renderPNG(project: project, to: thumbnailURL)
            project.assets.thumbnailPath = thumbnailURL.path
        } catch {
            project.assets.thumbnailPath = nil
            projectFileErrorMessage = error.localizedDescription
        }
    }

    private func thumbnailImage(for entry: ProjectLibraryEntry) -> NSImage? {
        guard let thumbnailPath = entry.thumbnailPath else {
            return nil
        }
        return NSImage(contentsOfFile: thumbnailPath)
    }

    private func existingOutputVideoURL(for entry: ProjectLibraryEntry) -> URL? {
        guard let outputVideoPath = entry.outputVideoPath else {
            return nil
        }

        let url = URL(fileURLWithPath: outputVideoPath)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    private var defaultProjectFilename: String {
        let title = project.visualIntent?.title
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let baseName = (title?.isEmpty == false ? title : nil) ?? "VideoWallpaper-\(project.seed)"
        return "\(baseName).\(WallpaperProjectFileStore.fileExtension)"
    }

    private func existingOutputVideoURL(for project: WallpaperProject) -> URL? {
        guard let outputVideoPath = project.assets.outputVideoPath else {
            return nil
        }

        let url = URL(fileURLWithPath: outputVideoPath)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    private func startManualExport() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.mpeg4Movie]
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        panel.nameFieldStringValue = "VideoWallpaper-\(project.seed).mp4"

        guard panel.runModal() == .OK, let outputURL = panel.url else {
            return
        }

        startExport(to: outputURL)
    }

    private func startLibraryExport() {
        do {
            startExport(to: try assetLibrary.videoURL(for: project))
        } catch {
            exportErrorMessage = error.localizedDescription
        }
    }

    private func startExport(to outputURL: URL) {
        stopSeamPreview()
        isExporting = true
        exportProgress = 0
        exportErrorMessage = nil
        lastExportURL = nil

        let exportProject = project
        exportTask = Task {
            do {
                let exportedURL = try await GenerativeVideoExporter.export(project: exportProject, to: outputURL) { progress in
                    Task { @MainActor in
                        exportProgress = progress
                    }
                }

                project.assets.outputVideoPath = exportedURL.path
                project.updatedAt = Date()
                lastExportURL = exportedURL
                exportProgress = 1
                autosaveCurrentProject()
            } catch is CancellationError {
                exportErrorMessage = "Export cancelled."
                exportProgress = 0
                try? FileManager.default.removeItem(at: outputURL)
            } catch {
                exportErrorMessage = error.localizedDescription
            }
            isExporting = false
            exportTask = nil
        }
    }

    private func cancelExport() {
        exportTask?.cancel()
    }
}

private enum PromptResolutionResult {
    case success(
        intent: VisualIntent,
        renderParameters: RenderParameters,
        exportSettings: ExportSettings
    )
    case failure(Error)
}

private extension UTType {
    static var videoWallpaperProject: UTType {
        UTType(exportedAs: WallpaperProjectFileStore.contentTypeIdentifier)
    }
}

private struct SliderRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                Text(value, format: .number.precision(.fractionLength(2)))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range)
        }
    }
}
