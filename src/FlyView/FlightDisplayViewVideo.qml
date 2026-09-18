import QtQuick
import QtQuick.Controls
import QtPositioning

import QGroundControl
import QGroundControl.FlyView
import QGroundControl.FlightMap
import QGroundControl.Controls


Item {
    id:     root
    clip:   true

    property bool useSmallFont: true

    property double _ar:                (cameraLoader.visible && cameraLoader.status === Loader.Ready)
                                            ? cameraLoader.item.implicitWidth / cameraLoader.item.implicitHeight
                                            : QGroundControl.videoManager.aspectRatio
    property bool   _showGrid:          QGroundControl.settingsManager.videoSettings.gridLines.rawValue
    property var    _dynamicCameras:    globals.activeVehicle ? globals.activeVehicle.cameraManager : null
    property bool   _connected:         globals.activeVehicle ? !globals.activeVehicle.communicationLost : false
    property int    _curCameraIndex:    _dynamicCameras ? _dynamicCameras.currentCamera : 0
    property bool   _isCamera:          _dynamicCameras ? _dynamicCameras.cameras.count > 0 : false
    property var    _camera:            _isCamera ? _dynamicCameras.cameras.get(_curCameraIndex) : null
    property bool   _hasZoom:           _camera && _camera.hasZoom
    property int    _fitMode:           QGroundControl.settingsManager.videoSettings.videoFit.rawValue
    property bool   _showStreamLoader:  QGroundControl.videoManager.decoding
    property bool   _showUvcLoader:     QGroundControl.videoManager.isUvc

    property bool   _isMode_FIT_WIDTH:  _fitMode === 0
    property bool   _isMode_FIT_HEIGHT: _fitMode === 1
    property bool   _isMode_FILL:       _fitMode === 2
    property bool   _isMode_NO_CROP:    _fitMode === 3

    property real targetNormX: 0.5
    property real targetNormY: 0.5
    property bool targetVisible: false
    property var result: null

    property bool acceptedThrow: false
                    

    
    property real groundDistance: 0
    property real distance: 0
    property real timeToHit: 0


    property real altitudeMeters: globals.activeVehicle ? globals.activeVehicle.altitudeRelative.value * 0.3048 : 0

    function getWidth() {
        return videoBackground.getWidth()
    }
    function getHeight() {
        return videoBackground.getHeight()
    }

    function pixelToGround(u, v, cameraHeight) {
        var fx = 523.0
        var fy = 596.0
        var cx = 640.0
        var cy = 480.0

        var x = (u - cx) / fx * cameraHeight
        var y = (v - cy) / fy * cameraHeight

        return Qt.vector3d(x, y, 0)
    }


    property double _thermalHeightFactor: 0.85 //-- TODO

        Image {
            id:             noVideo
            anchors.fill:   parent
            source:         "/res/NoVideoBackground.jpg"
            fillMode:       Image.PreserveAspectCrop
            visible:        !_showStreamLoader && !_showUvcLoader

            Rectangle {
                anchors.centerIn:   parent
                width:              noVideoLabel.contentWidth + ScreenTools.defaultFontPixelHeight
                height:             noVideoLabel.contentHeight + ScreenTools.defaultFontPixelHeight
                radius:             ScreenTools.defaultFontPixelWidth / 2
                color:              "black"
                opacity:            0.5
            }

            QGCLabel {
                id:                 noVideoLabel
                text:               QGroundControl.settingsManager.videoSettings.streamEnabled.rawValue ? qsTr("WAITING FOR VIDEO") : qsTr("VIDEO DISABLED")
                font.bold:          true
                color:              "white"
                font.pointSize:     useSmallFont ? ScreenTools.smallFontPointSize : ScreenTools.largeFontPointSize
                anchors.centerIn:   parent
            }

        
        

        }

    Rectangle {
        id:             videoBackground
        anchors.fill:   parent
        color:          "black"
        visible:        _showStreamLoader || _showUvcLoader
        function getWidth() {
            if(_ar != 0.0){
                if(_isMode_FIT_HEIGHT
                        || (_isMode_FILL && (root.width/root.height < _ar))
                        || (_isMode_NO_CROP && (root.width/root.height > _ar))){
                    // This return value has different implications depending on the mode
                    // For FIT_HEIGHT and FILL
                    //    makes so the video width will be larger than (or equal to) the screen width
                    // For NO_CROP Mode
                    //    makes so the video width will be smaller than (or equal to) the screen width
                    return root.height * _ar
                }
            }
            return root.width
        }
        function getHeight() {
            if(_ar != 0.0){
                if(_isMode_FIT_WIDTH
                        || (_isMode_FILL && (root.width/root.height > _ar))
                        || (_isMode_NO_CROP && (root.width/root.height < _ar))){
                    // This return value has different implications depending on the mode
                    // For FIT_WIDTH and FILL
                    //    makes so the video height will be larger than (or equal to) the screen height
                    // For NO_CROP Mode
                    //    makes so the video height will be smaller than (or equal to) the screen height
                    return root.width * (1 / _ar)
                }
            }
            return root.height
        }
        Loader {
            id:                 videoStreamLoader
            anchors.fill:       videoContentArea
            visible:            _showStreamLoader
            sourceComponent:    videoOutputComponent
           
            property bool videoDisabled: QGroundControl.settingsManager.videoSettings.videoSource.rawValue === QGroundControl.settingsManager.videoSettings.disabledVideoSource
            
        }
        Component {
            id: videoOutputComponent
            FlightDisplayViewVideoOutput {
            }
        }
        //-- UVC Video (USB Camera or Video Device)
        Loader {
            id:             cameraLoader
            anchors.fill:   videoContentArea
            visible:        _showUvcLoader
            source:         _showUvcLoader ? "qrc:/qml/QGroundControl/FlyView/FlightDisplayViewUVC.qml" : "qrc:/qml/QGroundControl/FlyView/FlightDisplayViewDummy.qml"
        }

        Item {
            id:                 videoContentArea
            height:             parent.getHeight()
            width:              parent.getWidth()
            anchors.centerIn:   parent
            visible:           _showStreamLoader || _showUvcLoader
            focus: true

            // grid lines
            Item {
                anchors.fill:   parent
                visible:        _showGrid && !QGroundControl.videoManager.fullScreen

                Rectangle {
                    color:  Qt.rgba(1,1,1,0.5)
                    height: parent.height
                    width:  1
                    x:      parent.width * 0.33
                }
                Rectangle {
                    color:  Qt.rgba(1,1,1,0.5)
                    height: parent.height
                    width:  1
                    x:      parent.width * 0.66
                }
                Rectangle {
                    color:  Qt.rgba(1,1,1,0.5)
                    width:  parent.width
                    height: 1
                    y:      parent.height * 0.33
                }
                Rectangle {
                    color:  Qt.rgba(1,1,1,0.5)
                    width:  parent.width
                    height: 1
                    y:      parent.height * 0.66
                }

            }
                  // Target dot
                    Rectangle {
                        id: targetDot

                        width: 12
                        height: 12
                        radius: width / 2

                        color: "red"
                        border.color: "white"
                        border.width: 2

                        visible: false
                        z: 10000

                        x: root.targetNormX * videoContentArea.width - width / 2
                        y: root.targetNormY * videoContentArea.height - height / 2
                    }
                   Rectangle {
                        id: toast
                        width: toastLabel.implicitWidth + ScreenTools.defaultFontPixelWidth * 3
                        height: toastLabel.implicitHeight + ScreenTools.defaultFontPixelHeight
                        visible: false
                        z: 10001
                        anchors.horizontalCenter: videoContentArea.horizontalCenter
                        anchors.top: videoContentArea.top
                        anchors.topMargin: ScreenTools.defaultFontPixelHeight
                        radius: 6
                        color: Qt.rgba(0, 0, 0, 0.75)
                        border.color: "white"
                        border.width: 1

                        QGCLabel {
                            id: toastLabel
                            anchors.centerIn: parent
                            text: qsTr("Target sent")
                            color: "white"
                            font.pointSize: ScreenTools.smallFontPointSize
                        }

                        Timer {
                            id: toastHideTimer
                            interval: 2000
                            repeat: false
                            onTriggered: toast.visible = false
                        }

                        function show(message) {
                            toastLabel.text = message
                            visible = true
                            toastHideTimer.restart()
                        }
                   }
                     // values
                   Rectangle {
                        id: targetValues

                        width: 150
                        height: 100
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        implicitWidth: element.implicitWidth
                        implicitHeight: element.implicitHeight

                        anchors.left: videoContentArea.left
                        anchors.bottom: videoContentArea.bottom

                        radius: 6
                        color: root.acceptedThrow ? "#FD1818": Qt.rgba(0, 0, 0, 0.75)
                        border.color: "white"
                        border.width: 1

                        visible: targetDot.visible
                        z: 9999

                        x: {
                            var proposedX = targetDot.x + targetDot.width + 10

                            // Keep box inside video
                            if (proposedX + width > videoContentArea.width) {
                                proposedX = targetDot.x - width - 10
                            }

                            return Math.max(0, proposedX)
                        }

                        y: {
                            var proposedY = targetDot.y

                            // Keep box inside video
                            if (proposedY + height > videoContentArea.height) {
                                proposedY = videoContentArea.height - height
                            }

                            return Math.max(0, proposedY)
                        }

                        Column {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 4

                            QGCLabel {
                                width: parent.width
                                text: "Ground: " +
                                    root.groundDistance.toFixed(2) + " m"
                                color: "white"
                                font.bold: true
                                font.pointSize: ScreenTools.smallFontPointSize
                            }

                            QGCLabel {
                                width: parent.width
                                text: "Distance: " +
                                    root.distance.toFixed(2) + " m"
                                color: "white"
                                font.pointSize: ScreenTools.smallFontPointSize
                            }
                            QGCLabel {
                                width: parent.width
                                text: "altitude: " +
                                    altitudeMeters.toFixed(2) + " m"
                                color: "white"
                                font.pointSize: ScreenTools.smallFontPointSize
                            }
                            QGCLabel {
                                width: parent.width
                                text: "Time to Impact: " +
                                    root.timeToHit.toFixed(2) + " s"
                                color: "white"
                                font.pointSize: ScreenTools.smallFontPointSize
                            }
                            QGCLabel {
                                width: parent.width
                                text: "GEO coords: " + root.result
                                wrapMode: Text.WordWrap
                                color: "white"
                                font.pointSize: ScreenTools.smallFontPointSize
                            }
                        }
                    }


                   

                    Timer {
                        id: acceptanceTimer
                        interval: 1000
                        repeat: false

                        onTriggered: {
                            root.acceptedThrow = true
                            
                            console.log("A held for 1 second")

                            console.log("THROW!")
                           
                        }
                    }

                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_A && !event.isAutoRepeat) {
                            acceptanceTimer.start()
                            event.accepted = true
                        }
                    }

                    Keys.onReleased: (event) => {
                        if (event.key === Qt.Key_A && !event.isAutoRepeat) {
                            acceptanceTimer.stop()
                            root.acceptedThrow = false
                            event.accepted = true
                        }
                    }



                    // Mouse/touch input
                    TapHandler {
                        id: targetSelector

                        acceptedButtons: Qt.LeftButton
                        grabPermissions: PointerHandler.CanTakeOverFromAnything

                        onTapped: function(eventPoint) {
                            
                            if(root.acceptedThrow){
                                console.log("pressed a for 1 secund")
                            } else {
                                console.log("didnt press a long enough")
                            }

                            // eventPoint.position is already relative to videoContentArea
                            var x = eventPoint.position.x
                            var y = eventPoint.position.y

                            // Store normalized position
                            root.targetNormX = x / videoContentArea.width
                            root.targetNormY = y / videoContentArea.height

                            targetDot.visible = true
                            targetValues.visible = true

                            console.log("Clicked:", x, y)
                        
                            var imageX = root.targetNormX * 3088.0
                            var imageY = root.targetNormY * 2076.0

                            root.groundDistance = CameraCalculator.calculateGroundDistance(
                                imageX,
                                imageY,
                                altitudeMeters
                            )

                            console.log(groundDistance)

                            root.distance = CameraCalculator.calculateDistanceToTarget(
                                imageX,
                                imageY,
                                altitudeMeters
                            )

                            root.timeToHit = CameraCalculator.calculateTimeInSeconds(
                                altitudeMeters
                            )
                           
                            var vehicle = globals.activeVehicle
                            var droneHeading = vehicle ? vehicle.heading.rawValue : 0.0
                            var droneCoords = vehicle
                                ? QtPositioning.coordinate(vehicle.coordinate.latitude, vehicle.coordinate.longitude)
                                : QtPositioning.coordinate()
                            root.result = CameraCalculator.calculateTargetCoordinate(
                                imageX, imageY, altitudeMeters, droneCoords, droneHeading
                            )

                            console.log("Target coordinate:", root.result)
                            console.log("Lat:", root.result.latitude, "Lon:", root.result.longitude)

                            if (vehicle && root.result.isValid && root.acceptedThrow) {
                                vehicle.doSetTargetPoint(root.result)
                                var observation = CameraCalculator.calculateTargetRelative(
                                    imageX,
                                    imageY,
                                    altitudeMeters,
                                    vehicle.roll.rawValue,
                                    vehicle.pitch.rawValue,
                                    vehicle.heading.rawValue
                                )
                                console.log("Sending TARGET_RELATIVE",
                                            observation.forwardMeters, observation.rightMeters, altitudeMeters,
                                            observation.posStd, observation.yawStd,
                                            observation.qTarget, observation.qSensor)
                                if (vehicle.sendTargetRelative(
                                        observation.forwardMeters,
                                        observation.rightMeters,
                                        altitudeMeters,
                                        observation.posStd,
                                        observation.yawStd,
                                        observation.qTarget,
                                        observation.qSensor)) {
                                    toast.show(qsTr("Target sent"))
                                }
                            } else {
                                console.log("No active Vehicle")
                            }
                          

                        }
                        
                        
                     


                    }



        }
        



        //-- Thermal Image
        Item {
            id:                 thermalItem
            width:              height * QGroundControl.videoManager.thermalAspectRatio
            height:             _camera ? (_camera.thermalMode === MavlinkCameraControlInterface.THERMAL_FULL ? parent.height : (_camera.thermalMode === MavlinkCameraControlInterface.THERMAL_PIP ? ScreenTools.defaultFontPixelHeight * 12 : parent.height * _thermalHeightFactor)) : 0
            anchors.centerIn:   parent
            visible:            QGroundControl.videoManager.hasThermal && _camera && _camera.thermalMode !== MavlinkCameraControlInterface.THERMAL_OFF
            function pipOrNot() {
                if(_camera) {
                    if(_camera.thermalMode === MavlinkCameraControlInterface.THERMAL_PIP) {
                        anchors.centerIn    = undefined
                        anchors.top         = parent.top
                        anchors.topMargin   = mainWindow.header.height + (ScreenTools.defaultFontPixelHeight * 0.5)
                        anchors.left        = parent.left
                        anchors.leftMargin  = ScreenTools.defaultFontPixelWidth * 12
                    } else {
                        anchors.top         = undefined
                        anchors.topMargin   = undefined
                        anchors.left        = undefined
                        anchors.leftMargin  = undefined
                        anchors.centerIn    = parent
                    }
                }
            }
            Connections {
                target:                 _camera
                function onThermalModeChanged() { thermalItem.pipOrNot() }
            }
            onVisibleChanged: {
                thermalItem.pipOrNot()
            }
            Loader {
                id:             thermalVideo
                anchors.fill:   parent
                opacity:        _camera ? (_camera.thermalMode === MavlinkCameraControlInterface.THERMAL_BLEND ? _camera.thermalOpacity / 100 : 1.0) : 0
                sourceComponent: thermalOutputComponent
                onLoaded: { if (item) item.objectName = "thermalVideo" }

                Component {
                    id: thermalOutputComponent
                    FlightDisplayViewVideoOutput {}
                }
            }
        }
        //-- Zoom
        PinchArea {
            id:             pinchZoom
            enabled:        false
            anchors.fill:   parent
            onPinchStarted: pinchZoom.zoom = 0
            onPinchUpdated: {
                if(_hasZoom) {
                    var z = 0
                    if(pinch.scale < 1) {
                        z = Math.round(pinch.scale * -10)
                    } else {
                        z = Math.round(pinch.scale)
                    }
                    if(pinchZoom.zoom != z) {
                        _camera.stepZoom(z)
                    }
                }
            }
            property int zoom: 0
        }
    }
    
   

    
}
