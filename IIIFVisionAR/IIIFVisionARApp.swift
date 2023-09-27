//
//  IIIFVisionARApp.swift
//  IIIFVisionAR
//
//  Created by Henry Huang on 8/20/23.
//

import SwiftUI
import IIIFImageEntity

@main
struct IIIFVisionARApp: App {
    var body: some Scene {
        WindowGroup {
            ManifestContentView()
        }
        .windowStyle(.plain)


        WindowGroup(id: "CompoundImageVolume") {
            CompoundImageVolumetric()
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 2.2, height: 1.418, depth: 1.418, in: .meters)

        ImmersiveSpace(id: "SingleImage") {
            SingleImageRealityView()
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
