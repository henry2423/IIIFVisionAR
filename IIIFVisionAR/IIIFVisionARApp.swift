//
//  IIIFVisionARApp.swift
//  IIIFVisionAR
//
//  Created by Henry Huang on 8/20/23.
//

import SwiftUI
import IIIFImageEntity

struct IIIFItem: Codable, Hashable {
    let width: Float
    let height: Float
    let urls: [URL]
}

@main
struct IIIFVisionARApp: App {
    var body: some Scene {
        WindowGroup {
            ManifestContentView()
        }
        .windowStyle(.plain)

        // MARK: SingleImage

        ImmersiveSpace(id: "SingleImage") {
            SingleImageRealityView(entityObject: SingleImageEntity(width: 2.261, height: 2.309, imageURL: Bundle.main.url(forResource: "Hollywood", withExtension: "jpg")!))
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
        
        // MARK: CompoundImage

        WindowGroup(id: "CompoundImageVolume", for: IIIFItem.self) { $iiifItem in
            if let iiifItem {
                CompoundImageVolumetric(entityObject: CompoundImageEntity(width: iiifItem.width,
                                                                          height: iiifItem.height,
                                                                          imageURLPairs: iiifItem.urls.buildPagePairs()))
            }
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 3, height: 3, depth: 3, in: .meters)

        ImmersiveSpace(id: "CompoundImage", for: IIIFItem.self) { $iiifItem in
            if let iiifItem {
                CompoundImageRealityView(entityObject: CompoundImageEntity(width: iiifItem.width,
                                                                           height: iiifItem.height,
                                                                           imageURLPairs: iiifItem.urls.buildPagePairs()))
            }
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }

    init() {
        // Register all the custom components and systems that the app uses.
        RotationComponent.registerComponent()
        RotationSystem.registerSystem()
    }
}
