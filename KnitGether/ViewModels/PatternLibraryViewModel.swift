//
//  PatternLibraryViewModel.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import Combine
import Foundation

nonisolated struct PatternFormData {
    var title = ""
    var designer = ""
    var pageCountText = ""
    var notes = ""

    init() {
    }

    init(
        title: String,
        designer: String,
        pageCountText: String,
        notes: String
    ) {
        self.title = title
        self.designer = designer
        self.pageCountText = pageCountText
        self.notes = notes
    }

    init(pattern: PatternDocument) {
        title = pattern.title
        designer = pattern.designer ?? ""
        pageCountText = pattern.pageCount.map(String.init) ?? ""
        notes = pattern.notes
    }

    var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedDesigner: String? {
        let trimmed = designer.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var trimmedNotes: String {
        notes.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var pageCount: Int? {
        let trimmed = pageCountText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        return Int(trimmed)
    }

    var canSave: Bool {
        !trimmedTitle.isEmpty && isPageCountValid
    }

    private var isPageCountValid: Bool {
        let trimmed = pageCountText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return true
        }

        guard let value = Int(trimmed) else {
            return false
        }

        return value >= 0
    }
}

@MainActor
final class PatternLibraryViewModel: ObservableObject {
    @Published private(set) var patterns: [PatternDocument] = []
    @Published private(set) var isRetryingSync = false
    @Published private(set) var errorMessage: String?
    @Published var searchText = ""

    private let patternRepository: any PatternRepository

    init(patternRepository: any PatternRepository) {
        self.patternRepository = patternRepository
    }

    var filteredPatterns: [PatternDocument] {
        Self.filteredPatterns(patterns, matching: searchText)
    }

    var hasPatternsNeedingSync: Bool {
        patterns.contains { $0.syncStatus.needsSync }
    }

    func loadPatterns() async {
        do {
            patterns = try await patternRepository.fetchPatterns()
            errorMessage = nil
        } catch {
            errorMessage = "도안 창고를 불러오지 못했어요."
        }
    }

    func retrySync() async {
        guard !isRetryingSync else {
            return
        }

        isRetryingSync = true
        await loadPatterns()
        isRetryingSync = false
    }

    func addPattern(fromFileAt fileURL: URL) async {
        do {
            _ = try await patternRepository.createPattern(fromFileAt: fileURL)
            patterns = try await patternRepository.fetchPatterns()
            errorMessage = nil
        } catch {
            errorMessage = "도안을 등록하지 못했어요."
        }
    }

    func updatePattern(_ pattern: PatternDocument, from formData: PatternFormData) async -> Bool {
        guard formData.canSave else {
            errorMessage = "도안 제목을 입력하고 페이지 수를 숫자로 적어 주세요."
            return false
        }

        let now = Date()
        let updatedPattern = PatternDocument(
            id: pattern.id,
            ownerId: pattern.ownerId,
            title: formData.trimmedTitle,
            designer: formData.trimmedDesigner,
            fileName: pattern.fileName,
            localFilePath: pattern.localFilePath,
            pageCount: formData.pageCount,
            notes: formData.trimmedNotes,
            createdAt: pattern.createdAt,
            updatedAt: now,
            deletedAt: pattern.deletedAt,
            syncStatus: pattern.syncStatus
        )

        do {
            try await patternRepository.savePattern(updatedPattern)
            patterns = try await patternRepository.fetchPatterns()
            errorMessage = nil
            return true
        } catch {
            errorMessage = "도안 정보를 저장하지 못했어요."
            return false
        }
    }

    func preparePatternForViewing(_ pattern: PatternDocument) async -> PatternDocument? {
        if patternRepository.fileURL(for: pattern) != nil {
            errorMessage = nil
            return pattern
        }

        do {
            guard let fetchedPattern = try await patternRepository.fetchPattern(id: pattern.id) else {
                errorMessage = "도안을 찾지 못했어요."
                return nil
            }

            replacePatternInList(fetchedPattern)
            errorMessage = nil
            return fetchedPattern
        } catch {
            errorMessage = "도안 파일을 불러오지 못했어요."
            return pattern
        }
    }

    func fileURL(for pattern: PatternDocument) -> URL? {
        patternRepository.fileURL(for: pattern)
    }

    @discardableResult
    func deletePattern(_ pattern: PatternDocument) async -> Bool {
        do {
            try await patternRepository.deletePattern(id: pattern.id)
            patterns = try await patternRepository.fetchPatterns()
            errorMessage = nil
            return true
        } catch {
            errorMessage = "도안을 삭제하지 못했어요."
            return false
        }
    }

    private func replacePatternInList(_ pattern: PatternDocument) {
        if let index = patterns.firstIndex(where: { $0.id == pattern.id }) {
            patterns[index] = pattern
        } else {
            patterns.append(pattern)
        }
    }

    static func filteredPatterns(_ patterns: [PatternDocument], matching searchText: String) -> [PatternDocument] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !query.isEmpty else {
            return patterns
        }

        return patterns.filter { pattern in
            pattern.title.localizedCaseInsensitiveContains(query)
                || pattern.designer?.localizedCaseInsensitiveContains(query) == true
                || pattern.fileName?.localizedCaseInsensitiveContains(query) == true
                || pattern.notes.localizedCaseInsensitiveContains(query)
        }
    }
}
