//
//  ProjectProgressPhotoPanelView.swift
//  KnitGether
//
//  Created by Codex on 7/9/26.
//

import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

struct ProjectProgressPhotoPanelView: View {
    @ObservedObject var viewModel: ProjectWorkspaceViewModel
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var editingPhoto: ProjectProgressPhoto?
    @State private var isImportingPhoto = false

    var body: some View {
        WorkspaceSectionView(title: "진행 사진", systemImage: "camera") {
            VStack(alignment: .leading, spacing: 14) {
                if viewModel.progressPhotos.isEmpty {
                    emptyState
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 12) {
                            ForEach(viewModel.progressPhotos) { photo in
                                Button {
                                    editingPhoto = photo
                                } label: {
                                    ProgressPhotoThumbnailView(
                                        photo: photo,
                                        fileURL: viewModel.progressPhotoFileURL(for: photo)
                                    )
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier(AppAccessibilityID.Workspace.progressPhotoRow(photo.id))
                            }
                        }
                    }
                }

                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Label(isImportingPhoto ? "업로드 중" : "사진 추가", systemImage: "photo.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier(AppAccessibilityID.Workspace.progressPhotoAddButton)
                .disabled(isImportingPhoto)
            }
        }
        .onChange(of: selectedPhotoItem) { newItem in
            guard let newItem else {
                return
            }

            Task {
                await importPhoto(from: newItem)
                selectedPhotoItem = nil
            }
        }
        .sheet(item: $editingPhoto) { photo in
            ProgressPhotoDetailSheet(
                photo: photo,
                fileURL: viewModel.progressPhotoFileURL(for: photo),
                updateAction: { caption, takenAt in
                    await viewModel.updateProgressPhoto(photo, caption: caption, takenAt: takenAt)
                },
                deleteAction: {
                    await viewModel.deleteProgressPhoto(photo)
                }
            )
        }
    }

    private var emptyState: some View {
        AppSoftPanel {
            VStack(alignment: .leading, spacing: 8) {
                Label("아직 진행 사진이 없어요.", systemImage: "camera")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("프로젝트 변화나 피팅 상태를 사진으로 남겨두세요.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func importPhoto(from item: PhotosPickerItem) async {
        isImportingPhoto = true
        defer {
            isImportingPhoto = false
        }

        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                return
            }

            let contentType = item.supportedContentTypes.first
            let fileExtension = contentType?.preferredFilenameExtension ?? "jpg"
            let mimeType = contentType?.preferredMIMEType ?? "image/jpeg"
            let fileName = "progress-photo-\(UUID().uuidString.lowercased()).\(fileExtension)"

            await viewModel.addProgressPhoto(
                imageData: data,
                fileName: fileName,
                contentType: mimeType,
                caption: "",
                takenAt: Date()
            )
        } catch {
        }
    }
}

private struct ProgressPhotoThumbnailView: View {
    let photo: ProjectProgressPhoto
    let fileURL: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            thumbnail
                .frame(width: 118, height: 118)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(captionText)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .frame(width: 118, alignment: .leading)

            Text(photo.takenAt.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 118, alignment: .leading)
        }
        .padding(10)
        .background(AppTheme.Color.warmBackground, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(AppTheme.Color.warmDivider, lineWidth: 1)
        }
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let fileURL, let image = UIImage(contentsOfFile: fileURL.path) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppTheme.Color.accentSoft)
                Image(systemName: "photo")
                    .font(.title2)
                    .foregroundStyle(AppTheme.Color.accent)
            }
        }
    }

    private var captionText: String {
        let trimmed = photo.caption.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "캡션 없음" : trimmed
    }
}

private struct ProgressPhotoDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var caption: String
    @State private var takenAt: Date
    @State private var isShowingDeleteConfirmation = false

    let photo: ProjectProgressPhoto
    let fileURL: URL?
    let updateAction: (String, Date) async -> Bool
    let deleteAction: () async -> Bool

    init(
        photo: ProjectProgressPhoto,
        fileURL: URL?,
        updateAction: @escaping (String, Date) async -> Bool,
        deleteAction: @escaping () async -> Bool
    ) {
        self.photo = photo
        self.fileURL = fileURL
        self.updateAction = updateAction
        self.deleteAction = deleteAction
        _caption = State(initialValue: photo.caption)
        _takenAt = State(initialValue: photo.takenAt)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    AppFormSection(
                        title: "사진",
                        description: "프로젝트 진행 상태를 확인할 대표 이미지를 보관해요.",
                        systemImage: "photo",
                        tint: AppTheme.Color.accent
                    ) {
                        Group {
                            if let fileURL, let image = UIImage(contentsOfFile: fileURL.path) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: .infinity)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            } else {
                                Label("사진 파일을 불러오지 못했어요.", systemImage: "photo")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, minHeight: 160)
                                    .background(AppTheme.Color.accentSoft.opacity(0.45), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                        }
                        .padding(.vertical, 12)
                    }

                    AppFormSection(
                        title: "기록",
                        description: "날짜와 캡션을 수정해 진행 흐름을 정리해요.",
                        systemImage: "calendar",
                        tint: AppTheme.Color.slate
                    ) {
                        DatePicker("촬영일", selection: $takenAt)
                            .font(.subheadline.weight(.semibold))
                            .tint(AppTheme.Color.softAccent)
                            .padding(.vertical, 12)
                            .accessibilityIdentifier(AppAccessibilityID.Workspace.progressPhotoTakenAtPicker)

                        AppFormDivider()

                        AppFormTextFieldRow(
                            title: "캡션",
                            placeholder: "예: 몸판 60% 완료",
                            systemImage: "text.alignleft",
                            text: $caption,
                            axis: .vertical,
                            minHeight: 86,
                            identifier: AppAccessibilityID.Workspace.progressPhotoCaptionField
                        )
                    }

                    Button(role: .destructive) {
                        isShowingDeleteConfirmation = true
                    } label: {
                        Label("사진 삭제", systemImage: "trash")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(AppTheme.Color.danger)
                    .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(AppTheme.Color.danger.opacity(0.25), lineWidth: 1)
                    }
                    .accessibilityIdentifier(AppAccessibilityID.Workspace.progressPhotoDeleteButton)
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 96)
            }
            .background(AppTheme.Color.warmBackground.ignoresSafeArea())
            .navigationTitle("진행 사진")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                AppFormSubmitBar(
                    title: "저장",
                    isDisabled: false,
                    accessibilityIdentifier: AppAccessibilityID.Workspace.progressPhotoSaveButton
                ) {
                    Task {
                        let didSave = await updateAction(caption, takenAt)
                        if didSave {
                            dismiss()
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") {
                        dismiss()
                    }
                }
            }
            .alert("사진을 삭제할까요?", isPresented: $isShowingDeleteConfirmation) {
                Button("취소", role: .cancel) {}

                Button("삭제", role: .destructive) {
                    Task {
                        let didDelete = await deleteAction()
                        if didDelete {
                            dismiss()
                        }
                    }
                }
            } message: {
                Text("삭제한 진행 사진은 복구할 수 없어요.")
            }
        }
    }
}
