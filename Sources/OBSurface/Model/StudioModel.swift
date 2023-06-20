//
//  StudioModel.swift
//  
//
//  Created by Kit Transue on 2022-12-29.
//  Copyright © 2022 Kit Transue
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SwiftUI  // FIXME: remove when AppStorage for managedScene is clarified

import OBSAsyncAPI
import OBSWebsocket
import Combine

@MainActor
class StudioModel: ObservableObject {
    // FIXME: handle "whiteboard": it is always the last overlay and treated differently.
    @Published var tiledSources: [ManagedSource] {
        didSet {
            synchronizeSourceOrder()
        }
    }
    
    
    private var obs: OBSClient
    private var subscriptions = Set<AnyCancellable>()
    
    // FIXME: state should be attached to the manaeged source; not separate (sources). Use a map?
    struct SourceState: Identifiable {
        var id: Int { name.hashValue }
        var isVisible: Bool
        var isMain: Bool
        var index: Int
        var name: String
    }
    
    @Published var tiled: OBSScene {
        didSet {
            // FIXME: establish better ownership of managedScene/tiled
            @AppStorage("managedScene")
            var managedScene = "Scene"
            managedScene = tiled.name
            
            Task.init {
                await syncSourceState()
            }
        }
     }
    
    /// The sources the server associates with the managed scene
    // FIXME: this more a cached version of the OBS state; update by watching events
    @Published var sceneSources: [String] = []
    
    @Published private(set) var mainSource: String
    @Published private(set) var sources: [SourceState]  = [] // FIXME: associate with
    @Published private(set) var volume: Double
    @Published private(set) var isRecording: Bool
    @Published private(set) var recordingPaused: Bool
    @Published private(set) var isWhiteboardOverlaid: Bool
    @Published private(set) var isConnected: Bool = false
    
    init(connectionConfiguration config: OBSClient.ConnectionInfo,
         sourcesConfiguration: [ManagedSource],
         tiledSceneName: String
    ) {
        self.tiledSources = sourcesConfiguration
        self.tiled = OBSScene(name: tiledSceneName)
        
        mainSource = sourcesConfiguration[0].sourceName
        volume = 0
        isRecording = false
        recordingPaused = false
        isWhiteboardOverlaid = false
        
        obs = OBSClient(hostname: config.host,
                        port: config.port,
                        password: config.password,
                        eventSubscriptions: .allLowVolume)
        
        synchronizeSourceOrder()
        
        obs.isConnected
            .receive(on: RunLoop.main)
            .assign(to: &$isConnected)
        
        // FIXME: use idiomatic Combine filter composition
        obs.events
            .receive(on: RunLoop.main) // update published variables on main thread so they can be used with SwiftUI
            .sink  { [self] event in
                switch(event) {
                case .inputVolumeChanged(let newVolume):
                    volume = pow(10, newVolume.inputVolumeDb / 50.0)
                    // FIXME: repsond to sourceenabled; maintain toggle
                case .recordStateChanged(let recording):
                    isRecording = recording.outputActive
                    switch recording.outputState {
                    case .paused:
                        recordingPaused = true
                    case .resumed, .stopped:
                        recordingPaused = false
                    default:
                        break
                    }
                    //                case .sceneItemEnableStateChanged(let item):
                    //                    if let index = BEWARE-SCENE/INDEX CONFUSION
                    //                        isMainSource[index] = false
                    //                    }
                case .currentPreviewSceneChanged(let info):
                    logger.debug("Scene changed to \(info.sceneName)")
                default: break
                }
            }
            .store(in: &subscriptions)
    }
    
    // FIXME: tile windows to base resolution, not to output (which may be scaled)
    @Published var outputWidth = 0.0
    @Published var outputHeight = 0.0
    
    func setConnectionConfiguration(_ config: OBSClient.ConnectionInfo) async {
        await obs.setConnectionInfo(config)
    }
    
    func syncSourceState() async {
        let src = await listSources(for: tiled)
        sceneSources = src
    }
    
    func synchronizeSourceOrder() {
        let oldState = [String: SourceState](
             sources.map { ($0.name, $0) },
             uniquingKeysWith: { x, _ in x } )
        
        sources = tiledSources.enumerated().map {index, source in
            let isMain: Bool
            let isVisible: Bool
            if let existing = oldState[source.sourceName] {
                isMain = existing.isMain
                isVisible = existing.isVisible
            } else {
                isMain = false
                isVisible = false
            }
            return SourceState(isVisible: isVisible, isMain: isMain, index: index, name: source.sourceName)}
    }
    
    func toggleVisibility(index: Int) {
        Task.init {
            do {
                // Odd: can't pass "tiledSources[index].sourceName)" directly: it's claimed to be in/out?
                let source = tiledSources[index].sourceName
                let enabled = try await toggleSource(scene: tiled, source: source)
                // FIXME: Maintain sources.isVisible by monitoring events
                sources[index].isVisible = enabled
                try await obs.setCurrentProgramScene(sceneName: tiled.name)  // realize changes
            } catch {
                logger.debug("toggleVisibility threw \(error); ignoring.")
            }
        }
    }
    
