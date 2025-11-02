SELECT e.emp_no,
       e.first_name,
       e.last_name
FROM employees e
LEFT JOIN dept_manager dm
  ON dm.emp_no = e.emp_no
WHERE dm.emp_no IS NULL
ORDER BY e.emp_no;

-- 2.2: Retrieve all columns in the sales table for customers above 60 years old.
-- (Assumes a `birth_date` column on `customers`; adjust the age logic for your schema.)
SELECT s.*
FROM sales s
JOIN customers c
  ON c.customer_id = s.customer_id
WHERE TIMESTAMPDIFF(YEAR, c.birth_date, CURRENT_DATE) > 60
ORDER BY s.customer_id, s.order_line;

-- Exercise 2.1: Write a JOIN statement to get the result of 2.3
SELECT e.emp_no,
       e.first_name,
       e.last_name,
       dm.dept_no
FROM employees e
JOIN dept_manager dm
  ON dm.emp_no = e.emp_no
ORDER BY e.emp_no;

-- Exercise 2.2: Retrieve a list of all managers that were employed
-- between 1st January, 1990 and 1st January, 1995
SELECT dm.emp_no,
       dm.dept_no,
       dm.from_date,
       dm.to_date
FROM dept_manager dm
JOIN employees e
  ON e.emp_no = dm.emp_no
WHERE e.hire_date >= '1990-01-01'
  AND e.hire_date <  '1995-01-01'
ORDER BY dm.emp_no, dm.dept_no;

-- 3.1: Retrieve a list of all customers living in the southern region
SELECT c.customer_id,
       c.customer_name,
       c.segment,
       c.region
FROM customers c
WHERE c.region = 'South';

-- Exercise 3.1: Retrieve a list of managers, their first, last, and their department names
SELECT dm.emp_no,
       e.first_name,
       e.last_name,
       dm.dept_no,
       d.dept_name,
       dm.from_date,
       dm.to_date
FROM dept_manager dm
JOIN employees e
  ON e.emp_no = dm.emp_no
JOIN departments d
  ON d.dept_no = dm.dept_no
ORDER BY dm.dept_no, dm.emp_no;

-- Exercise 4.1: Retrieve a list of customer_id, product_id, order_line and the name of the customer
SELECT s.customer_id,
       s.product_id,
       s.order_line,
       c.customer_name
FROM sales s
JOIN customers c
  ON c.customer_id = s.customer_id
ORDER BY s.customer_id, s.order_line;

-- Exercise 5.1: Return a list of all employees who are in Customer Service department
SELECT de.emp_no,
       de.dept_no,
       de.from_date,
       de.to_date
FROM dept_emp de
JOIN departments d
  ON d.dept_no = de.dept_no
WHERE d.dept_name = 'Customer Service'
ORDER BY de.emp_no;

-- Exercise 5.2: Include the employee number, first and last names
SELECT e.emp_no,
       de.dept_no,
       e.first_name,
       e.last_name,
       de.from_date,
       de.to_date
FROM employees e
JOIN dept_emp de
  ON de.emp_no = e.emp_no
JOIN departments d
  ON d.dept_no = de.dept_no
WHERE d.dept_name = 'Customer Service'
ORDER BY e.emp_no;

-- Exercise 5.3: Retrieve a list of all managers who became managers after
-- the 1st of January, 1985 and are in the Finance or HR department
SELECT dm.emp_no,
       e.first_name,
       e.last_name,
       dm.dept_no,
       d.dept_name,
       dm.from_date,
       dm.to_date
FROM dept_manager dm
JOIN employees e
  ON e.emp_no = dm.emp_no
JOIN departments d
  ON d.dept_no = dm.dept_no
WHERE dm.from_date > '1985-01-01'
  AND d.dept_name IN ('Finance', 'Human Resources')
ORDER BY dm.from_date, dm.emp_no;

-- Exercise 5.4: Retrieve a list of all employees that earn above 120,000
-- and are in the Finance or HR departments
SELECT DISTINCT s.emp_no,
       s.salary
FROM salaries s
JOIN dept_emp de
  ON de.emp_no = s.emp_no
