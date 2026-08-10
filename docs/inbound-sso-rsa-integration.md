# URGS 入站认证规则与技术档案（外部系统 → URGS）

> 本文只描述“用户已经登录其他系统，从其他系统进入 URGS”的认证规则和技术实现。
> 不描述“用户已经登录 URGS，再从 URGS 跳转其他系统”的认证流程；后者见
> [系统入口与单点登录对接说明](./system-entry-sso-integration.md)。
> 多系统统一扩展方案见[多系统 RSA 单点登录技术方案](./multi-system-rsa-sso-technical-solution.md)。

## 1. 结论先行

当前工作区已经实现一条入站 RSA 免登录链路：

1. 用户先在外部系统完成登录。
2. 外部系统取得 URGS RSA 公钥，用公钥加密用户工号 `empId`。
3. 外部系统把 Base64 密文作为 `ssoToken` 跳转到 URGS。
4. URGS 使用后端私钥解密，按 `sys_user.emp_id` 查找用户。
5. 用户存在且未被停用时，URGS 签发自己的登录会话。
6. 浏览器模式下，URGS 将会话交给 URGS Web，Web 再完成用户信息和权限加载。

当前入站接口不使用 `client_id`、`client_secret`、`callbackUrl` 或 OAuth 授权码。外部系统只需要遵循 RSA 密钥、`empId`、请求地址和 URL 编码规则。

## 2. 认证边界

### 2.1 支持的入站方式

| 方式 | 接口 | 用途 | 当前状态 |
| --- | --- | --- | --- |
| 浏览器跳转 | `GET /api/auth/sso/rsa?ssoToken=...` | 外部系统菜单点击后直接进入 URGS Web | 已实现 |
| 服务端/前端接口 | `POST /api/auth/sso/rsa` | 外部系统或中间层提交密文并获取 URGS 登录信息 | 已实现 |

### 2.2 不属于本文的方向

以下接口属于 URGS 作为授权中心向其他系统提供授权码、Token 或用户信息的出口流程，不应作为“其他系统跳入 URGS”的依据：

- `POST /api/system/{id}/jump`
- `GET/POST /api/oauth/authorize`
- `POST /api/oauth/token`
- `GET/POST /api/oauth/user_info`
- `GET/POST /idp/oauth2/getToken`
- `GET/POST /idp/oauth2/getUserInfo`

## 3. 当前认证规则

| 规则项 | 当前实现 |
| --- | --- |
| 外部身份字段 | 明文身份内容必须是 URGS 用户表中的 `empId`，即 `sys_user.emp_id` 的精确值 |
| 加密算法 | `RSA/ECB/PKCS1Padding` |
| 密文格式 | 标准 Base64；放入 URL 查询参数前必须再做 URL 编码 |
| 私钥格式 | PKCS#8 PEM，头尾为 `-----BEGIN PRIVATE KEY-----` / `-----END PRIVATE KEY-----` |
| RSA 密钥长度 | 当前解密器按 2048 位 RSA 的 256 字节分块处理 |
| 用户不存在 | 返回 `401 Unauthorized`，不签发会话 |
| 用户已停用 | 仅当 `sys_user.status` 等于 `inactive`（忽略大小写）时返回 `403 Forbidden` |
| 用户状态为空或其他值 | 当前代码不会在 RSA 入站链路额外拦截，生产数据应明确维护为有效状态 |
| URGS 会话 | 随机不透明 Token，保存到 `sys_auth_session`；当前实现不是 JWT |
| 会话初始有效期 | 2 小时 |
| 会话续期 | 每次通过认证拦截器校验成功时，过期时间刷新为当前时间后 2 小时 |
| 业务请求携带方式 | `Authorization: Bearer <URGS_TOKEN>`；认证拦截器也兼容查询参数 `token` |
| 入站接口本身 | `/api/auth/sso/**` 在 Web MVC 配置中排除认证拦截器，由 RSA 入站逻辑自行完成认证 |

## 4. 技术流程

### 4.1 浏览器跳转模式

```mermaid
sequenceDiagram
    participant E as 外部系统
    participant B as 浏览器
    participant A as URGS API
    participant D as URGS 数据库
    participant W as URGS Web

    E->>E: 外部系统完成用户登录
    E->>E: 使用 URGS 公钥加密 empId
    E->>B: GET /api/auth/sso/rsa?ssoToken=密文
    B->>A: 转发请求
    A->>A: 私钥解密并得到 empId
    A->>D: 查询 sys_user.emp_id
    D-->>A: 用户及状态
    A->>D: 写入 sys_auth_session
    A-->>B: 302 到 URGS Web?sso_login_token=URGS_TOKEN
    B->>W: 加载 URGS Web
    W->>A: GET /api/auth/profile?token=URGS_TOKEN
    A->>D: 校验并续期会话
    A-->>W: AuthResponse
    W->>A: 查询用户权限
    W-->>B: 进入 URGS 目标页面
```