    func makePrimary(index: Int) {
        makePrimary(sourceName: tiledSources[index].sourceName)
    }
    
    func makePrimary(sourceName: String) {
        Task.init {
            do {
                try await tileItems(makePrimary: sourceName)
            } catch {
                logger.debug("makePrimary: threw \(error); ignoring.")
            }
//            try? await obs.setCurrentProgramScene(sceneName: sceneName)
        }
    }
    
    func setCrops() {
        Task.init {
            do {
                try await setTilingCrops(tiledSources: tiledSources)
            } catch {
                logger.debug("Error setting crops: \(error)")
            }
        }
    }
    
    func setCrop(for source: ManagedSource) {
        Task.init {
            do {
                try await setTilingCrops(tiledSources: [source])
            } catch {
                logger.debug("Error setting crop for \(source.sourceName): \(error)")
            }
        }
    }
    
    private func sourceIndex(forName name: String) -> Int? {
        tiledSources.firstIndex(where: {$0.sourceName == name})
    }
    
    /// Toggle source visibility/enabled.
    ///
    /// - returns: true if source is now enabled.
    private func toggleSource(scene: OBSScene, source sourceName: String) async throws -> Bool {
        let sources = try await obs.getSceneItemList(scene: scene)
        let source = sources.first { $0.sourceName == sourceName }
        guard let source = source else {
            logger.debug("Didn't find source \(sourceName) to toggle enabled")
            return false
        }

        let newEnabledState = !source.sceneItemEnabled
        try await obs.setSceneItemEnabled(sceneName: scene.name, sceneItemId: source.sceneItemId, sceneItemEnabled: newEnabledState)
        return newEnabledState
    }
    
    func toggleRecord() {
        Task.init {
            do {
                try await obs.toggleRecord()
            } catch {
                logger.warning("toggleRecord failed with \(error)")
            }
        }
    }
    
    func toggleRecordPause() {
        Task.init {
            do {
                try await obs.toggleRecordPause()
            } catch {
                logger.warning("toggleRecordPause failed with \(error)")
            }
        }
    }

    func transformFor(transformInfo: SceneItemTransform, width: Double, height: Double, posX: Double = 0, posY: Double = 0) -> SceneItemTransform? {
        let fillX = width / transformInfo.croppedWidth!
        let fillY = height / transformInfo.croppedHeight!
        
        let scale = min(fillX, fillY)
        guard scale.isNormal else {return nil}
        
        return SceneItemTransform(
            positionX: posX,
            positionY: posY,
            scaleX: scale,
            scaleY: scale
        )
    }
    
    func transformForFitScreen(transformInfo: SceneItemTransform) -> SceneItemTransform? {
        transformFor(transformInfo: transformInfo, width: outputWidth, height: outputHeight)
    }
    
    func adjustSourceScale(index: Int, change: Int) {
        tiledSources[index].adjustScale(by: change)
        Task.init {
            do {
                try await setTilingCrops(tiledSources: tiledSources)
            } catch {
                logger.info("Error during setTilingCrops: \(error)")
            }
            do {
                try await tileItems(makePrimary: mainSource)
            } catch {
                logger.info("Error during setTilingCrops: \(error)")
            }
        }
    }
    
