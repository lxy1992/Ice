//
//  MenuBarImageScaleResolver.swift
//  Ice
//

import CoreGraphics

/// Resolves the backing scale used for a captured menu bar image.
enum MenuBarImageScaleResolver {
    /// Returns the uniform scale between a captured image's pixel size and
    /// the corresponding menu bar window's logical size. The capture itself
    /// is the source of truth because menu bar windows can span displays with
    /// different backing scales.
    static func captureScale(
        pixelSize: CGSize,
        logicalSize: CGSize
    ) -> CGFloat? {
        guard
            pixelSize.width > 0,
            pixelSize.height > 0,
            logicalSize.width > 0,
            logicalSize.height > 0
        else {
            return nil
        }

        let widthScale = pixelSize.width / logicalSize.width
        let heightScale = pixelSize.height / logicalSize.height
        let tolerance = max(widthScale, heightScale) * 0.01

        guard
            widthScale >= 1,
            heightScale >= 1,
            abs(widthScale - heightScale) <= tolerance
        else {
            return nil
        }

        return widthScale
    }
}
