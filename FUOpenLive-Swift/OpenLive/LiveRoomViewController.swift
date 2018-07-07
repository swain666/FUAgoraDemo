//
//  LiveRoomViewController.swift
//  OpenLive
//
//  Created by GongYuhua on 6/25/16.
//  Copyright © 2016 Agora. All rights reserved.
//

import UIKit
import AgoraRtcEngineKit

protocol LiveRoomVCDelegate: NSObjectProtocol {
    func liveVCNeedClose(_ liveVC: LiveRoomViewController)
}

class LiveRoomViewController: UIViewController {
    
    @IBOutlet weak var roomNameLabel: UILabel!
    @IBOutlet weak var remoteContainerView: UIView!
    @IBOutlet weak var broadcastButton: UIButton!
    @IBOutlet var sessionButtons: [UIButton]!
    @IBOutlet weak var audioMuteButton: UIButton!
    
    var roomName: String!
    var clientRole = AgoraClientRole.audience {
        didSet {
            updateButtonsVisiablity()
        }
    }
    var videoProfile: AgoraVideoProfile!
    weak var delegate: LiveRoomVCDelegate?
    
    //MARK: - engine & session view
    var rtcEngine: AgoraRtcEngineKit!
    fileprivate var isBroadcaster: Bool {
        return clientRole == .broadcaster
    }
    fileprivate var isMuted = false {
        didSet {
            rtcEngine?.muteLocalAudioStream(isMuted)
            audioMuteButton?.setImage(UIImage(named: isMuted ? "btn_mute_cancel" : "btn_mute"), for: .normal)
        }
    }
    
    fileprivate var videoSessions = [VideoSession]() {
        didSet {
            guard remoteContainerView != nil else {
                return
            }
            updateInterface(withAnimation: true)
        }
    }
    fileprivate var fullSession: VideoSession? {
        didSet {
            if fullSession != oldValue && remoteContainerView != nil {
                updateInterface(withAnimation: true)
            }
        }
    }
    
    fileprivate let viewLayouter = VideoViewLayouter()
    
    lazy var camera: FUCamera = {
        let camera = FUCamera.init()
        camera.delegate = self
        return camera
    }()
    
    lazy var glView : FUOpenGLView = {
        let view = FUOpenGLView.init(frame: UIScreen.main.bounds)
        return view
    }()
    
    lazy var demoBar : FUAPIDemoBar = {
        let demoBar = FUAPIDemoBar.init(frame: CGRect.init(x: 0, y: UIScreen.main.bounds.size.height - 180, width: UIScreen.main.bounds.size.width, height: 164))
        
        demoBar.itemsDataSource = FUManager.share().itemsDataSource;
        demoBar.selectedItem = FUManager.share().selectedItem ;

        demoBar.filtersDataSource = FUManager.share().filtersDataSource ;
        demoBar.beautyFiltersDataSource = FUManager.share().beautyFiltersDataSource ;
        demoBar.filtersCHName = FUManager.share().filtersCHName ;
        demoBar.selectedFilter = FUManager.share().selectedFilter ;
        demoBar.setFilterLevel(FUManager.share().selectedFilterLevel, forFilter: FUManager.share().selectedFilter)

        demoBar.skinDetectEnable = FUManager.share().skinDetectEnable;
        demoBar.blurShape = FUManager.share().blurShape ;
        demoBar.blurLevel = FUManager.share().blurLevel ;
        demoBar.whiteLevel = FUManager.share().whiteLevel ;
        demoBar.redLevel = FUManager.share().redLevel;
        demoBar.eyelightingLevel = FUManager.share().eyelightingLevel ;
        demoBar.beautyToothLevel = FUManager.share().beautyToothLevel ;
        demoBar.faceShape = FUManager.share().faceShape ;

        demoBar.enlargingLevel = FUManager.share().enlargingLevel ;
        demoBar.thinningLevel = FUManager.share().thinningLevel ;
        demoBar.enlargingLevel_new = FUManager.share().enlargingLevel_new ;
        demoBar.thinningLevel_new = FUManager.share().thinningLevel_new ;
        demoBar.jewLevel = FUManager.share().jewLevel ;
        demoBar.foreheadLevel = FUManager.share().foreheadLevel ;
        demoBar.noseLevel = FUManager.share().noseLevel ;
        demoBar.mouthLevel = FUManager.share().mouthLevel ;
        
        demoBar.delegate = self as FUAPIDemoBarDelegate

        return demoBar
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        roomNameLabel.text = roomName
        updateButtonsVisiablity()
        
        loadAgoraKit()
        
        if isBroadcaster {
            
            FUManager.share().loadItems()
            
            remoteContainerView.addSubview(glView)
            
            glView.addSubview(demoBar)
            
            camera.startCapture()
        }
    }
    
