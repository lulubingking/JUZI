-- =====================================================================
-- 橘子手机（JUZI PHONE）企业官网 · 数据库建表脚本 schema.sql
-- 版本：v1.0  |  日期：2026-08-26  |  数据库：MySQL 8.0+
-- 依据：《橘子手机企业官网数据库设计文档.md》v1.0（对齐开发技术文档 §5）
-- 约定：InnoDB / utf8mb4 / utf8mb4_unicode_ci；物理外键默认不建（逻辑引用）
-- 说明：21 张业务表；时间字段默认 created_at/updated_at；
--       pages、site_configs 仅 updated_at；operation_logs 仅 created_at；
--       visit_stats 以 visit_date 为时间维度。
-- =====================================================================

CREATE DATABASE IF NOT EXISTS juzi_phone
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;
USE juzi_phone;

-- ---------------------------------------------------------------------
-- ① 认证与权限域（4 张表）
-- ---------------------------------------------------------------------

CREATE TABLE admin_users (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  username       VARCHAR(50)  NOT NULL COMMENT '登录账号',
  password_hash  VARCHAR(255) NOT NULL COMMENT 'BCrypt 哈希',
  name           VARCHAR(50)  NULL COMMENT '姓名',
  email          VARCHAR(100) NULL COMMENT '邮箱',
  phone          VARCHAR(20)  NULL COMMENT '手机号',
  avatar         VARCHAR(255) NULL COMMENT '头像 URL',
  role_id        BIGINT UNSIGNED NULL COMMENT '角色 id（逻辑外键 roles.id，可空）',
  status         TINYINT      NOT NULL DEFAULT 1 COMMENT '1 启用 / 0 禁用',
  failed_attempts INT         NOT NULL DEFAULT 0 COMMENT '连续密码失败次数',
  locked_until   DATETIME     NULL COMMENT '账号锁定截止时间',
  last_login_at  DATETIME     NULL COMMENT '最近登录时间',
  created_at     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_admin_users_username (username),
  KEY idx_admin_users_role_id (role_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='后台管理员';

CREATE TABLE roles (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name        VARCHAR(50)  NOT NULL COMMENT '角色名',
  code        VARCHAR(50)  NOT NULL COMMENT '角色编码 super_admin/operator/support',
  description VARCHAR(200) NULL COMMENT '描述',
  is_builtin  TINYINT      NOT NULL DEFAULT 0 COMMENT '1=内置不可删/不可编辑',
  created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_roles_code (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='角色';

CREATE TABLE permissions (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name        VARCHAR(50)  NOT NULL COMMENT '权限名称',
  code        VARCHAR(50)  NOT NULL COMMENT '权限点编码 product:view',
  module      VARCHAR(50)  NOT NULL COMMENT '所属模块',
  description VARCHAR(200) NULL COMMENT '说明',
  created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_permissions_code (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='权限点';

CREATE TABLE role_permissions (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  role_id       BIGINT UNSIGNED NOT NULL COMMENT '角色 id（逻辑外键 roles.id）',
  permission_id BIGINT UNSIGNED NOT NULL COMMENT '权限点 id（逻辑外键 permissions.id）',
  created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_role_permissions_role_perm (role_id, permission_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='角色-权限关联';

-- ---------------------------------------------------------------------
-- ② 产品域（7 张表）
-- ---------------------------------------------------------------------

CREATE TABLE product_series (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name_zh         VARCHAR(100) NOT NULL COMMENT '系列名(中)',
  name_en         VARCHAR(100) NOT NULL COMMENT '系列名(英)',
  slug            VARCHAR(120) NOT NULL COMMENT '筛选参数 flagship/x/flip/trifold',
  description_zh  VARCHAR(500) NULL COMMENT '简介(中)',
  description_en  VARCHAR(500) NULL COMMENT '简介(英)',
  sort_order      INT      NOT NULL DEFAULT 0 COMMENT '排序',
  status          TINYINT  NOT NULL DEFAULT 1 COMMENT '1 启用 / 0 停用',
  deleted_at      DATETIME NULL COMMENT '逻辑删除',
  created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_product_series_slug (slug)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='产品系列';

CREATE TABLE products (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name_zh       VARCHAR(100) NOT NULL COMMENT '产品名称(中)',
  name_en       VARCHAR(100) NOT NULL COMMENT '产品名称(英)',
  slug          VARCHAR(120) NOT NULL COMMENT '详情页 URL 标识',
  series_id     BIGINT UNSIGNED NULL COMMENT '所属系列（逻辑外键 product_series.id，可空）',
  tagline_zh    VARCHAR(200) NULL COMMENT '一句话卖点(中)',
  tagline_en    VARCHAR(200) NULL COMMENT '一句话卖点(英)',
  description_zh TEXT NULL COMMENT '产品简介(中)',
  description_en TEXT NULL COMMENT '产品简介(英)',
  price         DECIMAL(10,2) NULL COMMENT '起售价（自动取最低版本价）',
  launch_date   DATE NULL COMMENT '产品上市日期',
  cover_image   VARCHAR(255) NULL COMMENT '封面图',
  status        TINYINT  NOT NULL DEFAULT 0 COMMENT '1 上架 / 0 下架',
  is_featured   TINYINT  NOT NULL DEFAULT 0 COMMENT '1 首页推荐',
  seo_title_zh  VARCHAR(150) NULL COMMENT 'SEO 标题(中)',
  seo_title_en  VARCHAR(150) NULL COMMENT 'SEO 标题(英)',
  seo_desc_zh   VARCHAR(300) NULL COMMENT 'SEO 描述(中)',
  seo_desc_en   VARCHAR(300) NULL COMMENT 'SEO 描述(英)',
  published_at  DATETIME NULL COMMENT '上架时间',
  sort_order    INT      NOT NULL DEFAULT 0 COMMENT '排序权重',
  deleted_at    DATETIME NULL COMMENT '逻辑删除',
  created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_products_slug (slug),
  KEY idx_products_status_series (status, series_id),
  KEY idx_products_featured (is_featured),
  KEY idx_products_sort (sort_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='产品';

CREATE TABLE product_variants (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  product_id  BIGINT UNSIGNED NOT NULL COMMENT '所属产品（逻辑外键 products.id）',
  color_zh    VARCHAR(50) NOT NULL COMMENT '颜色名(中)',
  color_en    VARCHAR(50) NOT NULL COMMENT '颜色名(英)',
  color_hex   VARCHAR(9)  NULL COMMENT '色值 #FF6A00',
  storage     VARCHAR(20) NOT NULL COMMENT '存储容量 256GB',
  ram         VARCHAR(20) NULL COMMENT '运行内存 12GB',
  price       DECIMAL(10,2) NOT NULL COMMENT '该版本价格',
  is_default  TINYINT     NOT NULL DEFAULT 0 COMMENT '默认版本标记',
  sort_order  INT         NOT NULL DEFAULT 0 COMMENT '排序',
  deleted_at  DATETIME    NULL COMMENT '逻辑删除',
  created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_variants_product (product_id, sort_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='产品版本(颜色×存储)';

CREATE TABLE product_images (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  product_id  BIGINT UNSIGNED NOT NULL COMMENT '所属产品（逻辑外键 products.id）',
  image_url   VARCHAR(255) NOT NULL COMMENT '图片地址',
  is_main     TINYINT NOT NULL DEFAULT 0 COMMENT '主图标记',
  sort_order  INT     NOT NULL DEFAULT 0 COMMENT '排序',
  created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_images_product (product_id, sort_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='产品图集';

CREATE TABLE product_specs (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  product_id  BIGINT UNSIGNED NOT NULL COMMENT '所属产品（逻辑外键 products.id）',
  group_zh    VARCHAR(50)  NOT NULL COMMENT '分组名(中)',
  group_en    VARCHAR(50)  NOT NULL COMMENT '分组名(英)',
  name_zh     VARCHAR(100) NOT NULL COMMENT '参数名(中)',
  name_en     VARCHAR(100) NOT NULL COMMENT '参数名(英)',
  value_zh    VARCHAR(255) NOT NULL COMMENT '参数值(中)',
  value_en    VARCHAR(255) NOT NULL COMMENT '参数值(英)',
  sort_order  INT          NOT NULL DEFAULT 0 COMMENT '排序',
  created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_specs_product (product_id, sort_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='产品参数规格';

CREATE TABLE product_highlights (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  product_id      BIGINT UNSIGNED NOT NULL COMMENT '所属产品（逻辑外键 products.id）',
  title_zh        VARCHAR(100) NOT NULL COMMENT '亮点标题(中)',
  title_en        VARCHAR(100) NOT NULL COMMENT '亮点标题(英)',
  description_zh  TEXT NULL COMMENT '描述(中)',
  description_en  TEXT NULL COMMENT '描述(英)',
  image_url       VARCHAR(255) NULL COMMENT '配图',
  sort_order      INT      NOT NULL DEFAULT 0 COMMENT '排序',
  created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_highlights_product (product_id, sort_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='产品亮点';

CREATE TABLE purchase_channels (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  product_id  BIGINT UNSIGNED NOT NULL COMMENT '所属产品（逻辑外键 products.id）',
  name_zh     VARCHAR(50)  NOT NULL COMMENT '渠道名(中)',
  name_en     VARCHAR(50)  NOT NULL COMMENT '渠道名(英)',
  url         VARCHAR(500) NOT NULL COMMENT '渠道链接',
  status      TINYINT      NOT NULL DEFAULT 1 COMMENT '1 启用 / 0 停用',
  sort_order  INT          NOT NULL DEFAULT 0 COMMENT '排序',
  created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_channels_product (product_id, sort_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='购买渠道';

-- ---------------------------------------------------------------------
-- ③ 内容域（6 张表）
-- ---------------------------------------------------------------------

CREATE TABLE cases (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  title_zh      VARCHAR(200) NOT NULL COMMENT '案例标题(中)',
  title_en      VARCHAR(200) NOT NULL COMMENT '案例标题(英)',
  summary_zh    VARCHAR(500) NULL COMMENT '摘要(中)',
  summary_en    VARCHAR(500) NULL COMMENT '摘要(英)',
  content_zh    LONGTEXT NULL COMMENT '富文本正文(中，XSS 清洗后)',
  content_en    LONGTEXT NULL COMMENT '富文本正文(英)',
  cover_image   VARCHAR(255) NULL COMMENT '封面图(16:9)',
  category_key  VARCHAR(50)  NOT NULL COMMENT '行业分类稳定标识 retail/education/manufacturing',
  category_zh   VARCHAR(50)  NULL COMMENT '行业分类展示名(中)',
  category_en   VARCHAR(50)  NULL COMMENT '行业分类展示名(英)',
  is_featured   TINYINT  NOT NULL DEFAULT 0 COMMENT '1 首页精选',
  status        TINYINT  NOT NULL DEFAULT 0 COMMENT '0 草稿 / 1 已发布 / 2 已下线',
  published_at  DATETIME NULL COMMENT '发布时间',
  seo_title_zh  VARCHAR(150) NULL COMMENT 'SEO 标题(中)',
  seo_title_en  VARCHAR(150) NULL COMMENT 'SEO 标题(英)',
  seo_desc_zh   VARCHAR(300) NULL COMMENT 'SEO 描述(中)',
  seo_desc_en   VARCHAR(300) NULL COMMENT 'SEO 描述(英)',
  sort_order    INT      NOT NULL DEFAULT 0 COMMENT '排序权重',
  deleted_at    DATETIME NULL COMMENT '逻辑删除',
  created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_cases_status_category (status, category_key, published_at),
  KEY idx_cases_featured (is_featured)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='应用案例';

CREATE TABLE banners (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  title_zh    VARCHAR(100) NOT NULL COMMENT '标题(中)',
  title_en    VARCHAR(100) NOT NULL COMMENT '标题(英)',
  subtitle_zh VARCHAR(200) NULL COMMENT '副标题(中)',
  subtitle_en VARCHAR(200) NULL COMMENT '副标题(英)',
  image_url   VARCHAR(255) NOT NULL COMMENT '图片(16:7)',
  link_type   TINYINT      NOT NULL DEFAULT 0 COMMENT '0 无 / 1 内部页面 / 2 外链',
  link_url    VARCHAR(500) NULL COMMENT '跳转地址',
  sort_order  INT          NOT NULL DEFAULT 0 COMMENT '排序',
  status      TINYINT      NOT NULL DEFAULT 1 COMMENT '1 上线 / 0 下线',
  start_at    DATETIME     NULL COMMENT '有效期起（可空=长期）',
  end_at      DATETIME     NULL COMMENT '有效期止',
  created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_banners_online (status, start_at, end_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='轮播图';

CREATE TABLE news (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  title_zh      VARCHAR(200) NOT NULL COMMENT '标题(中)',
  title_en      VARCHAR(200) NOT NULL COMMENT '标题(英)',
  summary_zh    VARCHAR(500) NULL COMMENT '摘要(中)',
  summary_en    VARCHAR(500) NULL COMMENT '摘要(英)',
  content_zh    LONGTEXT NULL COMMENT '富文本正文(中，XSS 清洗后)',
  content_en    LONGTEXT NULL COMMENT '富文本正文(英)',
  cover_image   VARCHAR(255) NULL COMMENT '封面图(16:8.4)',
  category      VARCHAR(20)  NOT NULL COMMENT 'company 企业新闻 / industry 行业资讯',
  status        TINYINT  NOT NULL DEFAULT 0 COMMENT '0 草稿 / 1 已发布 / 2 已下线',
  published_at  DATETIME NULL COMMENT '发布时间',
  seo_title_zh  VARCHAR(150) NULL COMMENT 'SEO 标题(中)',
  seo_title_en  VARCHAR(150) NULL COMMENT 'SEO 标题(英)',
  seo_desc_zh   VARCHAR(300) NULL COMMENT 'SEO 描述(中)',
  seo_desc_en   VARCHAR(300) NULL COMMENT 'SEO 描述(英)',
  deleted_at    DATETIME NULL COMMENT '逻辑删除',
  created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_news_status_category (status, category, published_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='新闻';

CREATE TABLE pages (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  page_key    VARCHAR(50)  NOT NULL COMMENT 'about/history/brand/service/career_social/career_campus',
  title_zh    VARCHAR(200) NOT NULL COMMENT '标题(中)',
  title_en    VARCHAR(200) NOT NULL COMMENT '标题(英)',
  content_zh  LONGTEXT NULL COMMENT '富文本正文(中)',
  content_en  LONGTEXT NULL COMMENT '富文本正文(英)',
  cover_image VARCHAR(255) NULL COMMENT '横幅图',
  updated_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '内容更新时间（仅 updated_at）',
  PRIMARY KEY (id),
  UNIQUE KEY uk_pages_page_key (page_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='页面内容';

CREATE TABLE faqs (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  category_zh   VARCHAR(50)  NOT NULL COMMENT '分类(中)',
  category_en   VARCHAR(50)  NOT NULL COMMENT '分类(英)',
  question_zh   VARCHAR(300) NOT NULL COMMENT '问题(中)',
  question_en   VARCHAR(300) NOT NULL COMMENT '问题(英)',
  answer_zh     TEXT NOT NULL COMMENT '答案(中)',
  answer_en     TEXT NOT NULL COMMENT '答案(英)',
  sort_order    INT      NOT NULL DEFAULT 0 COMMENT '排序',
  status        TINYINT  NOT NULL DEFAULT 1 COMMENT '1 上线 / 0 下线',
  deleted_at    DATETIME NULL COMMENT '逻辑删除',
  created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_faqs_status_sort (status, sort_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='常见问题';

CREATE TABLE service_policies (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  title_zh    VARCHAR(200) NOT NULL COMMENT '条目标题(中)',
  title_en    VARCHAR(200) NOT NULL COMMENT '条目标题(英)',
  content_zh  LONGTEXT NULL COMMENT '正文(中)',
  content_en  LONGTEXT NULL COMMENT '正文(英)',
  sort_order  INT      NOT NULL DEFAULT 0 COMMENT '排序',
  status      TINYINT  NOT NULL DEFAULT 1 COMMENT '1 上线 / 0 下线',
  deleted_at  DATETIME NULL COMMENT '逻辑删除',
  created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_policies_status_sort (status, sort_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='售后政策条目';

-- ---------------------------------------------------------------------
-- ④ 运营与系统域（4 张表）
-- ---------------------------------------------------------------------

CREATE TABLE messages (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name          VARCHAR(50)  NOT NULL COMMENT '姓名',
  phone         VARCHAR(20)  NULL COMMENT '手机号（与邮箱至少一个）',
  email         VARCHAR(100) NULL COMMENT '邮箱',
  subject       VARCHAR(100) NULL COMMENT '主题',
  content       TEXT NOT NULL COMMENT '留言内容(≤2000字)',
  source_page   VARCHAR(100) NULL COMMENT '来源页面',
  locale        VARCHAR(10)  NULL COMMENT '提交时语言 zh/en',
  status        TINYINT      NOT NULL DEFAULT 0 COMMENT '0 待处理 / 1 处理中 / 2 已回复',
  reply_content TEXT NULL COMMENT '回复内容(≤1000字)',
  replied_by    BIGINT UNSIGNED NULL COMMENT '回复人（逻辑外键 admin_users.id，可空）',
  replied_at    DATETIME NULL COMMENT '回复时间',
  deleted_at    DATETIME NULL COMMENT '逻辑删除',
  created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_messages_status_time (status, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='留言';

CREATE TABLE site_configs (
  id           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  config_key   VARCHAR(50)  NOT NULL COMMENT 'basic/contact/social/footer/maintenance',
  config_value JSON NOT NULL COMMENT '配置内容（分组 JSON）',
  description  VARCHAR(200) NULL COMMENT '说明',
  updated_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间（仅 updated_at）',
  PRIMARY KEY (id),
  UNIQUE KEY uk_site_configs_config_key (config_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='站点配置';

CREATE TABLE operation_logs (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  admin_id    BIGINT UNSIGNED NULL COMMENT '操作人（逻辑外键 admin_users.id，可空）',
  action      VARCHAR(50)  NOT NULL COMMENT 'login/create/update/delete/publish/unpublish/status',
  module      VARCHAR(50)  NOT NULL COMMENT 'product/case/news/banner/message/user/role/config',
  target_id   VARCHAR(50)  NULL COMMENT '目标对象 id',
  detail      VARCHAR(500) NULL COMMENT '摘要',
  ip          VARCHAR(50)  NULL COMMENT '来源 IP',
  created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '记录时间（仅 created_at，日志只读不可变）',
  PRIMARY KEY (id),
  KEY idx_logs_admin_time (admin_id, created_at),
  KEY idx_logs_module_time (module, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='操作日志';

CREATE TABLE visit_stats (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  page_url    VARCHAR(255) NOT NULL COMMENT '页面 URL',
  page_name   VARCHAR(100) NULL COMMENT '页面名',
  visit_date  DATE NOT NULL COMMENT '统计日期（按日聚合）',
  pv          INT NOT NULL DEFAULT 0 COMMENT '浏览量',
  uv          INT NOT NULL DEFAULT 0 COMMENT '独立访客（IP+UA 去重）',
  PRIMARY KEY (id),
  UNIQUE KEY uk_visit_stats_page_date (page_url, visit_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='访问统计';
