import QtQuick 6.0
import QtQml 6.0
import QtQuick.Window 6.0
import QtQuick.Controls 6.0
import QtQuick.Layouts 6.0
import QtQuick.Dialogs 6.0
import FishUI 1.0 as FishUI
import Cutefish.TextEditor 1.0
import "fonts.js" as FontsCache

Item {
    id: control

    // ===================== 对外属性 =====================
    property alias fileUrl: document.fileUrl
    property alias fileName: document.fileName
    property alias modified: document.modified
    property alias languageName: document.formatName

    // 标签页编号（由主窗口分配，用于"新建文本 N"显示）
    property int tabNumber: 0

    // 标签页标题：打开的文件显示文件名，未保存的新文件显示"新建文本 N"
    property string tabTitle: document.fileName.length > 0
                              ? document.fileName
                              : (qsTr("New Text") + " " + tabNumber)

    // 标签栏文字（含未保存标记）
    property var tabName: tabTitle + (document.modified ? " *" : "")

    // 标签图标：已保存用系统保存图标(磁盘💾)，未保存/新建文件用同款磁盘的红色线框图标(提示需保存)
    // 注: 不能靠 ColorOverlay/ShaderEffect 着色(软件渲染失效), 故未保存直接用基于系统
    // document-save 形状制作的红色线框 SVG(线条与系统图标完全一致, 仅颜色/描边不同)
    property string tabIcon: document.modified
                             ? "qrc:/images/document-save-unsaved.svg"
                             : "image://icontheme/document-save"
    property bool showLineNumbers: true
    property bool enableHighlighting: true
    property bool findBarVisible: _findBar.visible

    property int characterCount: body.length
    property int currentLine: Math.max(1, document.currentLineIndex + 1)
    property int currentColumn: _columnAtCursor()

    property alias canUndo: body.canUndo
    property alias canRedo: body.canRedo

    property real zoomScale: 1.0
    property int baseFontSize: 13

    // 查找条是否处于替换模式（显示替换行）
    property bool _replaceMode: false

    // 当前编辑器字体（可通过 View → Font 菜单修改）
    property string monoFont: _defaultMonoFont

    property string _defaultMonoFont: FontsCache.defaultMonoFont()

    // 修改编辑器字体
    function setFontFamily(family) {
        if (family && family.length > 0)
            control.monoFont = family
    }

    // 返回已安装的候选等宽字体（供 View → Font 菜单使用）。
    // 通过 fonts.js 模块缓存，避免反复扫描系统字体阻塞 UI 线程。
    function availableMonoFonts() {
        return FontsCache.monoFonts()
    }

    // 另存为请求（由主窗口统一处理保存对话框）
    signal saveAsRequested()
    signal saveAsFinished(bool success)

    // 尺寸跟随容器（TabView）：不要用 ListView.view attached 属性！
    // TextEditor 作为 Container(contentModel) 的项，addItem 后会被 Container 内部
    // reparent，ListView.view 会从 delegate 上下文变为 null，导致 width/height 绑定
    // 求值为 0（编辑区空白）。parent 在 reparent 后始终是可视的 QQuickItem。
    height: parent ? parent.height : 0
    width: parent ? parent.width : 0

    // ===================== 文档处理器 =====================
    DocumentHandler {
        id: document
        document: body.textDocument
        cursorPosition: body.cursorPosition
        selectionStart: body.selectionStart
        selectionEnd: body.selectionEnd
        backgroundColor: FishUI.Theme.backgroundColor
        enableSyntaxHighlighting: control.enableHighlighting
        theme: FishUI.Theme.darkMode ? "Breeze Dark" : "Breeze Light"
        tabSpace: 40

        onSearchFound: {
            body.select(start, end)
            body.cursorPosition = end
            control._scrollToVisible(start)
        }

        onFileSaved: {
            var w = control.Window.window
            if (w && typeof w.showPassiveNotification === "function")
                w.showPassiveNotification(qsTr("File saved"), 2000)
        }
    }

    // ===================== 主布局 =====================
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ---------- 查找 / 替换条 ----------
        Rectangle {
            id: _findBar
            visible: false
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? _findBarLayout.implicitHeight + FishUI.Units.smallSpacing * 2 : 0
            color: FishUI.Theme.secondBackgroundColor
            z: 10

            border.color: FishUI.Theme.darkMode ? Qt.rgba(255, 255, 255, 0.1) : Qt.rgba(0, 0, 0, 0.08)
            border.width: 1

            Behavior on Layout.preferredHeight { NumberAnimation { duration: 150 } }

            ColumnLayout {
                id: _findBarLayout
                anchors.fill: parent
                anchors.leftMargin: FishUI.Units.largeSpacing
                anchors.rightMargin: FishUI.Units.smallSpacing
                anchors.topMargin: FishUI.Units.smallSpacing
                anchors.bottomMargin: FishUI.Units.smallSpacing
                spacing: FishUI.Units.smallSpacing / 2

                // 第一行：查找
                RowLayout {
                    Layout.fillWidth: true
                    spacing: FishUI.Units.smallSpacing

                    Label {
                        text: qsTr("Find:")
                        color: FishUI.Theme.textColor
                    }

                    TextField {
                        id: _findInput
                        Layout.preferredWidth: 220
                        Layout.preferredHeight: 28
                        placeholderText: qsTr("Search text")
                        selectByMouse: true

                        onTextChanged: {
                            if (text.length > 0)
                                _findTimer.restart()
                            else
                                _findTimer.stop()
                        }

                        Keys.onPressed: {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                control.findNext()
                                event.accepted = true
                            } else if (event.key === Qt.Key_Escape) {
                                control.hideFindBar()
                                event.accepted = true
                            }
                        }
                    }

                    FishUI.RoundImageButton {
                        size: 28
                        iconMargins: 5
                        source: "image://icontheme/go-up"
                        onClicked: control.findPrevious()
                    }

                    FishUI.RoundImageButton {
                        size: 28
                        iconMargins: 5
                        source: "image://icontheme/go-down"
                        onClicked: control.findNext()
                    }

                    CheckBox {
                        id: _caseCheckBox
                        text: qsTr("Match case")
                        onToggled: control._applyFindOptions()
                    }

                    CheckBox {
                        id: _wordCheckBox
                        text: qsTr("Whole word")
                        onToggled: control._applyFindOptions()
                    }

                    Item { Layout.fillWidth: true }

                    FishUI.RoundImageButton {
                        size: 28
                        iconMargins: 7
                        source: "image://icontheme/window-close"
                        onClicked: control.hideFindBar()
                    }
                }

                // 第二行：替换（仅在替换模式显示）
                RowLayout {
                    Layout.fillWidth: true
                    visible: _replaceMode
                    spacing: FishUI.Units.smallSpacing

                    Label {
                        text: qsTr("Replace:")
                        color: FishUI.Theme.textColor
                    }

                    TextField {
                        id: _replaceInput
                        Layout.preferredWidth: 220
                        Layout.preferredHeight: 28
                        placeholderText: qsTr("Replacement text")
                        selectByMouse: true

                        Keys.onPressed: {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                control.replaceCurrent()
                                event.accepted = true
                            } else if (event.key === Qt.Key_Escape) {
                                control.hideFindBar()
                                event.accepted = true
                            }
                        }
                    }

                    Button {
                        text: qsTr("Replace")
                        onClicked: control.replaceCurrent()
                    }

                    Button {
                        text: qsTr("Replace All")
                        onClicked: control.replaceAllText()
                    }

                    Item { Layout.fillWidth: true }

                    Label {
                        id: _replaceStatusLabel
                        color: FishUI.Theme.disabledTextColor
                        visible: text.length > 0
                    }
                }
            }
        }


                // ---------- 编辑区 ----------
        // 可滚动文本：显式 Flickable + TextArea。
        // 不用 ScrollView 的 availableWidth/availableHeight 绑定（TextArea 文字
        // 渲染异常），也不用 TextArea.flickable 快捷方式（软件渲染下不渲染文字）。
        Flickable {
            id: _flickable
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: body.width
            contentHeight: body.height

            TextArea {
                id: body
                width: _flickable.width
                height: Math.max(_flickable.height, contentHeight)

                text: document.text
                onTextChanged: {
                    // 软件渲染（QSG software）下 TextArea 内容更新（如打开文件）
                    // 可能不触发重绘或延迟一帧，这里强制请求重绘并延续到下一帧。
                    body.update()
                    Qt.callLater(function() { body.update() })
                }
                selectByKeyboard: true
                selectByMouse: true
                persistentSelection: true
                textFormat: TextEdit.PlainText
                wrapMode: TextEdit.Wrap

                activeFocusOnPress: true
                activeFocusOnTab: false

                leftPadding: _linesCounter.width + FishUI.Units.smallSpacing
                padding: FishUI.Units.smallSpacing
                color: FishUI.Theme.textColor

                font.family: control.monoFont
                font.pointSize: control.baseFontSize * control.zoomScale

                background: Rectangle {
                    color: FishUI.Theme.backgroundColor
                }

                Keys.enabled: true
                Keys.onPressed: {
                    if (event.key === Qt.Key_Tab) {
                        // 插入制表符而不是移动焦点
                        body.insert(body.cursorPosition, "\t")
                        event.accepted = true
                    } else if (event.key === Qt.Key_Escape && control.findBarVisible) {
                        control.hideFindBar()
                        event.accepted = true
                    }
                }

                // 行号
                Loader {
                    id: _linesCounter
                    active: control.showLineNumbers && !document.isRich
                    asynchronous: true

                    anchors.left: body.left
                    anchors.top: body.top
                    anchors.topMargin: body.topPadding + body.textMargin

                    height: _flickable.height
                    width: active ? Math.max(32, document.lineCount.toString().length * 8 + 14) : 0

                    sourceComponent: _linesCounterComponent
                }
            }
        }
    }

    // ===================== 行号组件 =====================
    Component {
        id: _linesCounterComponent

        ListView {
            id: _linesCounterList
            model: document.lineCount
            clip: true

            Binding on currentIndex {
                value: document.currentLineIndex
                restoreMode: Binding.RestoreBindingOrValue
            }

            Timer {
                id: _lineIndexTimer
                interval: 250
                onTriggered: _linesCounterList.currentIndex = document.currentLineIndex
            }

            Connections {
                target: document

                function onLineCountChanged() {
                    _lineIndexTimer.restart()
                }
            }

            orientation: ListView.Vertical
            interactive: false
            snapMode: ListView.NoSnap

            boundsBehavior: Flickable.StopAtBounds
            boundsMovement: Flickable.StopAtBounds

            preferredHighlightBegin: 0
            preferredHighlightEnd: width

            highlightRangeMode: ListView.StrictlyEnforceRange
            highlightMoveDuration: 0
            highlightFollowsCurrentItem: false
            highlightResizeDuration: 0
            highlightMoveVelocity: -1
            highlightResizeVelocity: -1

            maximumFlickVelocity: 0

            delegate: Row {
                id: _delegate

                readonly property int line: index

                // 使用 ListView 的 id 而非 ListView.view attached 属性：
                // 组件在 TabView 内实例化早期，ListView.view 可能尚未解析为有效对象，
                // 直接读取会报 "Cannot read property 'width' of null"。
                width: _linesCounterList.width
                height: document.lineHeight(line)

                readonly property bool isCurrentItem: ListView.isCurrentItem

                Label {
                    width: _linesCounterList.width
                    height: parent.height
                    opacity: isCurrentItem ? 1 : 0.7
                    color: isCurrentItem ? FishUI.Theme.highlightColor
                                         : FishUI.Theme.textColor
                    font.pointSize: body.font.pointSize
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.family: control.monoFont
                    text: index + 1
                }
            }
        }
    }

    // ===================== 跳转到行对话框 =====================
    Dialog {
        id: _gotoLineDialog
        title: qsTr("Go to Line")
        modal: true
        anchors.centerIn: parent
        standardButtons: Dialog.Ok | Dialog.Cancel

        onAboutToShow: {
            _gotoLineInput.text = ""
            _gotoLineInput.forceActiveFocus()
        }

        onAccepted: control.goToLine(_gotoLineInput.text)

        contentItem: ColumnLayout {
            spacing: FishUI.Units.smallSpacing

            Label {
                text: qsTr("Line number (1 - %1):").arg(document.lineCount)
                color: FishUI.Theme.textColor
            }

            TextField {
                id: _gotoLineInput
                Layout.preferredWidth: 240
                Layout.fillWidth: true
                validator: IntValidator { bottom: 1 }
                selectByMouse: true

                Keys.onPressed: {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        _gotoLineDialog.accept()
                        event.accepted = true
                    }
                }
            }
        }
    }

    // ===================== 查找延迟定时器 =====================
    Timer {
        id: _findTimer
        interval: 300
        onTriggered: {
            if (_findInput.text.length > 0)
                control.findNext()
        }
    }


    // ===================== 对外函数 =====================

    function newFile() {
        document.setText("")
        document.fileUrl = ""
        body.forceActiveFocus()
    }

    function openFile(url) {
        document.fileUrl = url
        body.forceActiveFocus()
    }

    function saveFile() {
        if (document.fileUrl.toString().length === 0) {
            saveAsRequested()
            return false
        }
        document.saveAs(document.fileUrl)
        return true
    }

    function saveFileAs() {
        saveAsRequested()
    }

    function saveTo(url) {
        document.saveAs(url)
    }

    function findNext() {
        if (_findInput.text.length === 0)
            return
        _applyFindOptions()
        document.find(_findInput.text, true)
    }

    function findPrevious() {
        if (_findInput.text.length === 0)
            return
        _applyFindOptions()
        document.find(_findInput.text, false)
    }

    function replaceCurrent() {
        if (_findInput.text.length === 0 || _replaceInput.text.length === 0)
            return
        _applyFindOptions()
        document.replace(_findInput.text, _replaceInput.text)
    }

    function replaceAllText() {
        if (_findInput.text.length === 0 || _replaceInput.text.length === 0)
            return
        _applyFindOptions()
        document.replaceAll(_findInput.text, _replaceInput.text)
        _replaceStatusLabel.text = qsTr("Replaced all")
        _replaceStatusTimer.restart()
    }

    function _applyFindOptions() {
        document.findCaseSensitively = _caseCheckBox.checked
        document.findWholeWords = _wordCheckBox.checked
    }

    function _scrollToVisible(position) {
        var rect = body.positionToRectangle(position)
        // Flickable 方案：直接调整 contentY 使目标行滚动到可视区
        if (_flickable.contentHeight > _flickable.height) {
            var targetY = rect.y - _flickable.height / 2
            _flickable.contentY = Math.max(0, Math.min(_flickable.contentHeight - _flickable.height, targetY))
        }
    }

    function showFindBar(showReplace) {
        _replaceMode = showReplace
        _findBar.visible = true
        _findInput.forceActiveFocus()
        _findInput.selectAll()
    }

    function hideFindBar() {
        _findBar.visible = false
        body.forceActiveFocus()
    }

    function showGoToLine() {
        _gotoLineDialog.open()
    }

    function goToLine(text) {
        var line = parseInt(text)
        if (isNaN(line) || line < 1)
            return
        if (line > document.lineCount)
            line = document.lineCount
        body.cursorPosition = document.goToLine(line - 1)
        body.forceActiveFocus()
    }

    function undo() { body.undo() }
    function redo() { body.redo() }
    function cut() { body.cut() }
    function copy() { body.copy() }
    function paste() { body.paste() }
    function selectAll() { body.selectAll() }

    function zoomIn() { control.zoomScale = Math.min(4.0, control.zoomScale + 0.1) }
    function zoomOut() { control.zoomScale = Math.max(0.5, control.zoomScale - 0.1) }
    function resetZoom() { control.zoomScale = 1.0 }

    function toggleLineNumbers() { control.showLineNumbers = !control.showLineNumbers }
    function toggleHighlighting() { control.enableHighlighting = !control.enableHighlighting }

    function forceActiveFocus() {
        body.forceActiveFocus()
    }

    function _columnAtCursor() {
        var pos = body.cursorPosition
        var textBefore = body.text.substring(0, pos)
        var lineStart = textBefore.lastIndexOf("\n") + 1
        return pos - lineStart + 1
    }

    Timer {
        id: _replaceStatusTimer
        interval: 2000
        onTriggered: _replaceStatusLabel.text = ""
    }

}

