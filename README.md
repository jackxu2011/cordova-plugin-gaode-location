# cordova-plugin-gaode-location

基于cordova封装的高德地图定位插件

# Install

```bash
ionic plugin add cordova-plugin-gaode-location --variable ANDROIDKEY=YOU_ANDROIDKEY --variable IOSKEY=YOU_IOSKEY
```

# Parameters

Android端和iOS端各自有各自的参数

## Android:

- locationMode(int)：定位的模式(具体对应的模式参考官网)，默认： 1
  - 1：Hight_Accuracy
  - 2：Device_Sensors
  - 3：Battery_Saving
- gpsFirst(boolean)：是否GPS优先，默认： true
- httpTimeout(int， 毫秒)：网络请求超时时间，默认：10000
- interval(int，毫秒)：定位间隔时间，默认：2000
- needAddress(boolean)：是否返回逆地址信息，默认：false
- onceLocation(boolean)：是否单次定位，默认：true
- onceLocationLatest(boolean)：是否等待wifi刷新，如果是作为true，会自动变为单次定位，持续定位时不要使用，默认：false
- enableHtpps(boolean)：是否启用https，默认：false
- enableWifiScan(boolean)：是否开启wifi扫描，如果设置为false会同时停止主动刷新，停止以后完全依赖于系统刷新，定位为止可能存在误差，默认：true
- enableLocationCache(boolean)：是否使用缓存定位，默认：true

## iOS

- updateDistance(number)：设定最小更新距离，默认：200
- needAddress(boolean)：是否返回逆地址信息，默认：false

*注意：由于单次定位的响应时间过于漫长，iOS已经改成了默认是持续定位，android目前缺省还是单次定位，如果也要改成持续定位，将`onceLocation`改成`true`即可*

# Success return data

- latitude：经度
- longitude：纬度
- country： 国家
- province：省
- city：市
- district：区
- address：具体地址

__注：needAddress设为false，则只会返回经度和纬度__

# Useage

```Javascript
// 使用默认参数
GaodeLocation(function (locationInfo) {
  // do something
}, function (err) {
  console.log(err);
});


// 定制参数
var para = {
  android: {
    // set some parameters
  },
  ios: {
    // set some parameters
  }
}
GaodeLocation(para, function (locationInfo) {
  // do something
}, function (err) {
  console.log(err);
});
```
