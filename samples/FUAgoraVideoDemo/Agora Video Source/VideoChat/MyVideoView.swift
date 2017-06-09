//
//  MyVideoView.swift
//  Agora Video Source
//
//  Created by GongYuhua on 2017/4/11.
//  Copyright © 2017年 Agora. All rights reserved.
//

import UIKit
import AVFoundation

class MyVideoView: UIView {
    
    lazy var bufferDisplay: AVSampleBufferDisplayLayer = {
        
        var buffer = AVSampleBufferDisplayLayer()
        buffer.videoGravity = AVLayerVideoGravityResizeAspectFill
        buffer.frame = self.bounds
        self.layer.insertSublayer(buffer, at: 0)
        return buffer
    }()
    
    // 展示 CMSampleBuffer
    func displayBuffer(sampleBuffer: CMSampleBuffer) {
        
        if bufferDisplay.status == .failed {
            bufferDisplay.flush()
        }
        
        if bufferDisplay.isReadyForMoreMediaData {
            bufferDisplay.enqueue(sampleBuffer)
        }
    }
    
}
