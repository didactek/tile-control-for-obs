//
//  FrameTrimSetting.swift
//  
//
//  Created by Kit Transue on 2023-05-16.
//  Copyright © 2023 Kit Transue
//  SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

struct FrameTrimSetting: View {
    @Binding var trim: FrameTrim
    
    var body: some View {
        HStack {
            TextField("yOffset", value: $trim.yOffset, format: .number)
                .frame(width: 40)
            Picker("offset", selection: $trim.wellKnown) {
                ForEach(FrameOffset.allCases) { frameOffset in
                    Text(frameOffset.description())
                        .tag(frameOffset)
                }
            }
        }
    }
}




struct FrameTrimSetting_Previews: PreviewProvider {
    @State static var yOffset = FrameTrim(yOffset: 150)
    
    static var previews: some View {
        FrameTrimSetting(trim: $yOffset)
    }
}
