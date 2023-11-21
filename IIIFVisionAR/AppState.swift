//
//  AppState.swift
//  IIIFVisionAR
//
//  Created by Henry Huang on 11/19/23.
//

import Observation
import Foundation

@Observable
final class AppState {

    enum IIIFViewState: Equatable {
        case openImmersiveSpace(id: String, iiifItem: IIIFItem)
        case openWindow(id: String, iiifItem: IIIFItem)
        case closeImmersiveSpace(id: String)
        case closeWindow(id: String)
        case none
    }

    private(set) var iiifViewState = IIIFViewState.none

    func openIIIFItem(_ iiifItem: IIIFItem) {
        // Close iiifItem if needed
        closeIIIFItem()

        // Show SingleImageView if only one url
        if iiifItem.urls.count == 1 {
            iiifViewState = .openImmersiveSpace(id: "SingleImage", iiifItem: iiifItem)
        }
        // Show CompoundImageView in Volumetric if < 1x2 (The actual box width = iiifItem.width * 2 (Two page presented at the same time))
        else if iiifItem.width <= 1 && iiifItem.height <= 2 {
            iiifViewState = .openWindow(id: "CompoundImageVolume", iiifItem: iiifItem)
        }
        // Show CompoundImageView in Immersive Space if > 2x2x2
        else {
            iiifViewState = .openImmersiveSpace(id: "CompoundImage", iiifItem: iiifItem)
        }
    }

    func closeIIIFItem() {
        switch iiifViewState {
        case .openImmersiveSpace(let id, _):
            iiifViewState = .closeImmersiveSpace(id: id)
        case .openWindow(let id, _):
            iiifViewState = .closeWindow(id: id)
        case .closeImmersiveSpace, .closeWindow, .none:
            break
        }
    }
}
