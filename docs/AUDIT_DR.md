# Audit of the DR manuscript and supplied implementation

Date: 2026-10-10. Source: `Complete manuscript with suppl.pdf`, 27 PDF pages.
PDF pages 8--9 were rendered to `tmp/pdfs/dr-08.png` and `dr-09.png` and visually
read to verify the core formulas. The method sections, supplementary proof, and
relevant supplied scripts were read; this audit does not claim an independent
proof of the paper's results.

## Source-to-code mapping

| Source locator | Exact role | First-package implementation |
|---|---|---|
| p. 4, section 3.1 | Indicator delta = 1 for observed, 0 for missing | Logical observed rows derived from the original raw matrix; no imputed row becomes observed. |
| p. 5, section 3.3, equations 1--4 | Regression imputation with an empirical-likelihood residual correction; mean target under covariate-dependent MAR | The first release targets continuous data and fully observed MAR propensity predictors. It estimates linear means and logistic observation probabilities. |
| p. 7, section 4.2.1 | Sort incomplete variables by increasing missing rate and reuse recent updates | One `dr_impute` pass follows that order. `initial` allows a complete current state to be supplied by an outer iteration. |
| p. 8, section 4.2.2 | Outcome uses parents; observation model uses parents/children, missingness flags, predicted target values | Parent plus undirected sibling outcome sets adapt the supplied CPDAG code. First MAR release uses fully observed graph neighbors for propensity; excludes own target and partially observed propensity covariates. This is a deliberate restricted model, not full MNAR reproduction. |
| p. 8, equations 12--15 | Observation likelihood, normalized positive mass p_i, weighted observation moment, and weighted eta moment | Solver enforces positive denominators, normalization, observation moment, and centered eta moment. |
| pp. 8--9, equations 16--19 | gamma = (n - n_obs)/(n_obs (1 - theta)); solve two calibration equations for theta and xi | Uses dimensionless scaled eta for numerical conditioning, damped Newton with positive-domain backtracking, then a bounded Nelder-Mead attempt. All constraints must pass before accepting. |
| p. 9, equation 20 | Add one scalar SUM over observed weighted residuals to every missing prediction | `correction = sum(q * (y_observed - mu_observed))`; only missing entries receive `mu + correction`. |
| p. 9, Algorithm 1 | Alternate graph search and imputation, with graph and value stopping checks | Root's outer wrapper provides a bounded descriptive iteration; no inherited optimization theorem. |
| pp. 10--11, Theorems 1--2; pp. 20--26 supplement | Convergence and asymptotic mean claims under assumptions and regularity conditions | No standard errors or general convergence/graph-recovery theorem are claimed for this toy implementation. |

## Formula ambiguity found by visual inspection

Equation 16 on p. 8 visibly prints

`p_i = delta_i / n_obs * [1 + gamma (w_i - theta) + xi eta_centered_i]`.

This multiplicative bracket is inconsistent with equations 18--19, which divide
each moment numerator by that bracket, and with the positive normalized masses
from the constrained empirical likelihood. The supplied Python and R programs
also divide by the bracket. The implementation therefore uses the inferred
inverse form

`p_i = delta_i / (n_obs * [1 + gamma (w_i - theta) + xi eta_centered_i])`.

This is an explicit reconciliation of the manuscript's equations, not an exact
literal transcription of the printed equation 16. The same issue appears in
the precursor weight expression near equation 1 on p. 5.

## Two decisive errors in the supplied scripts

1. **A scalar average replaces the centered row-specific calibration vector.**
   `数据和代码/codes.py`, lines 46--47, computes `eta_tuta=eta=eta.mean()`.
   The manuscript requires `eta_i - mean(eta)`, with one value per row. The error
   is also present in `simulation_new_cpdags/R/04_dr_impute.R`, lines 83--84 and
   `dr_equations` lines 10--15, as `eta_bar`, and in
   `python_dr_iterative_sim/dr_imputer.py`, lines 118--119 and 20--24. It changes
   both the moment constraint and every empirical-likelihood denominator.

2. **The residual correction is zero on every missing row.**
   `codes.py`, line 60, computes `pred_y + delta*q*(Y-pred_y).sum()`. The R port
   `04_dr_impute.R`, line 101, computes the same elementwise expression. Since
   delta is zero wherever the target is missing, the correction to every value
   actually imputed is identically zero. Equation 20 instead requires one
   observed-row weighted residual sum, added to all missing predictions. The
   supplied completed datasets therefore implement regression prediction at
   missing entries, rather than the stated DR correction (assuming finite
   arithmetic; invalid denominators can additionally create NaN values).

Related scripts in `dr_validation_extended/scripts/dr_pass_specified.R` and
`python_dr_iterative_sim/R/dr_pass_graph_spec.R` contain the same two errors.
These files are left unchanged and are not copied into the new package.

Additional differences: the R port sometimes uses the Markov blanket, including
co-parents, whereas the manuscript specifies direct parent/child neighbors.
The original Python script adds the target itself after inserting predictions
for missing targets. Initial intercept-only predictions use the mean of the
working completed target, which can depend on a previous fill; the new code
uses the original observed targets for every outcome regression.

