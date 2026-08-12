// 等宽字体检测模块。
// .pragma library 使本模块成为单例，Qt.fontFamilies() 只在首次调用时执行一次，
// 避免在 TextEditor 创建 / Font 菜单绑定时反复扫描系统字体阻塞 UI 线程。
.pragma library

var _fonts = null

function monoFonts() {
    if (_fonts !== null)
        return _fonts

    var candidates = ["Noto Sans Mono", "Noto Mono", "DejaVu Sans Mono",
                      "Liberation Mono", "Source Code Pro", "Fira Code",
                      "Ubuntu Mono", "Hack", "Monospace"]
    var result = []
    try {
        var families = Qt.fontFamilies()
        for (var i = 0; i < candidates.length; ++i) {
            if (families.indexOf(candidates[i]) >= 0)
                result.push(candidates[i])
        }
    } catch (e) { }

    if (result.length === 0)
        result.push("Monospace")

    _fonts = result
    return _fonts
}

function defaultMonoFont() {
    var f = monoFonts()
    return f.length > 0 ? f[0] : "Monospace"
}