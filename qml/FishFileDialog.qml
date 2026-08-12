import QtQuick 6.0
import QtQuick.Controls 6.0
import QtQuick.Layouts 6.0
import Qt.labs.folderlistmodel 2.15
import FishUI 1.0 as FishUI

// 自定义 fishui 风格文件选择对话框（替换 Qt 原生 FileDialog）
Item {
    id: control
    anchors.fill: parent
    visible: false
    z: 10000
    focus: true

    Keys.onEscapePressed: control.reject()

    // ===================== 对外接口 =====================
    property string dialogTitle: qsTr("File")
    property bool saveMode: false
    property url folder: "file:///"
    property string defaultFileName: ""
    property url selectedFile
    property url defaultHome: "file:///"
    property var userDirs: []
    property var mounts: []

    signal accepted
    signal rejected

    property var nameFilters: [qsTr("All files (*)")]
    property var _activeFilters: ["*"]
    property int _filterIndex: 0

    // ===================== 内部状态 =====================
    property int _selectedIndex: -1
    property string _selectedName: ""

    function _localPath(urlStr) {
        var s = String(urlStr);
        if (s.indexOf("file://") === 0)
            s = s.substring(7);
        return decodeURIComponent(s);
    }

    function _combineUrl(dirUrl, name) {
        if (name.indexOf("/") === 0)
            return "file://" + name;
        var d = String(dirUrl);
        if (!d.endsWith("/"))
            d += "/";
        return d + name;
    }

    function open() {
        _folderModel.folder = String(control.folder).length > 7 ? control.folder : control.defaultHome;
        _fileNameInput.text = control.defaultFileName;
        control.visible = true;
        control._selectedIndex = -1;
        control._selectedName = "";
        Qt.callLater(function () {
            control.forceActiveFocus();
            _fileNameInput.forceActiveFocus();
        });
    }

    function reject() {
        control.visible = false;
        control.rejected();
    }

    function accept() {
        var urlStr = "";
        if (control.saveMode) {
            var name = _fileNameInput.text.trim();
            if (name.length === 0)
                return;
            urlStr = control._combineUrl(_folderModel.folder, name);
        } else {
            if (control._selectedIndex >= 0)
                urlStr = _folderModel.get(control._selectedIndex, "filePath");
            else {
                var n2 = _fileNameInput.text.trim();
                if (n2.length === 0)
                    return;
                urlStr = control._combineUrl(_folderModel.folder, n2);
            }
        }
        control.selectedFile = urlStr;
        control.visible = false;
        control.accepted();
    }

    // ===================== 遮罩 =====================
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.35)
        z: 0
        MouseArea {
            anchors.fill: parent
            z: 0
        }
    }

    // ===================== 对话框主体 =====================
    Rectangle {
        anchors.centerIn: parent
        width: 600
        height: 480
        radius: FishUI.Theme.windowRadius
        color: FishUI.Theme.secondBackgroundColor
        z: 1
        border.width: 1
        border.color: FishUI.Theme.darkMode ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(0, 0, 0, 0.1)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: FishUI.Units.largeSpacing
            spacing: FishUI.Units.largeSpacing

            // ---------- 标题行 + 右上角关闭 ----------
            RowLayout {
                Layout.fillWidth: true
                spacing: FishUI.Units.smallSpacing

                Label {
                    text: control.dialogTitle
                    font.bold: true
                    font.pixelSize: 15
                    color: FishUI.Theme.textColor
                    Layout.fillWidth: true
                }

                FishUI.TabCloseButton {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    size: 24
                    source: FishUI.Theme.darkMode ? "qrc:/images/dark/close.svg" : "qrc:/images/light/close.svg"
                    hoveredSource: "qrc:/images/dark/close.svg"
                    onClicked: control.reject()
                }
            }

            // ---------- 主体：左侧快捷栏 + 右侧内容 ----------
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: FishUI.Units.largeSpacing

                // ---- 左侧快捷访问栏 ----
                Rectangle {
                    Layout.preferredWidth: 150
                    Layout.fillHeight: true
                    radius: FishUI.Theme.smallRadius
                    color: FishUI.Theme.alternateBackgroundColor
                    clip: true
                    border.color: FishUI.Theme.darkMode ? Qt.rgba(255, 255, 255, 0.1) : Qt.rgba(0, 0, 0, 0.08)
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.topMargin: FishUI.Units.smallSpacing
                        anchors.bottomMargin: FishUI.Units.smallSpacing
                        spacing: 1

                        Label {
                            text: qsTr("Folders")
                            font.bold: true
                            font.pixelSize: 11
                            color: FishUI.Theme.disabledTextColor
                            leftPadding: FishUI.Units.smallSpacing
                            Layout.topMargin: FishUI.Units.smallSpacing
                        }

                        Repeater {
                            model: control.userDirs
                            delegate: ItemDelegate {
                                width: 150 - FishUI.Units.largeSpacing
                                height: 28
                                padding: 0
                                leftPadding: FishUI.Units.smallSpacing
                                background: Rectangle {
                                    radius: FishUI.Theme.smallRadius
                                    color: parent.hovered ? (FishUI.Theme.darkMode ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(0, 0, 0, 0.06)) : "transparent"
                                }
                                onClicked: _folderModel.folder = Qt.resolvedUrl("file://" + modelData.path)
                                contentItem: RowLayout {
                                    spacing: FishUI.Units.smallSpacing
                                    Image {
                                        Layout.preferredWidth: 16
                                        Layout.preferredHeight: 16
                                        sourceSize: Qt.size(16, 16)
                                        source: "image://icontheme/folder"
                                        opacity: 0.85
                                    }
                                    Label {
                                        text: modelData.name
                                        Layout.fillWidth: true
                                        elide: Text.ElideMiddle
                                        color: FishUI.Theme.textColor
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            Layout.topMargin: FishUI.Units.smallSpacing
                            Layout.bottomMargin: FishUI.Units.smallSpacing
                            color: FishUI.Theme.darkMode ? Qt.rgba(255, 255, 255, 0.1) : Qt.rgba(0, 0, 0, 0.08)
                        }

                        Label {
                            text: qsTr("Devices")
                            font.bold: true
                            font.pixelSize: 11
                            color: FishUI.Theme.disabledTextColor
                            leftPadding: FishUI.Units.smallSpacing
                        }

                        Repeater {
                            model: control.mounts
                            delegate: ItemDelegate {
                                width: 150 - FishUI.Units.largeSpacing
                                height: 28
                                padding: 0
                                leftPadding: FishUI.Units.smallSpacing
                                background: Rectangle {
                                    radius: FishUI.Theme.smallRadius
                                    color: parent.hovered ? (FishUI.Theme.darkMode ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(0, 0, 0, 0.06)) : "transparent"
                                }
                                onClicked: _folderModel.folder = Qt.resolvedUrl("file://" + modelData.path)
                                contentItem: RowLayout {
                                    spacing: FishUI.Units.smallSpacing
                                    Image {
                                        Layout.preferredWidth: 16
                                        Layout.preferredHeight: 16
                                        sourceSize: Qt.size(16, 16)
                                        source: "image://icontheme/drive-harddisk"
                                        opacity: 0.85
                                    }
                                    Label {
                                        text: modelData.name
                                        Layout.fillWidth: true
                                        elide: Text.ElideMiddle
                                        color: FishUI.Theme.textColor
                                    }
                                }
                            }
                        }
                    }
                }

                // ---- 右侧内容 ----
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: FishUI.Units.smallSpacing

                    // 路径栏
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: FishUI.Units.smallSpacing

                        FishUI.RoundImageButton {
                            size: 28
                            iconMargins: 6
                            source: "image://icontheme/go-up"
                            onClicked: _folderModel.folder = _folderModel.parentFolder
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 28
                            radius: FishUI.Theme.smallRadius
                            color: FishUI.Theme.alternateBackgroundColor
                            border.color: FishUI.Theme.darkMode ? Qt.rgba(255, 255, 255, 0.1) : Qt.rgba(0, 0, 0, 0.08)
                            border.width: 1
                            Label {
                                anchors.fill: parent
                                anchors.leftMargin: FishUI.Units.smallSpacing
                                anchors.rightMargin: FishUI.Units.smallSpacing
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideMiddle
                                text: _localPath(_folderModel.folder.toString())
                                color: FishUI.Theme.textColor
                            }
                        }

                        FishUI.RoundImageButton {
                            size: 28
                            iconMargins: 6
                            source: "image://icontheme/view-refresh"
                            onClicked: {
                                var f = _folderModel.folder;
                                _folderModel.folder = "";
                                Qt.callLater(function () {
                                    _folderModel.folder = f;
                                });
                            }
                        }
                    }

                    // 文件列表
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: FishUI.Theme.smallRadius
                        color: FishUI.Theme.alternateBackgroundColor
                        clip: true
                        border.color: FishUI.Theme.darkMode ? Qt.rgba(255, 255, 255, 0.1) : Qt.rgba(0, 0, 0, 0.08)
                        border.width: 1

                        FolderListModel {
                            id: _folderModel
                            showDirs: true
                            showFiles: true
                            showDotAndDotDot: false
                            showHidden: false
                            sortField: FolderListModel.Name
                            sortReversed: false
                            nameFilters: control._activeFilters
                        }

                        ListView {
                            id: _fileListView
                            anchors.fill: parent
                            anchors.margins: FishUI.Units.smallSpacing / 2
                            model: _folderModel
                            clip: true
                            focus: true
                            ScrollBar.vertical: ScrollBar {}

                            delegate: ItemDelegate {
                                width: _fileListView.width
                                height: 32
                                padding: 0
                                leftPadding: FishUI.Units.smallSpacing
                                highlighted: control._selectedIndex === index
                                background: Rectangle {
                                    radius: FishUI.Theme.smallRadius
                                    color: parent.highlighted ? FishUI.Theme.highlightColor : (parent.hovered ? (FishUI.Theme.darkMode ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(0, 0, 0, 0.06)) : "transparent")
                                }
                                onClicked: {
                                    if (fileIsDir) {
                                        _folderModel.folder = filePath;
                                        control._selectedIndex = -1;
                                    } else {
                                        control._selectedIndex = index;
                                        _fileNameInput.text = fileName;
                                        control.selectedFile = filePath;
                                    }
                                }
                                onDoubleClicked: {
                                    if (fileIsDir) {
                                        _folderModel.folder = filePath;
                                    } else {
                                        control.selectedFile = filePath;
                                        control.visible = false;
                                        control.accepted();
                                    }
                                }
                                contentItem: RowLayout {
                                    spacing: FishUI.Units.smallSpacing
                                    Image {
                                        Layout.preferredWidth: 18
                                        Layout.preferredHeight: 18
                                        sourceSize: Qt.size(18, 18)
                                        source: fileIsDir ? "image://icontheme/folder" : "image://icontheme/text-x-generic"
                                        opacity: 0.9
                                    }
                                    Label {
                                        text: fileName
                                        Layout.fillWidth: true
                                        elide: Text.ElideMiddle
                                        color: parent.parent.highlighted ? FishUI.Theme.highlightedTextColor : FishUI.Theme.textColor
                                    }
                                }
                            }
                        }
                    }

                    // 文件名输入
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: FishUI.Units.smallSpacing

                        Label {
                            text: control.saveMode ? qsTr("Name:") : qsTr("File name:")
                            color: FishUI.Theme.textColor
                        }

                        TextField {
                            id: _fileNameInput
                            Layout.fillWidth: true
                            Layout.preferredHeight: 28
                            selectByMouse: true
                            placeholderText: qsTr("File name")
                            Keys.onReturnPressed: control.accept()
                        }
                    }

                    // 文件类型过滤
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: FishUI.Units.smallSpacing

                        Label {
                            text: qsTr("File type:")
                            color: FishUI.Theme.textColor
                        }

                        Button {
                            id: _typeButton
                            Layout.fillWidth: true
                            Layout.minimumWidth: 200
                            Layout.preferredHeight: 32
                            text: control.nameFilters.length > 0 ? control.nameFilters[control._filterIndex] : ""
                            onClicked: {
                                if (_typeDropdown.visible)
                                    _typeDropdown.visible = false;
                                else
                                                    }
                        }
                    }

                    // 按钮行
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: FishUI.Units.smallSpacing

                        Item {
                            Layout.fillWidth: true
                        }

                        Button {
                            id: _cancelBtn
                            text: qsTr("Cancel")
                            onClicked: control.reject()
                        }

                        Button {
                            id: _openBtn
                            text: control.saveMode ? qsTr("Save") : qsTr("Open")
                            highlighted: true
                            onClicked: control.accept()
                        }
                    }
                }
            }
        }
    }

    // ===================== 自定义文件类型下拉 =====================
    Item {
        id: _typeDropdown
        visible: false
        z: 100
        anchors.fill: parent

        MouseArea {
            anchors.fill: parent
            z: 0
            onClicked: _typeDropdown.visible = false
        }

        Rectangle {
            id: _ddPanel
            property point _pos
            x: _pos.x
            y: _pos.y
            radius: FishUI.Theme.smallRadius
            color: FishUI.Theme.secondBackgroundColor
            border.width: 1
            border.color: FishUI.Theme.darkMode ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(0, 0, 0, 0.1)
            z: 1

            Column {
                anchors.fill: parent
                anchors.topMargin: FishUI.Units.smallSpacing
                anchors.bottomMargin: FishUI.Units.smallSpacing
                spacing: 1

                Repeater {
                    model: control.nameFilters

                    delegate: ItemDelegate {
                        height: 32
                        width: parent.width
                        padding: 0
                        leftPadding: FishUI.Units.smallSpacing
                        highlighted: index === control._filterIndex

                        background: Rectangle {
                            radius: FishUI.Theme.smallRadius
                            color: parent.highlighted ? FishUI.Theme.highlightColor : (parent.hovered ? (FishUI.Theme.darkMode ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(0, 0, 0, 0.06)) : "transparent")
                        }

                        contentItem: Label {
                            text: modelData
                            verticalAlignment: Text.AlignVCenter
                            color: parent.highlighted ? FishUI.Theme.highlightedTextColor : FishUI.Theme.textColor
                        }

                        onClicked: {
                            control._filterIndex = index;
                            control._activeFilters = (function () {
                                    var m = String(modelData).match(/\(([^)]+)\)/);
                                    return m ? m[1].split(/\s+/) : ["*"];
                                })();
                            _typeDropdown.visible = false;
                        }
                    }
                }
            }
        }

        function _show() {
            var g = _typeButton.mapToItem(null, 0, _typeButton.height + 4);
            var c = control.mapToItem(null, 0, 0);
            _ddPanel._pos = Qt.point(g.x - c.x, g.y - c.y);

            _ddPanel.width = Math.max(_typeButton.width, 240);
            _ddPanel.height = Math.min(control.nameFilters.length, 8) * 32 + FishUI.Units.smallSpacing * 2 + 2;
            _typeDropdown.visible = true;
        }
    }
}
