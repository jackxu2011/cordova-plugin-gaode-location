package com.linkcld.cordova.amap;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaArgs;
import org.apache.cordova.PluginResult;
import org.json.JSONException;
import org.json.JSONObject;

import com.amap.api.location.AMapLocation;
import com.amap.api.location.AMapLocationClient;
import com.amap.api.location.AMapLocationClientOption;
import com.amap.api.location.AMapLocationListener;
import com.amap.api.location.AMapLocationClientOption.AMapLocationMode;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import java.util.List;

import android.Manifest;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;
import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.provider.Settings;
import android.telecom.Call;

public class GaodeLocation extends CordovaPlugin {

    private static final int  ARGS_FORMAT_ERROR_CODE = 101;
    private static final String  ARGS_FORMAT_ERROR_MSG = "参数错误，请检查参数格式";

    private static final String LOCATION_PERMISSION_ERROR_MSG = "当前应用缺少必要权限";

    // AMapLocationClient类对象
    public AMapLocationClient locationClient = null;
    // 定位参数
    public AMapLocationClientOption locationOption = null;

    private LocationListener locationListener = null;

    // JS回掉接口对象
    public static CallbackContext cb = null;

    private Map<Integer, ActionHolder> actions = new HashMap();

    // 需要进行检测的权限数组
    public static String[] needPermissions = {
            Manifest.permission.ACCESS_COARSE_LOCATION,
            Manifest.permission.ACCESS_FINE_LOCATION
    };

    @Override
    protected void pluginInitialize() {
        // 初始化Client
        locationClient = new AMapLocationClient(this.webView.getContext());
        // 初始化监听器
        locationListener = new LocationListener();
        // 初始化定位参数
        locationOption = initOption();
        // 设置选项
        locationClient.setLocationOption(locationOption);
        // 设置定位监听函数
        locationClient.setLocationListener(locationListener);
    }

    @Override
    public boolean execute(String action, CordovaArgs args, CallbackContext callbackContext) throws JSONException {

        ActionHolder actionHolder = new ActionHolder(action, args, callbackContext);

        if(actionHolder.invalid(action)) {
            return false;
        } 

        execute(actionHolder);
        
        return true;
    }

    private void execute(ActionHolder actionHolder) {

        if (ActionHolder.GET_LOCATION.equals(actionHolder.getAction())) {
            if (this.isMissPermissions()) {
                this.requestNeedPermissions(actionHolder.getRequestCode());
            } else {
                getLocation(actionHolder);
            }
        } 

        if (ActionHolder.WATCH_LOCATION.equals(actionHolder.getAction())) {
            if (this.isMissPermissions()) {
                this.requestNeedPermissions(actionHolder.getRequestCode());
            } else {
                watchLocation(actionHolder);
            }
        } 

        if (ActionHolder.STOP_WATCH.equals(actionHolder.getAction())) {
            
            stopWatch(actionHolder);
        }

        if (ActionHolder.CONFIG_LOCATION_OPTION.equals(actionHolder.getAction())) {
            
            configLocationClient(actionHolder);
        }
    }

    /**
     * 初始化locationClient
     */
    private void configLocationClient(ActionHolder actionHolder) {

        // 获取初始化定位参数
        JSONObject androidPara = new JSONObject();
        try {
            JSONObject params = actionHolder.getArgs().getJSONObject(0);
            androidPara = params.has("android") ? params.getJSONObject("android") : androidPara;
        } catch (JSONException ignored) {}

        setOption(androidPara);
        actionHolder.getCallbackContext().success("初始化成功");
    }

    /**
     * 获取定位
     */
    private void getLocation(ActionHolder actionHolder) {

        if(locationListener.isOnceLocation()) {
            locationListener.addAction(actionHolder);
            locationClient.startLocation();
        } else {
            if(!locationClient.isStarted()) {
                locationListener.setOnceLocation(true);
                locationOption.setOnceLocation(true);
                locationClient.startLocation();
            }
            locationListener.addAction(actionHolder);
        }
    }

    /**
     * 订阅定位
     */
    private void watchLocation(ActionHolder actionHolder) {

        if(locationListener.isOnceLocation() ) {
            locationOption.setOnceLocation(false);
            locationListener.setOnceLocation(false);
            if(locationClient.isStarted()) {
                locationClient.stopLocation();
            }
        }
        if(!locationClient.isStarted()) {
            locationClient.startLocation();
        }

        actionHolder.sendResult(getStartWatchResult(actionHolder.getRequestCode()));

        locationListener.addAction(actionHolder);
    }

