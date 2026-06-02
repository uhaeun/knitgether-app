//
//  MyKnittingsView.swift
//  KnitGether
//
//  Created by yu haeun on 6/2/26.
//

import SwiftUI

struct MyKnittingsView: View {
    let projects: [KnittingProject]

    var body: some View {
        List(projects) { project in
            NavigationLink {
                ProjectDetailView(project: project)
            } label: {
                ProjectCardView(project: project)
            }
            .buttonStyle(.plain)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        }
        .listStyle(.plain)
        .navigationTitle("My Knittings")
    }
}

#Preview {
    NavigationStack {
        MyKnittingsView(projects: SampleKnittingData.projects)
    }
}
