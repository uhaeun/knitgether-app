//
//  YarnLibraryViewModel.swift
//  KnitGether
//
//  Created by yu haeun on 6/7/26.
//

import Combine
import Foundation

@MainActor
final class YarnLibraryViewModel: ObservableObject {
    @Published private(set) var yarns: [Yarn] = []
    @Published private(set) var errorMessage: String?

    private let libraryRepository: any LibraryRepository

    init(libraryRepository: any LibraryRepository) {
        self.libraryRepository = libraryRepository
    }

    func loadYarns() async {
        do {
            yarns = try await libraryRepository.fetchYarns()
            errorMessage = nil
        } catch {
            errorMessage = "실 창고를 불러오지 못했어요."
        }
    }

    func addYarn(from formData: YarnFormData) async -> Bool {
        guard formData.canSave else {
            errorMessage = "실 이름은 비워둘 수 없어요."
            return false
        }

        let now = Date()
        let yarn = Yarn(
            ownerId: SampleData.ownerId,
            name: formData.trimmedName,
            brand: formData.trimmedBrand,
            colorName: formData.trimmedColorName,
            colorCode: formData.trimmedColorCode,
            weight: formData.trimmedWeight,
            lengthMeters: formData.lengthMetersValue,
            fiberContent: formData.trimmedFiberContent,
            gaugeMemo: formData.trimmedGaugeMemo,
            quantity: formData.quantityValue,
            memo: formData.trimmedMemo,
            createdAt: now,
            updatedAt: now
        )

        do {
            try await libraryRepository.saveYarn(yarn)
            await loadYarns()
            return true
        } catch {
            errorMessage = "실을 저장하지 못했어요."
            return false
        }
    }

    func updateYarn(_ yarn: Yarn, with formData: YarnFormData) async -> Bool {
        guard formData.canSave else {
            errorMessage = "실 이름은 비워둘 수 없어요."
            return false
        }

        let updatedYarn = Yarn(
            id: yarn.id,
            ownerId: yarn.ownerId,
            name: formData.trimmedName,
            brand: formData.trimmedBrand,
            colorName: formData.trimmedColorName,
            colorCode: formData.trimmedColorCode,
            weight: formData.trimmedWeight,
            lengthMeters: formData.lengthMetersValue,
            fiberContent: formData.trimmedFiberContent,
            gaugeMemo: formData.trimmedGaugeMemo,
            quantity: formData.quantityValue,
            memo: formData.trimmedMemo,
            createdAt: yarn.createdAt,
            updatedAt: Date(),
            deletedAt: yarn.deletedAt,
            syncStatus: yarn.syncStatus
        )

        do {
            try await libraryRepository.saveYarn(updatedYarn)
            await loadYarns()
            return true
        } catch {
            errorMessage = "실을 수정하지 못했어요."
            return false
        }
    }

    func deleteYarn(_ yarn: Yarn) async {
        do {
            try await libraryRepository.deleteYarn(id: yarn.id)
            await loadYarns()
            errorMessage = nil
        } catch {
            errorMessage = "실을 삭제하지 못했어요."
        }
    }
}
