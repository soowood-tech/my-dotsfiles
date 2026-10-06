import QtQuick
import QtQuick.Window

Rectangle {
    id: root
    width: Screen.width
    height: Screen.height
    color: "#0a0c14"

    readonly property real s: Screen.height / 1080.0
    property bool inPasswordMode: false
    property int sessionIndex: (typeof sessionModel !== "undefined" && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property int userIndex: (typeof userModel !== "undefined" && userModel.lastIndex >= 0) ? userModel.lastIndex : 0

    // Dynamic colors from theme.conf (synced from Hyprland pywal_theme.py)
    readonly property color accentColor: (typeof config !== "undefined" && config.accent) ? config.accent : "#5ce5e6"
    readonly property color accentColor2: (typeof config !== "undefined" && config.accent2) ? config.accent2 : "#62a3f0"
    readonly property color textColor: (typeof config !== "undefined" && config.fg) ? config.fg : "#ffffff"
    readonly property string mainFont: (typeof config !== "undefined" && config.font) ? config.font : "JetBrainsMono Nerd Font"

    // Dynamically retrieve username from SDDM userModel on any Linux system
    function getUserName() {
        if (userHelper.currentItem && userHelper.currentItem.uName && userHelper.currentItem.uName.length > 0)
            return userHelper.currentItem.uName;
        if (typeof userModel !== "undefined" && userModel.lastUser && userModel.lastUser.length > 0)
            return userModel.lastUser;
        if (typeof config !== "undefined" && config.defaultUser && config.defaultUser.length > 0)
            return config.defaultUser;
        return "USER";
    }

    Component.onCompleted: {
        root.forceActiveFocus();
    }

    // Model helpers with non-zero viewport so delegates are instantiated by QtQuick
    ListView {
        id: sessionHelper
        model: typeof sessionModel !== "undefined" ? sessionModel : null
        currentIndex: root.sessionIndex
        opacity: 0
        width: 100
        height: 100
        z: -100
        delegate: Item {
            property string sName: (typeof model !== "undefined" && model.name) ? model.name : ""
        }
    }

    ListView {
        id: userHelper
        model: typeof userModel !== "undefined" ? userModel : null
        currentIndex: root.userIndex
        opacity: 0
        width: 100
        height: 100
        z: -100
        delegate: Item {
            property string uName: (typeof model !== "undefined" && (model.realName || model.name)) ? (model.realName || model.name) : ""
            property string uLogin: (typeof model !== "undefined" && model.name) ? model.name : ""
        }
    }

    // Focus & Key handling
    focus: true

    Keys.onPressed: function(event) {
        if (!root.inPasswordMode) {
            root.inPasswordMode = true;
            pwdInput.forceActiveFocus();
            if (event.key === Qt.Key_Space) {
                event.accepted = true;
            } else if (event.text && event.text.length > 0 &&
                       event.key !== Qt.Key_Return && event.key !== Qt.Key_Enter &&
                       event.key !== Qt.Key_Escape && event.key !== Qt.Key_Tab &&
                       event.key !== Qt.Key_Shift && event.key !== Qt.Key_Control &&
                       event.key !== Qt.Key_Alt) {
                pwdInput.text = event.text;
                event.accepted = true;
            }
        }
    }

    // 1. Wallpaper background
    Image {
        id: bgImage
        anchors.fill: parent
        source: (typeof config !== "undefined" && config.background) ? config.background : "wallpaper.jpg"
        fillMode: Image.PreserveAspectCrop
        cache: false
        smooth: true
        asynchronous: true
    }

    // 2. Wallpaper dimming overlay
    Rectangle {
        id: dimOverlay
        anchors.fill: parent
        color: "#000000"
        opacity: root.inPasswordMode ? (parseFloat(config.dimOpacity) || 0.65) : 0.0

        Behavior on opacity {
            NumberAnimation { duration: 320; easing.type: Easing.OutCubic }
        }
    }

    // Click anywhere to activate password mode
    MouseArea {
        anchors.fill: parent
        z: 0
        onClicked: {
            if (!root.inPasswordMode) {
                root.inPasswordMode = true;
                pwdInput.forceActiveFocus();
            } else {
                pwdInput.forceActiveFocus();
            }
        }
    }

    // 3. Center Content (Clock, Date, Password Box)
    Item {
        id: centerContainer
        anchors.centerIn: parent
        width: 500 * s
        height: 500 * s
        z: 10

        // Clock & Date Section
        Column {
            id: clockColumn
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.inPasswordMode ? 40 * s : 140 * s
            spacing: 10 * s

            Behavior on y {
                NumberAnimation { duration: 350; easing.type: Easing.OutCubic }
            }

            // Outlined Clock (Hours:Minutes)
            Item {
                id: clockBox
                anchors.horizontalCenter: parent.horizontalCenter
                width: clockMain.implicitWidth + 12 * s
                height: clockMain.implicitHeight + 12 * s

                // Multi-directional outline shadows for rich, crisp black contour
                Repeater {
                    model: [
                        [-3, -3], [-3, 0], [-3, 3],
                        [ 0, -3],          [ 0, 3],
                        [ 3, -3], [ 3, 0], [ 3, 3],
                        [-2, -2], [-2, 0], [-2, 2],
                        [ 0, -2],          [ 0, 2],
                        [ 2, -2], [ 2, 0], [ 2, 2],
                        [-1, -1], [-1, 0], [-1, 1],
                        [ 0, -1],          [ 0, 1],
                        [ 1, -1], [ 1, 0], [ 1, 1]
                    ]
                    Text {
                        x: modelData[0] * s + 6 * s
                        y: modelData[1] * s + 6 * s
                        text: clockMain.text
                        font.family: root.mainFont
                        font.pixelSize: 88 * s
                        font.bold: true
                        color: "#000000"
                    }
                }

                Text {
                    id: clockMain
                    x: 6 * s
                    y: 6 * s
                    text: Qt.formatTime(new Date(), "HH:mm")
                    font.family: root.mainFont
                    font.pixelSize: 88 * s
                    font.bold: true
                    color: root.textColor
                    style: Text.Outline
                    styleColor: "#000000"

                    Timer {
                        interval: 1000
                        running: true
                        repeat: true
                        onTriggered: clockMain.text = Qt.formatTime(new Date(), "HH:mm")
                    }
                }
            }

            // Outlined Date
            Item {
                id: dateBox
                anchors.horizontalCenter: parent.horizontalCenter
                width: dateMain.implicitWidth + 6 * s
                height: dateMain.implicitHeight + 6 * s

                Repeater {
                    model: [
                        [-1, -1], [0, -1], [1, -1],
                        [-1,  0],          [1,  0],
                        [-1,  1], [0,  1], [1,  1]
                    ]
                    Text {
                        x: modelData[0] * s + 3 * s
                        y: modelData[1] * s + 3 * s
                        text: dateMain.text
                        font.family: root.mainFont
                        font.pixelSize: 18 * s
                        font.bold: true
                        color: "#000000"
                    }
                }

                Text {
                    id: dateMain
                    x: 3 * s
                    y: 3 * s
                    text: new Date().toLocaleDateString(Qt.locale("ru_RU"), "dddd, d MMMM").toUpperCase()
                    font.family: root.mainFont
                    font.pixelSize: 18 * s
                    font.bold: true
                    color: "#ffffff"
                    style: Text.Outline
                    styleColor: "#000000"
                }
            }
        }

        // Login Panel (Password Input & User)
        Column {
            id: loginPanel
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 24 * s
            width: 340 * s
            spacing: 12 * s
            opacity: root.inPasswordMode ? 1.0 : 0.0
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation { duration: 300 }
            }

            Item {
                id: userPill
                anchors.horizontalCenter: parent.horizontalCenter
                width: userRow.implicitWidth
                height: 24 * s

                Row {
                    id: userRow
                    anchors.centerIn: parent
                    spacing: 8 * s

                    Rectangle {
                        width: 8 * s
                        height: 8 * s
                        radius: 4 * s
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.accentColor
                    }

                    Text {
                        text: root.getUserName().toUpperCase()
                        color: "#ffffff"
                        font.family: root.mainFont
                        font.pixelSize: 14 * s
                        font.bold: true
                        font.letterSpacing: 2 * s
                        style: Text.Outline
                        styleColor: "#000000"
                    }

                    Text {
                        visible: typeof userModel !== "undefined" && userModel.rowCount() > 1
                        text: "▾"
                        color: root.accentColor
                        font.pixelSize: 12 * s
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: (typeof userModel !== "undefined" && userModel.rowCount() > 1) ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        if (typeof userModel !== "undefined" && userModel.rowCount() > 1) {
                            root.userIndex = (root.userIndex + 1) % userModel.rowCount();
                        }
                    }
                }
            }

            // Password Field Card
            Rectangle {
                width: parent.width
                height: 48 * s
                radius: 12 * s
                color: "#181820dd"
                border.color: pwdInput.activeFocus ? root.accentColor : "#3a3a4c"
                border.width: pwdInput.activeFocus ? 2 * s : 1 * s

                Behavior on border.color {
                    ColorAnimation { duration: 150 }
                }

                TextInput {
                    id: pwdInput
                    anchors.fill: parent
                    anchors.leftMargin: 16 * s
                    anchors.rightMargin: 52 * s
                    verticalAlignment: TextInput.AlignVCenter
                    font.family: root.mainFont
                    font.pixelSize: 16 * s
                    color: "#ffffff"
                    echoMode: TextInput.Password
                    passwordCharacter: "●"
                    clip: true
                    focus: root.inPasswordMode

                    onTextEdited: {
                        errMsg.text = "";
                    }

                    Keys.onReturnPressed: doLogin()
                    Keys.onEnterPressed: doLogin()
                    Keys.onEscapePressed: function(event) {
                        if (pwdInput.text.length === 0) {
                            root.inPasswordMode = false;
                            root.forceActiveFocus();
                        } else {
                            pwdInput.text = "";
                        }
                        event.accepted = true;
                    }

                    Text {
                        anchors.fill: parent
                        verticalAlignment: TextInput.AlignVCenter
                        text: "Введите пароль..."
                        color: "#888899"
                        font.family: root.mainFont
                        font.pixelSize: 14 * s
                        visible: pwdInput.text.length === 0
                    }
                }

                // Submit Button
                Rectangle {
                    width: 36 * s
                    height: 36 * s
                    radius: 10 * s
                    anchors.right: parent.right
                    anchors.rightMargin: 6 * s
                    anchors.verticalCenter: parent.verticalCenter
                    color: submitMouse.containsMouse ? root.accentColor : "#2a2a38"

                    Behavior on color {
                        ColorAnimation { duration: 120 }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "➔"
                        color: "#ffffff"
                        font.pixelSize: 16 * s
                        font.bold: true
                    }

                    MouseArea {
                        id: submitMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: doLogin()
                    }
                }
            }

            // Error Message
            Text {
                id: errMsg
                anchors.horizontalCenter: parent.horizontalCenter
                text: ""
                color: "#ff5555"
                font.family: root.mainFont
                font.pixelSize: 12 * s
                font.bold: true
                visible: text.length > 0
                style: Text.Outline
                styleColor: "#000000"
            }
        }
    }

    // Top Right Controls (Power, Reboot, Session) with solid styled background
    Row {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 22 * s
        anchors.rightMargin: 26 * s
        spacing: 12 * s
        z: 20

        Repeater {
            model: [
                {
                    id: "session",
                    icon: "❖",
                    text: (sessionHelper.currentItem && sessionHelper.currentItem.sName ? sessionHelper.currentItem.sName : "Hyprland"),
                    action: 0
                },
                {
                    id: "reboot",
                    icon: "⟳",
                    text: "Перезагрузка",
                    action: 1
                },
                {
                    id: "power",
                    icon: "⏻",
                    text: "Выключение",
                    action: 2
                }
            ]

            Rectangle {
                id: topBtn
                width: btnContentRow.implicitWidth + 28 * s
                height: 38 * s
                radius: 10 * s

                // Solid background with high contrast and smooth hover effect
                color: btnMouse.containsMouse ? root.accentColor : "#141522f0"
                border.color: btnMouse.containsMouse ? "#ffffff" : root.accentColor
                border.width: 1.5 * s

                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                Row {
                    id: btnContentRow
                    anchors.centerIn: parent
                    spacing: 8 * s

                    Text {
                        text: modelData.icon
                        color: btnMouse.containsMouse ? "#ffffff" : root.accentColor
                        font.pixelSize: 14 * s
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                        style: Text.Outline
                        styleColor: "#000000"

                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    Text {
                        text: modelData.text
                        color: "#ffffff"
                        font.family: root.mainFont
                        font.pixelSize: 12 * s
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                        style: Text.Outline
                        styleColor: "#000000"
                    }
                }

                MouseArea {
                    id: btnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (modelData.action === 1) {
                            if (typeof sddm !== "undefined") sddm.reboot();
                        } else if (modelData.action === 2) {
                            if (typeof sddm !== "undefined") sddm.powerOff();
                        } else if (modelData.action === 0) {
                            if (typeof sessionModel !== "undefined" && sessionModel.rowCount() > 0) {
                                root.sessionIndex = (root.sessionIndex + 1) % sessionModel.rowCount();
                            }
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: typeof sddm !== "undefined" ? sddm : null
        function onLoginFailed() {
            errMsg.text = "Неверный пароль!";
            pwdInput.text = "";
            pwdInput.forceActiveFocus();
        }
    }

    function doLogin() {
        var user = (userHelper.currentItem && userHelper.currentItem.uLogin && userHelper.currentItem.uLogin.length > 0)
            ? userHelper.currentItem.uLogin
            : ((typeof userModel !== "undefined" && userModel.lastUser && userModel.lastUser.length > 0)
                ? userModel.lastUser
                : ((typeof config !== "undefined" && config.defaultUser) ? config.defaultUser : ""));
        if (typeof sddm !== "undefined") {
            sddm.login(user, pwdInput.text, root.sessionIndex);
        }
    }
}
