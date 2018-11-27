# cordova-plugin-gaode-location

基于cordova封装的高德地图定位插件(暂时只支持单次定位)

# Install

```bash
cordova plugin add https://github.com/jackxu2011/cordova-plugin-gaode-location --variable ANDROIDKEY=YOU_ANDROIDKEY --variable IOSKEY=YOU_IOSKEY --variable LOCATION_USAGE_DESCRIPTION="使用定位功能以查询人员附近公交车辆"
```

# Parameters

Android端和iOS端各自有各自的参数

## configLocation方法

### Android:

- locationMode(number)：定位的模式（精度逐级递减，具体对应的模式参考官网），默认： 1
  - 1：Hight_Accuracy
  - 2：Device_Sensors
  - 3：Battery_Saving

### iOS

- accuracy(number)：定位精度（精度逐级递减，具体对应的模式参考官网），默认：4
  - 1: kCLLocationAccuracyBestForNavigation
  - 2: kCLLocationAccuracyBest
  - 3: kCLLocationAccuracyNearestTenMeters
  - 4: kCLLocationAccuracyHundredMeters
  - 5: kCLLocationAccuracyKilometer
  - 6: kCLLocationAccuracyThreeKilometers
- locationTimeout：定位超时时间，默认：3
- reGeoCodeTimeout：逆地址超时时间，默认：5

  ## getLocation方法

  - retGeo: 是否返回逆地址，默认：false

# Success return data

- latitude：经度
- longitude：纬度
- country： 国家
- province：省
- city：市
- district：区
- address：具体地址

# Useage

```Javascript
var onLocationReady = $q.defer();
// 定制参数
var para = {
  appName: 'your app name',
  android: {
    // set some parameters
  },
  ios: {
    // set some parameters
  }
}
// 配置手機定位
GaodeLocation.configLocation(para, function (successMsg) {
  // do something
  onLocationReady.resolve();
});

// 在啟動手機定位后即可通過'getLocation'隨時獲取最新的位置信息，注意一定要再手机定位启动成功之后执行，否则会报错
onLocationReady
  .promise
  .then(function () {
    GaodeLocation.getLocation({ retGeo: true }, function (locationInfo) {
      // do something
    }, function (err) {
      console.log(err);
    });
  });
```
