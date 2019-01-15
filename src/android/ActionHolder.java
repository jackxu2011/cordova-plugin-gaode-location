package com.linkcld.cordova.amap;


import java.util.UUID;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaArgs;
import org.apache.cordova.PluginResult;

public class ActionHolder {

    public static final String GET_LOCATION = "getLocation";
    public static final String CONFIG_LOCATION_OPTION = "configLocationManager";
    public static final String WATCH_LOCATION = "watchLocation";
    public static final String STOP_WATCH = "stopWatch";

    private String action;
    private CordovaArgs args;
    private CallbackContext callbackContext;
    private Integer requestCode;

    public ActionHolder(String action, CordovaArgs args, CallbackContext callbackContext) {
        this.action = action;
        this.args = args;
        this.callbackContext = callbackContext;
        this.requestCode = UUID.randomUUID().hashCode();
    }

    public void sendResult(PluginResult result ) {
        if (this.isWatchLocation()) {
            result.setKeepCallback(true);
        }
        this.getCallbackContext().sendPluginResult(result);
    }

    public boolean isWatchLocation() {
        return ActionHolder.WATCH_LOCATION.equals(this.action);
    }

    public boolean isGetLocation() {
        return ActionHolder.GET_LOCATION.equals(this.action);
    }

    public boolean invalid(String action) {
        boolean result = false;
        switch(action) {
            case GET_LOCATION:  break;
            case CONFIG_LOCATION_OPTION: break;
            case WATCH_LOCATION: break;
            case STOP_WATCH: break;
            default: result = true;
        }
        return result;
    }

    public Integer getRequestCode() {
        return this.requestCode;
    }

    public String getAction() {
        return action;
    }

    public void setAction(String action) {
        this.action = action;
    }

    public CordovaArgs getArgs() {
        return args;
    }

    public CallbackContext getCallbackContext() {
        return callbackContext;
    }

    public void setCallbackContext(CallbackContext callbackContext) {
        this.callbackContext = callbackContext;
    }
}