import CoreGraphics
import UIKit

enum GaugeCountConfidence: String, Codable, Hashable {
    case high
    case medium
    case low

    var displayName: String {
        switch self {
        case .high:
            "높음"
        case .medium:
            "보통"
        case .low:
            "낮음"
        }
    }
}

struct GaugeAutoCountResult: Hashable {
    enum Source: Hashable {
        case projection

        var displayName: String {
            "투영법"
        }
    }

    let stitches: Double
    let rows: Double
    let confidence: GaugeCountConfidence

    var source: Source {
        .projection
    }
}

struct GaugeAutoCounter {
    func estimateCounts(in image: UIImage, cornerPoints: [CGPoint]) -> GaugeAutoCountResult? {
        guard cornerPoints.count == 4 else {
            return nil
        }

        return ProjectionGaugeCountStrategy().count(image: image, corners: cornerPoints)
    }
}

private struct ProjectionGaugeCountStrategy {
    private let gridSize = 200

    func count(image: UIImage, corners: [CGPoint]) -> GaugeAutoCountResult? {
        guard let cgImage = image.cgImage else {
            return nil
        }

        let grid = LuminanceGrid(cgImage: cgImage, corners: corners, size: gridSize)
        let horizontalSignal = grid.horizontalProjection()
        let verticalSignal = grid.verticalProjection()
        let stitches = BandCounter.count(signal: horizontalSignal)
        let rows = BandCounter.count(signal: verticalSignal)

        guard stitches > 0, rows > 0 else {
            return nil
        }

        let confidence: GaugeCountConfidence = stitches > 8 && rows > 8 ? .medium : .low

        return GaugeAutoCountResult(
            stitches: Double(stitches),
            rows: Double(rows),
            confidence: confidence
        )
    }
}

private struct LuminanceGrid {
    private let values: [Float]
    private let size: Int

    init(cgImage: CGImage, corners: [CGPoint], size: Int) {
        self.size = size

        var raw = [UInt8](repeating: 0, count: cgImage.width * cgImage.height)
        let colorSpace = CGColorSpaceCreateDeviceGray()

        if let context = CGContext(
            data: &raw,
            width: cgImage.width,
            height: cgImage.height,
            bitsPerComponent: 8,
            bytesPerRow: cgImage.width,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) {
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
        }

        let imageWidth = CGFloat(cgImage.width)
        let imageHeight = CGFloat(cgImage.height)
        let topLeft = CGPoint(x: corners[0].x * imageWidth, y: corners[0].y * imageHeight)
        let topRight = CGPoint(x: corners[1].x * imageWidth, y: corners[1].y * imageHeight)
        let bottomRight = CGPoint(x: corners[2].x * imageWidth, y: corners[2].y * imageHeight)
        let bottomLeft = CGPoint(x: corners[3].x * imageWidth, y: corners[3].y * imageHeight)

        var sampledValues = [Float](repeating: 0, count: size * size)

        for row in 0..<size {
            let vertical = Float(row) / Float(size - 1)

            for column in 0..<size {
                let horizontal = Float(column) / Float(size - 1)
                let x = (1 - horizontal) * (1 - vertical) * Float(topLeft.x)
                    + horizontal * (1 - vertical) * Float(topRight.x)
                    + horizontal * vertical * Float(bottomRight.x)
                    + (1 - horizontal) * vertical * Float(bottomLeft.x)
                let y = (1 - horizontal) * (1 - vertical) * Float(topLeft.y)
                    + horizontal * (1 - vertical) * Float(topRight.y)
                    + horizontal * vertical * Float(bottomRight.y)
                    + (1 - horizontal) * vertical * Float(bottomLeft.y)

                let pixelX = min(max(Int(x), 0), cgImage.width - 1)
                let pixelY = min(max(Int(y), 0), cgImage.height - 1)
                sampledValues[row * size + column] = Float(raw[pixelY * cgImage.width + pixelX]) / 255.0
            }
        }

        values = sampledValues
    }

    func horizontalProjection() -> [Float] {
        (0..<size).map { column in
            (0..<size).reduce(0) { partialResult, row in
                partialResult + values[row * size + column]
            } / Float(size)
        }
    }

    func verticalProjection() -> [Float] {
        (0..<size).map { row in
            (0..<size).reduce(0) { partialResult, column in
                partialResult + values[row * size + column]
            } / Float(size)
        }
    }
}

private enum BandCounter {
    static func count(signal: [Float]) -> Int {
        guard signal.count > 4 else {
            return 0
        }

        let smoothedSignal = smooth(signal, radius: 3)
        var minima = 0

        for index in 1..<(smoothedSignal.count - 1) {
            if smoothedSignal[index] < smoothedSignal[index - 1],
               smoothedSignal[index] < smoothedSignal[index + 1] {
                minima += 1
            }
        }

        return minima
    }

    private static func smooth(_ signal: [Float], radius: Int) -> [Float] {
        signal.indices.map { index in
            let lowerBound = max(0, index - radius)
            let upperBound = min(signal.count - 1, index + radius)
            let sum = signal[lowerBound...upperBound].reduce(0, +)

            return sum / Float(upperBound - lowerBound + 1)
        }
    }
}
