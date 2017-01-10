# OpenLive_iOS

Agora OpenLive is a demo of [Agora.io](http://www.agora.io) Interactive Broadcasting - iOS

* Up to 7 hosts / presenters 
* Any audience can call in to join live conversations 
* Super low latency, less than 1 second
* Switch stream type / screen UI freely 
* Unique anti-packet-loss algorithm  
* Globally distributed data centers to ensure international usage

Agora OpenLive 是[声网Agora.io](http://cn.agora.io)多人主播和视频连麦直播demo - iOS

* 最多7人同时主播
* 观众主播视频连麦
* 毫秒级超低延迟，秒杀CDN
* 大小流切换，多主播视窗随意切换
* 超强抗丢包，网络不好直播仍然流畅
* 跨洲跨国数据中心，保障直播全球扩展

##Agora OpenLive Overview

This demo is featuring live interactive broadcasting with the following unique features: 

1. Support 4 hosts by default (can be extended to 7). UI design can be self defined. 
2. Audiences can call in with audio / video. 
3. Switch video stream free with different screen UI.
4. Globally broadcasting.

This demo shall be working only with [Agora.io](http://www.agora.io) interactive broadcasting SDK. Please contact <mailto:sales@agora.io>. Developers from China can call 400 632 6626.

这个Demo模拟的是一个有多人主播同时对话，并且对观众直播的App。主要有4个独特之处：

1. 主播人数目前最多可以同时支持4人（SDK支持7人），也可以是4人以下任何人数。可根据场景来自由定义和设计视窗UI；
2. 支持观众和主播语音／视频连麦；
3. 支持大小流切换，观众在多视窗观看时，可选择任意主播放大主屏观看；
4. 支持全球范围的直播，跨国跨洲直播

该Demo需要基于[声网Agora.io](http://cn.agora.io)的实时互动直播技术才能运行。如有需求，请联系<mailto:sales@agora.io>。中国用户可直接拨打400 632 6626。

##Agora.io Interactive Broadcasting

[Agora.io](http://www.agora.io) Interactive Broadcasting is based on UDP featuring super low latency/delay, less than 1 second. This ensures “real time presence” experience when multiple hosts talking lively and when audiences call in.

[Agora.io](http://www.agora.io) has 100 data centers distributed globally. With the virtual network, the broadcasting experience are stable and smooth. 

[Agora.io](http://www.agora.io) Interactive Broadcasting SDK is available for iOS, Android, macOS and Windows, supporting RTMP and HLS. It enables bit rate auto adjustment to adapt to broadcasting under different bandwidth.

This demo does not include broadcasting business server. Developers can build your own business server and interact with [Agora.io](http://www.agora.io) SDK.

[声网Agora.io](http://cn.agora.io)的实时互动直播技术，区别于所有CDN方案。它是全球第一个以UDP为基础的直播方案。与传统CDN方案相比，最大的特点是超低延时，基本都在毫秒级的延迟。这能保证在多个主播及观众连麦时，有“实时对话”的体验。

[声网Agora.io](http://cn.agora.io)在全球部署了将近100个数据中心，加上lastmile算法，有超强抗丢包特点，可以保障全球范围稳定靠谱的直播体验。

[声网Agora.io](http://cn.agora.io)的客户端SDK，支持iOS、Android、macOS和Windows，支持RTMP、HLS协议。另外客户端SDK还支持码率自适应，以适应不同网络环境直播需求。支持美颜。

此Demo不涉及到直播业务服务器部分，此部分一般由开发者自行开发，然后和[声网Agora.io](http://cn.agora.io)直播服务交互。


## Bug reports

* https://github.com/AgoraLab/OpenLive_iOS/issues


## Build Instructions

NOTICE: before building, you need to


1. update your key at OpenLive/KeyCenter.swift

	you can get your vendor key at https://dashboard.agora.io


2. update AgoraRtcEngineKit.framework at OpenLive/libs

3. update videoprp.framework at OpenLive


Enjoy video broadcasting!
