//
//  SingleImageImmersiveView.swift
//  IIIFVisionAR
//
//  Created by Henry Huang on 8/20/23.
//

import SwiftUI
import RealityKit

struct SingleImageImmersiveView: View {
    @State private var entityObject: InteractiveObject?

    var body: some View {
        contentView
            .task {
                do {
                    let entityModel = try await ImageEntityGenerator.singleImagePlane(image_url: Bundle.main.url(forResource: "Hollywood", withExtension: "jpg")!, width: 2.261, height: 2.309)
                    entityObject = .init(entity: entityModel)
                } catch {
                    fatalError(error.localizedDescription)
                }
            }
    }

    @ViewBuilder
    private var contentView: some View {
        if let entityObject {
            SingleImageRealityView(entityObject: entityObject)
        } else {
            ProgressView()
        }
    }
}
