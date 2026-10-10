# Method audit: JSSAM integrated incomplete-data causal discovery

Date: 2026-10-10. Source: `JSSAM Asrat.pdf`, 49 PDF pages.

Paper: Asrat Ayele Woldemariam, Yingchun Zhou, and Yuqi Qiu (2026), **Causal discovery with incomplete data integrated from multiple sources**, *Journal of Survey Statistics and Methodology*, DOI `10.1093/jssam/smag016`.

The following records distinguish the paper's specifications from the package implementation. The audit is based on the whole extracted article, with the algorithm and central formulas checked against page images. Rendered evidence is in `tmp/paper_renders/jssam_p16.png`, `jssam_p17.png`, `jssam_p19.png`, `jssam_p20.png`, and `jssam_p35.png`.

## SOURCE: problem, target, and assumptions

- PDF pp. 3–4: PC starts with conditional independence tests, then discovers a skeleton, identifies unshielded colliders, and propagates edge orientations; observational discovery generally identifies a Markov equivalence class rather than a unique DAG.
- PDF pp. 10–11, Assumptions 1–3: faithfulness, causal Markov condition, causal sufficiency. These are needed for the intended causal interpretation.
- PDF pp. 7 and 11, Section 3.2: integration assumes population invariance/transferability, measurement comparability, and stable underlying causal structure across survey years. The target in the Mali application is a super-population causal graph.
- PDF pp. 14–15: imputation assumes missing at random conditional on the adopted predictors, including missingness propensity and source. A fitted propensity predictor is an auxiliary variable; the paper's motivating assumption does not become empirically guaranteed by inserting that predictor.
- PDF p. 43: mixed continuous/categorical/ordinal variable handling is a future extension, and unmeasured confounding plus violations of source invariance remain limitations.

## SOURCE: propensity and imputation mechanism

1. Define the original binary missingness indicator `M_ij = 1` if variable `j` is missing for row `i` and 0 otherwise (PDF p. 13).
2. From a current working graph, identify variable `j`'s adjacent variables `N_j`. Fit a logistic regression

   `logit Pr(M_ij = 1) = beta0 + X_i,N_j beta + M_i,N_j psi`.

   These are equations (1)–(2), PDF p. 14. Both neighboring variable values and neighboring original missingness indicators enter the design.
3. Regress each partially observed variable on all other variables, its variable-specific propensity score, and the source indicator. Draw missing values from the fitted posterior predictive model (PDF p. 15; Algorithm 1 Step 2 on PDF p. 17).
4. Alternate a completed-data PC fit, neighborhood propensity estimation, and imputation until the current and previous graphs share the same skeleton and v-structures, i.e. are Markov equivalent (PDF p. 15; Algorithm 1 on PDF p. 17).
5. Repeat for `M` independent imputations, then pool conditional-independence estimates; the final graph is learned from these pooled tests rather than obtained by voting over finished graphs (Algorithm 1 Steps 3–6, PDF p. 17).

Algorithm 1 initializes each missing entry with a random draw from values observed for that variable and starts its working graph at a null graph. Figure 2 on PDF p. 16 depicts the graph–propensity–imputation loop. The algorithm image explicitly calls for posterior predictive stochastic draws, so deterministic mean or fitted-value replacement alone would not implement its imputation step.

## SOURCE: exact unweighted Gaussian pooling formulas

Checked visually on PDF pp. 19–20:

- Eq. (8): `z_m = 0.5 log((1 + rho_m)/(1 - rho_m)) = atanh(rho_m)`.
- Eq. (9): `U_m = 1/(n - |Q| - 3)` for a Fisher-z partial correlation conditional on `Q`.
- Eq. (10): `z_bar = mean(z_m)`.
- Eq. (11): `T_var = U_bar + (1 + 1/M) B`, where `U_bar = mean(U_m)` and `B = sum((z_m - z_bar)^2)/(M - 1)`.
- Eq. (12): `t_MI = z_bar/sqrt(T_var)`.
- Unnumbered degrees-of-freedom formula on PDF p. 20:

  `nu = (M - 1) * (1 + M * U_bar / ((M + 1) * B))^2`.

The algorithm replaces the classical single-data-set Fisher-z test inside stable PC by the pooled test. PDF p. 20 specifies freezing adjacency sets within each conditioning-set size for order-independent skeleton estimation. Source indicators are also put in the conditioning design (abstract pp. 1–2, discussion p. 42, and application p. 34); the formula's effective number of conditioning regressors must count their contrasts.

## INTERPRETATION: what can be promised

- Individual pooled tests use approximate normality of Fisher-z and approximate Rubin t inference. Although Theorem 1's displayed statement on pp. 20–21 uses strong finite-sample language, its proof on p. 21 describes the t law as approximate. This toy implementation therefore documents approximate tests, not exact finite-sample coverage or certain graph recovery.
- Graph learning also requires the causal assumptions, sufficiently informative tests, and appropriate sample-size/threshold behavior. Using a fixed finite sample, fixed alpha, and truncated conditioning order does not establish recovery of the true equivalence class.
- Conditioning on source contrasts adjusts additive source mean effects in this Gaussian linear submodel. It does not make arbitrary source-specific mechanisms, variances, or covariance structures interchangeable, and averaging correlations can mask heterogeneity.
- If a variable is wholly absent from one source, its missing values in that source require transport/extrapolation assumptions. A source indicator with no observed target responses in a level cannot identify that level's target-specific mean shift. If a variable is absent everywhere, no data-based imputation is possible.
- Merely estimating missingness propensities does not turn an MNAR problem into MAR or establish overlap. Saturated or separated logistic fits can provide near-degenerate scores; these are numerical and modeling diagnostics, not evidence of correct MAR inference.

