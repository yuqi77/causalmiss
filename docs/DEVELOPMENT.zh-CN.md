# R package 开发与维护说明

## 依据与结构

建包规范以 R Core Team 的 [Writing R Extensions](https://cran.r-project.org/doc/manuals/r-release/R-exts.html) 为依据；重点是 Creating R packages、Package namespaces、Writing R documentation files、Checking packages。首版采用纯 R 实现，不需要编译工具链。

`DESCRIPTION` 使用 DCF 格式，每个字段占一项，换行续行必须缩进。`Package`、`Version`、`Title`、`Description`、`Authors@R`、`License` 是核心信息。`Depends` 指定 R 最低版本，`Imports` 声明使用的命名空间。代码中使用 `stats::` 等显式调用。

`NAMESPACE` 决定可访问的公开函数和 S3 方法注册。内部辅助函数以 `.cm_` 开头，不导出。`R/` 文件在安装时统一载入命名空间，不使用工作目录依赖、绝对用户路径或全局 `source()`。

`man/*.Rd` 提供 usage、arguments、value、details 与可执行 examples。本版直接维护 Rd，不要求 roxygen2。修改函数参数后同步修改帮助文档，并运行检查，避免文档与代码漂移。

`tests/*.R` 在安装的包上运行，因此测试的是实际安装后的命名空间。采用 base R 的 `stopifnot()`，无需 testthat。测试包含独立手算公式、校准残差、行对齐、数据保留及错误输入，而不是仅检查函数能返回对象。

## 本地开发流程

1. 修改指定模型的 `R/` 实现。
2. 同步修改 `man/`、`inst/doc/METHODS.md` 与必要的测试。
3. 调整公开 API 时更新 `NAMESPACE`，避免无文档的导出。
4. 在源码仓库目录运行 `Rscript tools/build_release.R`，或分别执行 `R CMD build`、`R CMD check`、`R CMD INSTALL`。
5. 在新 R 会话中安装构建后的归档，运行 `inst/examples/toy_workflow.R`。
6. 更新 `NEWS.md`、版本和发布记录，发布已经验证的同一归档。

```sh
R CMD build causalmiss --no-build-vignettes --no-manual
R CMD check causalmiss_0.1.0.tar.gz --no-manual
R CMD INSTALL causalmiss_0.1.0.tar.gz
```

上述命令在源码父目录执行。`--no-manual` 仅略过需要 LaTeX 的 PDF 帮助手册构建；R 帮助文档、示例、代码分析与测试仍被检查。包内提供可安装的 Markdown 教程。首版没有将其伪称为经 `R CMD build` 编译的 R vignette。

Windows 的构建脚本会为自身进程设置 UTF-8 字符分类及子进程 locale，确保中文目录可被正确处理；不修改系统或用户的永久环境设置。
Windows zip 由已成功安装的包目录使用系统 `tar.exe` 封装，避免依赖失效的外部 `zip.exe` 配置；安装包用全新库目录单独验证。

## 扩展顺序

下一版优先增加成熟库的可选 GES/完整 PC 适配器，并维持图对象的统一约定；再加入离散或非线性结果模型。复杂抽样需同时验证插补模型、权重和 CI 检验，不能只增加一个 weights 参数。时序代理方法需补齐原文识别检验、方向规则和序列依赖的推断处理。

每个新模型都应有明确的论文公式定位、实现变化说明、边界输入测试和至少一个独立数值核对。合成示例通过不代表完整论文模拟复现，也不代表真实数据上的收益。
