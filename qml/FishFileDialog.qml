import QtQuick 6.0
import QtQuick.Controls 6.0
import QtQuick.Layouts 6.0
import Qt.labs.folderlistmodel 2.15
import FishUI 1.0 as FishUI

// 自定义 fishui 风格文件选择对话框（替换 Qt 原生 FileDialog）
// 打开 / 保存两种模式，风格与主窗口一致（居中覆盖层 + 遮罩）
Item {
    id: control
    anchors.fill: parent
    visible: false
    z: 10000
    // 弹出时获得焦点：Esc 关闭、Tab/Enter 操作
    focus: true

    Keys.onEscapePressed: control.reject()

    // ===================== 对外接口 =====================
    property string dialogTitle: qsTr("File")
    // true = 保存模式, false = 打开模式
    property bool saveMode: false
    // 初始目录（file:// 形式），打开前由调用方设置
    property url folder: "file:///"
    // 保存模式的默认文件名
    property string defaultFileName: ""
    // 选中的文件（file:// 形式），接受后由调用方读取
    property url selectedFile

    // 用户主目录（file:// 形式）
    property url defaultHome: "file:///"
    // 左侧快捷访问用户目录：[{name, path}]
    property var userDirs: []
    // 左侧挂载磁盘列表：[{name, path}]
    property var mounts: []

    signal accepted()
    signal rejected()

    // 文件类型过滤器（"Text files (*.txt)" 形式）
    property var nameFilters: [qsTr("All files (*)")]

    // 当前生效的文件扩展名过滤（由 _filterCombo 驱动）
    property var _activeFilters: ["*"]

    // ===================== 内部状态 =====================
    property int _selectedIndex: -1
    property string _selectedName: ""

    function _localPath(urlStr) {
        var s = String(urlStr)
        if (s.indexOf("file://") === 0)
            s = s.substring(7)
        return decodeURIComponent(s)
    }

    function open() {
        // 未显式指定目录时默认进入用户主目录
        _folderModel.folder = String(control.folder).length > 7
                              ? control.folder : control.defaultHome
        _fileNameInput.text = control.defaultFileName
        control.visible = true
        control._selectedIndex = -1
        control._selectedName = ""
        // 延迟到对话框可见后再转移焦点（visible=true 当帧 forceActiveFocus
        // 有时不生效，尤其在软件渲染/焦点仍在编辑区时）
        Qt.callLater(function() {
            control.forceActiveFocus()
            _fileNameInput.forceActiveFocus()
        })
    }

    function reject() {
        control.visible = false
        control.rejected()
    }

    function _combineUrl(dirUrl, name) {
        // 绝对路径（/ 开头）直接转 file://；否则拼接当前目录
        if (name.indexOf("/") === 0)
            return "file://" + name
        var d = String(dirUrl)
        if (!d.endsWith("/"))
            d += "/"
        return d + name
    }

    function accept() {
        var urlStr = ""
        if (control.saveMode) {
            // 保存模式：当前目录 + 输入的文件名
            var name = _fileNameInput.text.trim()
            if (name.length === 0)
                return
            urlStr = control._combineUrl(_folderModel.folder, name)
        } else {
            // 打开模式：优先用列表选中项，否则用输入框内容
            if (control._selectedIndex >= 0)
                urlStr = _folderModel.get(control._selectedIndex, "filePath")
            else {
                var n2 = _fileNameInput.text.trim()
                if (n2.length === 0)
                    return
                urlStr = control._combineUrl(_folderModel.folder, n2)
            }
        }
        control.selectedFile = urlStr
        control.visible = false
        control.accepted()
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
                    source: FishUI.Theme.darkMode ? "qrc:/images/dark/close.svg"
                                                  : "qrc:/images/light/close.svg"
                    hoveredSource: "qrc:/images/dark/close.svg"
                    onClicked: control.reject()
                }
            }

            // ---------- 主体：左侧快捷栏 + 右侧内容 ----------
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: FishUI.Units.largeSpacing

                // ---- 左侧快捷访问栏（用户目录 + 挂载磁盘）----
                Rectangle {
                    Layout.preferredWidth: 150
                    Layout.fillHeight: true
                    radius: FishUI.Theme.smallRadius
                    color: FishUI.Theme.alternateBackgroundColor
                    clip: true
                    border.color: FishUI.Theme.darkMode ? Qt.rgba(255, 255, 255, 0.1)
                                                        : Qt.rgba(0, 0, 0, 0.08)
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

                        // 用户目录（主目录/文档/下载等）
                        Repeater {
                            model: control.userDirs

                            delegate: ItemDelegate {
                                width: 150 - FishUI.Units.largeSpacing
                                height: 28
                                padding: 0
                                leftPadding: FishUI.Units.smallSpacing

                                background: Rectangle {
                                    radius: FishUI.Theme.smallRadius
                                    color: parent.hovered ? (FishUI.Theme.darkMode
                                                             ? Qt.rgba(255, 255, 255, 0.08)
                                                             : Qt.rgba(0, 0, 0, 0.06))
                                                          : "transparent"
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


                        // 分隔线
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            Layout.topMargin: FishUI.Units.smallSpacing
                            Layout.bottomMargin: FishUI.Units.smallSpacing
                            color: FishUI.Theme.darkMode ? Qt.rgba(255, 255, 255, 0.1)
                                                         : Qt.rgba(0, 0, 0, 0.08)
                        }

                        Label {
                            text: qsTr("Devices")
                            font.bold: true
                            font.pixelSize: 11
                            color: FishUI.Theme.disabledTextColor
                            leftPadding: FishUI.Units.smallSpacing
                        }

                        // 挂载磁盘 / 分区
                        Repeater {
                            model: control.mounts

                            delegate: ItemDelegate {
                                width: 150 - FishUI.Units.largeSpacing
                                height: 28
                                padding: 0
                                leftPadding: FishUI.Units.smallSpacing

                                background: Rectangle {
                                    radius: FishUI.Theme.smallRadius
                                    color: parent.hovered ? (FishUI.Theme.darkMode
                                                             ? Qt.rgba(255, 255, 255, 0.08)
                                                             : Qt.rgba(0, 0, 0, 0.06))
                                                          : "transparent"
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


            // ---------- 路径栏 ----------
            RowLayout {
                Layout.fillWidth: true
                spacing: FishUI.Units.smallSpacing

                // 上一级
                FishUI.RoundImageButton {
                    size: 28
                    iconMargins: 6
                    source: "image://icontheme/go-up"
                    onClicked: _folderModel.folder = _folderModel.parentFolder
                }

                // 当前路径
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 28
                    radius: FishUI.Theme.smallRadius
                    color: FishUI.Theme.alternateBackgroundColor
                    border.color: FishUI.Theme.darkMode ? Qt.rgba(255, 255, 255, 0.1)
                                                        : Qt.rgba(0, 0, 0, 0.08)
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

                // 刷新
                FishUI.RoundImageButton {
                    size: 28
                    iconMargins: 6
                    source: "image://icontheme/view-refresh"
                    onClicked: {
                        var f = _folderModel.folder
                        _folderModel.folder = ""
                        Qt.callLater(function() { _folderModel.folder = f })
                    }
                }
            }


            // ---------- 文件列表 ----------
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: FishUI.Theme.smallRadius
                color: FishUI.Theme.alternateBackgroundColor
                clip: true
                border.color: FishUI.Theme.darkMode ? Qt.rgba(255, 255, 255, 0.1)
                                                    : Qt.rgba(0, 0, 0, 0.08)
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

                    ScrollBar.vertical: ScrollBar { }

                    delegate: ItemDelegate {
                        width: _fileListView.width
                        height: 32
                        padding: 0
                        leftPadding: FishUI.Units.smallSpacing

                        highlighted: control._selectedIndex === index
                        // 悬停/选中背景与 fishui 一致
                        background: Rectangle {
                            radius: FishUI.Theme.smallRadius
                            color: parent.highlighted ? FishUI.Theme.highlightColor
                                 : (parent.hovered ? (FishUI.Theme.darkMode
                                                      ? Qt.rgba(255, 255, 255, 0.08)
                                                      : Qt.rgba(0, 0, 0, 0.06))
                                                   : "transparent")
                        }

                        // 点击：目录进入，文件选中
                        onClicked: {
                            if (fileIsDir) {
                                _folderModel.folder = filePath
                                control._selectedIndex = -1
                                control._selectedName = ""
                            } else {
                                control._selectedIndex = index
                                control._selectedName = fileName
                                _fileNameInput.text = fileName
                                control.selectedFile = filePath
                            }
                        }

                        // 双击：目录进入，文件直接接受
                        onDoubleClicked: {
                            if (fileIsDir) {
                                _folderModel.folder = filePath
                            } else {
                                control.selectedFile = filePath
                                control.visible = false
                                control.accepted()
                            }
                        }

                        contentItem: RowLayout {
                            spacing: FishUI.Units.smallSpacing

                            // 图标（目录/文件）
                            Image {
                                Layout.preferredWidth: 18
                                Layout.preferredHeight: 18
                                sourceSize: Qt.size(18, 18)
                                source: fileIsDir ? "image://icontheme/folder"
                                                  : "image://icontheme/text-x-generic"
                                opacity: 0.9
                            }

                            Label {
                                text: fileName
                                Layout.fillWidth: true
                                elide: Text.ElideMiddle
                                color: parent.parent.highlighted ? FishUI.Theme.highlightedTextColor
                                                                 : FishUI.Theme.textColor
                            }
                        }
                    }
                }
            }


            // ---------- 文件名输入 ----------
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

            // ---------- 文件类型过滤（位于文件名输入框下方）----------
            RowLayout {
                Layout.fillWidth: true
                spacing: FishUI.Units.smallSpacing

                Label {
                    text: qsTr("File type:")
                    color: FishUI.Theme.textColor
                }

                ComboBox {
                    id: _filterCombo
                    Layout.fillWidth: true
                    Layout.preferredHeight: 28
                    model: control.nameFilters
                    onActivated: {
                        // 解析 "(...)" 中的扩展名列表并应用到文件过滤
                        var m = String(currentText).match(/\(([^)]+)\)/)
                        control._activeFilters = m ? m[1].split(/\s+/) : ["*"]
                    }
                }
            }
            // ---------- 按钮行 ----------
            RowLayout {
                Layout.fillWidth: true
                spacing: FishUI.Units.smallSpacing

                Item { Layout.fillWidth: true }

                Button {
                    text: qsTr("Cancel")
                    onClicked: control.reject()
                }

                }
            }

                Button {
                    text: control.saveMode ? qsTr("Save") : qsTr("Open")
                    highlighted: true
                    onClicked: control.accept()
                }
            }
        }
    }
}