## ADAPTATION: implemented version 0.1.0 components

### `pooled_ci_test(imputations, x, y, given, source)`

- Complete finite numeric matrices, same dimensions and column order, at least two imputations.
- Calls the package's `gaussian_ci_test()` for each completed data set, thereby sharing one residualization/partial-correlation implementation.
- Uses QR residualization on an intercept, the requested observed/imputed covariates, and complete source contrasts or a user-provided source design matrix.
- Uses actual QR conditioning rank (excluding the intercept) in `1/(n-rank-3)`. This is a deliberate design-rank extension of the formula when source factors need multiple contrasts or designs have redundant columns.
- Applies the displayed Rubin formulas exactly and returns each variance component and transformed estimate for audit.
- If `B = 0`, sets `nu = Inf` and uses the limiting normal distribution, avoiding division by zero.
- Carries no survey weighting or design inference.

### `source_mi(data, source, m, max_iter, graph, seed)`

- Bayesian linear FCS over continuous variables; all other current completed variables and source contrasts enter each target regression.
- Initializes by independent hot-deck draws from observed values of the target variable.
- Uses posterior residual variance draws `sigma^2 = RSS / chi_squared_(n_obs - rank)`, normal coefficient draws with covariance `sigma^2 (X'X)^(-1)`, then normal predictive draws for missing responses. This is an explicit small implementation choice for the paper's stochastic FCS step.
- Linear response and predictor calculations are standardized internally and back-transformed to the original measurement units, preserving the regression model while avoiding false degeneracy for tiny units. Logistic predictors are also standardized without changing the specified model class.
- Original observed entries never change. Entirely missing columns are rejected. At least three observed values are required for incomplete targets; lack of regression residual degrees of freedom or variance is also rejected.
- With a supplied graph, symmetrizes edge presence into an undirected neighborhood, ignores diagonal entries, and estimates the paper's logistic missingness model each sweep using current filled neighbors plus the original missingness mask. Adds fitted probabilities as target-specific auxiliary predictors.
- Propensity probabilities are clipped to `[1e-6, 1-1e-6]`, and convergence/boundary/clipping/warning/rank diagnostics are attached. A summary warning is emitted once per call if fits do not converge, reach a boundary, require clipping or emit a GLM warning. The propensity regression's coefficient uncertainty is not independently sampled. Propensity predictors that are constant or redundant on observed response rows are dropped along with other rank-deficient columns.
- **The graph stays fixed.** `max_iter` counts FCS sweeps. This is a fixed-neighborhood imputation module, not the paper's full alternating graph-estimation algorithm or its Markov-equivalence convergence rule.
- When `graph = NULL`, it is source-aware linear FCS without propensity augmentation, similar in scope to the paper's source-aware MIWPC imputation baseline (PDF p. 27).
- A supplied local seed restores the caller's RNG state on success or error. No external R package dependencies are needed.

For both functions, appropriate stochastic imputations and adequate model fit remain substantive assumptions. This lightweight FCS implementation has not established joint-model compatibility, frequentist operating characteristics, or the publication's numerical performance.

## SOURCE: complex survey branch deliberately outside v0.1.0

PDF pp. 34–38, Section 6.2 and Algorithm 2:

- The imputation model includes survey weights, stratum and cluster variables as well as source and propensity information (Algorithm 2, PDF p. 35).
- Compute weighted means, weighted covariances and weighted partial correlations (Eq. (19), PDF p. 36), followed by Fisher-z transformation (Eq. (20)).
- Estimate within-imputation variance by first-order Taylor linearization `g' V_design(theta_hat) g` (Eq. (21), PDF p. 37). Simple substitution of sample size, effective sample size or normalized weights into `1/(n-|Q|-3)` would not reproduce this step.
- Pool the design-based variances and Fisher-z estimates, then use the paper's displayed adjusted degrees of freedom based on Rubin df and survey df `number of PSUs - number of strata` (Eq. (22) and accompanying equations, PDF p. 38).
- Algorithm 2 explicitly includes collider orientation and orientation propagation after pooled skeleton learning.

The current API does not take survey weights, clusters, or strata, and the package must not be described as reproducing the Mali complex-survey analysis.

## Validation completed for this component

`causalmiss/tests/mi.R` passed against the current source files on R 4.5.0:

1. An independent direct `lm()` residualization and hand Rubin calculation matched every pooled estimate, variance, statistic, degrees of freedom, and p-value.
2. Repeated identical imputations returned zero between variance and infinite df.
3. Three-level source labels contributed two contrasts to conditioning rank, with the expected within variance.
4. All completed values were finite, observed entries were identical, imputations varied, and local-seed reruns were identical.
5. Graph-assisted propensity augmentation generated a diagnostic row for every target/sweep/imputation.
6. Invalid input and entirely missing variables were rejected; caller RNG restoration was also checked after an imputation error.
7. Redundant source columns did not inflate conditioning rank, and each level-zero MI skeleton test matched a direct pooled test with the same source design.
8. A local seed left an initially absent caller RNG state absent; FCS results were invariant to multiplication of every variable by `1e-10` after back transformation.
9. Propensity numerical problems produced one captured summary warning per call, and diagnostic records retained GLM warning messages and clipping counts.

These are component-level executable checks and formula verification, not a Monte Carlo study or replication of the paper's reported results.
