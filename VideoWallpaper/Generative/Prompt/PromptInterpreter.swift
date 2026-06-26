//
//  PromptInterpreter.swift
//  VideoWallpaper
//

import Foundation

enum PromptInterpreter {
    static func interpret(_ prompt: String, seed: UInt64) -> VisualIntent {
        let normalized = prompt.normalizedForPromptMatching
        let fallbackTitle = normalized.isEmpty ? "Field Lines" : prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let palette = makePalette(from: normalized, seed: seed)
        let motion = makeMotion(from: normalized)
        let composition = makeComposition(from: normalized)
        let elements = makeElements(from: normalized)
        let styleWeights = makeStyleWeights(from: normalized)
        let rendererFamily = makeRendererFamily(from: normalized, elements: elements, styleWeights: styleWeights)

        return VisualIntent(
            schemaVersion: 1,
            title: String(fallbackTitle.prefix(80)),
            summary: makeSummary(from: normalized, rendererFamily: rendererFamily),
            moodTags: makeMoodTags(from: normalized),
            rendererFamily: rendererFamily,
            palette: palette,
            composition: composition,
            motion: motion,
            elements: elements,
            styleWeights: styleWeights,
            safety: VisualIntent.Safety(
                flashIntensity: normalized.matches(any: ["flash", "strobe", "点滅", "フラッシュ"]) ? 0.35 : 0.15,
                motionIntensity: min(1.0, motion.speed * 0.55 + motion.turbulence * 0.25)
            ),
            seedHint: "\(seed)"
        )
    }

    static func makeFieldLinesParameters(from intent: VisualIntent) -> FieldLinesParameters {
        IntentToRenderParametersMapper.fieldLinesParameters(from: intent)
    }

    static func exportSettings(_ current: ExportSettings, applying intent: VisualIntent) -> ExportSettings {
        IntentToRenderParametersMapper.exportSettings(current, applying: intent)
    }

