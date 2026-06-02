//
//  ProjectDetailView.swift
//  KnitGether
//
//  Created by yu haeun on 6/2/26.
//

import SwiftUI

struct ProjectDetailView: View {
    let project: KnittingProject
    @State private var currentRow: Int

    init(project: KnittingProject) {
        self.project = project
        _currentRow = State(initialValue: project.currentRow)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    StatusBadgeView(status: project.status)

                    Text(project.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                }

                patternPlaceholder

                detailSection(title: "Memo") {
                    Text(project.memo)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                detailSection(title: "Row Counter") {
                    HStack(spacing: 18) {
                        Button {
                            currentRow = max(0, currentRow - 1)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 36))
                        }
                        .disabled(currentRow == 0)
                        .accessibilityLabel("Decrease row")

                        VStack(spacing: 4) {
                            Text("Current Row")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text("\(currentRow)")
                                .font(.system(size: 44, weight: .bold, design: .rounded))
                                .monospacedDigit()
                        }
                        .frame(maxWidth: .infinity)

                        Button {
                            currentRow += 1
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 36))
                        }
                        .accessibilityLabel("Increase row")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.accentColor)
                }
            }
            .padding()
        }
        .navigationTitle("Project")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var patternPlaceholder: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pattern")
                .font(.headline)

            VStack(spacing: 12) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)

                Text(project.patternName ?? "No pattern selected")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("Pattern preview will live here in a later version.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 160)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private func detailSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            content()
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

#Preview {
    NavigationStack {
        ProjectDetailView(project: SampleKnittingData.projects[0])
    }
}
