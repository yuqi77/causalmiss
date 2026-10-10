# Method map and implementation decisions

Version 0.1.0; assessed 2026-10-10. PDF page numbers below count from the first
page of the supplied files, including front matter. This package implements
selected components, rather than reproducing all three papers or their tables.

## 1. Doubly robust manuscript

**Source:** Peng Yunjia, Qiu Yuqi and Zhou Yingchun, *Doubly robust causal
structure learning under missing data, with an application to health survey
data*, supplied as `Complete manuscript with suppl.pdf` (27 pages). The supplied
file describes a submitted manuscript; no acceptance or publication status is asserted.

**Source formulas:** pp. 8-9, equations 12-20. Let delta=1 indicate observation,
`w_i=P(delta_i=1|X_i)`, `mu_i` be a fitted conditional mean,
`eta_i=(1-w_i)*mu_i`, and `eta_c=eta-mean(eta)` over all rows. With
`gamma=(n-n_obs)/(n_obs*(1-theta))`, use positive masses

```
d_i = 1 + gamma*(w_i-theta) + xi*eta_c_i
p_i = 1/(n_obs*d_i)                         [observed support only]
q_i = (1-w_i)*p_i/(1-theta)
c = sum_observed q_i*(y_i-mu_i)
y_imputed_i = mu_i + c                      [missing rows only]
```

The numerical solver checks `sum(p)=1`, `sum(p*(w-theta))=0`,
`sum(p*eta_c)=0` (eta is scaled internally), and strictly positive denominators.
It uses damped Newton/backtracking followed by a bounded second solver attempt.
A failed or infeasible calibration emits a warning and reports
`status="regression_fallback"`; it does not count as accepted calibration.

**Reconciliation:** the printed equation 16 visibly multiplies by its bracket,
whereas the moment equations 18-19, empirical-likelihood constraints and supplied
scripts use its reciprocal. We use the reciprocal and record this as an inferred
correction. The supplied scripts also replace centered row-specific eta by a
scalar mean, and multiply the residual adjustment by delta at each destination
row. That adjustment is identically zero where the target is missing. The new
implementation follows the centered-vector/scalar-sum formulas above. Original
research files are preserved.

**Implemented model:** linear regression fitted on originally observed targets;
logistic observation model with fully observed covariates; missing variables
updated in increasing missing-rate order. Directed graph columns select parents;
symmetric edges add undirected siblings. Propensity defaults use fully observed
direct neighbours and exclude the target itself. Predictor lists can override
these defaults. Outcome predictors may include current filled values, which is
a documented plug-in adaptation when multiple variables are incomplete.

**Interpretation:** the paper's robustness argument concerns marginal mean
estimation under its MAR/positivity/nuisance assumptions. It does not by itself
recover individual missing values, covariance structure, or a causal graph.
Clipping is a numerical safeguard and can affect the estimating target. This
version provides no theorem-based standard errors or unrestricted MNAR guarantee.
Theorems and supplementary calculations on pp. 10-11 and 20-26 were read; their
assumptions are not certified by running this implementation.

## 2. Multiple-source JSSAM paper

