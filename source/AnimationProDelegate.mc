import Toybox.WatchUi;
import Toybox.System;
import Toybox.Lang;
import Toybox.Timer;

class AnimationProDelegate extends WatchUi.BehaviorDelegate {
    private var _view as AnimationProView;

    function initialize(view as AnimationProView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    // Detectamos si se pulsa el botón físico de retroceso, UP, DOWN o LIGHT (para Undo)
    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        var isNav = _view.isNavMode();

        if (key == WatchUi.KEY_UP) {
            if (isNav) {
                _view.adjustZoom(1.0); // Delta positivo para acercar
            } else {
                if (_view.isPlaybackActive()) {
                    _view.stopPlayback();
                } else {
                    _view.startPlayback();
                }
            }
            WatchUi.requestUpdate();
            return true;
        } else if (key == WatchUi.KEY_DOWN) {
            if (isNav) {
                _view.adjustZoom(-1.0); // Delta negativo para alejar
            } else {
                // Usamos el botón down para Deshacer (Undo)
                _view.undoLastStroke();
                WatchUi.requestUpdate();
                return true;
            }
        } else if (key == WatchUi.KEY_MENU) {
            if (_view.isClean()) {
                // Si el dibujo está limpio, el botón MENU borra la app (salir)
                System.exit();
            } else {
                // Si hay algo dibujado, el botón MENU borra el dibujo
                _view.clearDrawing();
                WatchUi.requestUpdate();
                return true;
            }
        }
        return false; // Dejamos que el sistema siga su curso
    }

    // El botón físico de retroceso ahora funcionará normalmente.
    function onBack() as Boolean {
        return true; // no Permitir el comportamiento de "Atrás" por defecto (botón físico)
    }

    // // El botón SELECT alterna entre modo Dibujo y modo Navegación
    // // Una pulsación larga en la pantalla (Hold) en modo dibujo cambiará el color
    // function onSelect() as Boolean {
    //     _view.toggleNavMode();
    //     WatchUi.requestUpdate();
    //     return true;
    // }

    // Usamos el gesto de deslizamiento hacia arriba/abajo para cambiar colores en modo dibujo
    function onSwipe(swipeEvent as WatchUi.SwipeEvent) as Boolean {
        var direction = swipeEvent.getDirection();
        if (direction == WatchUi.SWIPE_RIGHT) {
            return false; // Bloqueamos el gesto táctil de retroceso
        } else if (!_view.isNavMode() && (direction == WatchUi.SWIPE_UP || direction == WatchUi.SWIPE_DOWN)) {
            _view.nextColor();
            WatchUi.requestUpdate();
            return true;
        }
        return false;
    }

    // Al pulsar (Hold) empezamos a seguir la posición
    function onHold(clickEvent as WatchUi.ClickEvent) as Boolean {
        var xy = clickEvent.getCoordinates();
        _view.setTouchPosition(xy[0].toFloat(), xy[1].toFloat(), true);
        return true;
    }

    // Al arrastrar actualizamos la posición
    function onDrag(dragEvent as WatchUi.DragEvent) as Boolean {
        var xy = dragEvent.getCoordinates();
        _view.setTouchPosition(xy[0].toFloat(), xy[1].toFloat(), true);
        return true;
    }

    // Al soltar dejamos de seguir
    function onRelease(clickEvent as WatchUi.ClickEvent) as Boolean {
        _view.setTouchPosition(null, null, false);
        return true;
    }

    // Manejador para eventos de toque
    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        var xy = clickEvent.getCoordinates();
        _view.setTouchPosition(xy[0].toFloat(), xy[1].toFloat(), true);

        // Timer para resetear el toque después de un tap rápido
        var resetTimer = new Timer.Timer();
        resetTimer.start(method(:resetTouch), 100, false);

        return true;
    }

    function resetTouch() as Void {
        _view.setTouchPosition(null, null, false);
    }

    // También podemos usar el botón SELECT como alternativa si no hay pantalla táctil
    function onSelect() as Boolean {
        _view.toggleNavMode();
        WatchUi.requestUpdate();
        return true;
    }
}
