import UIKit

enum PhotoMeasurementSource: String, CaseIterable, Hashable {
    case photoLibrary
    case camera

    var displayName: String {
        switch self {
        case .photoLibrary:
            "사진 앨범에서 선택"
        case .camera:
            "카메라로 촬영"
        }
    }

    var icon: String {
        switch self {
        case .photoLibrary:
            "photo.on.rectangle"
        case .camera:
            "camera"
        }
    }

    static func availableSources() -> [PhotoMeasurementSource] {
        UIImagePickerController.isSourceTypeAvailable(.camera)
            ? [.photoLibrary, .camera]
            : [.photoLibrary]
    }
}
