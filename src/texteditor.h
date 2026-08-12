#ifndef TEXTEDITOR_H
#define TEXTEDITOR_H

#include <QObject>
#include <QVariantList>

class FileHelper : public QObject
{
    Q_OBJECT
    // 用户主目录
    Q_PROPERTY(QString homePath READ homePath CONSTANT)
    // 标准用户目录（文档/下载/图片等）：[{name, path}]
    Q_PROPERTY(QVariantList standardPaths READ standardPaths CONSTANT)
    // 挂载的磁盘/分区列表：[{name, path}]
    Q_PROPERTY(QVariantList mounts READ mounts CONSTANT)

public:
    explicit FileHelper(QObject *parent = nullptr);

    QString homePath() const;
    QVariantList standardPaths() const;
    QVariantList mounts() const;

    Q_INVOKABLE void addPath(const QString &path);

signals:
    void newPath(const QString &path);
};

#endif // TEXTEDITOR_H
