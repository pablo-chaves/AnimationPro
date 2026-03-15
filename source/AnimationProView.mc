import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.System;
import Toybox.Lang;
import Toybox.ActivityMonitor;
import Toybox.Activity;
import Toybox.Sensor;
import Toybox.Timer;
import Toybox.Math;

class AnimationProView extends WatchUi.View {
  private var _shapes as Array<Shape> = [] as Array<Shape>;
  private var _organized as Boolean = false;
  private var _timer as Timer.Timer?;
  private var _accelData as Array<Float> = [0.0, 0.0, 0.0] as Array<Float>;
  private var _width as Number = 0;
  private var _height as Number = 0;
  private var _initialized as Boolean = false;

  function initialize() {
    View.initialize();
    Math.srand(System.getTimer());
  }

  function onLayout(dc as Graphics.Dc) as Void {
    _width = dc.getWidth();
    _height = dc.getHeight();

    if (!_initialized) {
      for (var i = 0; i < 20; i++) {
        _shapes.add(new Shape(_width, _height));
      }
      _initialized = true;
    } else {
      for (var i = 0; i < _shapes.size(); i++) {
        _shapes[i].setScreenSize(_width, _height);
      }
    }
  }

  function onShow() as Void {
    _timer = new Timer.Timer();
    _timer.start(method(:onTimer), 50, true);

    // Intentamos habilitar el sensor si está disponible.
    // Algunos dispositivos no permiten activar sensores en runtime y pueden fallar.
    try {
      if (Sensor has :setEnabledSensors) {
        Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE]);
        Sensor.enableSensorEvents(method(:onSensor));
      }
    } catch (e) {
      // Ignorar errores de sensor (dispositivo no soportado o permisos insuficientes).
    }
  }

  function onHide() as Void {
    if (_timer != null) {
      _timer.stop();
      _timer = null;
    }
    if (Sensor has :setEnabledSensors) {
      Sensor.setEnabledSensors([]);
    }
  }

  function onSensor(info as Sensor.Info) as Void {
    var sensorInfo = Sensor.getInfo();
    if (sensorInfo.accel != null) {
      var sensorInfoFloat = [0.0, 0.0, 0.0] as Array<Float>;

      for (var i = 0; i < sensorInfo.accel.size(); i++) {
        sensorInfoFloat.add(sensorInfo.accel[i].toFloat());
      }
      _accelData = sensorInfoFloat;
    }
  }

  function onTimer() as Void {
    WatchUi.requestUpdate();
  }

  function toggleOrganized() as Void {
    _organized = !_organized;
  }

  function onUpdate(dc as Graphics.Dc) as Void {
    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
    dc.clear();

    var centerX = _width / 2;
    var centerY = _height / 2;

    // 1. Dibujar Hora (Siempre fija en el centro)
    var clockTime = System.getClockTime();
    var timeStr = Lang.format("$1$:$2$", [
      clockTime.hour.format("%02d"),
      clockTime.min.format("%02d"),
    ]);
    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    dc.drawText(
      centerX,
      centerY - 20,
      Graphics.FONT_LARGE,
      timeStr,
      Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
    );

    // 2. Actualizar y Dibujar Formas Abstractas
    for (var i = 0; i < _shapes.size(); i++) {
      var shape = _shapes[i];
      if (_organized) {
        // Posiciones objetivo cuando está organizado
        var tx, ty;
        var offsetX = _width / 5;
        var offsetY = _height / 6;
        if (i < 10) {
          // Grupo de Frecuencia Cardiaca (Izquierda abajo)
          tx = centerX - offsetX + (i % 5) * 5;
          ty = centerY + offsetY + (i / 5) * 5;
        } else {
          // Grupo de Pasos (Derecha abajo)
          tx = centerX + offsetX + (i % 5) * 5;
          ty = centerY + offsetY + ((i - 10) / 5) * 5;
        }
        shape.moveTo(tx, ty);
      } else {
        // Movimiento libre basado en acelerómetro
        shape.moveWithAccel(_accelData[0], _accelData[1]);
      }
      shape.draw(dc);
    }

    // 3. Mostrar Información si está organizado
    if (_organized) {
      var info = ActivityMonitor.getInfo();
      var activityInfo = Activity.getActivityInfo();
      var hr = activityInfo.currentHeartRate;
      var steps = info.steps;

      var offsetX = _width / 5;
      var offsetY = _height / 6;

      var valueFont = _width > 300 ? Graphics.FONT_MEDIUM : Graphics.FONT_TINY;

      dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
      dc.drawText(
        centerX - offsetX,
        centerY + offsetY + 25,
        Graphics.FONT_XTINY,
        "HR",
        Graphics.TEXT_JUSTIFY_CENTER
      );
      dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
      dc.drawText(
        centerX - offsetX,
        centerY + offsetY + 45,
        valueFont,
        hr != null ? hr.toString() : "--",
        Graphics.TEXT_JUSTIFY_CENTER
      );

      dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
      dc.drawText(
        centerX + offsetX,
        centerY + offsetY + 25,
        Graphics.FONT_XTINY,
        "STEPS",
        Graphics.TEXT_JUSTIFY_CENTER
      );
      dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
      dc.drawText(
        centerX + offsetX,
        centerY + offsetY + 45,
        valueFont,
        steps != null ? steps.toString() : "0",
        Graphics.TEXT_JUSTIFY_CENTER
      );
    }
  }
}

