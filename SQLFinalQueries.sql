create table Public."Customer"(Id_client int, Total_amount int, Gender varchar(5), Age int, Count_city int, Response_communication int, Communication_3month int, Tenure int)

select * from Public."Customer"

COPY Public."Customer" from 'D:\customer_info.xlsx - QUERY_FOR_ABT_CUSTOMERINFO_0002.csv' DELIMITER ',' CSV HEADER ;

create table Public."Transaction"(date_new date, Id_check int, ID_client int, Count_products float, Sum_payment float)

select * from Public."Transaction"

COPY Public."Transaction" from 'D:\transactions_info.xlsx - TRANSACTIONS (1).csv' DELIMITER ',' CSV HEADER ;


WITH monthly_transactions AS (
    SELECT
        ID_client,
        DATE_TRUNC('month', date_new) AS month,
        COUNT(*) AS monthly_count,
        AVG(Sum_payment) AS avg_monthly_payment
    FROM Public."Transaction"
    WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY ID_client, DATE_TRUNC('month', date_new)
),
continuous_customers AS (
    SELECT
        ID_client,
        COUNT(DISTINCT month) AS month_count,
        AVG(avg_monthly_payment) AS avg_payment,
        SUM(monthly_count) AS total_operations
    FROM monthly_transactions
    GROUP BY ID_client
    HAVING COUNT(DISTINCT month) = 12
)
SELECT
    c.ID_client,
    c.avg_payment AS avg_check,
    c.avg_payment / 12 AS avg_monthly_payment,
    c.total_operations AS total_operations
FROM continuous_customers c;








WITH monthly_data AS (
    SELECT
        DATE_TRUNC('month', date_new) AS month,
        ID_client,
        COUNT(*) AS transaction_count,
        SUM(Sum_payment) AS total_monthly_sum,
        AVG(Sum_payment) AS avg_check_amount
    FROM Public."Transaction"
    WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY DATE_TRUNC('month', date_new), ID_client
),
monthly_totals AS (
    SELECT
        month,
        SUM(transaction_count) AS total_transactions,
        SUM(total_monthly_sum) AS total_monthly_sales,
        AVG(avg_check_amount) AS avg_check,
        COUNT(DISTINCT ID_client) AS unique_customers
    FROM monthly_data
    GROUP BY month
),
yearly_totals AS (
    SELECT
        SUM(total_transactions) AS yearly_transactions,
        SUM(total_monthly_sales) AS yearly_sales
    FROM monthly_totals
)
SELECT
    m.month,
    m.avg_check AS avg_check_amount,
    m.total_transactions AS avg_transactions,
    m.unique_customers AS avg_customers_per_month,
    (m.total_transactions::FLOAT / y.yearly_transactions) * 100 AS transaction_share,
    (m.total_monthly_sales::FLOAT / y.yearly_sales) * 100 AS monthly_sales_share
FROM monthly_totals m, yearly_totals y
ORDER BY m.month;




WITH age_groups AS (
    SELECT
        CASE
            WHEN Age IS NULL THEN 'Unknown'
            WHEN Age BETWEEN 0 AND 9 THEN '0-9'
            WHEN Age BETWEEN 10 AND 19 THEN '10-19'
            WHEN Age BETWEEN 20 AND 29 THEN '20-29'
            WHEN Age BETWEEN 30 AND 39 THEN '30-39'
            WHEN Age BETWEEN 40 AND 49 THEN '40-49'
            WHEN Age BETWEEN 50 AND 59 THEN '50-59'
            WHEN Age BETWEEN 60 AND 69 THEN '60-69'
            WHEN Age >= 70 THEN '70+'
        END AS age_group,
        t.ID_client,
        t.Sum_payment,
        DATE_TRUNC('quarter', t.date_new) AS quarter
    FROM Public."Transaction" t
    JOIN Public."Customer" c ON t.ID_client = c.Id_client
    WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
),
quarterly_stats AS (
    SELECT
        age_group,
        quarter,
        SUM(Sum_payment) AS total_spending,
        COUNT(*) AS total_operations,
        AVG(Sum_payment) AS avg_spending_per_operation
    FROM age_groups
    GROUP BY age_group, quarter
)
SELECT
    age_group,
    quarter,
    total_spending,
    total_operations,
    avg_spending_per_operation,
    (total_operations::FLOAT / SUM(total_operations) OVER (PARTITION BY age_group)) * 100 AS operations_share
FROM quarterly_stats
ORDER BY age_group, quarter;
