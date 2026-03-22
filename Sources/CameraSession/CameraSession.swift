import AVFoundation

public class CameraSession {

    public weak var delegate: CameraSessionDelegate?

    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")

    private let delegateQueue: DispatchQueue
    private var videoOutput = AVCaptureVideoDataOutput()

    public init(delegateQueue: DispatchQueue? = nil) {
        self.delegateQueue = delegateQueue ?? DispatchQueue.main
    }

    public func configure(resolution: AVCaptureSession.Preset, fps: Int) throws {
      sessionQueue.sync {

    captureSession.beginConfiguration()

    captureSession.sessionPreset = resolution

    guard let device = AVCaptureDevice.default(for: .video),
          let input = try? AVCaptureDeviceInput(device: device),
          captureSession.canAddInput(input) else {
        return
    }

    captureSession.addInput(input)

    if captureSession.canAddOutput(videoOutput) {
        captureSession.addOutput(videoOutput)
    }

    videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)


    var selectedFormat: AVCaptureDevice.Format?

    for format in device.formats {
        for range in format.videoSupportedFrameRateRanges {
            if range.maxFrameRate >= Double(fps) {
                selectedFormat = format
                break
            }
        }
        if selectedFormat != nil { break }
    }

    guard let format = selectedFormat else {
        captureSession.commitConfiguration()
        return
    }

    do {
        try device.lockForConfiguration()

        device.activeFormat = format
        device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: CMTimeScale(fps))
        device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: CMTimeScale(fps))

        device.unlockForConfiguration()
    } catch {
        print("Device config error: \(error)")
    }

    captureSession.commitConfiguration()
}
    }

    public func start() {
        sessionQueue.async {
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
        }
    }

    public func stop() {
        sessionQueue.async {
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
        }
    }
}

extension CameraSession: AVCaptureVideoDataOutputSampleBufferDelegate {

    public func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

        delegateQueue.async {
            self.delegate?.cameraSession(self,
                                         didOutputPixelBuffer: pixelBuffer,
                                         timestamp: timestamp)
        }
    }
}

