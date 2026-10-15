import CoreGraphics
import Foundation

@main
private enum MenuBarImageScaleResolverTests {
    static func main() {
        assertEqual(
            MenuBarImageScaleResolver.captureScale(
                pixelSize: CGSize(width: 33, height: 30),
                logicalSize: CGSize(width: 33, height: 30)
            ),
            1,
            "uses a 1x scale for a 1x menu bar item"
        )

        assertEqual(
            MenuBarImageScaleResolver.captureScale(
                pixelSize: CGSize(width: 66, height: 60),
                logicalSize: CGSize(width: 33, height: 30)
            ),
            2,
            "uses a 2x scale for a Retina menu bar item"
        )

        assertEqual(
            MenuBarImageScaleResolver.captureScale(
                pixelSize: CGSize(width: 1_224, height: 60),
                logicalSize: CGSize(width: 612, height: 30)
            ),
            2,
            "infers the scale of a composite capture from its output"
        )

        assertNil(
            MenuBarImageScaleResolver.captureScale(
                pixelSize: CGSize(width: 66, height: 30),
                logicalSize: CGSize(width: 33, height: 30)
            ),
            "rejects a capture that does not have one uniform scale"
        )

        assertNil(
            MenuBarImageScaleResolver.captureScale(
                pixelSize: .zero,
                logicalSize: CGSize(width: 33, height: 30)
            ),
            "rejects an empty capture"
        )

        print("PASS: menu bar image scale resolver")
    }

    private static func assertEqual<T: Equatable>(
        _ actual: T,
        _ expected: T,
        _ description: String
    ) {
        guard actual == expected else {
            fputs("FAIL: \(description) — expected \(expected), got \(actual)\n", stderr)
            exit(1)
        }
    }

    private static func assertNil<T>(_ actual: T?, _ description: String) {
        guard actual == nil else {
            fputs("FAIL: \(description) — expected nil, got \(actual!)\n", stderr)
            exit(1)
        }
    }
}
