import Toybox.WatchUi;
import Toybox.System;
import Toybox.Lang;

class AnimationProDelegate extends WatchUi.BehaviorDelegate {
    private var _view as AnimationProView;
    private var _lastTapTime as Number = 0;
    private const DOUBLE_TAP_THRESHOLD = 500; // milisegundos

    function initialize(view as AnimationProView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    // Manejador para eventos de toque
    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        var currentTime = System.getTimer();

        // Verificamos si es un doble tap
        if (currentTime - _lastTapTime < DOUBLE_TAP_THRESHOLD) {
            _view.toggleOrganized();
            WatchUi.requestUpdate();
            _lastTapTime = 0; // Reiniciamos para evitar triple tap como múltiple doble tap
        } else {
            _lastTapTime = currentTime;
        }

        return true;
    }

    // También podemos usar el botón SELECT como alternativa si no hay pantalla táctil
    function onSelect() as Boolean {
        _view.toggleOrganized();
        WatchUi.requestUpdate();
        return true;
    }
}
