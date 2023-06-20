//
//  SourceSwitcherView.swift
//  
//
//  Created by Kit Transue on 2023-04-27.
//  Copyright © 2023 Kit Transue
//  SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

struct Surround: ViewModifier {
    let selected: Bool

    func body(content: Content) -> some View {
        content
            .buttonStyle(.plain)
            .padding(3)
            .background(RoundedRectangle(cornerSize: CGSize(width: 3,height: 3) ).fill(Color.white))
            .padding(3)
            .background(RoundedRectangle(cornerSize: CGSize(width: 4,height: 4))
                .fill(selected ? Color.blue : Color.white)
                .shadow(radius: 3)
            )
    }
}

struct SourceSwitcherView: View {
    @ObservedObject
    var studio: StudioModel
    
    @Binding var path: [NavigationElement]
    
    var body: some View {
        VStack {
            Text("OBS Control").padding()
            Grid {
                GridRow {
                    ForEach(studio.sources) { source in
                        Button(String(source.name)) {
                            studio.toggleVisibility(index: source.index)
                        }
                        .modifier(Surround(selected: source.isVisible))
                    }
                }
                GridRow {
                    ForEach(studio.sources) { source in
                        Button(String(source.index)) {
                            studio.makePrimary(index: source.index)
                        }
                        .modifier(Surround(selected: source.isMain))

                    }
                }
            }
            HStack {
                Spacer()
                Text(studio.mainSource)
                Spacer()
                RecordControlView(studio: studio)
            }
        }
        .toolbar {
            Button(action: {
                path = [.settings]
            }, label:  {
                Image(systemName: "gear")
            })
        }
    }
}

//struct SourceSwitcherView_Previews: PreviewProvider {
//    static var previews: some View {
//        SourceSwitcherView()
//    }
//}
