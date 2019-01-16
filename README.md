# cordova-plugin-gaode-location

基于cordova封装的高德地图定位插件
* 单次定位 getLocation方法 去除retGeo参数
* 持续定位 watchLocation方法

<strong>变更</strong>
* 当无权限时直接返回错误回调，不直接显示错误信息。 errorCode: 12

# Install

```bash
cordova plugin add cordova-plugin-gaode-location-v2 --variable ANDROIDKEY=YOU_ANDROIDKEY --variable IOSKEY=YOU_IOSKEY --variable LOCATION_USAGE_DESCRIPTION="使用定位功能以查询人员附近公交车辆"
```

# Parameters

Android端和iOS端各自有各自的参数

## configLocation方法

### Android:

- locationMode(number)：定位的模式（精度逐级递减，具体对应的模式参考官网），默认： 1
  - 1：Hight_Accuracy
  - 2：Device_Sensors
  - 3：Battery_Saving
- httpTimeout：定位超时时间, 单位ms，默认：30000

### iOS

- accuracy(number)：定位精度（精度逐级递减，具体对应的模式参考官网），默认：3
  - 1: kCLLocationAccuracyBestForNavigation
  - 2: kCLLocationAccuracyBest
  - 3: kCLLocationAccuracyNearestTenMeters
  - 4: kCLLocationAccuracyHundredMeters
  - 5: kCLLocationAccuracyKilometer
  - 6: kCLLocationAccuracyThreeKilometers
- locationTimeout：定位超时时间，单位s 默认：10
- reGeoCodeTimeout：逆地址超时时间，单位s 默认：5

  ## getLocation方法

  - ~~retGeo: 是否返回逆地址，默认：true, 这个参数已不再生效~~

# Success return data

- latitude：经度
- longitude：纬度
- country： 国家
- province：省
- city：市
- district：区
- address：具体地址
- cityCode: 城市代码
- adCode: 行政区划代码

# Useage

```Javascript
var onLocationReady = $q.defer();
// 定制参数
var para = {
  android: {
    // set some parameters
  },
  ios: {
    // set some parameters
  }
}
// 配置手机定位（可选）
GaodeLocation.configLocation(para, function (successMsg) {
  // do something
  onLocationReady.resolve();
});

// 如果需要配置定位信息，需要以方式实现
onLocationReady
  .promise
  .then(function () {
    GaodeLocation.getLocation(function (locationInfo) {
      // do something
    }, function (err) {
      console.log(err);
    });
    GaodeLocation.watchLocation(function (locationInfo) {
      // first time will return 'requestCode', {requestCode: 1234}, use this code to stop watchLocation
      // do something
    }, function (err) {
      console.log(err);
    });
    GaodeLocation.stopWatch(requestCode, function (successMsg) {
      // do something
    }, function (err) {
      console.log(err);
    });
  });
  
//可直接调用getLocation等方法。
GaodeLocation.getLocation(function (locationInfo) {
  // do something
}, function (err) {
  console.log(err);
});
GaodeLocation.watchLocation(function (locationInfo) {
  // first time will return 'requestCode', {requestCode: 1234}, use this code to stop watchLocation
  // do something
}, function (err) {
  console.log(err);
});
GaodeLocation.stopWatch(requestCode, function (successMsg) {
  // do something
}, function (err) {
  console.log(err);
});
```
