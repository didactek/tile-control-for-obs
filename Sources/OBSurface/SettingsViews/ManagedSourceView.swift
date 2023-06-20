//
//  ManagedSourceView.swift
//  
//
//  Created by Kit Transue on 2023-04-29.
//  Copyright © 2023 Kit Transue
//  SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

struct ManagedSourceView: View {
    @Binding var managed: ManagedSource
    
    let studio: StudioModel  // not observed; used to set crop

    var body: some View {
        VStack(alignment: .leading) {
            Text("Source Name")
                .font(.caption)
            Text(managed.sourceName)
                .font(.headline)
            Divider()
            Text("Application to raise")
                .font(.caption)
            Text(managed.application ?? "")
            Divider()
            Group {
                Text("Sizing")
                    .font(.caption)
                Picker("Fit policy", selection: $managed.fitPolicy.policy) {
                    ForEach(SourceMorpher.FitPolicy.allCases) { policy in
                        Text(policy.rawValue)
                    }
                }
                FrameTrimSetting(trim: $managed.fitPolicy.trim)
                FitPolicyView(policy: managed.fitPolicy)
                Text("Current log scale")
                    .font(.caption)
                Text("\(managed.fitPolicy.logScale)")
            }
            Divider()
            Button("Set crop") {
                studio.setCrop(for: managed)
            }
        }
    }
}


// FIXME: no longer needed?
struct FitPolicyView: View {
    let policy: SourceMorpher
    
    var body: some View {
        Text("Crop \(policy.trim.yOffset) pixels")
        switch policy.policy {
        case .oneToOne:
            Text("Scale \(policy.logScale) corresponds to \(RationalLogScale.pretty(for: policy.logScale))")  // FIXME: LoD
        case .fill:
            Text("Fill/Crop, trimming evenly")
        case .fit:
            Text("Letterbox")
        case .rdesktop:
            Text("Specialized of rdesktop")
        }
    }
}

//struct ManagedSourceView_Previews: PreviewProvider {
//    static var previews: some View {
//        ManagedSourceView()
//    }
//}
