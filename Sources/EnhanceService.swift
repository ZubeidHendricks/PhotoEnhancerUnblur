import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

enum EnhanceError: Error { case badImage, notConfigured }

protocol PhotoEnhancing {
    /// strength 0…1; upscale 1, 2 or 4×.
    func enhance(_ image: UIImage, strength: Double, upscale: Int) async throws -> UIImage
}

/// On-device clarity pipeline: denoise → upscale (Lanczos) → unsharp + luminance
/// sharpen → mild contrast. Real, offline "unblur/enhance". Generative
/// super-resolution is the Remote upgrade.
struct OnDeviceEnhancer: PhotoEnhancing {
    private let context = CIContext()

    func enhance(_ image: UIImage, strength: Double, upscale: Int) async throws -> UIImage {
        try await Task.detached(priority: .userInitiated) {
            try Self.render(image: image, strength: strength, upscale: upscale, context: context)
        }.value
    }

    private static func render(image: UIImage, strength: Double, upscale: Int, context: CIContext) throws -> UIImage {
        guard let cg = image.normalizedUp().cgImage else { throw EnhanceError.badImage }
        var ci = CIImage(cgImage: cg)
        let s = max(0, min(1, strength))

        let nr = CIFilter.noiseReduction()
        nr.inputImage = ci; nr.noiseLevel = Float(0.015 * s); nr.sharpness = Float(0.4 + 0.4 * s)
        ci = nr.outputImage ?? ci

        if upscale > 1 {
            let scale = CIFilter.lanczosScaleTransform()
            scale.inputImage = ci; scale.scale = Float(upscale); scale.aspectRatio = 1
            ci = scale.outputImage ?? ci
        }

        let unsharp = CIFilter.unsharpMask()
        unsharp.inputImage = ci; unsharp.radius = 2.5; unsharp.intensity = Float(0.5 + 1.0 * s)
        ci = unsharp.outputImage ?? ci

        let sharp = CIFilter.sharpenLuminance()
        sharp.inputImage = ci; sharp.sharpness = Float(0.4 + 0.6 * s)
        ci = sharp.outputImage ?? ci

        let controls = CIFilter.colorControls()
        controls.inputImage = ci; controls.contrast = Float(1.0 + 0.06 * s); controls.saturation = Float(1.0 + 0.05 * s)
        ci = controls.outputImage ?? ci

        let extent = ci.extent
        guard let out = context.createCGImage(ci, from: extent) else { throw EnhanceError.badImage }
        return UIImage(cgImage: out)
    }
}

struct RemoteEnhancer: PhotoEnhancing {
    let apiKey: String
    func enhance(_ image: UIImage, strength: Double, upscale: Int) async throws -> UIImage { throw EnhanceError.notConfigured }
}

extension UIImage {
    func normalizedUp() -> UIImage {
        if imageOrientation == .up { return self }
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = scale
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