### 4.2 服务端接口模式

外部系统不需要让 URGS API 代为跳转时，可以直接调用：

```text
外部系统服务端/中间层
    -> POST /api/auth/sso/rsa
    -> 得到 URGS AuthResponse.token
    -> 由浏览器或外部系统前端保存该 Token
    -> 后续访问 URGS API 时携带 Authorization: Bearer <token>
```

该模式返回的是 URGS 登录信息，不会自动返回 302，也不会自动切换浏览器页面。

## 5. 接口契约

### 5.1 GET：浏览器入站跳转

请求：

```http
GET {URGS_API_BASE_URL}/api/auth/sso/rsa?ssoToken={URL_ENCODED_BASE64}&target=dashboard
```

参数：

| 参数 | 必填 | 说明 |
| --- | --- | --- |
| `ssoToken` | 是 | 外部系统使用 URGS 公钥加密 `empId` 后得到的标准 Base64 密文，再 URL 编码 |
| `target` | 否 | URGS Web 内部 hash 路由，例如 `dashboard`、`knowledge`；当前前端未做路由白名单校验，调用方只能传内部页面标识 |

成功响应为 `302 Found`，`Location` 结构如下：

```text
{URGS_WEB_BASE_URL}/?sso_login_token={URL_ENCODED_URGS_TOKEN}&sso_target=dashboard
```

`URGS Web` 读取 `sso_login_token`，调用 `/api/auth/profile?token=...` 完成二次校验和用户信息加载，然后删除地址栏中的临时参数。

### 5.2 POST：直接获取 URGS 登录信息

请求：

```http
POST {URGS_API_BASE_URL}/api/auth/sso/rsa
Content-Type: application/json
```

```json
{
  "ssoToken": "URL 解码后的标准 Base64 密文"
}
```

成功响应：

```json
{
  "token": "URGS opaque session token",
  "id": "1",
  "empId": "001001",
  "name": "张三",
  "roleName": "管理员",
  "roleId": 1,
  "system": "URGS",
  "orgName": "科技部",
  "phone": "13800000000",
  "avatarUrl": "/profile/avatar.png"
}
```

其中 `token` 是后续访问 URGS 业务接口的 Bearer Token。外部系统不应把 `ssoToken` 当作 URGS 业务 Token 使用。

### 5.3 URGS Web 内部交接接口

该接口是浏览器 GET 模式的内部交接步骤，不是外部系统必须实现的独立 SSO 协议：

```http
GET {URGS_API_BASE_URL}/api/auth/profile?token={URGS_TOKEN}
```

也可以使用：

```http
Authorization: Bearer {URGS_TOKEN}
```

成功返回同 `AuthResponse` 结构。后续普通 URGS API 请求统一使用：

```http
Authorization: Bearer {URGS_TOKEN}
```

## 6. 外部系统接入规则

### 6.1 身份映射

外部系统必须先完成本地账号到 URGS 工号的映射：

```text
外部系统当前登录用户
    -> 外部系统侧映射
    -> URGS sys_user.emp_id
    -> URGS user.id
    -> URGS sys_auth_session.user_id
```

不要把姓名、手机号、角色名或外部系统内部数据库 ID 直接作为 RSA 明文；当前 URGS 只按 `emp_id` 查用户。

### 6.2 RSA 加密要求

- URGS 生成 RSA 密钥对；私钥只部署在 URGS API，公钥提供给外部系统。
- 外部系统使用 `RSA/ECB/PKCS1Padding` 和 URGS 公钥加密 UTF-8 编码的 `empId`。
- 加密结果使用标准 Base64，不使用 Base64 URL-safe 变体。
- 作为 URL 参数传递时，对完整 Base64 字符串执行 URL 编码，尤其要处理 `+`、`/` 和 `=`。
- 当前实现只接受 PKCS#8 私钥 PEM；不要直接把 `BEGIN RSA PRIVATE KEY` 的 PKCS#1 私钥配置给 URGS。

Java 示例：

```java
String empId = "001001";
PublicKey publicKey = loadX509PublicKey(urgsPublicKeyPem);
Cipher cipher = Cipher.getInstance("RSA/ECB/PKCS1Padding");
cipher.init(Cipher.ENCRYPT_MODE, publicKey);
String encrypted = Base64.getEncoder().encodeToString(
        cipher.doFinal(empId.getBytes(StandardCharsets.UTF_8)));
String url = URGS_API_BASE_URL + "/api/auth/sso/rsa?ssoToken="
        + URLEncoder.encode(encrypted, StandardCharsets.UTF_8);
```

### 6.3 浏览器入口要求

