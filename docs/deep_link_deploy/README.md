# Paracosm 邀请链接部署文件

将本目录内容部署到 `https://invite.zjtxy.top` 对应站点根目录：

```text
/.well-known/apple-app-site-association
/.well-known/assetlinks.json
/invite/index.html
/invite/REPLACE_WITH_DOWNLOAD_PAGE_URL/index.html
```

要求：

- `apple-app-site-association` 不能带 `.json` 后缀，不能 301/302 跳转。
- `.well-known/*` 必须通过 HTTPS 访问。
- iOS 响应 `Content-Type` 建议为 `application/json`。
- Android `assetlinks.json` 已写入本次生成的 release 签名 SHA-256。
- 下载页里的 iOS、Android 下载地址必须按实际包地址维护；分享链接路径固定使用 `/invite/REPLACE_WITH_DOWNLOAD_PAGE_URL`。

当前工程配置：

```text
iOS Team ID: UQ5YNCKLPM
iOS Bundle ID: com.mak.io
Android applicationId: com.example.paracosm
Android release SHA-256: 44:E0:B4:E8:F7:53:AE:41:34:22:C8:37:4A:4B:C7:57:B0:1F:96:B0:A0:35:14:48:E9:C3:E8:EB:0D:BE:EB:33
Universal/App Link: https://invite.zjtxy.top/invite/REPLACE_WITH_DOWNLOAD_PAGE_URL?code=ABCD1234
Scheme Link: paracosm:///invite?code=ABCD1234
```

如果服务器支持 rewrite，可以直接把 `/invite/REPLACE_WITH_DOWNLOAD_PAGE_URL` 指向 `/invite/index.html`。如果只是上传静态目录，保留本目录中的兼容入口即可。

Android SHA-256 获取方式：

```bash
keytool -list -v -keystore your-release-key.jks -alias your_alias
```

当前 release 使用 `android/key.properties` 指向的正式签名文件；`key.properties` 与 keystore 不要提交 Git。
