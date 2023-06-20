//
//  SurfaceController.swift
//  
//
//  Created by Kit Transue on 2022-12-29.
//  Copyright © 2022 Kit Transue
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Combine

import MCSurface

class SurfaceController {
    private let surface: XTouchMiniMC
    private let studio: StudioModel
    private var subscriptions = Set<AnyCancellable>()
    
    init(studio: StudioModel) throws {
        self.surface = try XTouchMiniMC(midiSourceIndex: 0)
        self.studio = studio
    }

    let surfaceCount = 8 // number of encoder/button pair columns
    let whiteboardControlIndex = 7  // use rightmost rotary encoder for whiteboard
    let micControlIndex = 0 // use leftmost for mic level control

    // FIXME: why should the surface controller be concerned about MainActor? If the model updates have thread delivery requirements, the model should worry about that?
    @MainActor func subscribe() {
        let managed = studio.sources.filter { $0.index < surfaceCount }
        // State observers:
        studio.$sources
            .sink(receiveValue: { [self] newStates in
                for state in newStates {
                    guard state.index < surfaceCount else { continue }
                    surface.topRowButtons[state.index].isIlluminated = state.isVisible
                    surface.bottomRowButtons[state.index].isIlluminated = state.isMain
                }
            })
            .store(in: &subscriptions)
        studio.$volume
            .sink(receiveValue: { [self] volume in
                let position = surface.encoders[micControlIndex].indicator.changed(toNormalized: volume)
                surface.encoders[micControlIndex].indicator = position
            })
            .store(in: &subscriptions)
        studio.$isRecording
            .sink(receiveValue: { [self] isRecording in
                surface.layerButtons[0].isIlluminated = isRecording
            })
            .store(in: &subscriptions)
        studio.$recordingPaused
            .sink(receiveValue: { [self] isPaused in
                surface.layerButtons[1].blink = isPaused ? .blink : .off
            })
            .store(in: &subscriptions)
        studio.$isWhiteboardOverlaid
            .sink(receiveValue: { [self] overlaid in
                surface.encoders[whiteboardControlIndex].indicator = surface.encoders[whiteboardControlIndex].indicator.changed(toNormalized: overlaid ? 1.0 : 0.0)
            })
            .store(in: &subscriptions)
        // Action buttons:
        for state in managed {
            let index = state.index
            surface.topRowButtons[index].isPressed
                .sink { [self] pressed in
                    if pressed {
                        studio.toggleVisibility(index: index)
                    }
                }
                .store(in: &subscriptions)
        }
        for state in managed {
            let index = state.index
            surface.bottomRowButtons[index].isPressed
                .sink { [self] pressed in
                    if pressed {
                        studio.makePrimary(index: index)
                    }
                }
                .store(in: &subscriptions)
        }
        for state in managed {
            let index = state.index
            surface.encoders[index].change
                .eraseToAnyPublisher()
                .receive(on: DispatchQueue.main)
                .sink { [self]
                    change in
                    studio.adjustSourceScale(index: index, change: change)
                }
                .store(in: &subscriptions)
        }
        surface.layerButtons[1].isPressed
            .sink { [self] pressed in
                if pressed {
                    studio.toggleRecordPause()
                    // FIXME: respond by setting status
                }
            }
            .store(in: &subscriptions)
        // FIXME: enhance whiteboardControlIndex so CW rotation enables; CCW disables?
        surface.encoders[whiteboardControlIndex].isPressed
            .sink { [self] pressed in
                if pressed {
                    studio.toggleWhiteboard()
                }
            }
            .store(in: &subscriptions)
        surface.layerButtons[0].isPressed
            .sink { [self] pressed in
                if pressed {
                    studio.toggleRecord()
                }
            }
            .store(in: &subscriptions)
            
        
        let mic = surface.encoders[micControlIndex]
        mic.indicator = ControlValue(range: 0...100, value: 50)
        mic.change
            .sink { [self]
                change in
                let newValue = mic.indicator.adjusted(by: change)
                studio.setMicLevel(newValue.normalized())
            }
            .store(in: &subscriptions)
    }
}
