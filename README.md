# 寄丢日记 · Jidiu Diary

基于 Flutter 的离线日记与心情记录应用。记录日常、整理情绪，在普通的日子里留下自己的足迹。

**[下载 Android 安装包](https://github.com/lc-052/jidiu_diary/releases/latest)**

## 功能

| 模块 | 功能 |
| --- | --- |
| 今天 | 本周心情、每日心情打卡、内置每日一想、写日记入口 |
| 日记 | 新增、编辑、详情、单篇删除，关键词搜索与日期/心情组合筛选 |
| 我的 | 日记数量、心情天数、心情分布、深色模式、JSON 文本备份 |
| 数据保护 | 正文校验、重复保存保护、未保存退出提醒、读取异常保护 |

## 技术与结构

- **Flutter / Dart + Material 3**：中文界面、响应式宽度和明暗主题。
- **Provider + ChangeNotifier**：集中管理日记、每日心情和设置，通知首页、列表与统计页更新。
- **SharedPreferences + JSON**：保存带版本号的数据快照，启动时恢复。
- **Navigator + IndexedStack**：详情/编辑页导航，保留底部主页面的局部状态。
- **Flutter Test**：验证数据恢复、日记操作、搜索、每日心情和退出提醒。

```text
lib/
  main.dart                    # 应用入口、Provider 与主题
  models/diary_entry.dart       # 日记模型、心情枚举、日期键
  state/diary_store.dart        # 数据操作、持久化、变更通知
  pages/                       # 今天、日记列表、详情、编辑、我的
  widgets/                     # 本周心情、共享交互
 test/                         # 数据与页面交互测试
```

### 保存后的页面联动

```text
编辑页校验输入
    → context.read<DiaryStore>().saveEntry(entry)
    → 保存候选 JSON 快照
    → 存储 API 返回成功
    → 更新内存数据，notifyListeners()
    → 使用 context.watch 的首页、列表、统计页更新
```

搜索条件、底部导航和编辑输入等页面局部状态使用 `setState`；多页面共享的业务数据由 Store 管理。保存失败时保留原数据和编辑内容，读取失败或版本不支持时禁止覆盖原始快照。

## 本地运行

需要 Flutter SDK，Dart SDK 版本要求见 [pubspec.yaml](pubspec.yaml)。

```sh
flutter pub get
flutter run -d chrome
# 或连接开启 USB 调试的 Android 手机后运行
flutter run
```

## 检查与构建

```sh
flutter analyze
flutter test
flutter build apk --release
flutter build web
```

Android 输出：`build/app/outputs/flutter-apk/app-release.apk`。

当前 Android release 构建沿用 Flutter 模板的调试签名，适合展示与试用。应用商店发布需要配置独立的发布签名。首次构建后再次运行不会覆盖已有本地记录。

## 数据规则

- 同一天可以写多篇日记；每日心情只保留一个。
- 保存日记会更新对应日期的每日心情，日记内的心情作为该篇记录保留。
- 删除日记不删除独立心情打卡；修改日记日期也保留原日期的打卡记录。
- 每日一想来自内置题库，按设备日期轮换，不需要网络请求。
- 复制备份将日记、心情和设置导出为 JSON 文本，需自行粘贴到文件中保存。

## 当前范围

数据存储在当前设备或浏览器中，未提供登录、云同步、附件、加密或备份导入。卸载应用或清理站点存储会丢失记录，请定期备份。

SharedPreferences 适合此项目的小规模本地数据；当前每次修改重写快照，不适合大量长文本。后续可迁移到数据库并增加备份恢复。存储 API 返回成功不等于系统级落盘保证。

## 开发说明

在基础页面上通过 AI 辅助开发完成业务功能，结合静态检查、自动化测试与浏览器实测验证。详细的数据流与面试准备见 [面试讲解](docs/面试讲解.md)。