**Source:** Asrat Ayele Woldemariam, Yingchun Zhou and Yuqi Qiu (2026), *Causal
discovery with incomplete data integrated from multiple sources*, Journal of
Survey Statistics and Methodology, DOI [10.1093/jssam/smag016](https://doi.org/10.1093/jssam/smag016),
supplied as `JSSAM Asrat.pdf` (49 pages).

**Source formulas:** propensity model, pp. 13-15, equations 1-2; stochastic FCS
and alternating graph update, Algorithm 1 p. 17. The target-specific logistic
model predicts missingness from neighbouring current variable values and their
original missingness indicators. The imputation regression includes other
variables, this propensity, and source.

`source_mi()` implements Bayesian linear FCS with source contrasts: variance
draw `RSS/chi-square_(n_obs-rank)`, normal coefficient draws with covariance
`sigma^2*(X'X)^(-1)`, and normal predictive draws. A supplied graph adds the
neighbour propensity auxiliary variable; the graph remains fixed. With no graph,
this is a source-aware FCS baseline. It does not implement the paper's inner
graph-updating/Markov-equivalence stopping algorithm.

**Pooling:** pp. 19-20, equations 8-12 and the displayed Rubin degrees of freedom.
For each completed dataset, residualize on the requested conditioning variables
and source contrasts, and calculate

```
z_m = atanh(partial_correlation_m)
U_m = 1/(n-k_m-3)
z_bar = mean(z_m)
U_bar = mean(U_m)
B = var(z_m)
V = U_bar + (1+1/M)*B
t = z_bar/sqrt(V)
df = (M-1)*(1 + M*U_bar/((M+1)*B))^2
```

`pooled_ci_test()` uses those formulas. `k_m` is actual conditioning-design
rank excluding the intercept, counting all source contrasts. This is an explicit
rank-based extension to redundant designs. If B=0, df=Inf and the limiting normal
test is used. The distributions are approximate; model assumptions and proper
imputation matter. Matrix rows across imputations must refer to the same units.

**Outside this version:** complex survey extension, pp. 34-38, Algorithm 2 and
equations 19-22, requires design-based weighted covariance, Taylor variance and
survey-adjusted degrees of freedom. It is not implemented by an effective-sample-size
substitution. Source invariance, measurement comparability and transport of
variables absent from one source remain substantive assumptions. Additive source
contrasts do not resolve arbitrary covariance heterogeneity or MNAR.

## 3. Chinese subsampled-time-series manuscript

**Source:** *基于代理变量的子采样时间序列缺失插补与因果发现*, supplied as
`论文正文.pdf` (71 pages). Author/year metadata are not inferred from the file name.

**Source formulas:** PDF p. 32 (printed p. 24), equations 3.1-3.2 construct pairs
of time slices; PDF p. 33 (printed p. 25), equations 3.4-3.6 fit a graph-selected
regression on observed targets and replace only missing entries. `lag_windows()`
implements observed-row alignment, with explicit current-row indices and a
variable/lag map. `graph_regression_impute()` implements the fixed-graph linear
regression update and records numerical changes. These are helpers/adaptations,
not the manuscript's full proxy-based identification and direction algorithm.

The manuscript uses a subsampling/time-gap notation; this package's `step`
counts rows in the data supplied to the function. It does not reconstruct
unobserved intermediate time slices. Separate subjects/series must be processed
separately to prevent windows crossing subject boundaries. Overlapping windows
do not supply independent rows for ordinary Fisher-z inference.

The convergence conditions in PDF pp. 39-41 (printed pp. 31-33) impose model
correctness/identification, regression consistency and an approximate monotone
objective with summable errors. This toy code does not verify those conditions.

## 4. Shared discovery and outer iteration

`discover_skeleton()` implements PC-stable adjacency search with neighbourhoods
frozen within each conditioning level. It accepts one complete dataset or a list
of completed datasets and delegates each test to the corresponding single/pooled
test. It returns separating sets and a test log. The bound `max_cond` deliberately
limits search cost. No collider orientation or Meek-rule closure is implemented.
PC-stable reference: [Colombo and Maathuis (2014)](https://jmlr.org/papers/v15/colombo14a.html).

`iterative_discovery()` alternates this skeleton search with one graph-guided
imputation pass. It substitutes PC-stable skeletons for the DR manuscript's GES
or the Chinese manuscript's proxy orientation. `converged` means the recorded
numerical threshold and no-edge-change criterion were met; it does not establish
global likelihood maximization or theorem-level convergence.

## 5. Validation and provenance

All implementation code was written for this package; research scripts served
as comparison material and were not copied into it. No publisher PDFs, CHARLS,
CFPS or Mali individual-level data are redistributed. All examples are newly
generated synthetic data. Software is MIT licensed; article rights are separate.

Tests include independently computed Rubin pooling, a hand-constructed nonzero
calibration correction, calibration infeasibility, independent Gaussian residual
calculations, known synthetic skeleton recovery, lag alignment, preservation of
original observations, and local RNG restoration. These checks validate bounded
implementation behavior, not paper-level simulation results or empirical benefit.
