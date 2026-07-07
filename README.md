<p align="center">
<img src="https://images.weserv.nl/?url=raw.githubusercontent.com/7l4i8y1a4n3g8-7l4i8y1a4n3g8-1438-9748/moesora/master/templates/assets/dist/logo.svg&w=160&h=160&fit=cover&mask=circle" alt="moesora" width="160">
</p>

<h1 align="center">Moesora</h1>

<p align="center">As lovely as sora！一款二次元少女风格的 Halo 2.x 博客主题～</p>

<p align="center">
<a href="https://github.com/7l4i8y1a4n3g8-7l4i8y1a4n3g8-1438-9748/moesora/releases"><img alt="releases" src="https://img.shields.io/github/release/7l4i8y1a4n3g8-7l4i8y1a4n3g8-1438-9748/moesora.svg?style=flat-square"/></a>
<a href="https://github.com/halo-dev/halo"><img alt="halo" src="https://img.shields.io/badge/halo-2.14.0%2B-brightgreen?style=flat-square"/></a>
<a href="https://github.com/7l4i8y1a4n3g8-7l4i8y1a4n3g8-1438-9748/moesora/blob/master/LICENSE"><img alt="license" src="https://img.shields.io/github/license/7l4i8y1a4n3g8-7l4i8y1a4n3g8-1438-9748/moesora?style=flat-square"/></a>
<a href="https://github.com/7l4i8y1a4n3g8-7l4i8y1a4n3g8-1438-9748/moesora/releases"><img alt="downloads" src="https://img.shields.io/github/downloads/7l4i8y1a4n3g8-7l4i8y1a4n3g8-1438-9748/moesora/total.svg?style=flat-square"/></a>
<a href="https://github.com/7l4i8y1a4n3g8-7l4i8y1a4n3g8-1438-9748/moesora/commits"><img alt="commits" src="https://img.shields.io/github/last-commit/7l4i8y1a4n3g8-7l4i8y1a4n3g8-1438-9748/moesora.svg?style=flat-square"/></a>
</p>

本仓库为 `Halo 2.x` 主题仓库。设计参考二次元博客审美，主色为樱花粉 `#f9a8d4`，可在后台自由更换。

## 一、预览

