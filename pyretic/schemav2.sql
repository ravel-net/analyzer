CREATE OR REPLACE VIEW rm_match AS (
SELECT rm.fid,
       src.ip AS srcip,
       src.mac AS srcmac,
       dst.ip AS dstip,
       dst.mac AS dstmac
  FROM rm
  LEFT JOIN hosts dst
    ON dst.hid = rm.dst
  LEFT JOIN hosts src
    ON src.hid = rm.src
);


/*
FW policy:

Block flows (10.0.0.1, 10.0.0.2), (10.0.0.3, 10.0.0.4)

(match(srcip='10.0.0.1') & match(dstip='10.0.0.2')) |
(match(srcip='10.0.0.2') & match(dstip='10.0.0.1')) |
(match(srcip='10.0.0.3') & match(dstip='10.0.0.4')) |
(match(srcip='10.0.0.4') & match(dstip='10.0.0.3')) >> drop

One operation: (P|P|P|P) >> drop
*/

CREATE OR REPLACE VIEW fw_drop_violation AS (
    SELECT fid FROM rm_match
    WHERE (srcip = '10.0.0.1' AND dstip = '10.0.0.2') OR
          (srcip = '10.0.0.2' AND dstip = '10.0.0.1') OR
          (srcip = '10.0.0.3' AND dstip = '10.0.0.4') OR
          (srcip = '10.0.0.4' AND dstip = '10.0.0.3')
);

CREATE OR REPLACE VIEW fw_violation AS (
    SELECT fid FROM fw_drop_violation
);

CREATE OR REPLACE RULE fw_repair AS
   ON DELETE TO fw_violation
   DO INSTEAD (
        DELETE FROM fw_drop_violation WHERE fid = OLD.fid;
   );

CREATE OR REPLACE RULE fw_drop_repair AS
    ON DELETE TO fw_drop_violation
    DO INSTEAD (
        DELETE FROM rm WHERE fid = OLD.fid;
    );


/*
NAT policy:

Rewrite private IP 10.0.0.11 => 10.0.0.1

match(srcip='10.0.0.1') >> modify(srcip='10.0.0.11') ||
match(dstip='10.0.0.11') >> modify(dstip='10.0.0.1')

Two operations: P >> modify, P >> modify
*/

CREATE OR REPLACE VIEW nat_op1_rewrite_violation AS (
    SELECT fid FROM rm_match
    WHERE (srcip = '10.0.0.1')
);

CREATE OR REPLACE VIEW nat_op2_rewrite_violation AS (
    SELECT fid FROM rm_match
    WHERE (dstip = '10.0.0.11')
);

CREATE OR REPLACE VIEW nat_violation AS (
    SELECT fid FROM nat_op1_rewrite_violation
        UNION
    SELECT fid FROM nat_op2_rewrite_violation
);

CREATE OR REPLACE RULE nat_repair AS
    ON DELETE TO nat_violation
    DO INSTEAD (
        DELETE FROM nat_op1_rewrite_violation;
        DELETE FROM nat_op2_rewrite_violation;
    );

CREATE OR REPLACE RULE nat_op1_rewrite_repair AS
    ON DELETE TO nat_op1_rewrite_violation
    DO INSTEAD (
        UPDATE rm SET src = (SELECT hid FROM hosts WHERE ip = '10.0.0.11') WHERE fid=OLD.fid;
    );

CREATE OR REPLACE RULE nat_op2_rewrite_repair AS
    ON DELETE TO nat_op2_rewrite_violation
    DO INSTEAD (
        UPDATE rm SET dst = (SELECT hid FROM hosts WHERE ip = '10.0.0.1') WHERE fid=OLD.fid;
    );
