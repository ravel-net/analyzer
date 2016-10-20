# Pyretic Translation v2

### Overview

* Think of each (predicate, action) as a an operation

### Action: Drop

* Violation view query: `SELECT fid FROM rm_match WHERE predicate`
* Repair operation: `DELETE FROM rm WHERE fid=OLD.fid`

### Action: Rewrite

* Rewrite action `modify(h=v)`:
* Violation view query: `SELECT fid FROM rm_match WHERE predicate`
* Repair operation: `UPDATE rm SET h=v WHERE fid=OLD.fid`

### Multiple Actions:

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