DEMO：[https://www.moesora.cn/](https://www.moesora.cn/)

![screenshot](./screenshot.png)

## 二、说明

Moesora 是一款面向二次元 / ACG 爱好者的 Halo 2.x 博客主题，强调轻量、自包含与可定制：交互脚本以 CoffeeScript 编写、样式以 PostCSS 编写，经 Vite 构建为单一 `moesora.js` 与 `moesora.css`，评论等第三方客户端已内置打包，尽量不依赖外部 CDN。

如有问题或建议，欢迎提交 [Issue](https://github.com/7l4i8y1a4n3g8-7l4i8y1a4n3g8-1438-9748/moesora/issues)；如果愿意参与改进，也欢迎提交 PR。

## 三、功能特性

<details open>
<summary>点击展开 / 收起完整功能列表</summary>

- [x] 二次元少女风格设计，樱花粉主题色，可在后台自定义主题色
- [x] 浅色 / 深色 / 跟随系统三种配色，提供切换按钮并记忆选择
- [x] 完整 SEO：动态标题、描述、Open Graph、Twitter Card、JSON-LD、RSS 自动发现
- [x] 可选 Pjax 无刷新加载
- [x] 自包含图片灯箱（零依赖、不走 CDN）：缩放 / 旋转 / 拖动 / 长图滚动 / 双指缩放 / 键盘操作
- [x] 高级代码块：语言标识、行号、折叠、一键复制（兼容非 HTTPS 的复制回退）
- [x] 文章目录 TOC，滚动高亮（scrollspy）联动
- [x] CJK 感知的字数统计与预计阅读时长
- [x] 评论系统：内置评论 / Twikoo / Waline，客户端已内置打包，无需额外引入 CDN
- [x] 留言墙自定义页面（访客可写的便签留言墙，基于评论系统）
- [x] 恋爱墙 / 在一起时长展示
- [x] 原创二次元背景特效 + 点击特效 + 鼠标拖尾
- [x] 可选 Live2D 看板娘（模型地址自备，运行库走 CDN、不占主题体积）
- [x] 侧边栏布局可选：三列 / 仅左 / 仅右
- [x] 文章封面视差
- [x] 正文视频 / 音频播放器增强（支持 mp4 / m3u8）
- [x] KaTeX 数学公式
- [x] 可选 PWA（Service Worker 离线缓存）
- [x] 打印样式优化
- [x] 站外链接跳转确认页
- [x] 客户端随机生成的几何头像（默认评论头像，纯本地、无第三方请求）
- [x] 404 等错误页面
- [x] 适配 Halo 2.x 友链、图库、瞬间等插件页面

> 上述功能大部分均可在 `后台 -> 外观 -> 主题 -> 设置` 中开关与配置。

</details>

## 四、页面支持

| 页面 | 模板 | 说明 |
| --- | --- | --- |
| 首页 | `index.html` | 文章列表 |
| 文章页 | `post.html` | 正文、目录、评论 |
| 单页面 | `page.html` | 自定义页面 |
| 归档 | `archives.html` | 按时间归档 |
| 分类 | `categories.html` / `category.html` | 分类列表 / 分类详情 |
| 标签 | `tags.html` / `tag.html` | 标签列表 / 标签详情 |
| 友链 | `links.html` | 需 `plugin-links` |
| 图库 | `photos.html` | 需 `plugin-photos` |
| 瞬间 | `moments.html` / `moment.html` | 需 `plugin-moments` |
| 留言墙 | `page_wishes.html` | 自定义模板，单页 slug 建议设为 `wishes` |
| 错误页 | `error/` | 404 等 |

## 五、插件依赖

> 所有插件均为可选，未安装则对应功能不显示。

- 评论功能：[plugin-comment-widget](https://github.com/halo-sigs/plugin-comment-widget)（或在主题设置中改用内置的 Twikoo / Waline）
- 搜索功能：[plugin-search-widget](https://github.com/halo-sigs/plugin-search-widget)
- 流程图 / 文本绘图：[plugin-text-diagram](https://github.com/halo-sigs/plugin-text-diagram)
- 友链页面：[plugin-links](https://github.com/halo-sigs/plugin-links)
- 图库页面：[plugin-photos](https://github.com/halo-sigs/plugin-photos)
- 瞬间页面：[plugin-moments](https://github.com/halo-sigs/plugin-moments)

## 六、版本适配关系

| 主题版本 | 适配 Halo 版本 | 测试用 Halo 版本 |
| --- | --- | --- |
| 1.0.x | 2.14.0+ | 2.x |

## 七、安装 & 更新

1. 进入主题 [Release](https://github.com/7l4i8y1a4n3g8-7l4i8y1a4n3g8-1438-9748/moesora/releases) 界面，下载主题压缩包 `moesora.zip`；
2. 进入博客后台 `主题 -> 主题管理 -> 安装主题`，选择下载的 `moesora.zip` 上传；
3. 等待安装完成后启用主题；
4. 更新时同样前往 Release 下载新版 `moesora.zip`，通过 `主题 -> 主题管理 -> Moesora -> 升级` 上传安装包即可。

## 八、参与主题开发

本主题采用「构建模式」：交互脚本为 CoffeeScript，样式为 PostCSS，统一由 Vite 构建。

**源码目录**

- 脚本：`src/script/index.coffee`
- 样式：`src/style/index.css`
- 静态资源（logo、光标等）：`src/public/`
- 构建产物：`templates/assets/dist/{moesora.js, moesora.css}`（请勿手动编辑）

**开发环境**

- Node.js 18+
- 本主题使用 pnpm 管理依赖，请在主题目录下执行 `pnpm install` 安装依赖
  - 首次安装若提示 `Ignored build scripts: esbuild`，执行一次 `pnpm approve-builds` 选中 esbuild 即可

**命令**

- `pnpm dev` —— 监听源码变化并持续构建（`vite build --watch`），便于调试；
- `pnpm build` —— 编译 CoffeeScript + 打包 CSS，并调用官方 `@halo-dev/theme-package-cli` 生成可导入 Halo 的主题包 `dist/moesora-<版本>.zip`。

**技术栈**：Vite + CoffeeScript（自定义 Vite 插件编译）+ PostCSS（postcss-preset-env / autoprefixer，浏览器前缀按 browserslist 自动处理）。

## 九、开源协议

本项目基于 [MIT](./LICENSE) 协议开源。

## 十、赞助

如果 Moesora 对你有帮助，欢迎请作者喝一杯奶茶 (｡･ω･｡)ﾉ♡ —— 每一份支持都是项目持续维护的动力。

| 微信 | 支付宝 |
| :---: | :---: |
| <img src="https://www.moesora.cn/upload/wechat.png" width="200" alt="微信赞赏码"> | <img src="https://www.moesora.cn/upload/alipay.png" width="200" alt="支付宝收款码"> |

> 也欢迎通过 Star ⭐ 与 [提交 Issue / PR](https://github.com/7l4i8y1a4n3g8-7l4i8y1a4n3g8-1438-9748/moesora/issues) 来支持本项目。

<p align="center"><sub>少女祈祷中...</sub></p>
