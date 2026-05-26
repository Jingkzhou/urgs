# URGS 入站 RSA 免登录接入说明

## 1. 适用场景

外部系统已经完成本地登录，用户点击外部系统菜单后，直接免密进入 URGS。

本方案中：

- URGS 提供 RSA 公钥给外部系统。
- 外部系统使用 URGS 公钥加密用户工号 `empId`。
- 外部系统把加密结果作为 `ssoToken` 跳转到 URGS。
- URGS 使用私钥解密 `ssoToken`，按 `sys_user.emp_id` 找到用户并签发 URGS 登录态。

## 2. URGS 配置

后端启动前配置私钥：

```bash
export URGS_INBOUND_SSO_RSA_PRIVATE_KEY='-----BEGIN PRIVATE KEY-----
...
-----END PRIVATE KEY-----'
```

如果前后端不是同域部署，需要同时配置前端地址：

```bash
export URGS_WEB_BASE_URL='http://your-urgs-web-host/'
```

## 3. 外部系统跳转地址

```text
GET http://your-urgs-api-host/api/auth/sso/rsa?ssoToken=<URL编码后的密文>
```

可选指定进入 URGS 后的页面：

```text
GET http://your-urgs-api-host/api/auth/sso/rsa?ssoToken=<URL编码后的密文>&target=dashboard
```

## 4. 外部系统生成 ssoToken 示例

```java
String empId = "001001";
String publicKey = "URGS 提供的 RSA 公钥";
String encrypted = RsaEncryptUtil.encrypt(empId, publicKey);
String ssoToken = URLEncoder.encode(encrypted, StandardCharsets.UTF_8);
String url = "http://your-urgs-api-host/api/auth/sso/rsa?ssoToken=" + ssoToken;
```

加密内容必须是 URGS 用户表中的 `emp_id`。如果外部系统登录名与 URGS 工号不一致，需要先在外部系统侧完成映射。

## 5. 密钥生成示例

生成 PKCS#8 私钥和 X.509 公钥：

```bash
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out urgs_sso_private.pem
openssl rsa -pubout -in urgs_sso_private.pem -out urgs_sso_public.pem
```

`urgs_sso_private.pem` 只配置在 URGS 后端；`urgs_sso_public.pem` 提供给外部系统。
