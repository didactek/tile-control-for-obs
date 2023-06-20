 //
//  SourceListView.swift
//  
//
//  Created by Kit Transue on 2023-05-12.
//  Copyright © 2023 Kit Transue
//  SPDX-License-Identifier: Apache-2.0
//

import SwiftUI
import OBSWebsocket

struct SourceListView: View {
    @Binding var configuredSource: ManagedSource.ID?
    @Binding var tiledSources: [ManagedSource]

    // FIXME: originally had a binding, but that's not neccessary, right?
    var sceneSources: [String]

    var body: some View {
        VStack(alignment: .leading) {
            Text("Sources")
                .font(.caption)
            // FIXME: bug? I would think this would be succinct and effective, but move dominates selection:
            // List($tiledSources, editActions: .move, selection: $configuredSource)
            List {
                ForEach($tiledSources) {$source in
                    HStack {
                        Text(source.sourceName)
                            .onTapGesture {  // FIXME: text selection area dominates drag/move; stack icon to avoid?
                                if configuredSource == source.id {
                                    configuredSource = nil
                                } else {
                                    configuredSource = source.id
                                }
                            }
                        Spacer()
                        Image(systemName: "list.triangle")
                    }
                    // FIXME: dark mode; get from environment (local resources may not exist for SPM build)
                    .listRowBackground(source.id == configuredSource ? Color(red: 0.9, green: 0.9, blue: 0.9) : Color(red: 1.0, green: 1.0, blue: 1.0) )
                }
                .onMove { from, to in
                    tiledSources.move(fromOffsets: from, toOffset: to)
                }
                .onDelete { indexSet in
                    // FIXME: also set configuredSource = nil?
                    tiledSources.remove(atOffsets: indexSet)
                }
                Section {
                    ForEach(sceneSources.filter { sourceName in
                        !tiledSources.contains(where: {$0.sourceName == sourceName })
                    }, id: \.self) { source in
                        HStack{
                            Text(source)
                            Spacer()
                            Image(systemName: "plus")
                                .onTapGesture {
                                    tiledSources.append(ManagedSource(sourceName: source, fitPolicy: .fill))
                                }
                        }
                    }
                }
            }
        }
    }
}

//struct SourceListView_Previews: PreviewProvider {
//    static var previews: some View {
//        SourceListView()
//    }
//}
