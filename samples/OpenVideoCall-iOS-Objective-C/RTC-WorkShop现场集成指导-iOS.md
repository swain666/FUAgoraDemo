# RTC Workshop现场集成Faceunity指导文档

## 简介

本Demo基于OpenVideoCall集成。

在工程中搜索`TODO`，通过`TODO`查看需要完成的五个步骤，分别为：初始化，加载美颜道具，处理图像，切换道具，销毁道具。

5个步骤均完成后，将会得到一个在OpenVideoCall集成了Faceunity美颜与特效的Demo。

## 初始化
FaceunitySDK只需要初始化一次，故在`FUManager `单例初始化时对FaceunitySDK进行初始化，方式如下：

```C
NSString *path = [[NSBundle mainBundle] pathForResource:@"v3.bundle" ofType:nil];

[[FURenderer shareRenderer] setupWithDataPath:path authPackage:&g_auth_package authSize:sizeof(g_auth_package)];
```
以上接口的参数说明可在FURenderer.h中查看

## 加载美颜道具
进入房间时会在 `RoomViewController.m` 的 `viewDidLoad` 中调用 `[[FUManager shareManager] loadItems]` 加载贴纸道具，在Faceunity SDK中，美颜作为道具存在，使用美颜时也需要需要现加载美颜道具才能显示美颜效果。代码如下：

```C
/**加载美颜道具*/
- (void)loadFilter
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"face_beautification.bundle" ofType:nil];
    
    items[1] = [FURenderer itemWithContentsOfFile:path];
}
```


## 处理图像
在 `AGVideoPreProcessing.m` 的 `onCaptureVideoFrame` 视频回调接口中调用以下方法对视频图像进行处理：
	
```C
[[FUManager shareManager] renderItemsToYUVFrame:videoFrame.yBuffer u:videoFrame.uBuffer v:videoFrame.vBuffer ystride:videoFrame.yStride ustride:videoFrame.uStride vstride:videoFrame.vStride width:videoFrame.width height:videoFrame.height];
```

## 切换道具
实现FUAPIDemoBarDelegate方法，以配合UI实现道具的切换及美颜设置参数的设置

切换道具：

```C
- (void)demoBarDidSelectedItem:(NSString *)item
{
    // 加载道具
    [[FUManager shareManager] loadItem:item];
}
```

同步美颜参数：

```C
/**设置美颜参数*/
- (void)demoBarBeautyParamChanged
{
    [self syncBeautyParams];
}

- (void)syncBeautyParams
{
    [FUManager shareManager].selectedFilter = _fuDemoBar.selectedFilter;
    [FUManager shareManager].selectedBlur = _fuDemoBar.selectedBlur;
    [FUManager shareManager].beautyLevel = _fuDemoBar.beautyLevel;
    [FUManager shareManager].redLevel = _fuDemoBar.redLevel;
    [FUManager shareManager].faceShape = _fuDemoBar.faceShape;
    [FUManager shareManager].faceShapeLevel = _fuDemoBar.faceShapeLevel;
    [FUManager shareManager].thinningLevel = _fuDemoBar.thinningLevel;
    [FUManager shareManager].enlargingLevel = _fuDemoBar.enlargingLevel;
}
```

## 销毁道具
离开房间时销毁道具，在 `RoomViewController.m` 的 `leaveChannel` 中调用 `[[FUManager shareManager] destoryFaceunityItems]` 销毁faceunity全部道具，释放内存资源。

## 添加道具

最后为Demo添加一个新的道具 `bg_seg.bundle`，这个道具可以将人像抠图达到背景分割的效果。道具文件和icon资源已在项目中添加，且道具的文件名与icon的文件名相同，我们只需要在`FUManager `的`itemsDataSource`数组中添加`@"bg_seg"`，即可在程序启动后通过UI切换到该道具，显示出背景分割效果。

```C
self.itemsDataSource = @[@"noitem", @"lixiaolong", @"chibi_reimu", @"mask_liudehua",
					 @"yuguan", @"gradient", @"Mood", @"bg_seg"];
```