    // 0...1
    func setMicLevel(_ level: Double) {
        let newVolume = log10(max(0.01, level)) * 50.0
        Task.init {
            try? await self.obs.setInputVolume(inputName: "Mic/Aux", inputVolumeMul: nil, inputVolumeDb: newVolume)
        }
    }
    
    
    /// Configure the preview for the "SurfaceTiled" scene
    private func tileItems(makePrimary: String) async throws {
        let scene = tiled
        // handle overloaded document camera (whiteboard/document)
        // crop? center (cameras)/left (shells)/left offset (documents)
        // tile order?
        // index main view behind others
        // promote to main view?
        
        // get source list
        let sources = try await obs.getSceneItemList(scene: scene)
        guard let primary = sources.first(where: { $0.sourceName == makePrimary }) else {
            logger.info("Source \(makePrimary) not found in \(scene.name)")
            return
        }
        if !primary.sceneItemEnabled {
            try await obs.setSceneItemEnabled(sceneName: scene.name, sceneItemId: primary.sceneItemId, sceneItemEnabled: true)
        }
        // filter on enabled
        let secondary = tiledSources.compactMap {  // keep in tiledSources order
            sourceName in
            if let source = sources.first(where: {$0.sourceName == sourceName.sourceName}) {
                if source.sceneItemEnabled && source.sourceName != makePrimary {
                    return source
                }
            }
            return nil
        }
        
        // FIXME: crop to 4:3?

        let padding = 30.0
        let reserved = max(4, Double(secondary.count))
        let available = outputHeight - (padding * (reserved + 1))
        let height = available / reserved
        let width = height / outputHeight * outputWidth
        
        let posX = outputWidth - padding - width
        
        for (index, source) in secondary.enumerated() {
            let posY = padding + (height + padding) * Double(index)
            if let geometry = transformFor(transformInfo: source.sceneItemTransform, width: width, height: height, posX: posX, posY: posY) {
                try await obs.setSceneItemTransform(sceneName: scene.name, sceneItemId: source.sceneItemId, sceneItemTransform: geometry)
            }
        }

        if let fullGeometry = transformForFitScreen(transformInfo: primary.sceneItemTransform) {
            try await obs.setSceneItemTransform(sceneName: scene.name, sceneItemId: primary.sceneItemId, sceneItemTransform: fullGeometry)
        }

        try await obs.setSceneItemIndex(sceneName: scene.name, sceneItemId: primary.sceneItemId, sceneItemIndex: 0) // move to back

        // realize changes: all the above works on the preview scene; must set to show on output
        try await obs.setCurrentProgramScene(sceneName: scene.name)

        if let index = sourceIndex(forName: mainSource) {
            self.sources[index].isMain = false
        }
        mainSource = makePrimary
        if let index = sourceIndex(forName: mainSource) {
            self.sources[index].isMain = true
            self.sources[index].isVisible = true
            tiledSources[index].surfaceWindows()
        }
    }
    
    
    // places last, in front of all
    func toggleWhiteboard(source sourceName: String = "whiteboard") {
        Task.init {
            do {
                let sources = try await obs.getSceneItemList(scene: tiled)
                let source = sources.first { $0.sourceName == sourceName }
                guard let source = source else {
                    logger.info("Didn't find whiteboard/overlay source \(sourceName)")
                    return
                }
                
                if !source.sceneItemEnabled {
                    try await obs.setSceneItemIndex(sceneName: tiled.name, sceneItemId: source.sceneItemId, sceneItemIndex: sources.count) // move to front
                    
                    if let fullGeometry = transformForFitScreen(transformInfo: source.sceneItemTransform) {
                        try await obs.setSceneItemTransform(sceneName: tiled.name, sceneItemId: source.sceneItemId, sceneItemTransform: fullGeometry)
                    }
                }
                try await obs.setSceneItemEnabled(sceneName: tiled.name, sceneItemId: source.sceneItemId, sceneItemEnabled: !source.sceneItemEnabled)
                try await obs.setCurrentProgramScene(sceneName: tiled.name)  // realize changes
                isWhiteboardOverlaid = !source.sceneItemEnabled
            } catch {
                logger.warning("Ignoring error from toggleWhiteboard: \(error)")
            }
        }
    }
    
    func attemptConnection() {
        Task.init {
            do {
                try await obs.connect()
                
                let videoSettings = try? await obs.getVideoSettings()
                outputWidth = videoSettings?.outputWidth ?? 0
                outputHeight = videoSettings?.outputHeight ?? 0

                // FIXME: post-connection task: query scenes?
                // FIXME: delay isConnected until dimensions are ready
            } catch {
                logger.warning("Failed to connect to OBS: \(error)")
            }
        }
    }

    /// Configuration helper: set crops on input sources so they match screen aspect ratio.
    // FIXME: let UI send individual sources for configuration (don't do all automatically)
    private func setTilingCrops(tiledSources: [ManagedSource]) async throws {
        
        for source in try await obs.getSceneItemList(scene: tiled) {
            guard let managed = tiledSources.first(where: {$0.sourceName == source.sourceName}),
                  let crop = managed.sceneCrop(source: source,
                                               outputWidth: outputWidth,
                                               outputHeight: outputHeight)
            else { continue }
            
            try await obs.setSceneItemTransform(sceneName: tiled.name, sceneItemId: source.sceneItemId, sceneItemTransform: crop)
        }
    }
    
 
    func listScenes() async -> [OBSScene] {
        guard let reply = try? await obs.getSceneList()
        else { return [] }
        
        return reply.scenes.map { OBSScene(name: $0.sceneName) }
    }
    
    func listSources(for scene: OBSScene) async -> [String] {
        guard let items = try? await obs.getSceneItemList(scene: scene)
        else { return[] }
        
        return items.map { $0.sourceName }
    }
    
    
    
    //    Button("Shift inset") {
    //        Task.init {
    //            let scene = OBSScene(name: "inset")
    //            let reply = try! await obs.getSceneItemList(sceneName: scene.name)
    //            print("got items: \(reply)")
    //
    //            // do something with the reply: change/set the crop/etc
    //            let object = reply[0]
    //            let original = object.sceneItemTransform
    //            let transform = SceneItemTransform(positionX: original.positionX! - 10, positionY: original.positionY! - 10)
    //
    //            try! await obs.setSceneItemTransform(sceneName: scene.name, sceneItemId: object.sceneItemId, sceneItemTransform: transform)
    //            try! await obs.setSceneItemIndex(sceneName: scene.name, sceneItemId: object.sceneItemId, sceneItemIndex: 2)
    //            // FIXME: set scene if change is supposed to take effect immediately
    //        }
}


public struct OBSScene: Identifiable, Hashable, Equatable {
    public typealias ID = Int
    public var id: Int {
        return name.hash
    }

    public let name: String
    public init(name: String) {
        self.name = name
    }
}

extension OBSClient {
    func getSceneItemList(scene: OBSScene) async throws -> [SceneSource] {
        return try await getSceneItemList(sceneName: scene.name)
    }
}
