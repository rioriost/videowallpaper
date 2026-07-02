//
//  VisualIntentProvider.swift
//  RioVideoWallpaper
//

import Foundation

struct VisualIntentRequest: Equatable {
    var prompt: String
    var seed: UInt64
    var currentIntent: VisualIntent?
    var capabilities: RendererCapabilities
}

struct LocalVisualIntentProvider {
    func intent(for request: VisualIntentRequest) -> VisualIntent {
        let prompt = request.prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        if let currentIntent = request.currentIntent,
           let editedIntent = VisualIntentCommandEditor.intent(currentIntent, applying: prompt) {
            return editedIntent.withSupportedRendererFamily(in: request.capabilities)
        }

        return PromptInterpreter.interpret(prompt, seed: request.seed)
            .withSupportedRendererFamily(in: request.capabilities)
    }
}

extension VisualIntent {
    func withSupportedRendererFamily(in capabilities: RendererCapabilities) -> VisualIntent {
        guard !capabilities.supportedRendererFamilies.contains(rendererFamily) else {
            return self
        }

        var adjustedIntent = self
        adjustedIntent.rendererFamily = capabilities.rendererFamily
        return adjustedIntent
    }
}
