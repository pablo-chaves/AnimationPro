import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.System;
import Toybox.Lang;
import Toybox.ActivityMonitor;
import Toybox.Activity;
import Toybox.Sensor;
import Toybox.Timer;
import Toybox.Math;

class Stroke {
  public var points as Array<[Float, Float]>;
  public var color as Number;

  function initialize(c as Number) {
    points = [] as Array<[Float, Float]>;
    color = c;
  }
}

class AnimationProView extends WatchUi.View {
  private var _strokes as Array<Stroke> = [] as Array<Stroke>;
  private var _currentStroke as Stroke? = null;
  private var _timer as Timer.Timer?;
  private var _width as Number = 0;
  private var _height as Number = 0;
  private var _initialized as Boolean = false;

  // Estado del Canvas (Cámara)
  private var _zoom as Float = 1.0;
  private var _offsetX as Float = 0.0;
  private var _offsetY as Float = 0.0;
  private var _isNavMode as Boolean = false;

  // Estado de reproducción
  private var _isPlaying as Boolean = false;
  private var _playbackStrokeIndex as Number = 0;
  private var _playbackPointIndex as Number = 0;

  // Gestión de Colores
  private var _colors as Array<Number> = [
    Graphics.COLOR_WHITE,
    Graphics.COLOR_RED,
    Graphics.COLOR_BLUE,
    Graphics.COLOR_GREEN,
    Graphics.COLOR_YELLOW,
    Graphics.COLOR_ORANGE,
    Graphics.COLOR_PURPLE,
    Graphics.COLOR_PINK,
  ] as Array<Number>;
  private var _colorIndex as Number = 0;

  function initialize() {
    View.initialize();
    Math.srand(System.getTimer());
  }

  function onLayout(dc as Graphics.Dc) as Void {
    _width = dc.getWidth();
    _height = dc.getHeight();
    _initialized = true;
  }

  function onShow() as Void {
    _timer = new Timer.Timer();
    if (_isPlaying) {
      _timer.start(method(:onTimer), 20, true);
    } else {
      _timer.start(method(:onTimer), 50, true);
    }
  }

  function onHide() as Void {
    if (_timer != null) {
      _timer.stop();
      _timer = null;
    }
  }

  function onTimer() as Void {
    if (_isPlaying) {
      updatePlayback();
    }
    WatchUi.requestUpdate();
  }

  function startPlayback() as Void {
    if (_strokes.size() > 0) {
      _isPlaying = true;
      _playbackStrokeIndex = 0;
      _playbackPointIndex = 0;
    }
  }

  function updatePlayback() as Void {
    if (!_isPlaying) {
      return;
    }

    if (_isPlaying) {
      _playbackPointIndex += 1;
    } else {
      // Aumentamos el incremento para una reproducción más rápida
      _playbackPointIndex += 4;
    }

    // Si llegamos al final del trazo actual, pasamos al siguiente
    if (_playbackStrokeIndex < _strokes.size()) {
      var stroke = _strokes[_playbackStrokeIndex];
      if (_playbackPointIndex >= stroke.points.size()) {
        _playbackStrokeIndex += 1;
        _playbackPointIndex = 0;
      }
    }

    // Si terminamos todos los trazos, detenemos la reproducción
    if (_playbackStrokeIndex >= _strokes.size()) {
      _isPlaying = false;
    }
  }

  function setTouchPosition(
    x as Float?,
    y as Float?,
    touching as Boolean
  ) as Void {
    if (_isPlaying) {
      return; // No dibujar mientras se reproduce
    }

    if (touching && x != null && y != null) {
      if (_isNavMode) {
        // MODO NAVEGACIÓN: Pan (Desplazamiento)
        if (_currentStroke == null) {
          // Usamos _currentStroke temporalmente para guardar el punto de inicio del pan
          _currentStroke = new Stroke(0);
          _currentStroke.points.add([x, y] as [Float, Float]);
        } else {
          var lastPoint = _currentStroke.points[0];
          // Calculamos cuánto se ha movido el dedo en la pantalla
          var dx = (x - lastPoint[0]) / _zoom;
          var dy = (y - lastPoint[1]) / _zoom;
          // Actualizamos el offset del mundo (invertido para que el dibujo siga al dedo)
          _offsetX -= dx;
          _offsetY -= dy;
          // Actualizamos el punto de referencia
          _currentStroke.points[0] = [x, y] as [Float, Float];
        }
      } else {
        // MODO DIBUJO: Añadir puntos al trazo
        // Convertimos coordenadas de pantalla a coordenadas del mundo
        var wx = (x - _width / 2.0) / _zoom + _offsetX + _width / 2.0;
        var wy = (y - _height / 2.0) / _zoom + _offsetY + _height / 2.0;

        if (_currentStroke == null) {
          _currentStroke = new Stroke(_colors[_colorIndex]);
          _strokes.add(_currentStroke);
        }

        // Añadir punto al trazo actual si es suficientemente diferente del último (en coordenadas de mundo)
        var pts = _currentStroke.points;
        var lastPoint = pts.size() > 0 ? pts[pts.size() - 1] : null;
        if (
          lastPoint == null ||
          (wx - lastPoint[0]).abs() > 1.0 / _zoom ||
          (wy - lastPoint[1]).abs() > 1.0 / _zoom
        ) {
          pts.add([wx, wy] as [Float, Float]);
        }

        // Limitar memoria: si hay demasiados trazos o puntos, eliminamos los más antiguos
        if (_strokes.size() > 20) {
          // Aumentamos un poco el límite ya que el canvas es mayor
          _strokes.remove(_strokes[0]);
        }
      }
    } else {
      // Finalizar el trazo o el pan actual
      _currentStroke = null;
    }
  }

