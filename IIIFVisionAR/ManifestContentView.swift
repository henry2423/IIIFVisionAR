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

    var body: some View {
        NavigationStack {
            VStack {
                if isImmersiveSpaceOpened {
                    Button("Close the IIIF") {
                        Task {
                            await dismissImmersiveSpace()
                            isImmersiveSpaceOpened = false
                        }
                    }
                } else {
                    Button("Present IIIF in Immersive Space") {
                        Task {
                            await openImmersiveSpace(id: "SingleImage")
                            isImmersiveSpaceOpened = true
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ManifestContentView()
}
