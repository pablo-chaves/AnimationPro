import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class AnimationProApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Return the initial view of your application here
    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        var view = new AnimationProView();
        var delegate = new AnimationProDelegate(view);
        return [ view, delegate ];
    }

}

function getApp() as AnimationProApp {
    return Application.getApp() as AnimationProApp;
}