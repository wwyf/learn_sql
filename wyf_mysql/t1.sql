select dept_name
from instructor;

select distinct dept_name
from instructor;

-- 3.3 ////////////////////////////////////////////////////////////////
-- 3.3.2 找出所有教师的姓名，以及他们所在系的名称和系所在建筑的名称
select instructor.name, instructor.dept_name, department.building
from instructor, department
where instructor.dept_name = department.dept_name;

-- 3.3.3 对于大学中所有讲授课程的教师，找出他们的姓名以及所讲述的所有课程标识
select name, course_id
from instructor, teaches
where instructor.ID = teaches.ID;

-- 等价于
select name, course_id
from instructor natural join teaches;

-- 自然连接的话就是将两个表中的连接起来

select *
from instructor natural join teaches;

-- 3.3.3 列出教师的名称以及他们所讲授的课程的名称
select name, title
from instructor natural join teaches natural join course;

-- 3.4 附加的基本运算 ////////////////////////////////////////////////////////////////
-- 3.4.1 更名运算 找出工资至少比Biology系某一个教师工资要高的教师
select T.name, T.salary, S.name, S.salary
from instructor as T, instructor as S
where S.dept_name = 'Biology' and T.salary > S.salary;

-- 3.4.2 字符串运算
-- 名称中含有k的
select name
from instructor
where name like '%k%';

-- 系名以E开始且包含.
select dept_name
from instructor
where dept_name like 'E%.%';

-- 3.4.5 where 子句谓语
-- 工资在某个区间
select name, salary
from instructor
where salary between 90000 and 100000;

-- 整个元组的逻辑操作
select name, course_id
from instructor, teaches
where (instructor.ID, dept_name) = (teaches.ID, 'Biology');

-- 3.5 集合运算////////////////////////////////////////////////////////////////////

-- 3.5.1 并运算 2009秋季或2010年春菊开课
(select course_id
from section
where semester = 'Fall' and year = 2009)
union
(select course_id
from section
where semester = 'Spring' and year = 2010);

-- 3.5.2 交运算
-- 3.5.3 差运算

-- 3.6 空值 ////////////////////////////////////////////////////////////////

select name
from instructor
where salary is null;

-- TODO:空值可能还需要研究一下

-- 3.7 聚集函数

-- 3.7.1 找出cs教师的平均工资
select avg(salary) as avg_salary
from instructor
where dept_name = 'Comp. Sci.';

-- 3.7.1 平均工资
select dept_name, avg(salary) as avg_salary
from instructor
group by dept_name;

-- 3.7.1 找出在2010春季学期教过课程的教师总数
select count(distinct ID)
from teaches
where semester = 'Spring' and year = 2010;

-- 3.7.2 错误查询 不能够将ID上打出来
select dept_name, ID, avg(salary)
from instructor
group by dept_name;

-- 3.7.3
select dept_name, avg(salary) as avg_salary
from instructor
group by dept_name
having avg(salary) > 42000;

-- 3.7.3
select course_id, semester, year, sec_id, avg(tot_cred)
from takes natural join student
where year = 2009
group by course_id, semester, year, sec_id
having count(ID) >= 2;

-- 3.8 嵌套子查询

-- 3.8.1 2009年秋季和2010年春季都开课的课程
select course_id
from section
where semester = 'Fall' and year = 2009 and
    course_id in
                  (select course_id
                  from section
                  where semester = 'Spring' and year = 2010);

-- 3.8.2 集合的比较 教师的工资至少比Biology系的某一个教师的工资要高
select  name
from instructor
where salary > some (select salary
                        from instructor
                        where dept_name = 'Biology')

-- <> some 并不等价于 not in
-- =all 并不等价于 in

-- 3.8.3 空关系测试
-- 找出在2009年秋季，2010年春季同时开课的所有课程
select course_id
from section as S
where semester = 'Fall' and year = 2009 and
  exists (
      select *
      from section as T
      where T.semester = 'Spring' and year = 2010 and
       T.course_id = S.course_id
  );

--   找出选修了Biology系开设的所有课程的学生
-- FIXME:mysql 不支持except关键字
-- https://stackoverflow.com/questions/27151155/sql-error-in-syntax-near-except
-- https://stackoverflow.com/questions/16092353/error-when-using-except-in-a-query
select S.ID, S.name
from student as S
where not exists (
        (select course_id  -- Biology 的课程
        from course
        where dept_name = 'Biology')
        except
        (select T.course_id
        from takes as T
        where T.ID = S.ID));
-- 可以改成下面那样
select S.ID, S.name
from student as S
where not exists (
        select C.course_id
        from course as C
        where C.dept_name = 'Biology' and
                C.course_id not in
                        (select T.course_id
                        from takes as T
                        where T.ID = S.ID)
              );

