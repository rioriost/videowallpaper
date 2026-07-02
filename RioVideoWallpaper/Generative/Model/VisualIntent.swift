//
//  VisualIntent.swift
//  RioVideoWallpaper
//

import Foundation

struct VisualIntent: Codable, Equatable {
    var schemaVersion: Int
    var title: String
    var summary: String
    var moodTags: [String]
    var rendererFamily: RendererFamily
    var palette: Palette
    var composition: Composition
    var motion: Motion
    var elements: Elements
    var styleWeights: StyleWeights
    var safety: Safety
    var seedHint: String

    struct Palette: Codable, Equatable {
        var hueBaseDegrees: Double
        var hueSpreadDegrees: Double
        var saturation: Double
        var brightness: Double
        var contrast: Double
        var warmth: Double
    }

    struct Composition: Codable, Equatable {
        var density: Double
        var symmetry: Double
        var depth: Double
        var centerPull: Double
        var negativeSpace: Double
    }

    struct Motion: Codable, Equatable {
        var loopSeconds: Double
        var speed: Double
        var turbulence: Double
        var regularity: Double
        var trailLength: Double
    }

    struct Elements: Codable, Equatable {
        var particleAmount: Double
        var lineAmount: Double
        var objectAmount: Double
        var gridAmount: Double
        var glowAmount: Double
    }

    struct StyleWeights: Codable, Equatable {
        var sciFi: Double
        var fantasy: Double
        var nostalgia: Double
        var virtual: Double
        var futureCity: Double
        var cosmic: Double
    }

    struct Safety: Codable, Equatable {
        var flashIntensity: Double
        var motionIntensity: Double
    }
}