    private static func makeRendererFamily(
        from prompt: String,
        elements: VisualIntent.Elements,
        styleWeights: VisualIntent.StyleWeights
    ) -> RendererFamily {
        if prompt.matches(any: [
            "closed flow", "flow field", "curl flow", "curl noise", "magnetic stream",
            "particle current", "streamlines", "vector field",
            "流線", "ベクトル場", "磁力線", "流れる粒子", "閉じた流れ"
        ]) {
            return .closedFlowParticles
        }
        if prompt.matches(any: [
            "sdf tunnel", "raymarch tunnel", "raymarched tunnel", "distance field tunnel",
            "shader tunnel", "repeating corridor", "hyperspace grid",
            "SDFトンネル", "レイマーチ", "距離場トンネル", "反復空間", "回廊"
        ]) {
            return .sdfTunnel
        }
        if prompt.matches(any: [
            "feedback synth", "video synth", "hydra", "recursive echo", "feedback spiral",
            "analog video", "scanline feedback",
            "フィードバック", "ビデオシンセ", "再帰", "残像の渦", "アナログビデオ"
        ]) {
            return .feedbackSynth
        }
        if prompt.matches(any: [
            "guilloche", "rose engine", "banknote", "security print", "ornamental line",
            "spirograph rosette", "harmonic pen",
            "ギロシェ", "紙幣模様", "装飾線", "ローズエンジン", "精密な線"
        ]) {
            return .guillocheRose
        }
        if prompt.matches(any: [
            "instanced geometry", "geometry array", "triangle field", "glyph field",
            "modular icons", "geometric particles",
            "インスタンス", "幾何学配列", "三角形の群れ", "記号の群れ", "ジオメトリ"
        ]) {
            return .instancedGeometry
        }
        if prompt.matches(any: [
            "metaball", "metaballs", "liquid blobs", "soft blobs", "implicit field",
            "merging bubbles", "organic bubbles",
            "メタボール", "液体の塊", "柔らかい泡", "融合する泡", "暗黙曲面"
        ]) {
            return .metaballField
        }
        if prompt.matches(any: [
            "penrose", "aperiodic tiling", "aperiodic", "golden ratio tiling",
            "rhombus tiling", "star tiling",
            "ペンローズ", "非周期タイル", "黄金比タイル", "菱形タイル", "星形タイル"
        ]) {
            return .penroseTiling
        }
        if prompt.matches(any: [
            "wave terrain", "height field", "heightfield", "topographic lines",
            "topographic map", "contour terrain", "wave landscape",
            "波の地形", "高さ場", "等高線地形", "地形線", "波面"
        ]) {
            return .waveTerrain
        }
        if prompt.matches(any: [
            "hex grid", "hexagon", "hexagonal", "honeycomb", "hex lattice", "circuit panel",
            "sci-fi panel", "sci fi panel", "cellular tiles", "modular grid", "modular surface",
            "六角形", "六角格子", "ハニカム", "蜂の巣", "回路パネル", "セルタイル", "モジュール格子"
        ]) {
            return .hexPulseLattice
        }
        if prompt.matches(any: [
            "interference", "moire", "moiré", "diffraction", "quasicrystal", "crystal",
            "sacred geometry", "lattice", "harmonic pattern",
            "干渉", "モアレ", "回折", "準結晶", "結晶", "幾何学", "格子"
        ]) {
            return .interferenceField
        }
        if prompt.matches(any: [
            "kaleidoscope", "mandala", "stained glass", "radial symmetry", "ornament",
            "psychedelic", "op art", "flower geometry", "mirror symmetry",
            "万華鏡", "曼荼羅", "マンダラ", "ステンドグラス", "放射対称", "対称模様", "装飾", "サイケ"
        ]) {
            return .kaleidoscope
        }
        if prompt.matches(any: [
            "voronoi", "mosaic", "tessellation", "tessellated", "bubbles", "soap bubbles",
            "cell boundaries", "territory map", "organic islands", "crystal map",
            "ボロノイ", "モザイク", "テセレーション", "泡", "気泡", "セル境界", "領域", "島模様"
        ]) {
            return .voronoiFlow
        }
        if prompt.matches(any: [
            "reaction diffusion", "reaction-diffusion", "turing pattern", "gray scott", "gray-scott",
            "coral", "zebra stripes", "leopard spots", "biological texture", "chemical waves",
            "反応拡散", "チューリングパターン", "珊瑚", "サンゴ", "縞模様", "斑点", "化学波", "生物模様"
        ]) {
            return .reactionDiffusion
        }
        if prompt.matches(any: [
            "plasma", "lava lamp", "electric aura", "psychedelic color", "retro demoscene",
            "liquid light", "color field", "glowing wash", "lava",
            "プラズマ", "ラバランプ", "電気", "オーラ", "サイケデリック", "色面", "溶岩", "発光する色"
        ]) {
            return .plasmaField
        }
        if prompt.matches(any: [
            "warp tunnel", "hyperspace", "wormhole", "interplanetary tunnel", "space travel tunnel",
            "star gate", "stargate", "vortex tunnel", "speed tunnel", "light tunnel",
            "ワープ", "ハイパースペース", "ワームホール", "光のトンネル", "渦のトンネル"
        ]) {
            return .harmonicTunnel
        }
        if prompt.matches(any: [
            "lissajous", "oscilloscope", "laser line", "laser lines", "spirograph",
            "parametric curve", "parametric curves", "woven light", "signal trace", "xy trace",
            "リサージュ", "オシロスコープ", "レーザー", "スピログラフ", "パラメトリック曲線", "光の織物", "信号波形"
        ]) {
            return .lissajousWeave
        }
        if prompt.matches(any: [
            "superformula", "super formula", "alien flower", "organic emblem", "morphing shell",
            "mathematical flower", "radial silhouette", "ornate medallion", "closed contour",
            "スーパー式", "スーパーフォーミュラ", "異星の花", "有機的な紋章", "数式の花", "貝殻", "輪郭線"
        ]) {
            return .superformulaMorph
        }
        if prompt.matches(any: [
            "phyllotaxis", "sunflower spiral", "seed spiral", "golden angle",
            "organic bloom", "botanical fireworks", "flower burst", "luminous spores",
            "フィロタキシス", "葉序", "ひまわり", "種の螺旋", "黄金角", "花火", "胞子", "開花"
        ]) {
            return .phyllotaxisBloom
        }
        if prompt.matches(any: [
            "periodic noise", "fluid", "liquid", "marble", "water", "caustic", "fire",
            "terrain", "topographic", "contour", "organic noise", "flowing ink",
            "流体", "液体", "水", "波紋", "マーブル", "大理石", "炎", "地形", "等高線", "有機的"
        ]) {
            return .periodicNoise
        }
        if prompt.matches(any: [
            "cellular automata", "cellular", "automata", "life game", "game of life",
            "cell grid", "pixel organism", "digital coral",
            "セル", "細胞", "オートマトン", "ライフゲーム", "ピクセル", "デジタル珊瑚"
        ]) {
            return .cyclicAutomata
        }
        if prompt.matches(any: [
            "swarm", "flock", "firefly", "fireflies", "school of fish", "fish school",
            "birds", "drone formation", "particle organism", "migrating lights",
            "群れ", "蛍", "ホタル", "魚群", "鳥群", "ドローン群", "移動する光"
        ]) {
            return .agentSwarm
        }
        if prompt.matches(any: [
            "planet", "orbital", "orbit", "ring", "satellite", "portal", "interplanetary",
            "惑星", "軌道", "衛星", "リング", "星間", "惑星間", "ポータル"
        ]) {
            return .orbital
        }
        if prompt.matches(any: [
            "nebula", "mist", "fog", "cloud", "smoke", "haze", "atmosphere", "dream",
            "星雲", "霧", "雲", "煙", "霞", "夢", "大気"
        ]) {
            return .softVolumetric
        }
        if prompt.matches(any: [
            "city", "urban", "grid", "cyberpunk", "matrix", "data highway", "architecture",
            "都市", "街", "グリッド", "サイバー", "建築", "データ"
        ]) || elements.gridAmount > 0.5 || styleWeights.futureCity > 0.7 {
            return .gridCity
        }
        return .fieldLines
    }