The original simulation also differs from the manuscript: p. 12 prints an X3
observation model depending on X1 and X3 while calling it MAR; `codes.py` uses X1
and X2. Its M3/M5/M6 draws are deleted at indicator 1, so their displayed
probabilities are missing probabilities rather than the manuscript's delta = 1
observation probabilities. Later `simulation_new_cpdags` scripts use a different
V1--V6 SEM. These inconsistencies rule out describing this release's demonstration
as an exact reproduction of the paper's tables. The toy package uses a separately
documented MAR example.

## Interpretation and proof boundaries

The MAR argument in section 3.3 requires the identifying conditional relation
`E(delta | covariates, Y) = E(delta | covariates)` and appropriate positivity,
moment, and nuisance-model assumptions. Replacing an unknown target value by a
deterministic prediction in a logistic model is not, by itself, identification
of an unrestricted MNAR observation law. No unrestricted MNAR guarantee is
assigned to this release.

The result's primary target is a marginal mean. Preserving that mean does not
recover missing-entry errors or preserve variances, covariances, conditional
independence relations, or the entire joint distribution. Deterministic
`mu + correction` completion does not retain conditional residual noise.
Graph recovery therefore does not follow just from the DR mean argument.

The supplement's convergence argument assumes imputation maximizes a common
conditional likelihood and graph search exactly maximizes an equivalent score.
Equation 20 and a greedy penalized graph score do not establish those premises
for the implemented steps. A nondecreasing bounded likelihood sequence alone
does not imply a global maximum, a unique maximum, or convergence of its
parameter sequence. A continuous-data density need not be bounded by 1. Measured
parents alone do not remove Markov equivalence. Thus the package records finite
iteration stopping empirically and does not advertise global optimization or
guaranteed convergence.

Theorem 2 supplement p. 23 lists smoothness, positivity, integrability, a positive
definite nuisance information matrix, a nonzero calibration determinant, and a
finite outcome second moment. Its calculations use graph-based oracle
covariates. Estimated graphs, filled propensity covariates, arbitrary MNAR,
propensity clipping, or deterministic full-distribution recovery need their own
arguments; these are not supplied by the implemented toy code. The first
release therefore does not provide a standard error based on equation 24.

## Bounded implementation delivered

`dr_impute(data, graph = NULL, outcome_predictors = NULL,
propensity_predictors = NULL, clip = 0.01, calibration_tol = 1e-6,
initial = NULL)` completes numeric data with linear outcome and logistic
observation models. User-specified propensity predictors must be fully observed;
graph defaults use fully observed direct neighbors and exclude own target.
Outcomes use incoming and undirected edges and may use current filled predictor
values, an explicitly documented plug-in approximation.

`dr_calibrate(y, observed, mu, propensity, tol = 1e-6)` exposes the core equation
calculation with supplied nuisance predictions. It returns observed-support
weights, a scalar correction, normalized moment error, positive denominator
checks, and completed values, with observed responses unchanged.

When the centered eta target is outside the observed convex hull, the positive
calibration equations cannot be accepted. Solver failure, logistic failure, or
infeasibility gives a warning and `status = "regression_fallback"`, not a falsely
labeled DR completion. Nuisance design rank deficiency errors explicitly.

## Verification evidence

Executed `tmp/verify_dr.R` using R 4.5.0. Equation and integration tests passed:

- Independently constructed nonzero correction at a hand-computable
  theta = 0.5, xi = 0 root; verifies centered eta, inverse weights, and a scalar
  correction rather than an elementwise zero-at-missing correction.
- Exact zero residual produces zero correction.
- Infeasible observed convex hull is explicitly rejected and marked fallback.
- MAR end-to-end completion preserves every observed value and accepts positive
  calibrated weights and moment residuals within tolerance.
- Names with spaces, graph predictor selection, fully observed input, and
  explicit `initial` restoration are supported.
- A partially observed user propensity predictor is rejected.
- Response scaling by 1e-10 and 1e6 preserves the calibration weights and scales
  the residual correction as expected.
- Extreme probabilities that make a starting denominator numerically zero
  produce an explicit fallback rather than a solver crash.

Executed `tmp/verify_dr_iterative.R` with the package's outer wrapper, MAR data
from `simulate_causal_data(n = 300, missing = 0.25, seed = 9)`, and five DR
iterations. All original observations were preserved, all completed values
were finite, no target fell back, and accepted moment errors were at most
4.9e-9. The final value change was about 0.19677 and one graph edge changed;
the bounded run correctly reported that its convergence criterion was not met.

These checks establish implementation consistency on bounded examples; they
are not Monte Carlo validation or verification of the manuscript's theorems.

The cited Qin, Shao and Zhang (2008) bibliographic record and DOI were checked
against the publisher page: https://www.tandfonline.com/doi/abs/10.1198/016214508000000238.
That page's abstract describes covariate-dependent missing responses; the
original article's full formulas were not used as an independent proof source
in this audit.
