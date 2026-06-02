//
//  ContentView.swift
//  KnitGether
//
//  Created by yu haeun on 6/2/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                MyKnittingsView(projects: SampleKnittingData.projects)
            }
            .tabItem {
                Label("My Knittings", systemImage: "heart.text.square")
            }

            NavigationStack {
                LibraryView()
            }
            .tabItem {
                Label("Library", systemImage: "books.vertical")
            }

            NavigationStack {
                ToolsView()
            }
            .tabItem {
                Label("Tools", systemImage: "wrench.and.screwdriver")
            }
        }
    }
}

#Preview {
    ContentView()
}