  function toggleNavMode() as Void {
    _isNavMode = !_isNavMode;
    _currentStroke = null;
  }

  function adjustZoom(delta as Float) as Void {
    if (delta > 0) {
      _zoom *= 1.2;
    } else {
      _zoom /= 1.2;
    }
    if (_zoom < 0.2) {
      _zoom = 0.2;
    }
    if (_zoom > 10.0) {
      _zoom = 10.0;
    }
  }

  function isNavMode() as Boolean {
    return _isNavMode;
  }

  function undoLastStroke() as Void {
    if (_strokes.size() > 0) {
      _strokes.remove(_strokes[_strokes.size() - 1]);
      _currentStroke = null;
    }
  }

  function isClean() as Boolean {
    return _strokes.size() == 0;
  }

  function clearDrawing() as Void {
    _strokes = [] as Array<Stroke>;
    _offsetX = 0.0;
    _offsetY = 0.0;
    _zoom = 1.0;
    _currentStroke = null;
  }

  function onUpdate(dc as Graphics.Dc) as Void {
    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
    dc.clear();

    if (_isPlaying) {
      drawPlayback(dc);
    } else {
      drawAllStrokes(dc);
    }

    // Dibujar mini-mapa o indicador de posición si estamos lejos del centro
    if (_offsetX.abs() > _width || _offsetY.abs() > _height) {
      dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
      dc.drawCircle(_width - 20, _height - 20, 10);
      var indX = (_offsetX / 500.0) * 10;
      var indY = (_offsetY / 500.0) * 10;
      dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
      dc.fillCircle(
        _width - 20 + indX.toNumber(),
        _height - 20 + indY.toNumber(),
        2
      );
    }

    // Mostrar instrucciones rápidas
    dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
    var modeText = "Pizarra";
    if (_isPlaying) {
      modeText = "Reproduciendo...";
    } else if (_isNavMode) {
      modeText = "(Zoom: " + _zoom.format("%.1f") + ")";
    }

    // Dibujar indicador de color actual
    if (!_isPlaying && !_isNavMode) {
      dc.setColor(_colors[_colorIndex], Graphics.COLOR_TRANSPARENT);
      dc.fillCircle(_width - 25, 30, 8);
      dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
      dc.drawCircle(_width - 25, 30, 8);
    }

    dc.drawText(
      _width / 2,
      25,
      Graphics.FONT_XTINY,
      modeText,
      Graphics.TEXT_JUSTIFY_CENTER
    );

    dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
    // Texto de ayuda dinámico basado en los cambios solicitados
    var footerText = _isPlaying
      ? "Up: Detener"
      : _isNavMode
        ? "Up/Down: Zoom"
        : "S-Up/Down: Color | Menu: Borrar";

    dc.drawText(
      _width / 2,
      _height - 55,
      Graphics.FONT_XTINY,
      footerText,
      Graphics.TEXT_JUSTIFY_CENTER
    );
  }

  function drawAllStrokes(dc as Graphics.Dc) as Void {
    dc.setPenWidth(
      (4 * _zoom).toNumber().abs() > 1 ? (4 * _zoom).toNumber() : 1
    );
    for (var i = 0; i < _strokes.size(); i++) {
      drawStroke(dc, _strokes[i], _strokes[i].points.size());
    }
  }

  function drawPlayback(dc as Graphics.Dc) as Void {
    dc.setPenWidth(
      (4 * _zoom).toNumber().abs() > 1 ? (4 * _zoom).toNumber() : 1
    );
    // Dibujar trazos completos anteriores al actual
    for (var i = 0; i < _playbackStrokeIndex; i++) {
      drawStroke(dc, _strokes[i], _strokes[i].points.size());
    }

    // Dibujar el trazo actual hasta el punto actual
    if (_playbackStrokeIndex < _strokes.size()) {
      drawStroke(dc, _strokes[_playbackStrokeIndex], _playbackPointIndex);
    }
  }

  function drawStroke(
    dc as Graphics.Dc,
    stroke as Stroke,
    pointCount as Number
  ) as Void {
    var pts = stroke.points;
    if (pointCount <= 0) {
      return;
    }

    var cx = _width / 2.0;
    var cy = _height / 2.0;

    if (pointCount < 2) {
      var p = pts[0];
      var sx = (p[0] - _offsetX - cx) * _zoom + cx;
      var sy = (p[1] - _offsetY - cy) * _zoom + cy;
      dc.setColor(stroke.color, Graphics.COLOR_TRANSPARENT);
      dc.fillCircle(
        sx.toNumber(),
        sy.toNumber(),
        (2 * _zoom).toNumber() > 1 ? (2 * _zoom).toNumber() : 1
      );
      return;
    }

    dc.setColor(stroke.color, Graphics.COLOR_TRANSPARENT);
    var limit = pointCount < pts.size() ? pointCount : pts.size();
    for (var j = 0; j < limit - 1; j++) {
      var p1 = pts[j];
      var p2 = pts[j + 1];

      var s1x = (p1[0] - _offsetX - cx) * _zoom + cx;
      var s1y = (p1[1] - _offsetY - cy) * _zoom + cy;
      var s2x = (p2[0] - _offsetX - cx) * _zoom + cx;
      var s2y = (p2[1] - _offsetY - cy) * _zoom + cy;

      dc.drawLine(
        s1x.toNumber(),
        s1y.toNumber(),
        s2x.toNumber(),
        s2y.toNumber()
      );
    }
  }

  function isPlaybackActive() as Boolean {
    return _isPlaying;
  }

  function nextColor() as Void {
    _colorIndex = (_colorIndex + 1) % _colors.size();
  }

  function stopPlayback() as Void {
    _isPlaying = false;
  }
}