    private static func makePalette(from prompt: String, seed: UInt64) -> VisualIntent.Palette {
        let hueBase: Double
        if prompt.matches(any: ["red", "crimson", "scarlet", "赤", "紅"]) {
            hueBase = 350
        } else if prompt.matches(any: ["orange", "amber", "sunset", "夕焼け", "琥珀"]) {
            hueBase = 28
        } else if prompt.matches(any: ["yellow", "gold", "黄金", "金色"]) {
            hueBase = 48
        } else if prompt.matches(any: ["green", "emerald", "forest", "緑", "森"]) {
            hueBase = 135
        } else if prompt.matches(any: ["cyan", "aqua", "turquoise", "水色", "シアン"]) {
            hueBase = 185
        } else if prompt.matches(any: ["blue", "azure", "ocean", "sky", "青", "海", "空"]) {
            hueBase = 215
        } else if prompt.matches(any: ["purple", "violet", "magenta", "neon", "紫", "マゼンタ", "ネオン"]) {
            hueBase = 285
        } else {
            hueBase = Double(seed % 360)
        }

        let calm = prompt.matches(any: ["calm", "soft", "quiet", "gentle", "静か", "穏やか", "淡い"])
        let vivid = prompt.matches(any: ["vivid", "bright", "electric", "neon", "鮮やか", "明るい", "発光"])
        let dark = prompt.matches(any: ["dark", "night", "shadow", "midnight", "暗い", "夜", "深夜"])
        let pastel = prompt.matches(any: ["pastel", "dreamy", "mist", "パステル", "夢", "霧"])

        return VisualIntent.Palette(
            hueBaseDegrees: hueBase,
            hueSpreadDegrees: vivid ? 70 : (calm ? 22 : 42),
            saturation: pastel ? 0.48 : (vivid ? 0.95 : 0.78),
            brightness: dark ? 0.72 : (vivid ? 1.0 : 0.88),
            contrast: vivid ? 0.82 : 0.55,
            warmth: hueBase < 80 || hueBase > 330 ? 0.8 : 0.35
        )
    }

