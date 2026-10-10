# GitHub 发布流程

目标公开仓库为 [yuqi77/causalmiss](https://github.com/yuqi77/causalmiss)，版本 tag 为 `v0.1.0`。
作者与维护者为 Yuqi Qiu、yqqiu@fem.ecnu.edu.cn。本文件记录发布操作和核对方法；实际完成状态见
[RELEASE_CHECKLIST.md](../RELEASE_CHECKLIST.md)。

## 仓库内容和首次推送

只将 `causalmiss/` 作为仓库根目录。不要将整个上层工作区推送，避免把论文 PDF、原始调查数据、原始脚本或本地检查库发布出去。
GitHub 仓库保留源码、帮助文档、测试、合成示例、方法核对、开发材料、许可证与 CI 配置。

1. 确认 GitHub 的 `yuqi77/causalmiss` 是公开仓库，且首次推送前没有冲突的独立提交。
2. 核对 `DESCRIPTION`、`inst/CITATION` 和两个 README 中的仓库、issue、tag 与 Release 地址。
3. 从最终源码重新构建、检查并安装；验证 Windows zip 后重新生成所有归档的 SHA-256 校验信息。
4. 检查 `git status`、待提交差异与完整文件列表，再提交代码并推送。

首次连接远程仓库时，从包目录执行：

```sh
git remote add origin https://github.com/yuqi77/causalmiss.git
git push -u origin main
```

已经配置远程仓库时，先用 `git remote -v` 核对地址，再正常推送；不重复添加 `origin`。
不要在命令、文件或聊天中写入个人访问令牌。使用 GitHub 的正常登录流程。

## 自动检查和 Release

推送后在 [GitHub Actions](https://github.com/yuqi77/causalmiss/actions) 核对 Windows、macOS、Linux 的检查结果。
三个系统都通过后，为已测试的提交创建版本 tag：

```sh
git tag v0.1.0
git push origin v0.1.0
```

手动运行 Build release assets 工作流可生成源码归档；Windows job 也生成 zip。
该工作流将构建产物上传到 Actions，不自动创建 Release。核对下载的产物后，在 GitHub 创建
[v0.1.0 Release](https://github.com/yuqi77/causalmiss/releases/tag/v0.1.0)，附上源码 tar.gz、Windows zip、版本说明与 SHA-256 校验信息。
GitHub 自带的 tag 源码归档同时保留完整仓库材料；本地已安装的库和检查目录不作为发布材料上传。

## 用户下载安装与外部验证

tag 发布后，可安装指定版本：

```r
install.packages("remotes")
remotes::install_github("yuqi77/causalmiss", ref = "v0.1.0")
library(causalmiss)
```

也可下载 [源码 tar.gz](https://github.com/yuqi77/causalmiss/releases/download/v0.1.0/causalmiss_0.1.0.tar.gz)
或 [Windows zip](https://github.com/yuqi77/causalmiss/releases/download/v0.1.0/causalmiss_0.1.0.zip)，
核对 SHA-256 后使用 `install.packages("实际文件路径", repos = NULL, type = "source")`；Windows zip 的 `type` 为 `"win.binary"`。
纯 R 源码安装不需要 Rtools。`remotes` 用于 GitHub 安装，不是 causalmiss 的运行依赖。

发布后必须在全新库目录中验证实际公开 tag 与 Release 下载文件，而非仅重用本地归档。
确认 `packageVersion("causalmiss")` 为 `0.1.0`、包能载入，并运行安装后的完整教程：

```r
source(system.file("examples", "toy_workflow.R", package = "causalmiss"))
```

最后核对公开仓库的文件树、tag 对应提交、Release 下载链接及校验信息。
只有观察到相应检查、发布与安装成功后，才更新发布清单和验证记录。