- 浏览器入口使用 GET 模式。
- `URGS_WEB_BASE_URL` 为空时，API 使用相对根路径；API 和 Web 分离部署时必须配置该变量。
- `target` 只传 URGS 内部页面标识，不传外部 URL，不把它当作开放重定向参数使用。
- 生产环境必须使用 HTTPS；当前代码不负责把 HTTP 自动升级为 HTTPS。

## 7. URGS 侧配置与密钥管理

### 7.1 环境变量

```bash
export URGS_INBOUND_SSO_RSA_PRIVATE_KEY='-----BEGIN PRIVATE KEY-----
...
-----END PRIVATE KEY-----'

# API 与 Web 非同域或非同一服务时配置
export URGS_WEB_BASE_URL='https://urgs.example.com/'
```

对应 Spring 配置：

```yaml
urgs:
  web-base-url: "${URGS_WEB_BASE_URL:}"
  inbound-sso:
    rsa:
      private-key: "${URGS_INBOUND_SSO_RSA_PRIVATE_KEY:}"
```

### 7.2 生成密钥对

```bash
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out urgs_sso_private.pem
openssl rsa -pubout -in urgs_sso_private.pem -out urgs_sso_public.pem
```

分发规则：

- `urgs_sso_private.pem` 只进入 URGS API 的受保护密钥配置，不进入前端、不发给外部系统、不提交 Git。
- `urgs_sso_public.pem` 提供给外部系统使用。
- 测试、预生产、生产环境应使用独立密钥对，并登记公钥指纹和生效环境。
- 密钥轮换需要安排新旧密钥重叠期；当前代码没有内置多公钥轮换能力，需要通过部署切换或后续改造完成。

## 8. 会话和数据库档案

### 8.1 会话生命周期

`AuthTokenService.issue(userId)` 生成随机不透明 Token，并写入 `sys_auth_session`。Token 初始有效期为 2 小时。

`AuthenticationInterceptor` 对业务请求提取 Bearer Token 后调用 `AuthTokenService.validate(token)`：

1. 查询 `sys_auth_session.token`。
2. 不存在返回未认证。
3. 已过期删除该会话并返回未认证。
4. 有效时把 `userId` 写入请求属性。
5. 将过期时间刷新为当前时间后 2 小时。

因此当前会话是“滑动有效期”，不是固定的两小时绝对过期。

### 8.2 关键表

| 表 | 关键字段 | 用途 |
| --- | --- | --- |
| `sys_user` | `id`, `emp_id`, `status` | 外部 `empId` 映射到 URGS 用户，并判断是否停用 |
| `sys_auth_session` | `token`, `user_id`, `expires_at` | 保存 URGS 不透明登录会话 |

`sys_auth_session` 由 Flyway `V85__Create_Auth_Session.sql` 创建。入站 RSA 本身不新增 Entity 字段，也不要求新增迁移脚本。

## 9. 认证拦截和权限边界

当前请求处理顺序如下：

1. `WebConfig` 将 `/api/**` 接入 `AuthenticationInterceptor`。
2. `/api/auth/sso/**` 被排除在通用认证拦截之外，否则首次入站没有 URGS Token 会被提前拒绝。
3. `AuthController` 自己完成 RSA 解密、用户查找和 URGS Token 签发。
4. 其他普通 API 必须通过 `Authorization: Bearer <token>` 或兼容的 `token` 查询参数。
5. 需要业务权限的接口再由 `AuthorizationInterceptor` 检查 `@RequirePermission`。

`SecurityConfig` 当前对 Spring Security 请求统一 `permitAll`，实际登录 Token 门禁由 `AuthenticationInterceptor` 完成；排查入站认证问题时应优先查看该拦截器和 `AuthController` 日志。

## 10. 错误和联调判定

| 场景 | 当前结果 | 重点检查 |
| --- | --- | --- |
| GET 入站成功 | `302 Found` | `Location` 是否为正确的 URGS Web 地址 |
| POST 入站成功 | `200 OK` | 是否返回 `token` 和正确的用户信息 |
| RSA 私钥未配置 | `503 Service Unavailable` | `URGS_INBOUND_SSO_RSA_PRIVATE_KEY` 是否注入到 API 进程 |
| `ssoToken` 为空或密文非法 | `400 Bad Request` | 是否使用正确密钥、算法、Base64 和 URL 编码 |
| `empId` 在 URGS 不存在 | `401 Unauthorized` | 外部工号映射和 `sys_user.emp_id` |
| 用户状态为 `inactive` | `403 Forbidden` | URGS 用户是否被停用 |
| Web 交接失败 | 通常为 `401 Unauthorized` | `sso_login_token` 是否被截断、是否跨域配置错误、API 与 Web 是否使用同一会话数据库 |
| 普通业务 API 无 Token | `401 Unauthorized` | 是否携带 `Authorization: Bearer <token>` |

