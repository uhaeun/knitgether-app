//
//  StatusBadgeView.swift
//  KnitGether
//
//  Created by yu haeun on 6/2/26.
//

import SwiftUI

struct StatusBadgeView: View {
    let status: ProjectStatus

    var body: some View {
        Text(status.rawValue)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .foregroundStyle(tint)
            .background(tint.opacity(0.14))
            .clipShape(Capsule())
    }

    private var tint: Color {
        switch status {
        case .planning:
            .blue
        case .inProgress:
            .green
        case .paused:
            .orange
        case .finished:
            .purple
        }
    }
}

#Preview {
    HStack {
        ForEach(ProjectStatus.allCases) { status in
            StatusBadgeView(status: status)
        }
    }
    .padding()
}
