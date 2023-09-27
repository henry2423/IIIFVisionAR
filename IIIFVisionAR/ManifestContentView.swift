//
//  ContentView.swift
//  IIIFVisionAR
//
//  Created by Henry Huang on 8/20/23.
//

import SwiftUI

struct ManifestContentView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Toggle(isOn: $isImmersiveSpaceOpened, label: {
                    Text("Present Single IIIF in Immersive Space")
                        .onTapGesture {
                            Task {
                                if !isImmersiveSpaceOpened {
                                    await openImmersiveSpace(id: "SingleImage")
                                } else {
                                    await dismissImmersiveSpace()
                                }
                                isImmersiveSpaceOpened.toggle()
                            }
                        }
                })
                .toggleStyle(.button)

                Toggle(isOn: $isImmersiveSpaceOpened, label: {
                    Text("Present Compound IIIF in Immersive Space")
                        .onTapGesture {
                            Task {
                                if !isImmersiveSpaceOpened {
                                    await openImmersiveSpace(id: "CompoundImage")
                                } else {
                                    await dismissImmersiveSpace()
                                }
                                isImmersiveSpaceOpened.toggle()
                            }
                        }
                })
                .toggleStyle(.button)

                Toggle("Present Compound IIIF in Volumetric Space", isOn: $isShowingVolumetric)
                    .onChange(of: isShowingVolumetric) { _, isShowing in
                        if isShowing {
                            openWindow(id: "CompoundImageVolume")
                        } else {
                            dismissWindow(id: "CompoundImageVolume")
                        }
                    }
                    .toggleStyle(.button)
            }
        }
    }

    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @State private var isImmersiveSpaceOpened = false
    @State private var isShowingVolumetric = false
}


#Preview {
    ManifestContentView()
}