    /**
     * 取消定位
     */
    private void stopWatch(ActionHolder actionHolder) {
        int requestCode = actionHolder.getArgs().optInt(0);
        if(requestCode == 0) {
            actionHolder.sendResult(getArgsErrorResult());
            return;
        }

        locationListener.stopWatch(requestCode);
        if(locationListener.getActionHolders().isEmpty()) {
            locationClient.stopLocation();
        }
        
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        if(this.locationClient != null) {
            locationClient.onDestroy();
        }
        this.locationClient = null;
    }

    private PluginResult getArgsErrorResult() {
        JSONObject error = new JSONObject();
        try {
            error.put("errorCode", ARGS_FORMAT_ERROR_CODE);
            error.put("errorInfo", ARGS_FORMAT_ERROR_MSG);
        } catch (JSONException ignored) {}

        PluginResult result = new PluginResult(PluginResult.Status.ERROR, error);
        return result;
    }

    private PluginResult getStartWatchResult(int requestCode) {
        JSONObject msg = new JSONObject();
        try {
            msg.put("requestCode", requestCode);
        } catch (JSONException ignored) {}

        PluginResult result = new PluginResult(PluginResult.Status.OK, msg);
        return result;
    }

    private void setOption(JSONObject params) {

        if(params != null) {
            try {
                AMapLocationMode mode = AMapLocationMode.Hight_Accuracy;
                // 定位模式，默认为高精度
                int modeCode = params.has("mode") ? params.getInt("mode") : 1;
                switch (modeCode) {
                    case 1: mode = AMapLocationMode.Hight_Accuracy; break;
                    case 2: mode = AMapLocationMode.Device_Sensors; break;
                    case 3: mode = AMapLocationMode.Battery_Saving; break;
                }
                locationOption.setLocationMode(mode);
                long httpTimeout = params.has("httpTimeout") ? params.getLong("httpTimeout") : 30000;
                locationOption.setHttpTimeOut(httpTimeout);
            } catch (JSONException ignored) {}
        }
    }

    /**
     * 初始化clientOption
     */
    private AMapLocationClientOption initOption() {

        AMapLocationClientOption mOption = new AMapLocationClientOption();
        
        mOption.setOnceLocation(true);
        mOption.setOnceLocationLatest(true);
        mOption.setMockEnable(false);
        return mOption;
    }

    /**
     * 权限检测回调
     */
    public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] paramArrayOfInt) {
        ActionHolder actionHolder =  actions.get(requestCode);
        if(actionHolder == null) {
            return;
        }
        actions.remove(requestCode);
        if (!verifyPermissions(paramArrayOfInt)) {
            actionHolder.sendResult(getPermissionErrorResult());
        } else {
            execute(actionHolder);
        }
    }

    private PluginResult getPermissionErrorResult() {
        JSONObject error = new JSONObject();
        try {
            error.put("errorCode", AMapLocation.ERROR_CODE_FAILURE_LOCATION_PERMISSION);
            error.put("errorInfo", LOCATION_PERMISSION_ERROR_MSG);
        } catch (JSONException ignored) {}

        PluginResult result = new PluginResult(PluginResult.Status.ERROR, error);
        return result;
    }


    /**
     * 检测是否所有的权限都已经授权
     */
    private boolean verifyPermissions(int[] grantResults) {
        for (int result : grantResults) {
            if (result != PackageManager.PERMISSION_GRANTED) {
                return false;
            }
        }
        return true;
    }

    /**
     * 检查权限
     */
    private void requestNeedPermissions(int requestCode) {
        try {
            List<String> missPermissionList = findMissPermissions(GaodeLocation.needPermissions);
            if (null != missPermissionList && missPermissionList.size() > 0) {
                String[] array = new String[missPermissionList.size()];
                array = missPermissionList.toArray(array);
                cordova.requestPermissions(this, requestCode, array);
            }
        } catch (Throwable e) {

        }
    }

    /**
     * 判断是否需要权限校验
     */
    private boolean isMissPermissions() {
        List<String> missPermissionList = findMissPermissions(GaodeLocation.needPermissions);
        if (null != missPermissionList && missPermissionList.size() > 0) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * 获取需要获取权限的集合
     */
    private  List<String> findMissPermissions(String[] permissions) {
        List<String> missPermissionList = new ArrayList<String>();
        try {
            for (String perm : permissions) {
                if (!cordova.hasPermission(perm)) {
                    missPermissionList.add(perm);
                }
            }
        } catch (Throwable e) {

        }
        return missPermissionList;
    }

}
