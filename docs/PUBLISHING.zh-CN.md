# 后续 GitHub 发布流程

本轮按作者要求先完成本地内容。此文件记录以后公开发布时可直接执行的步骤；没有创建远程仓库或上传文件。

## 待商定信息

GitHub 账号/组织、仓库名称、公开时点。建议仓库名与包名同为 `causalmiss`，但最终以作者决定为准。作者与维护者已设为 Yuqi Qiu、yqqiu@fem.ecnu.edu.cn。

## 建仓库和推送

只将 `causalmiss/` 作为仓库根目录。不要将整个上层工作区推送，避免把论文 PDF、原始调查数据、原始脚本或本地检查库发布出去。

1. 在 GitHub 创建空的公开仓库。
2. 将 `DESCRIPTION` 的 `URL`、`BugReports` 填为实际仓库和 issue URL。
3. 将 README 的 GitHub 安装命令填为实际账号/仓库，并更新本地版本措辞。
4. 再次构建、检查，确认与发布的代码一致。
5. 从包目录执行以下命令，其中 URL 替换为实际仓库地址。

```sh
git init
git add .
git commit -m "Initial causalmiss 0.1.0 release"
git branch -M main
git remote add origin https://github.com/OWNER/REPOSITORY.git
git push -u origin main
```

不要在命令、文件或聊天中写入个人访问令牌。使用 GitHub 的正常登录流程。

## 自动检查和 Release

仓库包含 Windows、macOS、Linux 的检查工作流。第一次推送后核对三个系统的结果，再给已通过检查的提交打 tag：

```sh
git tag v0.1.0
git push origin v0.1.0
```

手动运行 Build release assets 工作流可生成源码归档；Windows job 也生成 zip。工作流只上传构建产物到 Actions，不自动发布 Release。下载产物、核对后在 GitHub 新建 `v0.1.0` Release 并附上归档、版本说明及校验信息。

## 用户下载安装

公开后，用户可以安装仓库源码：

```r
install.packages("remotes")
remotes::install_github("OWNER/REPOSITORY", ref = "v0.1.0")
library(causalmiss)
```

`OWNER/REPOSITORY` 是本文的明确占位示例，不是已存在的安装地址。也可以从实际 GitHub Release 下载 tar.gz 或 Windows zip，然后使用本地 `install.packages(..., repos=NULL, type=...)`。纯 R 源码安装不需要 Rtools。
