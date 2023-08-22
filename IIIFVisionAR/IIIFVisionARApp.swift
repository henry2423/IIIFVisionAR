//
//  IIIFVisionARApp.swift
//  IIIFVisionAR
//
//  Created by Henry Huang on 8/20/23.
//

import SwiftUI

@main
struct IIIFVisionARApp: App {
    var body: some Scene {
        WindowGroup {
            ManifestContentView()
        }
        .windowStyle(.plain)

        ImmersiveSpace(id: "SingleImage") {
            SingleImageImmersiveView()
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)

        ImmersiveSpace(id: "CompoundImage") {
            CompoundImageRealityView()
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }

    init() {
        // Register all the custom components and systems that the app uses.
        RotationComponent.registerComponent()
        RotationSystem.registerSystem()
    }
}
