select salary
from(
select salary,
dense_rank() over (order by desc) as r
from employees
)t
where r = 3
