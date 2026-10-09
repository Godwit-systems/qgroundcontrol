// Custom builds can override this file to add custom guided actions.

import QtQml

import QGroundControl

QtObject {
    id: _root

    // GuidedActionsController.customActionStart is 10000. Stay at or above it.
    readonly property int actionCustomButton: 10000
    readonly property int actionSetTargetPoint: 10001
    readonly property string customButtonTitle: qsTr("Custom")
    readonly property string customButtonMessage: qsTr("Example of a custom action.")
    readonly property string setTargetPointTitle: qsTr("Set Target Point")
    readonly property string setTargetPointMessage: qsTr("Set target point to the selected location?")
    property bool showSetTargetPoint: true

    function customConfirmAction(actionCode, actionData, mapIndicator, confirmDialog) {
        switch (actionCode) {
        case actionCustomButton:
            confirmDialog.hideTrigger = true
            confirmDialog.title = customButtonTitle
            confirmDialog.message = customButtonMessage
            break
        case actionSetTargetPoint:
            confirmDialog.title = setTargetPointTitle
            confirmDialog.message = setTargetPointMessage
            confirmDialog.hideTrigger = Qt.binding(function() { return !showSetTargetPoint })
            break
        default:
            return false // false = action not handled here
        }

        return true // true = action handled here
    }

    function customExecuteAction(actionCode, actionData, sliderOutputValue, optionCheckedode) {
        switch (actionCode) {
        case actionCustomButton:
            QGroundControl.showMessageDialog(mainWindow, "Custom Action", "Custom action executed.")
            break
        case actionSetTargetPoint:
            if (!QGroundControl.multiVehicleManager.activeVehicle) {
                return false
            }
            QGroundControl.multiVehicleManager.activeVehicle.doSetTargetPoint(actionData)
            break
        default:
            return false // false = action not handled here
        }

        return true // true = action handled here
    }
}