    //MARK: - user action
    @IBAction func doSwitchCameraPressed(_ sender: UIButton) {
        rtcEngine?.switchCamera()
    }
    
    @IBAction func doMutePressed(_ sender: UIButton) {
        isMuted = !isMuted
    }
    
    @IBAction func doBroadcastPressed(_ sender: UIButton) {
        if isBroadcaster {
            clientRole = .audience
            if fullSession?.uid == 0 {
                fullSession = nil
            }
        } else {
            clientRole = .broadcaster
        }
        
        rtcEngine.setClientRole(clientRole)
        updateInterface(withAnimation :true)
    }
    
    @IBAction func doDoubleTapped(_ sender: UITapGestureRecognizer) {
        if fullSession == nil {
            if let tappedSession = viewLayouter.responseSession(of: sender, inSessions: videoSessions, inContainerView: remoteContainerView) {
                fullSession = tappedSession
            }
        } else {
            fullSession = nil
        }
    }
    
    @IBAction func doLeavePressed(_ sender: UIButton) {
        leaveChannel()
    }
}

private extension LiveRoomViewController {
    func updateButtonsVisiablity() {
        guard let sessionButtons = sessionButtons else {
            return
        }
        
        broadcastButton?.setImage(UIImage(named: isBroadcaster ? "btn_join_cancel" : "btn_join"), for: UIControlState())
        broadcastButton.isHidden = !isBroadcaster
        for button in sessionButtons {
            button.isHidden = !isBroadcaster
        }
    }
    
    func leaveChannel() {
        setIdleTimerActive(true)
        
        rtcEngine.setupLocalVideo(nil)
        rtcEngine.leaveChannel(nil)
        if isBroadcaster {
            rtcEngine.stopPreview()
        }
        
        for session in videoSessions {
            session.hostingView.removeFromSuperview()
        }
        videoSessions.removeAll()
        
        delegate?.liveVCNeedClose(self)
    }
    
    func setIdleTimerActive(_ active: Bool) {
        UIApplication.shared.isIdleTimerDisabled = !active
    }
    
    func alert(string: String) {
        guard !string.isEmpty else {
            return
        }
        
        let alert = UIAlertController(title: nil, message: string, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}



extension LiveRoomViewController : FUCameraDelegate {

    func didOutputVideoSampleBuffer(_ sampleBuffer: CMSampleBuffer!) {

        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)

        FUManager.share().renderItems(to: pixelBuffer)
        
        glView.display(pixelBuffer)
        
        let videoFrame = AgoraVideoFrame.init()
        videoFrame.format = 12
        videoFrame.textureBuf = pixelBuffer
        videoFrame.time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        rtcEngine.pushExternalVideoFrame(videoFrame)
    }
}

extension LiveRoomViewController : FUAPIDemoBarDelegate {
    func demoBarBeautyParamChanged() {

        FUManager.share().skinDetectEnable = demoBar.skinDetectEnable;
        FUManager.share().blurShape = demoBar.blurShape;
        FUManager.share().blurLevel = demoBar.blurLevel ;
        FUManager.share().whiteLevel = demoBar.whiteLevel;
        FUManager.share().redLevel = demoBar.redLevel;
        FUManager.share().eyelightingLevel = demoBar.eyelightingLevel;
        FUManager.share().beautyToothLevel = demoBar.beautyToothLevel;
        FUManager.share().faceShape = demoBar.faceShape;
        FUManager.share().enlargingLevel = demoBar.enlargingLevel;
        FUManager.share().thinningLevel = demoBar.thinningLevel;
        FUManager.share().enlargingLevel_new = demoBar.enlargingLevel_new;
        FUManager.share().thinningLevel_new = demoBar.thinningLevel_new;
        FUManager.share().jewLevel = demoBar.jewLevel;
        FUManager.share().foreheadLevel = demoBar.foreheadLevel;
        FUManager.share().noseLevel = demoBar.noseLevel;
        FUManager.share().mouthLevel = demoBar.mouthLevel;

        FUManager.share().selectedFilter = demoBar.selectedFilter ;
        FUManager.share().selectedFilterLevel = demoBar.selectedFilterLevel;
    }

