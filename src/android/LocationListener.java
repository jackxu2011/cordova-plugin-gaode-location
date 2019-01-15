package com.linkcld.cordova.amap;

import com.amap.api.location.AMapLocation;
import com.amap.api.location.AMapLocationListener;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.PluginResult;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

public class LocationListener implements AMapLocationListener {

    private List<ActionHolder> actionHolders = new ArrayList<ActionHolder>();

    private PluginResult currentLocation;
    private PluginResult error;

    private Boolean onceLocation = true;

    void addAction(ActionHolder actionHolder) {

        if(onceLocation) {
            this.actionHolders.add(actionHolder);
            return;
        }

        if (actionHolder.isWatchLocation()) {
            this.actionHolders.add(actionHolder);
        }

        if (this.error != null) {
            actionHolder.sendResult(this.error);
        } if (this.currentLocation != null){
            actionHolder.sendResult(this.currentLocation);
        } else {
            if (actionHolder.isGetLocation()) {
                this.actionHolders.add(actionHolder);
            }
        }
    }

    public void stopWatch(Integer requestCode) {
        Iterator<ActionHolder> iter = actionHolders.iterator();
        while (iter.hasNext()) {
            ActionHolder actionHolder = iter.next();
            if(actionHolder.getRequestCode().equals(requestCode)) {
                iter.remove();
            }
        }
    }

    @Override
    public void onLocationChanged(AMapLocation location) {
        if (location == null) {
            return;
        }

        if (location.getErrorCode() != 0) {
            this.error = getErrorResult(location);
            this.sendResult(error);
            return;
        }

        PluginResult currentLocation = this.getLocationResult(location);

        if(currentLocation != null) {
            this.currentLocation = currentLocation;
            this.sendResult(currentLocation);
        }
        this.error = null;
    }

    private PluginResult getErrorResult(AMapLocation location) {
        JSONObject error = new JSONObject();
        try {
            error.put("errorCode", location.getErrorCode());
            error.put("errorInfo", location.getErrorInfo());
        } catch (JSONException ignored) {}

        PluginResult result = new PluginResult(PluginResult.Status.ERROR, error);
        return result;
    }

    private JSONObject getLocationJson(AMapLocation location) {

        JSONObject resultJson = new JSONObject();
        try {
            // 纬度
            resultJson.put("latitude", location.getLatitude());
            // 经度
            resultJson.put("longitude", location.getLongitude());
            // 国家
            resultJson.put("country", location.getCountry());
            // 省
            resultJson.put("province", location.getProvince());
            // 市
            resultJson.put("city", location.getCity());
            // 区
            resultJson.put("district", location.getDistrict());
            // 地址
            resultJson.put("address", location.getAddress());
            //城市代码
            resultJson.put("cityCode", location.getCityCode());
            //行政区划代码
            resultJson.put("adCode", location.getAdCode());

        } catch (JSONException ignored) {
            return null;
        }
        return resultJson;
    }

    private PluginResult getLocationResult(AMapLocation location) {
        JSONObject resultJson = getLocationJson(location);
        if(resultJson != null) {
            PluginResult result = new PluginResult(PluginResult.Status.OK, resultJson);
            return result;
        }
        return null;
    }

    private void sendResult(PluginResult result) {

        Iterator<ActionHolder> iter = actionHolders.iterator();
        while (iter.hasNext()) {
            ActionHolder actionHolder = iter.next();
            actionHolder.sendResult(result);
            if(actionHolder.isGetLocation()) {
                iter.remove();
            }
        }
    }

    

    public void setOnceLocation(Boolean onceLocation) {
        this.onceLocation = onceLocation;
    }

    public Boolean isOnceLocation() {
        return onceLocation;
    }

    public List<ActionHolder> getActionHolders() {
        return this.actionHolders;
    }

}