    private static func makeMotion(from prompt: String) -> VisualIntent.Motion {
        let fast = prompt.matches(any: ["fast", "rapid", "storm", "speed", "速い", "高速", "嵐"])
        let slow = prompt.matches(any: ["slow", "calm", "gentle", "float", "ゆっくり", "静か", "漂う"])
        let turbulent = prompt.matches(any: ["chaos", "turbulent", "storm", "wild", "chaotic", "混沌", "荒い"])
        let smooth = prompt.matches(any: ["smooth", "minimal", "simple", "clean", "滑らか", "ミニマル"])
        let longTrail = prompt.matches(any: ["trail", "comet", "afterimage", "long exposure", "軌跡", "彗星", "残像"])

        return VisualIntent.Motion(
            loopSeconds: slow ? 16 : (fast ? 6 : 10),
            speed: fast ? 1.65 : (slow ? 0.48 : 1.0),
            turbulence: turbulent ? 1.75 : (smooth ? 0.45 : 1.0),
            regularity: smooth ? 0.82 : (turbulent ? 0.25 : 0.55),
            trailLength: longTrail ? 0.95 : (fast ? 0.62 : 0.48)
        )
    }

    private static func makeComposition(from prompt: String) -> VisualIntent.Composition {
        let dense = prompt.matches(any: ["dense", "busy", "many", "crowded", "密", "たくさん", "多い"])
        let sparse = prompt.matches(any: ["sparse", "minimal", "simple", "empty", "余白", "少ない", "ミニマル"])
        let deep = prompt.matches(any: ["deep", "space", "galaxy", "cosmic", "depth", "宇宙", "銀河", "奥行"])
        let symmetrical = prompt.matches(any: ["symmetry", "mandala", "radial", "flower", "対称", "曼荼羅", "花"])

        return VisualIntent.Composition(
            density: dense ? 0.9 : (sparse ? 0.28 : 0.56),
            symmetry: symmetrical ? 0.82 : 0.48,
            depth: deep ? 0.9 : 0.52,
            centerPull: symmetrical ? 0.82 : 0.58,
            negativeSpace: sparse ? 0.76 : 0.32
        )
    }

    private static func makeElements(from prompt: String) -> VisualIntent.Elements {
        let particleHeavy = prompt.matches(any: ["stars", "dust", "spark", "particle", "星", "粒子", "火花"])
        let lineHeavy = prompt.matches(any: ["line", "wave", "ribbon", "stream", "線", "波", "リボン"])
        let glow = prompt.matches(any: ["glow", "light", "neon", "bloom", "発光", "光", "ネオン"])

        return VisualIntent.Elements(
            particleAmount: particleHeavy ? 0.88 : 0.48,
            lineAmount: lineHeavy ? 0.88 : 0.62,
            objectAmount: 0.0,
            gridAmount: prompt.matches(any: ["grid", "cyber", "matrix", "グリッド", "サイバー"]) ? 0.65 : 0.0,
            glowAmount: glow ? 0.9 : 0.58
        )
    }

    private static func makeStyleWeights(from prompt: String) -> VisualIntent.StyleWeights {
        VisualIntent.StyleWeights(
            sciFi: prompt.matches(any: ["sci-fi", "scifi", "cyber", "neon", "サイバー", "SF"]) ? 0.9 : 0.45,
            fantasy: prompt.matches(any: ["magic", "fantasy", "fairy", "魔法", "幻想"]) ? 0.85 : 0.28,
            nostalgia: prompt.matches(any: ["retro", "vapor", "nostalgia", "レトロ", "懐かしい"]) ? 0.82 : 0.22,
            virtual: prompt.matches(any: ["virtual", "digital", "matrix", "デジタル", "仮想"]) ? 0.82 : 0.45,
            futureCity: prompt.matches(any: ["city", "urban", "future", "都市", "未来"]) ? 0.72 : 0.2,
            cosmic: prompt.matches(any: ["space", "galaxy", "nebula", "cosmic", "宇宙", "銀河", "星雲"]) ? 0.9 : 0.32
        )
    }

