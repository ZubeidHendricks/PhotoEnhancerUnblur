import XCTest
import UIKit
// EnhanceService.swift compiled into this test target.

final class EnhanceTests: XCTestCase {
    private func image(_ s: CGFloat = 200) -> UIImage {
        let f = UIGraphicsImageRendererFormat.default(); f.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: s, height: s), format: f).image { c in
            UIColor.gray.setFill(); c.fill(CGRect(x: 0, y: 0, width: s, height: s))
        }
    }

    func testEnhanceKeepsDimensionsAt1x() async throws {
        let out = try await OnDeviceEnhancer().enhance(image(), strength: 0.6, upscale: 1)
        XCTAssertEqual(out.cgImage?.width, 200)
    }

    func testUpscaleDoublesDimensions() async throws {
        let out = try await OnDeviceEnhancer().enhance(image(), strength: 0.6, upscale: 2)
        XCTAssertEqual(out.cgImage?.width, 400)
    }
}