-- 3.8.4 重复元组存在性测试
-- 找出2009年最多开设一次的课程
-- FIXME：Mysql 似乎不支持unique关键字
select T.course_id
from course as T
where unique (
        select R.course_id
        from section as R
        where T.course_id = R.course_id and R.year = 2009
);
-- 可以写成这样子
select T.course_id
from course as T
where 1 >= (select count(R.course_id)
             from section as R
             where R.course_id = T.course_id and
                    R.year = 2009);

-- 3.8.5 from 子句中的字查询
-- 找出系平均工资超过42000的那些系中教师的平均工资
-- FIXME:Mysql from语句中的子查询必须加上as指出别名
select dept_name, avg_salary
from (
        select dept_name, avg(salary) as avg_salary
        from instructor
        group by dept_name
) as dept_avg
where avg_salary > 42000;

-- 找出所有系中工资总额最大的系
select max(tot_salary)
from (select dept_name, sum(salary)
       from instructor
       group by dept_name) as dept_total(dept_name, tot_salary);

-- 找出工资总额最大的系以及系名
-- TODO: 这种方法很麻烦，有没有一种简单点的(下面就有了）
select dept_name, tot_salary
from (
        select dept_name, sum(salary)
        from instructor
        group by dept_name
) as dept_total(dept_name, tot_salary)
where tot_salary = (select max(tot_salary)
                    from (select dept_name, sum(salary)
                          from instructor
                          group by dept_name
                         ) as dept_total2(dept_name, tot_salary)
                    );

-- lateral 打印每位教师的姓名，工资及所在系的平均工资
-- FIXME: 似乎不支持
select name, salary, avg_salary
from instructor I1, lateral (select  avg(salary) as avg_salary
                             from instructor I2
                             where I2.dept_name = I1.dept_name);

-- 3.8.6 with子句
with max_budget(value) as
(
select max(budget)
from department
)
select dept_name, budget
from department, max_budget
where department.budget = max_budget.value;

-- with子句使查询在逻辑上更加清晰
-- 查出所有工资总额大于所有系平均工资总额的系
with dept_total_salary(dept_name, value) as
  (
  select dept_name, sum(salary)
  from instructor
  group by dept_name
  ),
  dept_avg_salary(value) as
  (
  select avg(value)
  from dept_total_salary
  )
select dept_name, dept_total_salary.value
from dept_total_salary, dept_avg_salary
where dept_total_salary.value > dept_avg_salary.value;

-- 3.8.7
-- 列出所有的系以及它们拥有的教师数
select dept_name,(
      select count(*)
      from instructor
      where instructor.dept_name = department.dept_name)
      as num_instroctors
from department;

-- 3.9 数据库的修改 ////////////////////////////////////////////////////////////////
-- 3.9.1 删除
-- 注意删除的时候一定是以元组为单位删除的
delete from XX
where P;

-- 注意删除的时候，mysql会有一些限制
-- FIXME:以下语句会出现问题
-- https://stackoverflow.com/questions/4429319/you-cant-specify-target-table-for-update-in-from-clause
delete from instructor
where salary < (select avg(salary)
                from instructor);
-- 修改为这样子就可以了（会有额外的内存消耗，参考上面的网址）
delete from instructor
where salary < (select avg(salary)
                from (select * from instructor) as instructor2);

(select avg(salary)
                from (select * from instructor) as instructor2);

-- 3.9.2 插入
insert into instructor values ('76766', 'Crick', 'Biology', '72000');
insert into instructor values ('58583', 'Califieri', 'History', '62000');
insert into instructor values ('32343', 'El Said', 'History', '60000');
insert into instructor values ('15151', 'Mozart', 'Music', '40000');
insert into instructor values ('10101', 'Srinivasan', 'Comp. Sci.', '65000');

-- 允许在insert语句中指定属性

-- 在查询结果的基础上插入元组（注意在执行插入之前先执行完select语句是非常重要的）

-- 暂时有主码约束，就不会出事
-- Mysql的话，会先执行完select语句再执行插入，不会发生插入无限元组的情况
-- 每执行一次，该表复制一遍
insert into student
  select *
  from student;

-- 3.9.3 更新
-- FIXME:在修改自己的时候，不能够引用自己
update instructor
set salary = salary * 2
where salary < (select avg(salary) from instructor);

-- case结构
update instructor
set salary = case
    when salary > 90000 then 2
    else 0.5
  end;

-- 标量子查询在更新中的作用
-- 将每个student元组中的tot_cred属性值设为该生成功学完的课程学分的总和
update student S
set tot_cred = (
  select sum(credits)
  from takes natural join course
  where S.ID = takes.ID and
    takes.grade <> 'F' and
    takes.grade is not null
);
-- 改进版，没有学完任何课程的设为0
update student S
set tot_cred = (
  select case when sum(credits) is not null then sum(credits)
  else 0
  end
  from takes natural join course
  where S.ID = takes.ID and
    takes.grade <> 'F' and
    takes.grade is not null
);


