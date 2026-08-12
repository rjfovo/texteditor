# Text Editor

Elegant text editor for CutefishOS.

## 功能特性

- 多标签页编辑，支持文件拖放/命令行参数打开
- 完整编辑操作：撤销/重做、剪切/复制/粘贴、全选
- 查找 / 替换（支持区分大小写、全词匹配）
- 跳转到指定行
- 行号显示、语法高亮（KSyntaxHighlighting）
- 文本缩放（Ctrl+/-/0）、字体自适应
- 状态栏显示 行/列、字符数、语言、编码、缩放比例
- 未保存修改关闭保护（标签关闭 / 窗口退出）
- 菜单栏 + 工具栏完整界面

## 快捷键

| 快捷键 | 功能 |
| ------ | ---- |
| Ctrl+N | 新建标签 |
| Ctrl+O | 打开文件 |
| Ctrl+S / Ctrl+Shift+S | 保存 / 另存为 |
| Ctrl+W | 关闭标签 |
| Ctrl+F / Ctrl+H | 查找 / 替换 |
| F3 / Shift+F3 | 查找下一个 / 上一个 |
| Ctrl+G | 跳转到行 |
| Ctrl+= / Ctrl+- / Ctrl+0 | 放大 / 缩小 / 重置缩放 |
| Ctrl+Q | 退出 |

## Dependencies

### Debian/Ubuntu

```
sudo apt install qt6-base-dev qt6-declarative-dev libkf6syntaxhighlighting-dev cmake build-essential
```

## Build

```shell
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX:PATH=/usr ..
make
```

## Install

```shell
sudo make install
```

### 构建 deb 包

```shell
dpkg-buildpackage -b -uc -us
```

> 注意：VMware/Mesa 虚拟机环境中 Qt6 默认的 OpenGLRhi 场景图后端无法正常渲染，
> 程序已在 main.cpp 中强制使用软件渲染（可用 `QT_QUICK_BACKEND` 环境变量覆盖）。

## License

This project has been licensed by GPLv3.
