//
//  LibraryItemPhotoContent.swift
//  KnitGether
//
//  관찰 6: 실, 바늘, 도구 상세의 대표 사진 블록. 부모의 섹션 안에 들어간다.
//  사진은 온라인 필수(v1) 동작이라 실패 시 안내 문구를 표시한다.
//

import PhotosUI
import SwiftUI
import UIKit

struct LibraryItemPhotoContent: View {
    let hasPhoto: Bool
    let loadPhoto: () async -> Data?
    let uploadPhoto: (Data) async -> Bool
    let deletePhoto: () async -> Bool

    @State private var photoData: Data?
    @State private var selectedItem: PhotosPickerItem?
    @State private var isWorking = false
    @State private var noticeText: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let photoData, let image = UIImage(data: photoData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else if hasPhoto {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
            } else {
                Text("사진을 등록하면 목록에서 눈으로 바로 구분할 수 있어요.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Label(hasPhoto ? "사진 바꾸기" : "사진 등록", systemImage: "photo.badge.plus")
                        .font(.caption.weight(.semibold))
                }
                .disabled(isWorking)

                if hasPhoto {
                    Button(role: .destructive) {
                        Task {
                            isWorking = true
                            let didDelete = await deletePhoto()
                            isWorking = false

                            if didDelete {
                                photoData = nil
                                noticeText = nil
                            } else {
                                noticeText = "사진을 삭제하지 못했어요. 서버 연결을 확인해 주세요."
                            }
                        }
                    } label: {
                        Label("사진 삭제", systemImage: "trash")
                            .font(.caption.weight(.semibold))
                    }
                    .disabled(isWorking)
                }

                if isWorking {
                    ProgressView()
                        .controlSize(.small)
                }

                Spacer(minLength: 0)
            }

            if let noticeText {
                Text(noticeText)
                    .font(.caption)
                    .foregroundStyle(AppTheme.Color.rose)
            }
        }
        .task(id: hasPhoto) {
            guard hasPhoto, photoData == nil else {
                return
            }

            photoData = await loadPhoto()
        }
        .onChange(of: selectedItem) { item in
            guard let item else {
                return
            }

            Task {
                defer { selectedItem = nil }

                guard let rawData = try? await item.loadTransferable(type: Data.self) else {
                    noticeText = "사진을 불러오지 못했어요."
                    return
                }

                // HEIC 등 포맷 편차를 없애기 위해 JPEG로 정규화해 업로드한다.
                let uploadData = UIImage(data: rawData)?.jpegData(compressionQuality: 0.85) ?? rawData

                isWorking = true
                let didUpload = await uploadPhoto(uploadData)
                isWorking = false

                if didUpload {
                    photoData = uploadData
                    noticeText = nil
                } else {
                    noticeText = "사진을 저장하지 못했어요. 서버 연결을 확인해 주세요."
                }
            }
        }
    }
}
