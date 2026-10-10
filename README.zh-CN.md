# causalmiss：缺失数据下因果发现的首版 R 包

作者与维护者：Yuqi Qiu，yqqiu@fem.ecnu.edu.cn。版本：0.1.0。

本版完成的是可以安装、运行、检查和继续开发的正式软件包。方法范围为三篇论文的部分线性高斯模块。完整的模型范围与公式核对见 `inst/doc/METHODS.md`。

## 安装

```r
install.packages("remotes") # 用于 GitHub 安装，不是 causalmiss 的运行依赖。
remotes::install_github("yuqi77/causalmiss", ref = "v0.1.0")
library(causalmiss)
help(package = "causalmiss")
```

源码仓库地址为 [yuqi77/causalmiss](https://github.com/yuqi77/causalmiss)。
[v0.1.0 Release](https://github.com/yuqi77/causalmiss/releases/tag/v0.1.0) 提供
[源码 tar.gz](https://github.com/yuqi77/causalmiss/releases/download/v0.1.0/causalmiss_0.1.0.tar.gz) 和
[Windows zip](https://github.com/yuqi77/causalmiss/releases/download/v0.1.0/causalmiss_0.1.0.zip)。下载后也可按实际文件路径安装：

```r
install.packages("实际路径/causalmiss_0.1.0.tar.gz", repos = NULL, type = "source")
```

Windows 安装 zip 时将 `type` 改成 `"win.binary"`。运行仅依赖 R 自带包，需要 R >= 4.1.0；源码安装不需要 Rtools。
发布与各平台检查的实际完成状态见 [发布清单](RELEASE_CHECKLIST.md)。

## 主要用法

```r
s <- simulate_causal_data(n = 400, mechanism = "mar", seed = 42)
fit <- iterative_discovery(s$incomplete, max_iter = 5)
fit$trace
plot(fit$graph)

dr <- dr_impute(s$incomplete, graph = s$dag)
dr$diagnostics

file.show(system.file("doc", "GETTING_STARTED.md", package = "causalmiss"))
source(system.file("examples", "toy_workflow.R", package = "causalmiss"))
```

示例中的 DAG 只作为已知图的插补演示。实际发现的 `fit$graph$adjacency` 为无向骨架。矩阵中 `graph[i,j]=1` 表示 i 指向 j；两个方向都为 1 表示无向相邻。

## 本版覆盖与限制

1. `Complete manuscript with suppl.pdf`：实现线性结果模型、logistic 观测倾向、经验似然校准、残差修正；修正附带脚本中与公式不一致的计算。只在校准成功时记录为经验似然修正，失败会警告并明确记录回退。
2. `JSSAM Asrat.pdf`：实现来源指标辅助的线性 FCS 多重插补、固定邻域倾向协变量，以及 Fisher-z 条件独立检验的 Rubin 合并。本版不包含复杂抽样权重、分层、PSU 方差扩展。
3. `论文正文.pdf`：实现观测尺度的滞后窗口和固定图下的线性回归插补。原文的代理变量识别与方向判别尚未实现。
4. 提供 PC-stable 的骨架搜索，并将它与插补结合成可运行的交替流程。这是算法适配，不是原论文 GES 或时序代理算法的完整复现。

论文中的渐近或收敛结论依赖其具体假设；本包的迭代停止标志只描述数值停止条件。将时序数据构造成重叠窗口后，不能直接将普通独立样本检验的 p 值当作已校准的时序推断。

## 材料在哪里

| 文件/目录 | 用途 |
|---|---|
| `DESCRIPTION`, `NAMESPACE` | 元数据、作者、依赖与函数导出 |
| `R/` | 可安装的方法实现 |
| `man/` | 每个公开函数的 R 帮助文档 |
| `tests/` | 公式、边界输入、观测保持与可重复性测试 |
| `inst/doc/` | 随安装提供的教程与方法映射 |
| `inst/examples/` | 可执行合成数据示例 |
| `inst/CITATION` | 软件与方法引用 |
| `.github/workflows/` | Windows、macOS、Linux 自动检查与手动构建发布文件 |
| `docs/DEVELOPMENT.zh-CN.md` | 建包流程、结构与维护方法 |
| `docs/PUBLISHING.zh-CN.md` | GitHub 发布、归档核对与下载安装的步骤 |
| `LICENSE`, `LICENSE.md`, `NEWS.md` | 软件许可与版本记录 |

原始 PDF、真实调查数据和原始研究脚本保留在工作区；未放进分发的软件包。正式本地验证结果见
[docs/LOCAL_VALIDATION.md](docs/LOCAL_VALIDATION.md)，托管检查结果见
[GitHub Actions](https://github.com/yuqi77/causalmiss/actions)。软件问题可提交到
[GitHub Issues](https://github.com/yuqi77/causalmiss/issues)。
