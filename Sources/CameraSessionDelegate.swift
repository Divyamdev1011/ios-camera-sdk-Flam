import AVFoundation

public protocol CameraSessionDelegate: AnyObject {
    func cameraSession(
        _ session: CameraSession,
        didOutputPixelBuffer buffer: CVPixelBuffer,
        timestamp: CMTime
    )
}
