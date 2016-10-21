# Pyretic Translation v2

### Overview

* Think of each (predicate, action) as an operation
* For each operation predicate, create a violation view
* For each operation action, create a repair for the violation view
* At a high-level:
    * App
    * op1: P1 >> A1
    * op2: P2 >> A2
    * view app_op1_a1_violation
    * view app_op2_a2_violation
    * view app_violation:o app_op1_a1_violation union app_op2_a2_violation
    * rule app_repair: delete from app_op1_a1_violation, app_op2_a2_violation
    * action-specific repairs for app_op1_a1_violation, app_op2_a2_violation


### Action: Drop

* Violation view query: `SELECT fid FROM rm_match WHERE predicate`
* Repair operation: `DELETE FROM rm WHERE fid=OLD.fid`


* Example: (match(srcip="10.0.0.1") & match(dstip="10.0.0.2")) | (match(srcip="10.0.0.2") & match("10.0.0.1")) >> drop

```
CREATE OR REPLACE VIEW drop_violation AS (
    SELECT fid FROM rm_match
    WHERE (srcip = '10.0.0.1' AND dstip = '10.0.0.2') OR
          (srcip = '10.0.0.2' AND dstip = '10.0.0.1')
);

CREATE OR REPLACE RULE drop_repair AS
    ON DELETE TO drop_violation
    DO INSTEAD (
        DELETE FROM rm WHERE fid = OLD.fid;
    );
```

### Action: Rewrite

* Rewrite action `modify(h=v)`:
* Violation view query: `SELECT fid FROM rm_match WHERE predicate`
* Repair operation: `UPDATE rm SET end = (SELECT hid FROM hosts WHERE type=v) WHERE fid=OLD.fid`
    * type = type(h) = ip or mac
    * end = src or dst


* Example: match(srcip='10.0.0.1') >> modify(srcip='10.0.0.11')
    * h = srcip, v = 10.0.0.11
    * type = ip
    * end = src

```
CREATE OR REPLACE VIEW rewrite_violation AS (
    SELECT fid FROM rm_match
    WHERE (srcip = '10.0.0.1')
);

CREATE OR REPLACE RULE rewrite_repair AS
    ON DELETE TO rewrite_violation
    DO INSTEAD (
        UPDATE rm SET src = (SELECT hid FROM hosts WHERE ip = '10.0.0.11') WHERE fid=OLD.fid;
    );

```

### Combining Multiple Operations:

* Given multiple operations: predicate1 >> action1 || predicate2 >> action2
* Create one violation view for each operation


```
CREATE OR REPLACE VIEW app_op1_action_violation AS (
    SELECT fid FROM rm_match
    WHERE predicate1
);

CREATE OR REPLACE VIEW app_op2_action_violation AS (
    SELECT fid FROM rm_match
    WHERE predicate2
);

CREATE OR REPLACE VIEW app_violation AS (
    SELECT fid FROM app_op1_action_violation
        UNION
    SELECT fid FROM app_op2_action_violation
);
```


* Repair is action-specific:

```
CREATE OR REPLACE RULE app_repair AS
    ON DELETE TO app_violation
    DO INSTEAD (
        DELETE FROM app_op1_action_violation;
        DELETE FROM app_op2_action_violation;
    );

CREATE OR REPLACE RULE app_op1_action_repair AS
    ON DELETE TO app_op1_action_violation
    DO INSTEAD (
        -- action specific repair
    );

CREATE OR REPLACE RULE app_op2_action_repair AS
    ON DELETE TO app_op2_action_violation
    DO INSTEAD (
        -- action specific repair
    );
```
