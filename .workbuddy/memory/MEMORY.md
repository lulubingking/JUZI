# 橘子手机（Orange Phone）企业官网 · 长期项目记忆

## 项目定位
- 纯展示型企业官网（无在线交易），虚构品牌"橘子手机 Orange Phone"，参考 mi.com 信息架构
- 技术栈：FastAPI + MySQL + SQLAlchemy 后端；React 18 + Vite + TS + Zustand + Ant Design(后台) 前端
- 路径：`C:\Users\13535\Desktop\橘子手机`

## PRD 基线（v1.3 已评审确认）
- 文档：`橘子手机企业官网PRD.md`（同目录，v1.3：品牌 JUZI PHONE、四大系列、示例产品 JUZI 1/X1/Flip/TriFold、§12.5 素材约定）
- 导航结构（v1.1 起固定）：一级 5 项 = 首页 / 产品 / 新闻 / 招聘入口 / 关于我们；每项挂二级；服务中心体系**不进入顶部导航**，入口仅在页脚
- 功能编号：前台 F-XXX-###（F-GLB/F-HOME/F-LIST/F-DET/F-CASE/F-NEWS/F-CAREER/F-ABOUT/F-CONT/F-SRV），后台 B-XXX-###
- 双语字段命名 `xxx_zh` / `xxx_en`，缺英文回退中文
- 案例分类用稳定 `category_key`（retail/education/manufacturing）做 URL 参数
- 产品"保存草稿=下架态"（status=0），products 表用 launch_date 区别上市日期与 published_at
- 里程碑 M1-M6：脚手架→产品→内容→前台完善→系统能力→优化上线

## 原型资产
- `index.html`（根目录）= 前台高保真单文件多视图原型（10 视图 / 244 项 i18n）
- `admin.html`（根目录）= 后台管理系统原型（17 视图，Ant Design 风格）
- `手机素材/` = 设计素材（logo.png + 机型颜色图 + 透明轮播图）
- 设计系统：主色 #FF6A00（橘子橙）/ 字体 PingFang SC + Inter / 圆角 14-20 / 头部 72px sticky
- 关键约束：footer 必须在 `<main>` **之外**（否则会阻断后续视图渲染）

## 关键文件与决策
- PRD：根目录 `橘子手机企业官网PRD.md`
- 原型：根目录 `index.html`
- 工作记忆：`.workbuddy/memory/YYYY-MM-DD.md`（按日追加）
- 每日清理临时 `.tmp_*.png` 截图

## 用户协作偏好
- 文档/原型交付前需逐项确认关键决策（导航、模块、字段等）
- 偏好"继续"等极简增量指令，按里程碑节奏推进
- 文档优先 Markdown 格式；原型优先 HTML（可视化、可交互）
