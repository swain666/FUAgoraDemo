//
//  MediaInfo.swift
//  OpenVideoCall
//
//  Created by GongYuhua on 4/11/16.
//  Copyright © 2016 Agora. All rights reserved.
//

import Foundation

struct MediaInfo {
    var resolution = CGSize.zero
    var fps = 0
    var bitRate = 0
    
    init() {}
    
    init?(videoProfile: AgoraRtcVideoProfile) {
        if let resolution = videoProfile.resolution(), let bitRate = videoProfile.bitRate() {
            self.resolution = resolution
            self.bitRate = bitRate
            self.fps = videoProfile.fps()
        } else {
            return nil
        }
    }
    
    func description() -> String {
        return "\(Int(resolution.width))×\(Int(resolution.height)), \(fps)fps, \(bitRate)k"
    }
}

extension AgoraRtcVideoProfile {
    static func defaultProfile() -> AgoraRtcVideoProfile {
        return ._VideoProfile_360P
    }
    
    static func validProfileList() -> [AgoraRtcVideoProfile] {
        return [._VideoProfile_120P,
                ._VideoProfile_180P,
                ._VideoProfile_240P,
                ._VideoProfile_360P,
                ._VideoProfile_480P,
                ._VideoProfile_720P]
    }
    
    func resolution() -> CGSize? {
        switch self {
        case ._VideoProfile_120P: return CGSize(width:160, height: 120)
        case ._VideoProfile_180P: return CGSize(width: 320, height: 180)
        case ._VideoProfile_240P: return CGSize(width:320, height: 240)
        case ._VideoProfile_360P: return CGSize(width:640, height: 320)
        case ._VideoProfile_480P: return CGSize(width:640, height: 480)
        case ._VideoProfile_720P: return CGSize(width:1280, height: 720)
        default: return nil
        }
    }
    
    func fps() -> Int {
        return 15
    }
    
    func bitRate() -> Int? {
        switch self {
        case ._VideoProfile_120P: return 65
        case ._VideoProfile_180P: return 140
        case ._VideoProfile_240P: return 200
        case ._VideoProfile_360P: return 400
        case ._VideoProfile_480P: return 500
        case ._VideoProfile_720P: return 1130
        default: return nil
        }
    }
}
