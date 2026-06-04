//
//  DraggableBottomSheet.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import SwiftUI

struct DraggableBottomSheet<Header: View, Content: View>: View {
    @Binding var position: ProjectWorkspaceSheetPosition
    let header: Header
    let content: Content

    @State private var dragOffset: CGFloat = 0

    init(
        position: Binding<ProjectWorkspaceSheetPosition>,
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content
    ) {
        _position = position
        self.header = header()
        self.content = content()
    }

    var body: some View {
        GeometryReader { proxy in
            let maxHeight = proxy.size.height
            let currentOffset = offset(for: position, in: maxHeight)
            let clampedOffset = min(
                max(currentOffset + dragOffset, offset(for: .expanded, in: maxHeight)),
                offset(for: .collapsed, in: maxHeight)
            )

            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.35))
                        .frame(width: 44, height: 5)
                        .padding(.top, 10)

                    header
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                }
                .contentShape(Rectangle())
                .gesture(dragGesture(maxHeight: maxHeight, currentOffset: currentOffset))

                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .frame(width: proxy.size.width, height: maxHeight, alignment: .top)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: Color.black.opacity(0.16), radius: 18, x: 0, y: -4)
            .offset(y: clampedOffset)
            .animation(.spring(response: 0.32, dampingFraction: 0.86), value: position)
            .animation(.interactiveSpring(response: 0.24, dampingFraction: 0.88), value: dragOffset)
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private func dragGesture(maxHeight: CGFloat, currentOffset: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                let expandedOffset = offset(for: .expanded, in: maxHeight)
                let collapsedOffset = offset(for: .collapsed, in: maxHeight)
                let proposedOffset = currentOffset + value.translation.height
                let boundedOffset = min(max(proposedOffset, expandedOffset), collapsedOffset)
                dragOffset = boundedOffset - currentOffset
            }
            .onEnded { value in
                let projectedOffset = currentOffset + value.predictedEndTranslation.height
                let nextPosition = nearestPosition(for: projectedOffset, in: maxHeight)

                dragOffset = 0
                position = nextPosition
            }
    }

    private func nearestPosition(
        for proposedOffset: CGFloat,
        in maxHeight: CGFloat
    ) -> ProjectWorkspaceSheetPosition {
        ProjectWorkspaceSheetPosition.allCases.min { first, second in
            abs(offset(for: first, in: maxHeight) - proposedOffset) < abs(offset(for: second, in: maxHeight) - proposedOffset)
        } ?? .medium
    }

    private func offset(
        for position: ProjectWorkspaceSheetPosition,
        in maxHeight: CGFloat
    ) -> CGFloat {
        maxHeight - visibleHeight(for: position, in: maxHeight)
    }

    private func visibleHeight(
        for position: ProjectWorkspaceSheetPosition,
        in maxHeight: CGFloat
    ) -> CGFloat {
        switch position {
        case .collapsed:
            return min(112, maxHeight * 0.18)
        case .medium:
            return min(max(360, maxHeight * 0.48), maxHeight * 0.62)
        case .expanded:
            return maxHeight - 18
        }
    }
}
