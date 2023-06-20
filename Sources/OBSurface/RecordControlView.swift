//
//  RecordControlView.swift
//  
//
//  Created by Kit Transue on 2023-05-27.
//  Copyright © 2023 Kit Transue
//  SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

struct RecordControlView: View {
    @ObservedObject var studio: StudioModel
    
    var body: some View {
        HStack {  // VStack would match control surface layout
            Button(action: {
                studio.toggleRecord()
            }, label: {
                (studio.isRecording ? Image(systemName: "stop.circle") : Image(systemName: "record.circle"))
                    .foregroundColor(.red)
                    .font(.largeTitle)
            })
            .buttonStyle(PlainButtonStyle())
            Button(action: {
                studio.toggleRecordPause()
            }, label: {
                (studio.recordingPaused ? Image(systemName: "pause.rectangle.fill") : Image(systemName: "pause.rectangle"))
                    .font(.largeTitle)
            })
            .buttonStyle(PlainButtonStyle())
            .disabled(!studio.isRecording)
        }
    }
}

//struct RecordControlView_Previews: PreviewProvider {
//    static var previews: some View {
//        RecordControlView()
//    }
//}
