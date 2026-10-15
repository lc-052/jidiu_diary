<p align="center">
  <img src="lib/assets/app_icon.png" width="112" alt="寄丢日记图标" />
</p>

<h1 align="center">寄丢日记 · Jidiu Diary</h1>

<p align="center">一句话也算，什么都可以写。<br />用文字、照片和涂鸦，留下生活里的小片段。</p>

<p align="center">
  <a href="https://github.com/lc-052/jidiu_diary/releases/latest">下载最新版本</a>
  · <a href="https://github.com/lc-052/jidiu_diary/issues">反馈问题</a>
</p>

## 认识寄丢

寄丢日记是一款基于 Flutter 的本地日记与心情记录应用。以米白、暖灰和黄豆小人为视觉元素，提供浅色、深色以及跟随系统的外观。记录保存在当前设备，不需要登录。

| 页面 | 可以做什么 |
| --- | --- |
| 今天 | 记录每日心情、回看其他日期、查看黄豆形象、抽取每日塔罗、开始写日记 |
| 日记 | 一天记录多篇，按日期分组、按时间排列，搜索标题、正文或日期，继续草稿与编辑记录 |
| 我的 | 查看累计记录数据与心情分布，使用带每日心情 emoji 的月历，导入和导出备份 |
| 设置 | 切换外观、管理本地音乐、导入和导出备份 |

### 写下日常

- 标题可选，支持文字、图片与涂鸦；只有图片或涂鸦也能保存。
- 编辑内容自动保存为草稿；保存后返回日记列表。
- 图片和涂鸦随日记保存，缩略图支持放大查看。
- 涂鸦提供画笔、颜色、粗细、橡皮擦、撤销、重做和清空。
- 每篇日记可以选择自己的心情，与每日心情独立保存。

### 照顾心情

- **每日心情只在「本周心情」中设置**，修改日记心情不会覆盖每日心情。
- 点击月份按钮打开日历，选择日期即可查看对应周；未来日期不可选择。
- 首页心情卡随当前所选日期更新；日历上的 emoji 来自每日心情。
- 音乐播放时，心情卡里的黄豆小人戴上耳机；暂停后恢复普通形象。

### 一点陪伴

- **今日塔罗**：78 张寄丢形象塔罗牌，在设备端随机抽取并按日期保存。当天重复打开保留同一结果，不同用户不会因为同一个日期而固定抽到同一张牌；历史日期只展示已有记录，不补抽。
- **音乐小憩**：顶部音乐按钮打开悬浮播放器，点击外部关闭。支持播放、暂停、上一首、下一首、进度拖动，以及音频内嵌封面显示；没有封面时使用默认图标。
- **本地音乐库**：支持 MP3、WAV、OGG、M4A，最多导入 50 首；内置背景音乐也可以从音乐库移除，内置曲目不占导入额度。具体解码支持取决于设备和浏览器。

## 下载与使用

