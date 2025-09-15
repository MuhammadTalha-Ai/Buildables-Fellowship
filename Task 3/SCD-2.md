# Different Types of Slowly Changing Dimensions (SCD)

## SCD Type 0 (Retain Original Data)

Never updates the record, keeps original values.
Useful for immutable attributes like date of birth.

## SCD Type 1 (Overwrite)

Overwrites old data with new values.
Useful for non-historical attributes like spelling corrections.

## SCD Type 2 (History Tracking)

Maintains full history by closing old records and inserting new ones.
Useful for attributes where history is important (price changes, job role, subscription status).

## SCD Type 3 (Limited History with Previous Column)

Adds an extra column for "previous value".
Useful when only one level of history is needed (e.g., current and previous address).

#Which SCD to Use?

**Type 0 →** Immutable data (DOB, SSN).
**Type 1 →** Corrections where history is irrelevant (typo fixes, minor metadata).
**Type 2 →** Historical tracking (prices, status, subscriptions).
**Type 3 →** When limited history is enough (e.g., only keep current and last department of an employee).