class Shape {
  private var _x as Float;
  private var _y as Float;
  private var _vx as Float = 0.0;
  private var _vy as Float = 0.0;
  private var _size as Number;
  private var _color as Number;
  private var _screenWidth as Number = 240;
  private var _screenHeight as Number = 240;

  function initialize(w as Number, h as Number) {
    _screenWidth = w;
    _screenHeight = h;
    _x = (Math.rand() % _screenWidth).toFloat();
    _y = (Math.rand() % _screenHeight).toFloat();
    // Aumentamos el tamaño base para pantallas de alta resolución
    var baseSize = _screenWidth > 300 ? 8 : 4;
    _size = baseSize + (Math.rand() % 10);
    var colors = [
      Graphics.COLOR_RED,
      Graphics.COLOR_BLUE,
      Graphics.COLOR_GREEN,
      Graphics.COLOR_YELLOW,
      Graphics.COLOR_PURPLE,
      Graphics.COLOR_ORANGE,
    ];
    _color = colors[Math.rand() % colors.size()];
  }

  function setScreenSize(w as Number, h as Number) as Void {
    _screenWidth = w;
    _screenHeight = h;
  }

  function moveWithAccel(ax as Float, ay as Float) as Void {
    // ax y ay suelen venir en mG (mili-G)
    _vx += ax / 200.0;
    _vy -= ay / 200.0; // Garmin Y es invertido

    // Fricción simple
    _vx *= 0.92;
    _vy *= 0.92;

    _x += _vx;
    _y += _vy;

    // Rebotes en los bordes
    if (_x < 0) {
      _x = 0.0;
      _vx *= -0.5;
    } else if (_x > _screenWidth) {
      _x = _screenWidth.toFloat();
      _vx *= -0.5;
    }

    if (_y < 0) {
      _y = 0.0;
      _vy *= -0.5;
    } else if (_y > _screenHeight) {
      _y = _screenHeight.toFloat();
      _vy *= -0.5;
    }
  }

  function moveTo(tx as Number, ty as Number) as Void {
    _x += (tx - _x) * 0.15;
    _y += (ty - _y) * 0.15;
  }

  function draw(dc as Graphics.Dc) as Void {
    dc.setColor(_color, Graphics.COLOR_TRANSPARENT);
    // Dibujamos formas aleatorias (círculos o rectángulos)
    if (_size % 2 == 0) {
      dc.fillCircle(_x.toNumber(), _y.toNumber(), _size / 2);
    } else {
      dc.fillRectangle(
        _x.toNumber() - _size / 2,
        _y.toNumber() - _size / 2,
        _size,
        _size
      );
    }
  }
}
