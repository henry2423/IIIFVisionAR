//
//  ManifestListView.swift
//  IIIFVisionAR
//
//  Created by Henry Huang on 11/19/23.
//

import SwiftUI

struct ManifestListView: View {
    var body: some View {
        NavigationStack {
            List(iiifItems) { iiifItem in
                NavigationLink {
                    ManifestContentView()
                } label: {
                    Text(iiifItem.itemName)
                }
            }
            .navigationTitle("IIIF Demo")
        }
    }

    private let iiifItems = [
        IIIFItem(itemName: "Hollywood", width: 2.261, height: 2.309, urls: [Bundle.main.url(forResource: "Hollywood", withExtension: "jpg")!]),
        IIIFItem(itemName: "Love",
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
                 ]),
    ]
}

#Preview {
    ManifestListView()
}
