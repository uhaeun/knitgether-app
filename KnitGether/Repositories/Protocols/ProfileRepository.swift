//
//  ProfileRepository.swift
//  KnitGether
//
//  Created by yu haeun on 6/4/26.
//

import Foundation

protocol ProfileRepository {
    func fetchCurrentProfile() async throws -> UserProfile
    func saveCurrentProfile(_ profile: UserProfile) async throws
}