    func demoBarDidSelectedItem(_ itemName: String!) {

        FUManager.share().loadItem(itemName)
    }
}

private extension LiveRoomViewController {
    func updateInterface(withAnimation animation: Bool) {
        if animation {
            UIView.animate(withDuration: 0.3, animations: { [weak self] _ in
                self?.updateInterface()
                self?.view.layoutIfNeeded()
            })
        } else {
            updateInterface()
        }
    }
    
    func updateInterface() {
        var displaySessions = videoSessions
        if !isBroadcaster && !displaySessions.isEmpty {
            displaySessions.removeFirst()
        }
        viewLayouter.layout(sessions: displaySessions, fullSession: fullSession, inContainer: remoteContainerView)
        setStreamType(forSessions: displaySessions, fullSession: fullSession)
    }
    
    func setStreamType(forSessions sessions: [VideoSession], fullSession: VideoSession?) {
        if let fullSession = fullSession {
            for session in sessions {
                rtcEngine.setRemoteVideoStream(UInt(session.uid), type: (session == fullSession ? .high : .low))
            }
        } else {
            for session in sessions {
                rtcEngine.setRemoteVideoStream(UInt(session.uid), type: .high)
            }
        }
    }
    
    func addLocalSession() {
        let localSession = VideoSession.localSession()
        videoSessions.append(localSession)
        rtcEngine.setupLocalVideo(localSession.canvas)
    }
    
    func fetchSession(ofUid uid: Int64) -> VideoSession? {
        for session in videoSessions {
            if session.uid == uid {
                return session
            }
        }
        
        return nil
    }
    
    func videoSession(ofUid uid: Int64) -> VideoSession {
        if let fetchedSession = fetchSession(ofUid: uid) {
            return fetchedSession
        } else {
            let newSession = VideoSession(uid: uid)
            videoSessions.append(newSession)
            return newSession
        }
    }
}

//MARK: - Agora Media SDK
private extension LiveRoomViewController {
    func loadAgoraKit() {
        
        
        if  isBroadcaster {
            
            rtcEngine = AgoraRtcEngineKit.sharedEngine(withAppId: KeyCenter.AppId, delegate: self)
            rtcEngine.setChannelProfile(.liveBroadcasting)
            rtcEngine.setClientRole(.broadcaster)
            rtcEngine.enableVideo()
            rtcEngine.setVideoProfile(.portrait360P, swapWidthAndHeight: true)
            rtcEngine.setExternalVideoSource(true, useTexture: true, pushMode: true)
            isMuted = false ;
            rtcEngine.joinChannel(byToken: nil, channelId: roomName, info: nil, uid: 0, joinSuccess: nil)
        }else {
            
            rtcEngine = AgoraRtcEngineKit.sharedEngine(withAppId: KeyCenter.AppId, delegate: self)
            rtcEngine.setChannelProfile(.liveBroadcasting)
            rtcEngine.enableDualStreamMode(true)
            rtcEngine.enableVideo()
            rtcEngine.setVideoProfile(videoProfile, swapWidthAndHeight: true)
            rtcEngine.setClientRole(clientRole)
            
            addLocalSession()
            
            let code = rtcEngine.joinChannel(byToken: nil, channelId: roomName, info: nil, uid: 0, joinSuccess: nil)
            if code == 0 {
                setIdleTimerActive(false)
                rtcEngine.setEnableSpeakerphone(true)
            } else {
                DispatchQueue.main.async(execute: {
                    self.alert(string: "Join channel failed: \(code)")
                })
            }
        }
    }
}

extension LiveRoomViewController: AgoraRtcEngineDelegate {
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        let userSession = videoSession(ofUid: Int64(uid))
        rtcEngine.setupRemoteVideo(userSession.canvas)
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, firstLocalVideoFrameWith size: CGSize, elapsed: Int) {
        if let _ = videoSessions.first {
            updateInterface(withAnimation: false)
        }
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        var indexToDelete: Int?
        for (index, session) in videoSessions.enumerated() {
            if session.uid == Int64(uid) {
                indexToDelete = index
            }
        }
        
        if let indexToDelete = indexToDelete {
            let deletedSession = videoSessions.remove(at: indexToDelete)
            deletedSession.hostingView.removeFromSuperview()
            
            if deletedSession == fullSession {
                fullSession = nil
            }
        }
    }
}
