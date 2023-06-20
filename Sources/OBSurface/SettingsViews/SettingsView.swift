//
//  SettingsView.swift
//  
//
//  Created by Kit Transue on 2023-04-27.
//  Copyright © 2023 Kit Transue
//  SPDX-License-Identifier: Apache-2.0
//

import SwiftUI
import OBSWebsocket
import OBSAsyncAPI

extension OBSClient.ConnectionInfo {
    static let appStorageKey = "serverConnectionSettings"
}

struct SettingsView: View {
    @ObservedObject var studio: StudioModel
    @Binding var surface: SurfaceController?
    
    @AppStorage(OBSClient.ConnectionInfo.appStorageKey) @CodableRaw
    var savedConnectionConfig = OBSClient.ConnectionInfo()
    
    @AppStorage(ManagedSource.appStorageKey) @CodableRaw
    var savedSourcesConfig = ManagedSource.defaultConfigs
    
    @State var connectionConfig = OBSClient.ConnectionInfo()
    
    @State var configuredSource: ManagedSource.ID? = nil

    @Binding var sceneSources: [String]
    
    func clearSourceSettings() {
        configuredSource = nil
        savedSourcesConfig = ManagedSource.defaultConfigs
        studio.tiledSources = savedSourcesConfig
    }
    

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    OBSConnection
                    Divider()
                    ResolutionStatus
                    Divider()
                    SourceChooser

                }
                .frame(width: 200)
                SourceConnfigurationPanel
                Spacer()
            }
            Divider()
            HStack {
                Surface
                Divider()
                    .frame(height: 40)
                Button("Set Crops") {
                    studio.setCrops()
                }
                Spacer()
                Button("Reset") {
                    clearSourceSettings()
                }
                Button("Save") {
                    savedSourcesConfig = studio.tiledSources
                }
            }
        }
        .frame(width: 600)
        .padding()
        .onAppear {
            connectionConfig = savedConnectionConfig
        }
    }
    
    private var ResolutionStatus: some View {
        VStack(alignment: .leading) {
            Text("Output Resolution")
                .font(.caption)
            Text(String(format: "%.0f x %.0f", studio.outputWidth, studio.outputHeight))
        }
    }
    
    private var SourceChooser: some View {
        VStack(alignment: .leading) {
            TiledSceneSelectorView(model: studio, selected: $studio.tiled)
            SourceListView(configuredSource: $configuredSource,
                           tiledSources: $studio.tiledSources,
                           sceneSources: sceneSources)
        }
    }
    
    private var SourceConnfigurationPanel: some View {
        Group {
            if let source = configuredSource,
               let managed = $studio.tiledSources.first(where: {$0.id == source})
            {
                ManagedSourceView(managed: managed, studio: studio)
            } else {
                Text("Select source to configure")
            }
        }
    }
    
    private var OBSConnection: some View {
        VStack(alignment: .leading) {
            Text("OBS Connection")
            TextField("hostname", value: $connectionConfig.host, format: HostnameFormat())
            TextField("port", value: $connectionConfig.port, format: .number)
            TextField("password", value: $connectionConfig.password, format: HostnameFormat()) // FIXME: Relax to allow spaces
            if studio.isConnected {
                HStack {
                    Image(systemName: "link")
                        .font(.title)
                    Text("Connected")
                }
            } else {
                HStack {
                    Image(systemName: "link.badge.plus")
                        .font(.title)
                    Button("Reconnect") {
                        studio.attemptConnection()
                    }
                }
            }
            HStack {
                Button("Reset") {
                    connectionConfig = savedConnectionConfig
                }
                .disabled(savedConnectionConfig == connectionConfig)
                Button("Apply") {
                    // FIXME: if unsaved changes, prompt on close?
                    savedConnectionConfig = connectionConfig
                    Task.init {
                        await studio.setConnectionConfiguration(connectionConfig)
                    }
                }
                .disabled(savedConnectionConfig == connectionConfig)
            }
        }
    }
    
    
    private var Surface: some View {
        VStack {
            Text("MIDI Surface")
            if surface == nil {
                HStack {
                    Image(systemName: "slider.horizontal.2.gobackward")
                        .font(.title)
                    Button("Reconnect") {
                        surface = try? SurfaceController(studio: studio)
                        surface?.subscribe()
                    }
                }
            } else {
                HStack {
                    Image(systemName: "slider.horizontal.3")
                        .font(.title)
                    Text("Connected")
                }
            }
        }
    }
}

//struct SettingsView_Previews: PreviewProvider {
//    static var previews: some View {
//        SettingsView()
//    }
//}