    private static func makeMoodTags(from prompt: String) -> [String] {
        var tags: [String] = []
        if prompt.matches(any: ["calm", "quiet", "静か", "穏やか"]) { tags.append("calm") }
        if prompt.matches(any: ["neon", "cyber", "ネオン", "サイバー"]) { tags.append("neon") }
        if prompt.matches(any: ["space", "galaxy", "宇宙", "銀河"]) { tags.append("cosmic") }
        if prompt.matches(any: ["magic", "fantasy", "魔法", "幻想"]) { tags.append("fantasy") }
        if prompt.matches(any: ["minimal", "simple", "ミニマル"]) { tags.append("minimal") }
        return tags.isEmpty ? ["ambient"] : tags
    }

    private static func makeSummary(from prompt: String, rendererFamily: RendererFamily) -> String {
        if prompt.isEmpty {
            return "Ambient \(rendererFamily.displayName.lowercased()) wallpaper."
        }
        switch rendererFamily {
        case .fieldLines:
            return "Generated field-line wallpaper from prompt keywords."
        case .orbital:
            return "Generated orbital wallpaper from prompt keywords."
        case .softVolumetric:
            return "Generated soft volumetric wallpaper from prompt keywords."
        case .gridCity:
            return "Generated grid city wallpaper from prompt keywords."
        case .interferenceField:
            return "Generated interference-field wallpaper from prompt keywords."
        case .periodicNoise:
            return "Generated periodic-noise wallpaper from prompt keywords."
        case .cyclicAutomata:
            return "Generated cyclic-automata wallpaper from prompt keywords."
        case .agentSwarm:
            return "Generated agent-swarm wallpaper from prompt keywords."
        case .kaleidoscope:
            return "Generated kaleidoscope wallpaper from prompt keywords."
        case .voronoiFlow:
            return "Generated voronoi-flow wallpaper from prompt keywords."
        case .reactionDiffusion:
            return "Generated reaction-diffusion wallpaper from prompt keywords."
        case .plasmaField:
            return "Generated plasma-field wallpaper from prompt keywords."
        case .harmonicTunnel:
            return "Generated harmonic-tunnel wallpaper from prompt keywords."
        case .lissajousWeave:
            return "Generated lissajous-weave wallpaper from prompt keywords."
        case .phyllotaxisBloom:
            return "Generated phyllotaxis-bloom wallpaper from prompt keywords."
        case .hexPulseLattice:
            return "Generated hex-pulse-lattice wallpaper from prompt keywords."
        case .superformulaMorph:
            return "Generated superformula-morph wallpaper from prompt keywords."
        case .closedFlowParticles:
            return "Generated closed-flow-particles wallpaper from prompt keywords."
        case .sdfTunnel:
            return "Generated sdf-tunnel wallpaper from prompt keywords."
        case .feedbackSynth:
            return "Generated feedback-synth wallpaper from prompt keywords."
        case .guillocheRose:
            return "Generated guilloche-rose wallpaper from prompt keywords."
        case .instancedGeometry:
            return "Generated instanced-geometry wallpaper from prompt keywords."
        case .metaballField:
            return "Generated metaball-field wallpaper from prompt keywords."
        case .penroseTiling:
            return "Generated penrose-tiling wallpaper from prompt keywords."
        case .waveTerrain:
            return "Generated wave-terrain wallpaper from prompt keywords."
        }
    }

    private static func clamp(_ value: Double, _ lower: Double, _ upper: Double) -> Double {
        min(max(value, lower), upper)
    }
}

private extension String {
    var normalizedForPromptMatching: String {
        folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: .current)
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func matches(any keywords: [String]) -> Bool {
        keywords.contains { contains($0.normalizedForPromptMatching) }
    }
}
