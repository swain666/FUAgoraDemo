//
//  MyVideoCapture.swift
//  Agora Video Source
//
//  Created by GongYuhua on 2017/4/11.
//  Copyright © 2017年 Agora. All rights reserved.
//

import UIKit
import AVFoundation

protocol MyVideoCaptureDelegate {
    func myVideoCapture(didOutput sampleBuffer:CMSampleBuffer, pixelBuffer: CVPixelBuffer)
}

enum Camera: Int {
    case front = 1
    case back = 0
    
    static func defaultCamera() -> Camera {
        return .front
    }
    
    func next() -> Camera {
        switch self {
        case .back: return .front
        case .front: return .back
        }
    }
}

class MyVideoCapture: NSObject {
    
    fileprivate var delegate: MyVideoCaptureDelegate?
    private var videoView: MyVideoView
    
     var currentCamera = Camera.defaultCamera()
    private let captureSession: AVCaptureSession
    private let captureQueue: DispatchQueue
    
    var isChangeMirr:Bool = true
    
//    private var currentOutput: AVCaptureVideoDataOutput
    private var currentOutput: AVCaptureVideoDataOutput? {
        if (self.captureSession.outputs as? [AVCaptureVideoDataOutput]) != nil {
        let outputs = self.captureSession.outputs as! [AVCaptureVideoDataOutput]
            return outputs.first!
        } else {
            return nil
        }
    }
    
    init(delegate: MyVideoCaptureDelegate?, videoView: MyVideoView) {
        self.delegate = delegate
        self.videoView = videoView
        
        captureSession = AVCaptureSession()
        captureSession.usesApplicationAudioSession = false
        
        let captureOutput = AVCaptureVideoDataOutput()
        captureOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
        
        if captureSession.canAddOutput(captureOutput) {
            captureSession.addOutput(captureOutput)
        }
        
        captureQueue = DispatchQueue(label: "MyCaptureQueue")
    }
    
    func startCapture(ofCamera camera: Camera) {
        guard let currentOutput = currentOutput else {
            return
        }
        
        currentCamera = camera
        currentOutput.setSampleBufferDelegate(self, queue: captureQueue)
        captureQueue.async { [unowned self] in
            self.changeCaptureDevice(toIndex: camera.rawValue, ofSession: self.captureSession)
            self.captureSession.beginConfiguration()
            self.captureSession.canSetSessionPreset(AVCaptureSessionPreset640x480)
            self.captureSession.commitConfiguration()
            self.captureSession.startRunning()
        }
    }
    
    func stopCapture() {
        currentOutput?.setSampleBufferDelegate(nil, queue: nil)
        captureQueue.async { [unowned self] in
            self.captureSession.stopRunning()
        }
    }
    
    func switchCamera() {
        
        isChangeMirr = true
        stopCapture()
        currentCamera = currentCamera.next()
        startCapture(ofCamera: currentCamera)
    }
}

private extension MyVideoCapture {
    func changeCaptureDevice(toIndex index: Int, ofSession captureSession: AVCaptureSession) {
        guard let captureDevice = captureDevice(atIndex: index) else {
            return
        }
        
        let currentInputs = captureSession.inputs as? [AVCaptureDeviceInput]
        let currentInput = currentInputs?.first
        
        if let currentInput = currentInput,
            let currentInputName = currentInput.device.localizedName,
            currentInputName == captureDevice.uniqueID {
            return
        }
        
        guard let newInput = try? AVCaptureDeviceInput(device: captureDevice) else {
            return
        }
        
        captureSession.beginConfiguration()
        if let currentInput = currentInput {
            captureSession.removeInput(currentInput)
        }
        if captureSession.canAddInput(newInput) {
            captureSession.addInput(newInput)
        }
        captureSession.commitConfiguration()
    }
    
    func captureDevice(atIndex index: Int) -> AVCaptureDevice? {
        guard let devices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) as? [AVCaptureDevice] else {
            return nil
        }
        
        let count = devices.count
        guard count > 0, index >= 0 else {
            return nil
        }
        
        let device: AVCaptureDevice
        if index >= count {
            device = devices.last!
        } else {
            device = devices[index]
        }
        
        return device
    }
}

extension MyVideoCapture: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        
        
        // 设置正向采集
        if connection.videoOrientation != .portrait {
            connection.videoOrientation = .portrait
        }
        // 前置摄像头会面镜像，后置不用镜像
        if isChangeMirr {
            isChangeMirr = false
            if self.currentCamera == .front {
                connection.isVideoMirrored = true
            }else {
                connection.isVideoMirrored = false
            }
        }
        
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        DispatchQueue.main.async {[weak self] _ in
            guard let weakSelf = self else {
                return
            }
            weakSelf.delegate?.myVideoCapture(didOutput: sampleBuffer, pixelBuffer: pixelBuffer)
        }
    }
}
