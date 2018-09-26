//
//  CaptureViewController.swift
//  QRCaptureDemo
//
//  Created by Nicolás Miari on 2017/10/12.
//  Copyright © 2017 Nicolás Miari. All rights reserved.
//

import UIKit
import AVFoundation

/**
 User Your Loaf's original blog post (tutorial):
 https://useyourloaf.com/blog/reading-qr-codes/

 Apple's docs:
 https://developer.apple.com/documentation/avfoundation/avcapturesession
 */
class CaptureViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    ///
    @IBOutlet weak var proceedButton: UIButton!

    private var codeObjects = [AVMetadataObject]()

    /**
     The original code's approach to lazy initiaization of session, with the
     'side effect' of the preview layer being created too was abandoned in favour
     of a more explicit approach (see `newCaptureSession()` and
     `resetLayers(with:)`).
     */
    private var captureSession: AVCaptureSession?
    private var targetLayer: CALayer?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        //proceedButton.layer.borderWidth = 1.0
        //proceedButton.layer.borderColor = UIColor.white.cgColor
        proceedButton.layer.cornerRadius = 10
        proceedButton.layer.masksToBounds = true

        proceedButton.setTitleColor(UIColor.darkGray, for: .normal)
        proceedButton.setBackgroundColor(UIColor.white, for: .normal)

        proceedButton.setTitleColor(UIColor.white, for: .highlighted)
        proceedButton.setBackgroundColor(UIColor.black, for: .highlighted)

        proceedButton.setTitleColor(UIColor.lightGray, for: .disabled)
        proceedButton.setBackgroundColor(UIColor.white, for: .disabled)

        proceedButton.isEnabled = false
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startRunning()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopRunning()
    }

    override func viewDidLayoutSubviews() {
        self.previewLayer?.bounds = self.view.bounds
    }

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "ShowResults" {
            return codeObjects.count > 0
        }
        return false
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowResults" {
            guard let destination = segue.destination as? ResultsViewController else {
                fatalError("!!!")
            }
            destination.results = codeObjects
        }
    }

    // MARK: - Control Actions

    @IBAction func cancel(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func proceed(_ sender: UIButton) {
        
    }

    // MARK: - Internal Operation

    private func newCaptureSession() -> AVCaptureSession? {
        let session = AVCaptureSession()

        guard let device = AVCaptureDevice.default(for: .video) else {
            return nil
        }
        if device.isAutoFocusRangeRestrictionSupported {
            do {
                try device.lockForConfiguration()
                device.autoFocusRangeRestriction = .near
                device.unlockForConfiguration()
            } catch {
                // TODO: alert user?
            }
        }
        guard let deviceInput = try? AVCaptureDeviceInput(device: device) else {
            return nil
        }
        guard session.canAddInput(deviceInput) else {
            return nil
        }
        session.addInput(deviceInput)

        let metadataOutput = AVCaptureMetadataOutput()
        guard session.canAddOutput(metadataOutput) else {
            return nil
        }
        session.addOutput(metadataOutput)
        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        metadataOutput.metadataObjectTypes = [.qr]

        return session
    }

    private func resetLayers(with session :AVCaptureSession) {
        if let previewLayer = self.previewLayer {
            previewLayer.removeFromSuperlayer()
        }
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = self.view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        self.view.layer.insertSublayer(previewLayer, at: 0)
        self.previewLayer = previewLayer

        if let targetLayer = self.targetLayer {
            targetLayer.removeFromSuperlayer()
        }
        let targetLayer = CALayer()
        targetLayer.frame = self.view.bounds
        self.view.layer.insertSublayer(targetLayer, above: previewLayer)
        self.targetLayer = targetLayer
    }

    private func startRunning() {
        codeObjects.removeAll()

        if let session = newCaptureSession() {
            self.captureSession = session
            resetLayers(with: session)
        }
        captureSession?.startRunning()
    }

    private func stopRunning() {
        captureSession?.stopRunning()
        self.captureSession = nil
    }

    private func clearTargetLayer() {
        guard let sublayers = targetLayer?.sublayers else {
            return
        }
        sublayers.forEach { $0.removeFromSuperlayer() }
    }

    private func showDetected(objects: [AVMetadataObject]) {
        objects.forEach {
            guard let object = $0 as? AVMetadataMachineReadableCodeObject else { return }
            let shapeLayer = CAShapeLayer()
            shapeLayer.strokeColor = UIColor.red.cgColor
            shapeLayer.lineWidth = 10
            shapeLayer.fillColor = UIColor.clear.cgColor
            shapeLayer.lineJoin = CAShapeLayerLineJoin.round
            shapeLayer.path = pathWithPoints(object.corners)

            targetLayer?.addSublayer(shapeLayer)
        }
    }

    private func pathWithPoints(_ points: [CGPoint]) -> CGPath {
        let path = CGMutablePath()

        if points.count > 0 {
            path.move(to: points[0])
            for index in 1 ..< points.count {
                let point = points[index]
                path.addLine(to: point)
            }
            path.closeSubpath()
        }

        return path
    }

    // MARK: - AVCaptureMetadataOutputObjectsDelegate

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection) {

        self.codeObjects.removeAll()

        let newObjects = metadataObjects.compactMap({ object in
            return self.previewLayer?.transformedMetadataObject(for: object)
        })
        self.codeObjects = newObjects

        self.proceedButton.isEnabled = (newObjects.count > 0)

        self.clearTargetLayer()
        self.showDetected(objects: newObjects)
    }
}

/**
 Taken from here: https://stackoverflow.com/a/44325883/433373
 */
extension UIButton {
    func setBackgroundColor(_ color: UIColor, for state: UIControl.State) {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        color.setFill()
        UIRectFill(rect)
        let colorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        setBackgroundImage(colorImage, for: state)
    }
}

