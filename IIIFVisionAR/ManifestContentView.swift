//
//  ContentView.swift
//  IIIFVisionAR
//
//  Created by Henry Huang on 8/20/23.
//

import SwiftUI

struct ManifestContentView: View {
    let iiifItem: IIIFItem

    var body: some View {
        VStack {
            Text(iiifItem.itemName)
            Button("Close IIIF Viewer") {
                Task {
                    appState.closeIIIFItem()
                }
            }
        }
        .onAppear {
            appState.openIIIFItem(iiifItem)
        }
        // Navigate back to previous page if IIIF Viewer closed
        .onChange(of: appState.viewState) { _, viewState in
            switch viewState {
            case .closeWindow, .closeImmersiveSpace:
                presentationMode.wrappedValue.dismiss()
            case .openImmersiveSpace, .openWindow, .none:
                break
            }
        }
    }

    @Environment(AppState.self) private var appState
    @Environment(\.presentationMode) var presentationMode
}

#Preview {
    ManifestContentView(iiifItem: IIIFItem(itemName: "Love",
                                           width: 1.105,
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
                                           ]))
}
