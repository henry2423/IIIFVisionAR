//
//  ContentView.swift
//  IIIFVisionAR
//
//  Created by Henry Huang on 8/20/23.
//

import SwiftUI

struct ManifestContentView: View {
    private let iiifItem = IIIFItem(width: 1.105,
                                    height: 1.418,
                                    urls: [
                                        Bundle.main.url(forResource: "Love-1", withExtension: "jpg")!,
                                        Bundle.main.url(forResource: "Love-2", withExtension: "jpg")!,
                                        Bundle.main.url(forResource: "Love-3", withExtension: "jpg")!,
                                        Bundle.main.url(forResource: "Love-4", withExtension: "jpg")!,
                                        Bundle.main.url(forResource: "Love-5", withExtension: "jpg")!,
                                        Bundle.main.url(forResource: "Love-6", withExtension: "jpg")!,
                                        Bundle.main.url(forResource: "Love-7", withExtension: "jpg")!,
                                        Bundle.main.url(forResource: "Love-8", withExtension: "jpg")!,
                                    ])

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
                                    await openImmersiveSpace(id: "CompoundImage", value: iiifItem)
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
                            openWindow(id: "CompoundImageVolume", value: iiifItem)
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
