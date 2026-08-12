import QtQuick 6.0
import QtQuick.Window 6.0
import QtQuick.Controls 6.0
import QtQuick.Layouts 6.0
import QtQuick.Dialogs
import FishUI 1.0 as FishUI
import Cutefish.TextEditor 1.0

FishUI.Window {
    id: root
    width: 960
    height: 640
    minimumWidth: 640
    minimumHeight: 440
    visible: true
    // 窗口标题显示当前编辑的文件名（含未保存标记）
    title: root.currentItem ? (root.currentItem.tabName + " - " + qsTr("Text Editor"))
                            : qsTr("Text Editor")

    // 用户确认放弃修改后强制退出（绕过 onClosing 的未保存拦截）
    property bool _forceQuit: false

    // 新建标签编号计数器（"新建文本 N"）
    property int _newTabCounter: 0

    // 标签右键菜单当前操作的目标标签索引
    property int _contextTabIndex: -1

    // ===================== 文件助手（外部打开文件） =====================
    FileHelper {
        id: fileHelper

        onNewPath: {
            root.openPath(path)
        }
    }

    // ===================== 主内容 =====================
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ---------- 菜单栏 ----------
        Rectangle {
            id: _menuBar
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            color: FishUI.Theme.backgroundColor
            z: 20

            Row {
                anchors.left: parent.left
                anchors.leftMargin: FishUI.Units.smallSpacing
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Repeater {
                    model: [
                        { text: qsTr("File"), menu: _fileMenu },
                        { text: qsTr("Edit"), menu: _editMenu },
                        { text: qsTr("Search"), menu: _searchMenu },
                        { text: qsTr("View"), menu: _viewMenu }
                    ]

                    delegate: Button {
                        id: menuBtn

                        property var menu: modelData.menu
                        text: modelData.text

                        flat: true
                        implicitHeight: 26
                        implicitWidth: menuBtnTextMetrics.advanceWidth + 24

                        onClicked: {
                            if (menuBtn.menu) {
                                // 菜单顶部沿按钮下边弹出。
                                // 菜单的 parent 是 FishUI.Window 的内容区（位于 header 下方），
                                // 坐标需相对该 parent 计算，否则会整体偏移 header 高度。
                                var target = menuBtn.mapToItem(menuBtn.menu.parent, 0, menuBtn.height)
                                menuBtn.menu.popup(target.x, target.y)
                            }
                        }

                        TextMetrics {
                            id: menuBtnTextMetrics
                            text: menuBtn.text
                            font: menuBtn.font
                        }

                        contentItem: Text {
                            text: menuBtn.text
                            color: menuBtn.hovered ? FishUI.Theme.highlightColor : FishUI.Theme.textColor
                            font: menuBtn.font
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        background: Rectangle {
                            radius: 5
                            color: menuBtn.hovered ? (FishUI.Theme.darkMode ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(0, 0, 0, 0.06)) : "transparent"
                        }
                    }
                }
            }
        }

        // ---------- 工具栏 ----------
        Rectangle {
            id: _toolBar
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            color: FishUI.Theme.secondBackgroundColor
            z: 10

            border.color: FishUI.Theme.darkMode ? Qt.rgba(255, 255, 255, 0.06) : Qt.rgba(0, 0, 0, 0.05)
            border.width: 1

            Row {
                anchors.fill: parent
                anchors.leftMargin: FishUI.Units.smallSpacing
                anchors.rightMargin: FishUI.Units.smallSpacing
                spacing: 1

                ToolButton {
                    icon.source: "image://icontheme/document-new"
                    onClicked: root.addTab({})
                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("New")
                    anchors.verticalCenter: parent.verticalCenter
                }
                ToolButton {
                    icon.source: "image://icontheme/document-open"
                    onClicked: _openDialog.open()
                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("Open")
                    anchors.verticalCenter: parent.verticalCenter
                }
                ToolButton {
                    icon.source: "image://icontheme/document-save"
                    onClicked: root.saveCurrentFile()
                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("Save")
                    anchors.verticalCenter: parent.verticalCenter
                }

                Rectangle {
                    width: 1
                    height: parent.height - 12
                    anchors.verticalCenter: parent.verticalCenter
                    color: FishUI.Theme.darkMode ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(0, 0, 0, 0.1)
                }

                ToolButton {
                    icon.source: "image://icontheme/edit-undo"
                    enabled: root.currentItem ? root.currentItem.canUndo : false
                    onClicked: root.currentItem.undo()
                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("Undo")
                    anchors.verticalCenter: parent.verticalCenter
                }
                ToolButton {
                    icon.source: "image://icontheme/edit-redo"
                    enabled: root.currentItem ? root.currentItem.canRedo : false
                    onClicked: root.currentItem.redo()
                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("Redo")
                    anchors.verticalCenter: parent.verticalCenter
                }

                Rectangle {
                    width: 1
                    height: parent.height - 12
                    anchors.verticalCenter: parent.verticalCenter
                    color: FishUI.Theme.darkMode ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(0, 0, 0, 0.1)
                }

                ToolButton {
                    icon.source: "image://icontheme/edit-cut"
                    onClicked: root.currentItem.cut()
                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("Cut")
                    anchors.verticalCenter: parent.verticalCenter
                }
                ToolButton {
                    icon.source: "image://icontheme/edit-copy"
                    onClicked: root.currentItem.copy()
                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("Copy")
                    anchors.verticalCenter: parent.verticalCenter
                }
                ToolButton {
                    icon.source: "image://icontheme/edit-paste"
                    onClicked: root.currentItem.paste()
                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("Paste")
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }


        // ---------- 文件标签栏 ----------
        // 位于工具栏下方（Notepad++ 风格：菜单栏→工具栏→标签页→编辑区）
        Rectangle {
            id: _tabBarContainer
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            color: FishUI.Theme.backgroundColor

            border.color: FishUI.Theme.darkMode ? Qt.rgba(255, 255, 255, 0.06) : Qt.rgba(0, 0, 0, 0.05)
            border.width: 1

            FishUI.TabBar {
                id: _tabbar
                anchors.fill: parent
                anchors.leftMargin: FishUI.Units.smallSpacing
                anchors.rightMargin: FishUI.Units.smallSpacing
                anchors.topMargin: 2
                anchors.bottomMargin: 2

                // 去掉"+"新建按钮，改为双击空白处新建（Notepad++ 风格）
                newTabVisibile: false
                onBlankDoubleClicked: root.addTab({})

                model: _tabView.count
                currentIndex: _tabView.currentIndex

                onNewTabClicked: root.addTab({})

                delegate: FishUI.TabButton {
                    id: _tabBtn
                    text: _tabView.contentModel.get(index).tabName
                    iconSource: _tabView.contentModel.get(index).tabIcon
                    implicitHeight: _tabbar.height
                    implicitWidth: Math.min(220, Math.max(120, _tabBtn.contentWidth))

                    ToolTip.delay: 1000
                    ToolTip.timeout: 5000

                    checked: _tabView.currentIndex === index

                    ToolTip.visible: hovered
                    ToolTip.text: _tabView.contentModel.get(index).tabTitle

                    // 右键 → 弹出标签操作菜单
                    TapHandler {
                        acceptedButtons: Qt.RightButton
                        onTapped: {
                            root._contextTabIndex = index
                            var pos = _tabBtn.mapToItem(_tabContextMenu.parent,
                                                        point.position.x, point.position.y)
                            _tabContextMenu.popup(pos.x, pos.y)
                        }
                    }

                    onClicked: {
                        _tabView.currentIndex = index
                        _tabView.currentItem.forceActiveFocus()
                    }

                    onCloseClicked: {
                        root.closeTab(index)
                    }
                }
            }
        }

        // ---------- 标签页 ----------
        FishUI.TabView {
            id: _tabView
            Layout.fillWidth: true
            Layout.fillHeight: true

            onCurrentIndexChanged: {
                if (_tabView.currentItem)
                    _tabView.currentItem.forceActiveFocus()
            }
        }

        // ---------- 状态栏 ----------
        Rectangle {
            id: _statusBar
            Layout.fillWidth: true
            Layout.preferredHeight: 24 + FishUI.Units.smallSpacing
            color: FishUI.Theme.backgroundColor

            border.color: FishUI.Theme.darkMode ? Qt.rgba(255, 255, 255, 0.06) : Qt.rgba(0, 0, 0, 0.05)
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: FishUI.Units.largeSpacing
                anchors.rightMargin: FishUI.Units.largeSpacing
                anchors.bottomMargin: FishUI.Units.smallSpacing / 2
                spacing: FishUI.Units.largeSpacing

                Label {
                    text: root.currentItem ? qsTr("Ln %1, Col %2").arg(root.currentItem.currentLine).arg(root.currentItem.currentColumn)
                                           : ""
                    color: FishUI.Theme.textColor
                    font.pointSize: 9
                }

                Label {
                    text: root.currentItem ? qsTr("%1 chars").arg(root.currentItem.characterCount) : ""
                    color: FishUI.Theme.textColor
                    font.pointSize: 9
                }

                Item { Layout.fillWidth: true }

                Label {
                    text: root.currentItem && root.currentItem.languageName ? root.currentItem.languageName : ""
                    color: FishUI.Theme.textColor
                    font.pointSize: 9
                }

                Label {
                    text: "UTF-8"
                    color: FishUI.Theme.textColor
                    font.pointSize: 9
                }

                Label {
                    text: root.currentItem ? qsTr("Zoom %1%").arg(Math.round(root.currentItem.zoomScale * 100)) : ""
                    color: FishUI.Theme.textColor
                    font.pointSize: 9
                }
            }
        }
    }


    // ===================== 菜单定义 =====================

    Menu {
        id: _fileMenu
        title: qsTr("File")

        MenuItem {
            text: qsTr("New")
            icon.source: "image://icontheme/document-new"
            onTriggered: root.addTab({})
        }
        MenuItem {
            text: qsTr("Open...")
            icon.source: "image://icontheme/document-open"
            onTriggered: _openDialog.open()
        }
        MenuSeparator { }
        MenuItem {
            text: qsTr("Save")
            icon.source: "image://icontheme/document-save"
            onTriggered: root.saveCurrentFile()
        }
        MenuItem {
            text: qsTr("Save As...")
            icon.source: "image://icontheme/document-save-as"
            onTriggered: root.saveCurrentFileAs()
        }
        MenuSeparator { }
        MenuItem {
            text: qsTr("Close Tab")
            icon.source: "image://icontheme/window-close"
            onTriggered: root.closeCurrentTab()
        }
        MenuSeparator { }
        MenuItem {
            text: qsTr("Quit")
            icon.source: "image://icontheme/application-exit"
            onTriggered: root.requestQuit()
        }
    }

    Menu {
        id: _editMenu
        title: qsTr("Edit")

        MenuItem {
            text: qsTr("Undo")
            icon.source: "image://icontheme/edit-undo"
            enabled: root.currentItem ? root.currentItem.canUndo : false
            onTriggered: root.currentItem.undo()
        }
        MenuItem {
            text: qsTr("Redo")
            icon.source: "image://icontheme/edit-redo"
            enabled: root.currentItem ? root.currentItem.canRedo : false
            onTriggered: root.currentItem.redo()
        }
        MenuSeparator { }
        MenuItem {
            text: qsTr("Cut")
            icon.source: "image://icontheme/edit-cut"
            onTriggered: root.currentItem.cut()
        }
        MenuItem {
            text: qsTr("Copy")
            icon.source: "image://icontheme/edit-copy"
            onTriggered: root.currentItem.copy()
        }
        MenuItem {
            text: qsTr("Paste")
            icon.source: "image://icontheme/edit-paste"
            onTriggered: root.currentItem.paste()
        }
        MenuItem {
            text: qsTr("Select All")
            icon.source: "image://icontheme/edit-select-all"
            onTriggered: root.currentItem.selectAll()
        }
        MenuSeparator { }
        MenuItem {
            text: qsTr("Go to Line...")
            icon.source: "image://icontheme/go-jump"
            onTriggered: root.currentItem.showGoToLine()
        }
    }

    Menu {
        id: _searchMenu
        title: qsTr("Search")

        MenuItem {
            text: qsTr("Find...")
            icon.source: "image://icontheme/edit-find"
            onTriggered: root.currentItem.showFindBar(false)
        }
        MenuItem {
            text: qsTr("Replace...")
            icon.source: "image://icontheme/edit-find-replace"
            onTriggered: root.currentItem.showFindBar(true)
        }
        MenuItem {
            text: qsTr("Find Next")
            onTriggered: root.currentItem.findNext()
        }
        MenuItem {
            text: qsTr("Find Previous")
            onTriggered: root.currentItem.findPrevious()
        }
    }

    Menu {
        id: _viewMenu
        title: qsTr("View")

        MenuItem {
            text: qsTr("Zoom In")
            icon.source: "image://icontheme/zoom-in"
            onTriggered: root.currentItem.zoomIn()
        }
        MenuItem {
            text: qsTr("Zoom Out")
            icon.source: "image://icontheme/zoom-out"
            onTriggered: root.currentItem.zoomOut()
        }
        MenuItem {
            text: qsTr("Reset Zoom")
            onTriggered: root.currentItem.resetZoom()
        }
        MenuSeparator { }
        // 字体子菜单：QQC2 要求 Menu 作为父菜单的直接子项（title 作为菜单项文字）。
        // 子菜单项必须在 Menu 的 contentModel 中才能显示/展开（Repeater 生成的不在其中），
        // 因此打开时用 addItem() 动态填充，避免启动时扫描字体阻塞 UI。
        Menu {
            title: qsTr("Font")
            id: _fontMenu

            Component {
                id: _fontMenuItemComponent
                MenuItem {
                    checkable: true
                    onTriggered: {
                        if (root.currentItem)
                            root.currentItem.setFontFamily(text)
                    }
                }
            }

            onOpened: {
                // 清空旧项
                for (var i = _fontMenu.contentData.length - 1; i >= 0; --i) {
                    var obj = _fontMenu.contentData[i]
                    if (obj && obj instanceof MenuItem) {
                        _fontMenu.removeItem(obj)
                        obj.destroy()
                    }
                }
                // 填充字体列表
                var fonts = root.currentItem ? root.currentItem.availableMonoFonts() : []
                for (var j = 0; j < fonts.length; ++j) {
                    // 以 null 为 parent 创建（避免"not placed in graphics scene"警告），
                    // addItem() 会把它正确加入 contentModel 并进入场景
                    var mi = _fontMenuItemComponent.createObject(null)
                    mi.text = fonts[j]
                    mi.checked = (root.currentItem && root.currentItem.monoFont === fonts[j])
                    _fontMenu.addItem(mi)
                }
                // 软件渲染（QSG software）下子菜单（overlay 内）可能不上屏，
                // 强制请求窗口重绘
                Qt.callLater(function() {
                    if (_fontMenu.Window.window)
                        _fontMenu.Window.window.contentItem.update()
                })
            }
        }
        MenuSeparator { }
        MenuItem {
            text: qsTr("Show Line Numbers")
            checkable: true
            checked: root.currentItem ? root.currentItem.showLineNumbers : true
            onTriggered: root.currentItem.toggleLineNumbers()
        }
        MenuItem {
            text: qsTr("Syntax Highlighting")
            checkable: true
            checked: root.currentItem ? root.currentItem.enableHighlighting : true
            onTriggered: root.currentItem.toggleHighlighting()
        }
    }

    // 标签栏右键菜单（Notepad++ 风格）
    Menu {
        id: _tabContextMenu

        MenuItem {
            text: qsTr("Close")
            onTriggered: root.closeTab(root._contextTabIndex)
        }
        MenuItem {
            text: qsTr("Close Others")
            onTriggered: root.closeOtherTabs(root._contextTabIndex)
        }
        MenuSeparator { }
        MenuItem {
            text: qsTr("Save")
            onTriggered: {
                var item = _tabView.contentModel.get(root._contextTabIndex)
                if (item)
                    item.saveFile()
            }
        }
        MenuItem {
            text: qsTr("Save As")
            onTriggered: {
                root._saveTargetItem = _tabView.contentModel.get(root._contextTabIndex)
                _saveDialog.open()
            }
        }
    }


    // ===================== 对话框 =====================

    FileDialog {
        id: _openDialog
        title: qsTr("Open File")
        fileMode: FileDialog.OpenFile
        nameFilters: [qsTr("Text files (*.txt)"),
                      qsTr("All files (*)"),
                      qsTr("Markdown (*.md *.markdown)"),
                      qsTr("C/C++ (*.c *.h *.cpp *.hpp)"),
                      qsTr("Python (*.py)"),
                      qsTr("QML (*.qml)"),
                      qsTr("JSON (*.json)"),
                      qsTr("XML (*.xml *.html)"),
                      qsTr("Shell (*.sh)")]

        onAccepted: root.openPath(_openDialog.selectedFile)
    }

    FileDialog {
        id: _saveDialog
        title: qsTr("Save File")
        fileMode: FileDialog.SaveFile
        nameFilters: [qsTr("Text files (*.txt)"),
                      qsTr("All files (*)")]

        onAccepted: {
            var url = _saveDialog.selectedFile
            if (_saveTargetItem)
                _saveTargetItem.saveTo(url)
            _saveTargetItem = null
            _continuePendingSaves()
        }

        onRejected: {
            _saveTargetItem = null
            _pendingSaveTabs = []
        }
    }

    // ===================== 通用确认对话框 =====================
    // 自定义居中对话框：QQC2 Dialog 在 FishUI.Window + 软件渲染下背景透明、
    // 位置异常（左上角）、样式粗糙，改用内容区覆盖层实现，外观与 fishui 一致。
    Component {
        id: _confirmDialogComponent

        Item {
            id: _dlg
            anchors.fill: parent
            visible: false
            z: 10000

            property int tabIndex: -1

            property string titleText: ""
            property string messageText: ""
            property string leftBtnText: ""
            property string rightBtnText: ""
            property string cancelBtnText: ""

            signal leftClicked()
            signal rightClicked()
            signal cancelClicked()

            function showDialog(title, message, left, right, cancel) {
                _dlg.titleText = title
                _dlg.messageText = message
                _dlg.leftBtnText = left
                _dlg.rightBtnText = right
                _dlg.cancelBtnText = cancel
                _dlg.visible = true
            }

            function hideDialog() {
                _dlg.visible = false
            }

            // 遮罩（拦截点击，保持模态）
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.35)

                MouseArea {
                    anchors.fill: parent
                }
            }

            // 对话框主体（居中、圆角、不透明）
            Rectangle {
                anchors.centerIn: parent
                width: 460
                height: Math.max(190, _dlgColumn.implicitHeight + FishUI.Units.largeSpacing * 2)
                radius: FishUI.Theme.windowRadius
                color: FishUI.Theme.secondBackgroundColor
                border.width: 1
                border.color: FishUI.Theme.darkMode ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(0, 0, 0, 0.1)

                ColumnLayout {
                    id: _dlgColumn
                    anchors.fill: parent
                    anchors.margins: FishUI.Units.largeSpacing
                    spacing: FishUI.Units.largeSpacing

                    // 标题行 + 右上角关闭按钮（点击=取消）
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: FishUI.Units.smallSpacing

                        Label {
                            text: _dlg.titleText
                            font.bold: true
                            font.pixelSize: 15
                            color: FishUI.Theme.textColor
                            Layout.fillWidth: true
                        }

                        // 右上角关闭按钮
                        FishUI.TabCloseButton {
                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 24
                            size: 24
                            source: FishUI.Theme.darkMode ? "qrc:/images/dark/close.svg"
                                                          : "qrc:/images/light/close.svg"
                            hoveredSource: "qrc:/images/dark/close.svg"
                            onClicked: {
                                _dlg.visible = false
                                _dlg.cancelClicked()
                            }
                        }
                    }

                    Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        color: FishUI.Theme.textColor
                        text: _dlg.messageText
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: FishUI.Units.smallSpacing

                        // 弹性空白，将按钮推到右侧
                        Item {
                            Layout.fillWidth: true
                        }

                        Button {
                            text: _dlg.leftBtnText
                            onClicked: {
                                _dlg.visible = false
                                _dlg.leftClicked()
                            }
                        }

                        Button {
                            text: _dlg.rightBtnText
                            highlighted: true
                            onClicked: {
                                _dlg.visible = false
                                _dlg.rightClicked()
                            }
                        }

                        // 取消按钮（不保存、保存、取消 顺序）
                        Button {
                            text: _dlg.cancelBtnText
                            onClicked: {
                                _dlg.visible = false
                                _dlg.cancelClicked()
                            }
                        }
                    }
                }
            }
        }
    }

    Loader {
        id: _closeConfirmDialog
        sourceComponent: _confirmDialogComponent
        active: true
        anchors.fill: parent
    }

    Loader {
        id: _quitConfirmDialog
        sourceComponent: _confirmDialogComponent
        active: true
        anchors.fill: parent
    }


    // ===================== 编辑器组件 =====================
    Component {
        id: textEditorComponent

        TextEditor {
        }
    }

    // ===================== 快捷键 =====================
    Shortcut {
        sequence: "Ctrl+N"
        onActivated: root.addTab({})
    }
    Shortcut {
        sequence: "Ctrl+O"
        onActivated: _openDialog.open()
    }
    Shortcut {
        sequence: "Ctrl+S"
        onActivated: root.saveCurrentFile()
    }
    Shortcut {
        sequence: "Ctrl+Shift+S"
        onActivated: root.saveCurrentFileAs()
    }
    Shortcut {
        sequence: "Ctrl+W"
        onActivated: root.closeCurrentTab()
    }
    Shortcut {
        sequence: "Ctrl+Q"
        onActivated: root.requestQuit()
    }
    Shortcut {
        sequence: "Ctrl+F"
        onActivated: root.currentItem.showFindBar(false)
    }
    Shortcut {
        sequence: "Ctrl+H"
        onActivated: root.currentItem.showFindBar(true)
    }
    Shortcut {
        sequence: "F3"
        onActivated: root.currentItem.findNext()
    }
    Shortcut {
        sequence: "Shift+F3"
        onActivated: root.currentItem.findPrevious()
    }
    Shortcut {
        sequence: "Ctrl+G"
        onActivated: root.currentItem.showGoToLine()
    }
    Shortcut {
        sequence: "Ctrl+="
        onActivated: root.currentItem.zoomIn()
    }
    Shortcut {
        sequence: "Ctrl+-"
        onActivated: root.currentItem.zoomOut()
    }
    Shortcut {
        sequence: "Ctrl+0"
        onActivated: root.currentItem.resetZoom()
    }

    // ===================== 内部状态 =====================
    property Item _saveTargetItem: null
    property var _pendingSaveTabs: []
    property bool _quittingAfterSave: false

    // 当前活动标签页（TabView 的 currentItem）
    readonly property Item currentItem: _tabView.currentItem

    // ===================== 核心函数 =====================

    function addTab(properties) {
        var props = properties || {}
        // 新建空标签：分配"新建文本 N"编号（打开文件时不分配）
        if (props.fileUrl === undefined) {
            root._newTabCounter++
            props.tabNumber = root._newTabCounter
        }
        var item = _tabView.addTab(textEditorComponent, props)
        item.saveAsRequested.connect(function() {
            root._saveTargetItem = item
            _saveDialog.open()
        })
        return item
    }

    function openPath(path) {
        // 已打开的标签直接切换
        for (var i = 0; i < _tabView.count; ++i) {
            var existing = _tabView.contentModel.get(i)
            if (existing.fileUrl.toString() === path.toString()) {
                _tabView.currentIndex = i
                return
            }
        }
        root.addTab({ fileUrl: path })
    }

    function closeTab(index) {
        var item = _tabView.contentModel.get(index)
        if (item && item.modified) {
            _closeConfirmDialog.item.tabIndex = index
            _closeConfirmDialog.item.showDialog(
                        qsTr("Save changes"),
                        qsTr("Do you want to save the changes made to \"%1\"?").arg(item.tabTitle),
                        qsTr("Don't Save"), qsTr("Save"), qsTr("Cancel"))
            return
        }
        _tabView.closeTab(index)
        // 关闭最后一个标签后退出程序（类似单文档编辑器的行为）
        if (_tabView.count === 0)
            Qt.quit()
    }

    function closeCurrentTab() {
        root.closeTab(_tabView.currentIndex)
    }

    // 关闭除指定标签外的所有标签（保留 keepIndex，从后往前逐个关闭）
    function closeOtherTabs(keepIndex) {
        for (var i = _tabView.count - 1; i >= 0; --i) {
            if (i !== keepIndex)
                root.closeTab(i)
        }
    }

    function saveCurrentFile() {
        if (root.currentItem)
            root.currentItem.saveFile()
    }

    function saveCurrentFileAs() {
        if (root.currentItem)
            root.currentItem.saveFileAs()
    }

    function requestQuit() {
        if (root.hasModifiedTabs()) {
            var names = []
            for (var i = 0; i < _tabView.count; ++i) {
                var item = _tabView.contentModel.get(i)
                if (item.modified)
                    names.push(item.fileName)
            }
            _quitConfirmDialog.item.showDialog(
                        qsTr("Unsaved changes"),
                        qsTr("The following files have unsaved changes:\n%1\n\nDo you want to save them before quitting?").arg(names.join("\n")),
                        qsTr("Discard All"), qsTr("Save All"), qsTr("Cancel"))
        } else {
            Qt.quit()
        }
    }

    function hasModifiedTabs() {
        for (var i = 0; i < _tabView.count; ++i) {
            if (_tabView.contentModel.get(i).modified)
                return true
        }
        return false
    }

    function saveAllAndQuit() {
        _pendingSaveTabs = []
        for (var i = 0; i < _tabView.count; ++i) {
            var item = _tabView.contentModel.get(i)
            if (item.modified)
                _pendingSaveTabs.push(item)
        }
        _quittingAfterSave = true
        _continuePendingSaves()
    }

    function _continuePendingSaves() {
        while (_pendingSaveTabs.length > 0) {
            var item = _pendingSaveTabs[0]
            if (item.fileUrl.toString().length > 0) {
                // 有路径，直接保存
                item.saveFile()
                _pendingSaveTabs.shift()
            } else {
                // 无路径，需要弹另存为对话框
                _saveTargetItem = item
                _saveDialog.open()
                return
            }
        }

        if (_quittingAfterSave) {
            _quittingAfterSave = false
            Qt.quit()
        }
    }

    // 打开命令行指定的文件
    Component.onCompleted: {
        Qt.callLater(function() {
            if (typeof commandLineFiles !== "undefined" && commandLineFiles.length > 0) {
                for (var i = 0; i < commandLineFiles.length; ++i) {
                    var path = commandLineFiles[i]
                    root.openPath("file://" + path)
                }
            }
            if (_tabView.count === 0)
                root.addTab({})
        })

        // 关闭标签确认对话框按钮
        _closeConfirmDialog.item.leftClicked.connect(function() {
            // Don't Save
            _tabView.closeTab(_closeConfirmDialog.item.tabIndex)
            if (_tabView.count === 0)
                Qt.quit()
        })
        _closeConfirmDialog.item.rightClicked.connect(function() {
            // Save
            var item = _tabView.contentModel.get(_closeConfirmDialog.item.tabIndex)
            if (item && item.saveFile())
                _tabView.closeTab(_closeConfirmDialog.item.tabIndex)
            if (_tabView.count === 0)
                Qt.quit()
        })
        // Cancel / 右上角关闭：不关闭标签，仅隐藏对话框
        _closeConfirmDialog.item.cancelClicked.connect(function() {
            _closeConfirmDialog.item.hideDialog()
        })

        // 退出确认对话框按钮
        _quitConfirmDialog.item.leftClicked.connect(function() {
            // Discard All：标记强制退出，绕过 onClosing 的未保存拦截
            root._forceQuit = true
            Qt.quit()
        })
        _quitConfirmDialog.item.rightClicked.connect(function() {
            // Save All
            root.saveAllAndQuit()
        })
        // Cancel / 右上角关闭：取消退出
        _quitConfirmDialog.item.cancelClicked.connect(function() {
            _quitConfirmDialog.item.hideDialog()
        })
    }

    // 关闭窗口时的未保存保护
    onClosing: {
        if (root._forceQuit) {
            // 用户已点击"Discard All"，放行退出
            root._forceQuit = false
        } else if (root.hasModifiedTabs()) {
            close.accepted = false
            root.requestQuit()
        }
    }
}

