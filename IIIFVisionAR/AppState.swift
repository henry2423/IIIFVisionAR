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

    private(set) var viewState = IIIFViewState.none

    func openIIIFItem(_ iiifItem: IIIFItem) {
        // Close iiifItem if needed
        closeIIIFItem()

        // Show SingleImageView if only one url
        if iiifItem.urls.count == 1 {
            viewState = .openImmersiveSpace(id: "SingleImage", iiifItem: iiifItem)
        }
        // Show CompoundImageView in Volumetric if < 2x2
        else if iiifItem.width <= 1 && iiifItem.height <= 2 {
            viewState = .openWindow(id: "CompoundImageVolume", iiifItem: iiifItem)
        }
        // Show CompoundImageView in Immersive Space if > 2x2x2
        else {
            viewState = .openImmersiveSpace(id: "CompoundImage", iiifItem: iiifItem)
        }
    }

    func closeIIIFItem() {
        switch viewState {
        case .openImmersiveSpace(let id, _):
            viewState = .closeImmersiveSpace(id: id)
        case .openWindow(let id, _):
            viewState = .closeWindow(id: id)
        case .closeImmersiveSpace, .closeWindow, .none:
            break
        }
    }
}
