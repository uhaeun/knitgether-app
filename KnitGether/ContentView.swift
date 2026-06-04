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
                MyKnittingView(repositories: .shared)
            }
            .tabItem {
                Label("My Knitting", systemImage: "heart.text.square")
            }

            NavigationStack {
                LibraryView(repositories: .shared)
            }
            .tabItem {
                Label("Library", systemImage: "books.vertical")
            }

            NavigationStack {
                ToolView(repositories: .shared)
            }
            .tabItem {
                Label("Tool", systemImage: "wrench.and.screwdriver")
            }
        }
    }
}

#Preview {
    ContentView()
}
