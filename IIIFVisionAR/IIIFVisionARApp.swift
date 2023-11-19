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
                    case .openImmersiveSpace(let id):
                        Task {
                            await openImmersiveSpace(id: id)
                        }
                    case .openWindow(let id):
                        openWindow(id: id)
                    case .closeImmersiveSpace:
                        Task {
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

        ImmersiveSpace(id: "SingleImage") {
            SingleImageRealityView(entityObject: SingleImageEntity(width: 2.261, height: 2.309, imageURL: Bundle.main.url(forResource: "Hollywood", withExtension: "jpg")!))
                .environment(appState)
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
        
        // MARK: CompoundImage

        WindowGroup(id: "CompoundImageVolume", for: IIIFItem.self) { $iiifItem in
            if let iiifItem {
                CompoundImageVolumetric(entityObject: CompoundImageEntity(width: iiifItem.width,
                                                                          height: iiifItem.height,
                                                                          imageURLPairs: iiifItem.urls.buildPagePairs()))
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
