//
//  ContentView.swift
//  IIIFVisionAR
//
//  Created by Henry Huang on 8/20/23.
//

import SwiftUI

struct ManifestContentView: View {
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        NavigationStack {
            VStack {
                Button("Present Solar System In New Immersive Space") {
                    Task {
                        await openImmersiveSpace(id: "SingleImage")
                    }
                }
//                NavigationLink {
//    //                ARContentView(avgWidth: viewModel.averageImageWidth,
//    //                              avgLength: viewModel.averageImageLength,
//    //                              image_urls: viewModel.imageEntities.compactMap { $0.localImageURL },
//    //                              currentIndex: selectedItem,
//    //                              title: viewModel.values[0],
//    //                              widthratio: viewModel.widthratio,
//    //                              heightratio: viewModel.heightratio)
//    //                .onAppear {
//    //                    AnalyticsEventService.shared.logEvent(.init(name: .itemARViewed, attributes: [
//    //                        "manifest_url": viewModel.sourceURLString
//    //                    ]))
//    //                }
//                    SingleImageRealityView()
//                } label: {
//                    ZStack(){
//                        Color.init(.systemBlue)
//                            .cornerRadius(10)
//                        HStack {
//                            Image(systemName: "arkit")
//                                .foregroundColor(.white)
//                            Text("View in Your Space")
//                                .foregroundColor(.white)
//                                .font(.system(size: 18, weight: .medium, design: .default))
//                        }
//                    }
//                    .frame(height: 50.0)
//                    .padding(EdgeInsets(top: 10, leading: 30, bottom: 10, trailing: 30))
//                }
            }
            .padding()
        }
    }
}

//#Preview {
//    ManifestContentView()
//}
