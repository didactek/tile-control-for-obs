//
//  OBSurface.swift
//  
//
//  Created by Kit Transue on 2022-09-02.
//  Copyright © 2022 Kit Transue
//  SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

import DeftLog
import OBSAsyncAPI

let logger = DeftLog.logger(label: "com.didactek.surface")

@main
struct OBSurface: App {
    @ObservedObject
    private var studio: StudioModel
    
    @State private var surface: SurfaceController?
    @State private var path = [NavigationElement]()
    
    init() {
        DeftLog.settings = [
//            ("com.didactek.surface", .trace),
//            ("com.didactek.xtouch", .trace),
//            ("com.didactek.obswebsocket", .trace),
            ("com.didactek", .debug),
        ]
        
        @AppStorage(OBSClient.ConnectionInfo.appStorageKey) @CodableRaw
        var config = OBSClient.ConnectionInfo()
        
        @AppStorage(ManagedSource.appStorageKey) @CodableRaw
        var sourcesConfig = ManagedSource.defaultConfigs
        
        @AppStorage("managedScene")
        var managedScene = "Scene"

        let studio = StudioModel(connectionConfiguration: config,
                                 sourcesConfiguration: sourcesConfig,
                                 tiledSceneName: managedScene
        )
        self.studio = studio

        surface = try? SurfaceController(studio: studio)
        surface?.subscribe()
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $path) {
                SourceSwitcherView(studio: studio, path: $path)
                    .padding()
                    .navigationDestination(for: NavigationElement.self) { value in
                        switch(value) {
                        case .settings:
                            SettingsView(studio: studio,
                                         surface: $surface,
                                         sceneSources: $studio.sceneSources)
                        case .sourceSwitcher:
                            SourceSwitcherView(studio: studio, path: $path)
                        }
                    }
                    .task {
                        // FIXME: startup only happens when view is launched
                        studio.attemptConnection()
                    }
            }
        }
        
        Settings {
            SettingsView(studio: studio, surface: $surface,  sceneSources: $studio.sceneSources)
        }
    }
}
