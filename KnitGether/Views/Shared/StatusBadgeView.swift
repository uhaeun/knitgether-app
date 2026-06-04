//
//  StatusBadgeView.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import SwiftUI

struct StatusBadgeView: View {
    let status: ProjectStatus

    var body: some View {
        Text(status.badgeTitle)
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
        case .planned:
            return .blue
        case .wip:
            return .green
        case .ufo:
            return .orange
        case .fo:
            return .purple
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
