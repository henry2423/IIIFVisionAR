//
//  File.swift
//  
//
//  Created by Henry Huang on 9/8/23.
//

import SwiftUI
import RealityKit
import Foundation

public protocol IIIFImageEntityProtocol: Entity {
    func loadInitialResource() async throws
    func turnToNextPage()
    func turnToPreviousPage()
    #if os(visionOS)
    func handleDragGesture(_ value: EntityTargetValue<DragGesture.Value>)
    func handleDragGestureEnded()
    func handleRotationGesture(_ value: EntityTargetValue<RotateGesture.Value>)
    func handleRotationGestureEnded()
    #endif
}
