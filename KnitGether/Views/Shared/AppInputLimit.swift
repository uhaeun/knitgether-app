import Foundation

/// 입력 길이 상한 모음.
/// 프로젝트 이름 30자 구현(SPEC-PROJ-01)과 같은 UX를 쓴다.
/// 글자 수 카운터(n/상한)를 표시하고, 타이핑이든 붙여넣기든 상한을 넘는 입력은 잘라 반영한다.
enum AppInputLimit {
    /// 창고 실, 바늘, 도구 이름과 수동 도안 제목. 프로젝트 이름 상한(30자)과 같은 값을 쓴다.
    static let name = ProjectFormData.nameCharacterLimit

    /// 프로젝트 메모, 창고 메모류.
    static let memo = 500

    /// 표시 이름. 서버 상한 80자(auth-register.dto)와 같은 값을 쓴다.
    static let displayName = 80

    /// 비밀번호. 서버 규칙은 8자 이상 256자 이하다(auth-register.dto).
    static let password = 256
}
