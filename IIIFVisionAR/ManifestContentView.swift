//
//  ContentView.swift
//  IIIFVisionAR
//
//  Created by Henry Huang on 8/20/23.
//

import SwiftUI

struct ManifestContentView: View {
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @State private var isImmersiveSpaceOpened = false
    @State private var isShowingVolumetric = false

    var body: some View {
        NavigationStack {
            VStack {
                SpaceToggle(
                    title: "Present Single IIIF in Immersive Space",
                    id: "SingleImage",
                    isShowing: $isImmersiveSpaceOpened)

                SpaceToggle(
                    title: "Present Compound IIIF in Immersive Space",
                    id: "CompoundImage",
                    isShowing: $isImmersiveSpaceOpened)

                WindowToggle(
                    title: "Present Compound IIIF in Volumetric Space",
                    id: "CompoundImageVolume",
                    isShowing: $isShowingVolumetric)
            }
        }
    }
}

/// A toggle that activates or deactivates a window with
/// the specified identifier.
private struct WindowToggle: View {
    var title: String
    var id: String
    @Binding var isShowing: Bool

    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        Toggle(title, isOn: $isShowing)
            .onChange(of: isShowing) { wasShowing, isShowing in
                if isShowing {
                    openWindow(id: id)
                } else {
                    dismissWindow(id: id)
                }
            }
            .toggleStyle(.button)
    }
}

/// A toggle that activates or deactivates the immersive space with
/// the specified identifier.
private struct SpaceToggle: View {
    var title: String
    var id: String
    @Binding var isShowing: Bool

    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    var body: some View {
        Toggle(title, isOn: $isShowing)
            .onChange(of: isShowing) { wasShowing, isShowing in
                Task {
                    if isShowing {
                        await openImmersiveSpace(id: id)
                    } else {
                        await dismissImmersiveSpace()
                    }
                }
            }
            .toggleStyle(.button)
    }
}


#Preview {
    ManifestContentView()
}
