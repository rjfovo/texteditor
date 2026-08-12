#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QSGRendererInterface>
#include <QDir>
#include <QIcon>
#include <QStandardPaths>
#include "documenthandler.h"
#include "highlightmodel.h"
#include "texteditor.h"

int main(int argc, char *argv[])
{
    // VMware/Mesa 虚拟显卡环境下 Qt6 默认的 OpenGLRhi 场景图后端无法正常渲染
    // （窗口内容全黑）。文本编辑器对渲染性能要求不高，这里强制使用软件渲染，
    // 保证在虚拟机环境也能稳定显示。可用 QT_QUICK_BACKEND 环境变量覆盖。
    // 注意：必须在创建 QGuiApplication 之前调用。
    if (qEnvironmentVariableIsEmpty("QT_QUICK_BACKEND"))
        QQuickWindow::setSceneGraphBackend(QStringLiteral("software"));

    QGuiApplication app(argc, argv);

    // 清理本应用缓存的旧 QML 字节码（应用升级后旧缓存与新版不兼容，
    // 会导致 QML 加载异常甚至段错误，实测 VMware 环境必现）。
    // 因此放弃使用 QML 磁盘缓存（qrc 内嵌 QML 无需缓存加速）。
    const QString cacheDir = QStandardPaths::writableLocation(QStandardPaths::GenericCacheLocation)
            + QLatin1String("/cutefish-texteditor");
    QDir(cacheDir).removeRecursively();

    // 显式指定 Qt Quick Controls 主题为 fish-style（与 cutefish-desktop / dock /
    // filemanager / settings 一致）。会话设置了 QT_STYLE_OVERRIDE=cutefish，
    // QQuickStyle 解析时优先用它（而不是 QT_QUICK_CONTROLS_STYLE），导致 QQC2 控件
    // 回退到 Basic 的 "默认 demo 样式"。必须在 engine.load() 之前显式调用本 API。
    QQuickStyle::setStyle(QStringLiteral("fish-style"));

    // 设置系统图标主题（CutefishOS 默认使用 Crule）。
    // 无 XSettings 环境下 QIcon::themeName() 可能返回空或默认值，
    // 导致 image://icontheme 图标加载失败，这里按优先级挑选已安装的主题。
    QStringList iconThemePaths;
    iconThemePaths << QStringLiteral("/usr/share/icons");
    iconThemePaths << QDir::homePath() + QLatin1String("/.local/share/icons");
    iconThemePaths << QStringLiteral("/usr/local/share/icons");
    iconThemePaths << QStringLiteral("/usr/share/pixmaps");
    QIcon::setThemeSearchPaths(iconThemePaths);

    const QStringList preferredThemes = {
        QStringLiteral("cutefish"),
        QStringLiteral("Crule"),
        QStringLiteral("Crule-dark"),
        QStringLiteral("breeze"),
        QStringLiteral("Adwaita"),
        QStringLiteral("hicolor")
    };
    for (const QString &theme : preferredThemes) {
        if (QDir(QStringLiteral("/usr/share/icons/") + theme).exists()) {
            QIcon::setThemeName(theme);
            break;
        }
    }

    qmlRegisterType<DocumentHandler>("Cutefish.TextEditor", 1, 0, "DocumentHandler");
    qmlRegisterType<FileHelper>("Cutefish.TextEditor", 1, 0, "FileHelper");

    // 收集命令行传入的文件路径（跳过选项参数）
    const QStringList args = app.arguments();
    QStringList filePaths;
    for (int i = 1; i < args.size(); ++i) {
        const QString &arg = args.at(i);
        if (arg == QLatin1String("-f") && i + 1 < args.size()) {
            filePaths << args.at(++i);
        } else if (!arg.startsWith(QLatin1Char('-'))) {
            filePaths << arg;
        }
    }

    QQmlApplicationEngine engine;
    engine.addImportPath(QStringLiteral("/usr/share/qml"));
    engine.rootContext()->setContextProperty("commandLineFiles", QVariant::fromValue(filePaths));

    const QUrl url(QStringLiteral("qrc:/qml/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
