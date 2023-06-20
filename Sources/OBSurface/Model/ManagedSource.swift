//
//  ManagedSource.swift
//  
//
//  Created by Kit Transue on 2022-09-20.
//  Copyright © 2022 Kit Transue
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation
import OBSWebsocket

/// Policy/procedure for setting up source transformations.
struct SourceMorpher: Codable, Hashable { // FIXME: is this the best name?
    var policy: FitPolicy
    var trim: FrameTrim
    // FIXME: bug in when yOffset is applied? And at scale?
    
    var logScale: Int  // FIXME: only for oneToOne
    
    init(policy: FitPolicy, yOffset: Int = 0, logScale: Int = 0) {
        self.policy = policy
        self.trim = FrameTrim(yOffset: yOffset)
        self.logScale = logScale
    }
    
    mutating
    func adjustScale(by adjustment: Int) {
        logScale = logScale - adjustment
    }
    
    /// How to fit when tiling or filling screen
    enum FitPolicy: String, Codable, CaseIterable, Identifiable {
        var id: Self { self }
        
        /// One pixel per output pixel, vertical offset as specified to allow position to hide application's toolbar.
        ///
        case oneToOne
        /// Remove excess content (equally on each removed side) so remainder fills screen.
        case fill
        /// Scale to fit all content within window; letterbox if need be.
        case fit
        /// known-size capture of a window that reports full scresn
        case rdesktop
    }
    
    func sceneCrop(specs: SceneItemTransform,
                   outputWidth: Double, outputHeight: Double
    ) -> SceneItemTransform? {
        let targetAspect = outputWidth / outputHeight
        
        let crop: SceneItemTransform
        
        switch policy {
        case .oneToOne:
            let windowScale = RationalLogScale.pow(for: logScale)
            
            crop = SceneItemTransform(
                cropBottom:
                    max(0,
                        (Int(specs.sourceHeight! / windowScale) - trim.yOffset) - Int(outputHeight)
                       ),
                cropLeft: 0,
                cropRight:
                    max(0, Int(specs.sourceWidth! / windowScale) - Int(outputWidth)),
                cropTop: trim.yOffset
            )
            guard (crop.cropLeft! + crop.cropRight!) < Int(specs.sourceWidth! + 1) else {
                logger.warning("cropped too much width")
                return nil
            }
            guard (crop.cropTop! + crop.cropBottom!) < Int(specs.sourceHeight! + 1) else {
                logger.warning("cropped too much height")
                return nil
            }
            guard Int(specs.sourceHeight!) > trim.yOffset else {
                logger.warning("yOffset \(specs.sourceHeight!) is bigger than input screen")
                return nil
            }
            
            logger.trace("Scene: \(specs) cropped to: \(crop)")
        case .fill:
            let sourceAspect = specs.croppedWidth! / specs.croppedHeight!
            guard sourceAspect != targetAspect else { // danger! floating point comparison!
                logger.trace("Source has correct aspect \(sourceAspect); not changing")
                return nil
            }
            if sourceAspect < targetAspect {
                // too narrow; crop top/bottom
                let excess = Int(specs.sourceHeight! - specs.sourceWidth! / targetAspect)
                crop = SceneItemTransform(
                    cropBottom: excess / 2,
                    cropLeft: 0,
                    cropRight: 0,
                    cropTop: excess / 2
                )
            } else {
                // too wide; crop sides
                // FIXME: NaN
                let excess = Int(specs.sourceWidth! - specs.sourceHeight! * targetAspect)
                crop = SceneItemTransform(
                    cropBottom: 0,
                    cropLeft: excess / 2,
                    cropRight: excess / 2,
                    cropTop: 0
                )
            }
        case .fit:
            crop = SceneItemTransform(
                cropBottom: 0,
                cropLeft: 0,
                cropRight: 0,
                cropTop: 0
            )
        case .rdesktop:
            let xqWindowChrome = 96
            let retinaFactor = 2
            let rdpWidth = 1280
            let rdpHeight = 720
            crop = SceneItemTransform(
                cropBottom: Int(specs.sourceHeight!) - rdpHeight * retinaFactor - xqWindowChrome,
                cropLeft: 0,
                cropRight: Int(specs.sourceWidth!) - rdpWidth * retinaFactor,
                cropTop: xqWindowChrome
            )
        }
        return crop
    }
    
}

struct ManagedSource: Codable, Identifiable, Hashable {
    static let appStorageKey = "managedSourcenSettings"
    static func == (lhs: ManagedSource, rhs: ManagedSource) -> Bool {
        lhs.sourceName == rhs.sourceName
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(sourceName)
    }
    
    var id: String { sourceName }  // FIXME: better identifier?
    
    let sourceName: String
    let application: String?
    var fitPolicy: SourceMorpher

    
    init(sourceName: String, application: String? = nil, fitPolicy: SourceMorpher.FitPolicy, yOffset: Int = 0, logScale: Int = 0) {
        self.sourceName = sourceName
        self.application = application
        self.fitPolicy = SourceMorpher(policy: fitPolicy, yOffset: yOffset, logScale: logScale)
    }
    

    func surfaceWindows() {
        guard let application = application else {
            return
        }
        let cmd = Process()
        cmd.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        cmd.arguments = ["-a", application]
        try? cmd.run()
    }
    
    mutating
    func adjustScale(by adjustment: Int) {
        fitPolicy.adjustScale(by: adjustment)
    }
    
    func sceneCrop(source: SceneSource, outputWidth: Double, outputHeight: Double) -> SceneItemTransform? {
        return fitPolicy.sceneCrop(specs: source.sceneItemTransform, outputWidth: outputWidth, outputHeight: outputHeight)
    }
    
    static let defaultConfigs: [Self] = [
        ManagedSource(sourceName: "Sony CamLink", fitPolicy: .fill),
   //    ManagedSource(sceneName: "iMac built-in"),
       ManagedSource(sourceName: "Safari", application: "Safari", fitPolicy: .oneToOne, yOffset: 150, logScale: RationalLogScale.modulus),
       ManagedSource(sourceName: "Preview", application: "Preview", fitPolicy: .oneToOne, yOffset: 150),
       ManagedSource(sourceName: "document", fitPolicy: .fill),
       ManagedSource(sourceName: "Terminal", application: "Terminal", fitPolicy: .oneToOne, yOffset: 50),
       ManagedSource(sourceName: "Windows", application: "XQuartz", fitPolicy: .rdesktop),  // changes focus, but doesn't raise,
       ManagedSource(sourceName: "VSCode", application: "Visual Studio Code", fitPolicy: .oneToOne, yOffset: 50),
       ManagedSource(sourceName: "Diagrams", application: "Draw.io", fitPolicy: .oneToOne, yOffset: 50),
       ManagedSource(sourceName: "Emacs", application: "Emacs", fitPolicy: .oneToOne, yOffset: 50),
    ]
}