从 [Releases](https://github.com/lc-052/jidiu_diary/releases/latest) 下载：

| 文件 | 用途 |
| --- | --- |
| `jidiu_diary-v1.1.0-arm64-v8a.apk` | 大多数较新 Android 手机，优先下载 |
| `jidiu_diary-v1.1.0-armeabi-v7a.apk` | 32 位 ARM Android 设备 |
| `jidiu_diary-v1.1.0-x86_64.apk` | x86_64 Android 设备或模拟器 |
| `jidiu_diary-v1.1.0-web.zip` | Web 静态网站构建产物，解压后部署到 HTTP / HTTPS 服务 |
| `SHA256SUMS.txt` | 发布文件的 SHA-256 校验值 |

Web 构建不能直接双击 `index.html` 使用，需要部署到静态服务器的根路径。部署到子目录时，请按实际路径重新设置 `--base-href`（例如 `/jidiu_diary/`）并构建。浏览器可能要求用户先点击播放才能播放音频。

Android 最低需要 Android 7.0（API 24），按 CPU 架构分包以减少下载大小，无需下载全部 APK。安装包目前沿用模板的调试签名，供体验与测试；应用商店发行需要配置正式签名。若旧包签名不同，请先在旧版备份数据，再处理安装冲突。iOS、macOS、Windows 与 Linux 保留工程入口，本次发布不提供这些平台的安装包，也不将其视为已经完成真机验收。

## 数据与备份

在「设置」或「我的」中使用「数据备份」卡片：

1. 点击 **导出数据**，保存 JSON 备份文件。
2. 点击 **导入数据**，选择本应用导出的备份，核对数量后确认导入。
3. 导入采用合并方式；重复记录保留当前本地版本，不清空已有数据。

备份包含 **日记、草稿、图片、涂鸦、每日心情与塔罗记录**，不包含本地音乐和外观设置。备份文件未加密，包含正文和图片，请妥善保管。

原生端日记及媒体使用 Sembast 本地数据库，Web 端使用 IndexedDB；塔罗与外观等偏好使用 SharedPreferences。当前没有账号、云同步或数据加密功能。卸载应用、清理浏览器站点数据或浏览器更换访问地址后，原数据可能不可用，请定期导出备份。

**旧版迁移**：本次版本重构了数据结构，未提供旧版 SharedPreferences JSON 快照的自动迁移；新版导入器只接受本项目当前备份格式。升级前请保留旧版原始备份，避免将更新应用视为数据迁移。

## 本地开发

当前开发环境为 **Flutter 3.47.5 / Dart 3.13.4**；最低 Dart 约束见 [pubspec.yaml](pubspec.yaml)。Android 构建还需要 Android SDK 与兼容的 JDK。

```sh
git clone https://github.com/lc-052/jidiu_diary.git
cd jidiu_diary
flutter pub get
flutter run -d chrome
# 或连接 Android 设备
flutter run
```

### 检查与构建

```sh
flutter analyze
flutter test
flutter build apk --release --split-per-abi
flutter build web --release
```

Android 输出位于 `build/app/outputs/flutter-apk/`，文件名形如 `app-arm64-v8a-release.apk`；Web 输出位于 `build/web/`。项目测试覆盖日记与草稿持久化、图片和涂鸦、每日心情、日历、塔罗随机与历史记录、音乐状态联动、备份恢复、明暗主题和主卡片切换。

### 工程结构

```text
lib/
  main.dart             应用入口与共享状态
  assets/               图标、黄豆表情、音频和塔罗牌素材
  backup/               JSON 备份校验与合并恢复
  constants/            主题色与心情素材映射
  diary/                日记、草稿、媒体模型与数据库
  music/                播放状态、本地音乐库与封面读取
  pages/home/           今天、日记、我的与主页面布局
  pages/diary/          日记编辑与涂鸦
  tarot/                78 张牌数据与每日抽牌存储
  theme/                浅色、深色主题
  widgets/              心情日历、播放器、功能卡片与备份卡片
test/                   数据与界面自动化测试
tool/                   应用图标生成与塔罗素材压缩工具
```

内置音频放在 `lib/assets/audio/`；心情形象放在 `lib/assets/emoji/`。塔罗原始 PNG 保留在 `lib/assets/Tarot Deck/`，应用仅打包 `lib/assets/tarot_webp/` 中的压缩 WebP，不打包原图。WebP 最大尺寸为 768 × 1152，编码质量为 86；牌面 ID 不变，历史抽牌记录继续使用。更新原图后，安装 Pillow 并运行 `python tool/compress_tarot.py` 生成压缩素材，再重新构建应用。

## 素材与项目说明

此仓库尚未声明开源许可证；公开源码不代表授予素材或代码的任意再分发权。图像、音频等素材的使用与分发需遵守各自权利人的授权。项目通过 AI 辅助开发，并结合静态检查与自动化测试验证；塔罗内容仅作为日常灵感与娱乐。
