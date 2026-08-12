#include "texteditor.h"

#include <QDir>
#include <QStandardPaths>
#include <QVariantMap>

FileHelper::FileHelper(QObject *parent)
    : QObject(parent)
{
}

QString FileHelper::homePath() const
{
    return QDir::homePath();
}

QVariantList FileHelper::standardPaths() const
{
    QVariantList list;
    const auto add = [&list](const QString &name, QStandardPaths::StandardLocation loc) {
        const QString path = QStandardPaths::writableLocation(loc);
        if (!path.isEmpty()) {
            QVariantMap m;
            m.insert(QStringLiteral("name"), name);
            m.insert(QStringLiteral("path"), path);
            list << m;
        }
    };
    add(QStringLiteral("Home"), QStandardPaths::HomeLocation);
    add(QStringLiteral("Desktop"), QStandardPaths::DesktopLocation);
    add(QStringLiteral("Documents"), QStandardPaths::DocumentsLocation);
    add(QStringLiteral("Downloads"), QStandardPaths::DownloadLocation);
    add(QStringLiteral("Pictures"), QStandardPaths::PicturesLocation);
    add(QStringLiteral("Music"), QStandardPaths::MusicLocation);
    add(QStringLiteral("Videos"), QStandardPaths::MoviesLocation);
    return list;
}

QVariantList FileHelper::mounts() const
{
    QVariantList list;

    // 根文件系统
    QVariantMap root;
    root.insert(QStringLiteral("name"), QStringLiteral("File System"));
    root.insert(QStringLiteral("path"), QStringLiteral("/"));
    list << root;

    // /media/<用户名>/ 下的可移动设备
    const QString home = QDir::homePath();
    const QString mediaDir = QStringLiteral("/media/") + home.section(QLatin1Char('/'), -1);
    auto appendSubDirs = [&list](const QString &dir) {
        QDir d(dir);
        if (!d.exists())
            return;
        const auto entries = d.entryList(QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name);
        for (const QString &entry : entries) {
            QVariantMap m;
            m.insert(QStringLiteral("name"), entry);
            m.insert(QStringLiteral("path"), dir + QLatin1Char('/') + entry);
            list << m;
        }
    };
    appendSubDirs(mediaDir);
    appendSubDirs(QStringLiteral("/mnt"));

    return list;
}

void FileHelper::addPath(const QString &path)
{
    emit newPath(path);
}
