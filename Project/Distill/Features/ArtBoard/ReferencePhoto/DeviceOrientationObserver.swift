import SwiftUI

/// Stub — orientation observation is optional polish not needed
/// for the current feature. Uncomment and wire into a view when
/// landscape/portrait repositioning is implemented.
@Observable
final class DeviceOrientationObserver {

    private(set) var orientation: UIDeviceOrientation = .portrait

}
