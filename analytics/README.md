# Analytics implementation

The analytical package contains two lightweight, reproducible baselines. The text classifier uses multinomial Naive Bayes with add-one smoothing and lowercase word tokens. The forecast uses the mean of the previous three complete calendar months. Both are integrated into the authenticated application API.

demo_transactions.csv contains 40 manually constructed, synthetic English descriptions across five categories. A deterministic stratified split with seed 42 puts 30 examples in training and 10 in evaluation. The demonstration produced accuracy 0.40 and macro F1 0.4267. This small corpus exposes the weakness of sparse vocabulary and is not evidence of performance on real bank statements. The running suggestion model uses all 40 examples; it returns no category if all tokens are unknown. Its confidence score is an uncalibrated model score.

The forecast demonstration uses 12 synthetic monthly totals. The last four months are evaluated in order, each using only earlier observations. The three-month mean has MAE 1250.00 KZT; the previous-month baseline has MAE 1375.00 KZT. These results describe only that artificial sequence and do not justify a general superiority claim. Missing recorded months are treated as zero, so incomplete history can bias the estimate.

Run `python -m analytics.evaluate` from the project root to reproduce docs/analytics-results.json. The application does not use real personal data for these experiments.