JOIN departments d
  ON d.dept_no = de.dept_no
WHERE s.salary > 120000
  AND d.dept_name IN ('Finance', 'Human Resources')
ORDER BY s.salary DESC;

-- Exercise 5.5: Retrieve the average salary of these employees
SELECT s.emp_no,
       ROUND(AVG(s.salary), 2) AS avg_salary
FROM salaries s
JOIN dept_emp de
  ON de.emp_no = s.emp_no
JOIN departments d
  ON d.dept_no = de.dept_no
WHERE d.dept_name IN ('Finance', 'Human Resources')
  AND s.salary > 120000
GROUP BY s.emp_no
ORDER BY avg_salary DESC;

-- Exercise 6.1 & 6.2: Employee salary vs overall salary metrics using window functions
WITH salary_stats AS (
  SELECT s.emp_no,
         AVG(s.salary)       AS emp_avg_salary,
         AVG(s.salary) OVER () AS overall_avg_salary
  FROM salaries s
  GROUP BY s.emp_no
)
SELECT e.emp_no,
       e.first_name,
       e.last_name,
       ss.emp_avg_salary,
       ss.overall_avg_salary,
       ss.emp_avg_salary - ss.overall_avg_salary AS salary_diff
FROM salary_stats ss
JOIN employees e
  ON e.emp_no = ss.emp_no
ORDER BY e.emp_no;

-- Exercise 6.3: Max salary gap for Finance / HR employees vs company-wide max
WITH emp_max AS (
  SELECT e.emp_no,
         MAX(s.salary) AS emp_max_salary
  FROM employees e
  JOIN salaries s
    ON s.emp_no = e.emp_no
  JOIN dept_emp de
    ON de.emp_no = e.emp_no
  JOIN departments d
    ON d.dept_no = de.dept_no
  WHERE d.dept_name IN ('Finance', 'Human Resources')
  GROUP BY e.emp_no
), overall AS (
  SELECT MAX(s.salary) AS overall_max_salary
  FROM salaries s
)
SELECT e.emp_no,
       e.first_name,
       e.last_name,
       em.emp_max_salary,
       o.overall_max_salary,
       o.overall_max_salary - em.emp_max_salary AS salary_diff
FROM emp_max em
JOIN employees e
  ON e.emp_no = em.emp_no
CROSS JOIN overall o
ORDER BY e.emp_no;

-- Exercise 7.1: Retrieve the salary that occurred the most
WITH salary_counts AS (
  SELECT salary,
         COUNT(*) AS salary_count
  FROM salaries
  GROUP BY salary
)
SELECT salary
FROM salary_counts
ORDER BY salary_count DESC, salary DESC
LIMIT 1;

-- Exercise 7.2: Find the average salary excluding the highest and the lowest salaries
WITH extremes AS (
  SELECT MIN(salary) AS min_salary,
         MAX(salary) AS max_salary
  FROM salaries
)
SELECT ROUND(AVG(s.salary), 2) AS avg_salary
FROM salaries s
CROSS JOIN extremes e
WHERE s.salary NOT IN (e.min_salary, e.max_salary);

-- Exercise 7.3: Retrieve a list of customers who bought the most from the store
WITH customer_orders AS (
  SELECT s.customer_id,
         COUNT(*) AS order_count
  FROM sales s
  GROUP BY s.customer_id
)
SELECT c.customer_id,
       c.customer_name,
       co.order_count
FROM customer_orders co
JOIN customers c
  ON c.customer_id = co.customer_id
ORDER BY co.order_count DESC, c.customer_id;

-- Exercise 7.4: Customers who bought the most and generated the highest total sales
WITH customer_sales AS (
  SELECT s.customer_id,
         COUNT(*)    AS order_count,
         SUM(s.sales) AS total_sales
  FROM sales s
  GROUP BY s.customer_id
)
SELECT c.customer_id,
       c.customer_name,
       c.segment,
       cs.order_count,
       cs.total_sales
FROM customer_sales cs
JOIN customers c
  ON c.customer_id = cs.customer_id
ORDER BY cs.total_sales DESC, cs.order_count DESC;