最小验收清单：

- 正确工号可以进入 URGS。
- 不存在工号不能进入 URGS。
- 停用用户不能进入 URGS。
- 修改一个 Base64 字符后不能进入 URGS。
- GET 模式可以完成 302、`profile`、权限加载和目标页进入。
- POST 模式返回的 Token 可以调用 `/api/auth/profile` 或其他需要登录的 URGS API。
- API 与 Web 分离部署时，`URGS_WEB_BASE_URL` 配置正确。

## 11. 当前安全等级和生产加固项

当前实现适合可信内网联调或受控环境接入，但不能把“RSA 加密”误认为完整的外部系统身份认证。原因是：任何拿到 URGS 公钥的一方都可以为任意已知 `empId` 生成可解密密文；密文没有证明发送方是谁。

当前需要明确记录的限制：

| 限制 | 当前行为 | 生产建议 |
| --- | --- | --- |
| 来源真实性 | 只有加密，没有外部系统签名、`client_id` 或来源绑定 | 使用外部系统私钥签名的带 `issuer`、`audience`、`empId`、`iat`、`exp`、`nonce` 断言，或采用 mTLS/服务端换票 |
| 重放 | 同一个 RSA 密文可重复调用，每次都能签发新 URGS Token | 使用一次性票据，短 TTL，服务端消费后立即失效 |
| Token 暴露 | GET 模式把 URGS Token 放入 302 URL，再由 Web 以查询参数交接 | URL 只传短时一次性 code，Web 通过 POST 换取 URGS Token |
| 调用范围 | 代码没有内置外部系统白名单、IP 白名单或限流 | 按系统、环境、网络区域配置访问控制和限流 |
| 密钥轮换 | 单个环境变量只支持当前一把私钥 | 建立密钥版本、双钥过渡、吊销和审计机制 |
| 目标页 | `target` 当前由前端直接转换为 hash，未做服务端白名单 | 只允许固定的内部路由集合 |
| 审计 | 有成功/失败日志和脱敏 Token 引用，但没有完整的外部系统、请求号和一次性票据审计模型 | 记录系统标识、用户映射、结果、失败原因、票据引用和追踪号，禁止记录原始密文和 Token |
| 传输 | 代码不强制 HTTPS | 生产入口、反向代理和外部系统到 URGS 的链路必须使用 HTTPS |

在未完成上述加固前，入站 RSA 方案的上线边界应限定为可信网络、受控外部系统和已登记用户映射，不应直接作为公网开放 SSO。

## 12. 技术文件索引

| 文件 | 责任 |
| --- | --- |
| `urgs-api/src/main/java/com/example/urgs_api/auth/controller/AuthController.java` | `/api/auth/sso/rsa` GET/POST、解密、用户查找、会话签发、浏览器 302 |
| `urgs-api/src/main/java/com/example/urgs_api/auth/util/RsaSsoTokenUtil.java` | PKCS#8 RSA 私钥解析、标准 Base64 解码、PKCS#1 v1.5 解密 |
| `urgs-api/src/main/java/com/example/urgs_api/auth/service/AuthTokenService.java` | URGS 会话 Token 签发、数据库校验和滑动续期 |
| `urgs-api/src/main/java/com/example/urgs_api/config/AuthenticationInterceptor.java` | 普通 API 的 Bearer/查询参数 Token 门禁 |
| `urgs-api/src/main/java/com/example/urgs_api/config/WebConfig.java` | `/api/auth/sso/**` 入站路径排除规则和 CORS |
| `urgs-api/src/main/java/com/example/urgs_api/auth/dto/AuthResponse.java` | 入站成功返回的用户和 Token 数据结构 |
| `urgs-web/src/App.tsx` | 读取 `sso_login_token`、调用 profile、保存本地会话、加载权限和目标页 |
| `urgs-api/src/main/resources/application.yml` | `URGS_INBOUND_SSO_RSA_PRIVATE_KEY`、`URGS_WEB_BASE_URL` 配置映射 |
| `urgs-api/src/main/resources/db/migration/V85__Create_Auth_Session.sql` | `sys_auth_session` 会话表 |
| `docs/system-entry-sso-integration.md` | 反向的 URGS → 其他系统 OAuth 出口流程，不要与本文混用 |

## 13. 对接方交付资料清单

外部系统正式接入 URGS 前，双方应至少交换并确认：

- 外部系统名称、环境和联系人。
- 外部系统用户唯一标识到 URGS `empId` 的映射表或映射规则。
- URGS 入站 API 地址和目标页面约定。
- 当前环境对应的 URGS RSA 公钥指纹。
- 外部系统使用的加密算法、编码和 URL 拼接实现。
- 测试用户、正常用户、停用用户和不存在用户的验收结果。
- HTTPS、网络白名单、密钥保管和日志脱敏责任人。
