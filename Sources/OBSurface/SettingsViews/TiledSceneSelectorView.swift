//
//  TiledSceneSelectorView.swift
//  
//
//  Created by Kit Transue on 2023-05-10.
//  Copyright © 2023 Kit Transue
//  SPDX-License-Identifier: Apache-2.0
//

import SwiftUI
import OBSWebsocket

struct TiledSceneSelectorView: View {
    @State private var scenes: [OBSScene]
    @Binding var selected: OBSScene

    
    init(model: StudioModel, selected: Binding<OBSScene>) {
        self.model = model
        scenes = [model.tiled]
        self._selected = selected
    }
    
    @ObservedObject var model: StudioModel
    var body: some View {
        VStack(alignment: .leading) {
            Picker("Managed Scene", selection: $selected) {
                ForEach(scenes) { scene in
                    Text(scene.name)
                        .tag(scene)
                }
            }
        }
        .task {
            let current = model.tiled
            var scenes = await model.listScenes()
            if  !scenes.contains(where: {$0 == current}) {
                scenes.insert(current, at: 0)
            }
            self.scenes = scenes
        }
    }
}

//struct TiledSceneSelectorView_Previews: PreviewProvider {
//    static var previews: some View {
//        TiledSceneSelectorView()
//    }
//}
