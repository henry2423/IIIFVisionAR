//
//  IIIFVisionARApp.swift
//  IIIFVisionAR
//
//  Created by Henry Huang on 8/20/23.
//

import SwiftUI
import IIIFImageEntity

struct IIIFItem: Codable, Hashable, Identifiable {
    var id = UUID()
    let itemName: String
    let width: Float
    let height: Float
    let urls: [URL]
}

@main
struct IIIFVisionARApp: App {
    var body: some Scene {
        WindowGroup {
            ManifestListView()
                .environment(appState)
                // Call ImmersiveSpace/Window system call when viewState changed
                .onChange(of: appState.viewState) { _, viewState in
                    switch viewState {
                    case .openImmersiveSpace(let id, let iiifItem):
                        Task { @MainActor in
                            await openImmersiveSpace(id: id, value: iiifItem)
                        }
                    case .openWindow(let id, let iiifItem):
                        openWindow(id: id, value: iiifItem)
                    case .closeImmersiveSpace:
                        Task { @MainActor in
                            await dismissImmersiveSpace()
                        }
                    case .closeWindow(let id):
                        dismissWindow(id: id)
                    case .none:
                        break
                    }
                }
        }
        .windowStyle(.plain)

        // MARK: SingleImage

        ImmersiveSpace(id: "SingleImage", for: IIIFItem.self) { $iiifItem in
            if let iiifItem {
                SingleImageRealityView(entityObject: SingleImageEntity(width: iiifItem.width,
                                                                       height: iiifItem.height,
                                                                       imageURL: iiifItem.urls.first!))
                    .environment(appState)
            }
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
        
        // MARK: CompoundImage

        WindowGroup(id: "CompoundImageVolume", for: IIIFItem.self) { $iiifItem in
            if let iiifItem {
                let zOffset = (2 - iiifItem.height) / 2
                CompoundImageVolumetric(entityObject: CompoundImageEntity(width: iiifItem.width,
                                                                          height: iiifItem.height,
                                                                          imageURLPairs: iiifItem.urls.buildPagePairs()),
                                        yOffset: -0.8, // To put the object in the middle height of the box
                                        zOffset: zOffset) // To put the object in the middle depth of the box
                .environment(appState)
            }
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 2, height: 2, depth: 2, in: .meters)

        ImmersiveSpace(id: "CompoundImage", for: IIIFItem.self) { $iiifItem in
            if let iiifItem {
                CompoundImageRealityView(entityObject: CompoundImageEntity(width: iiifItem.width,
                                                                           height: iiifItem.height,
                                                                           imageURLPairs: iiifItem.urls.buildPagePairs()))
                .environment(appState)
            }
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }

    init() {
        // Register all the custom components and systems that the app uses.
        RotationComponent.registerComponent()
        RotationSystem.registerSystem()
    }

    @State private var appState = AppState()
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
}
