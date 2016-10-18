------------------------------------------------------------
-- POLICY TABLE
------------------------------------------------------------
DROP TABLE IF EXISTS pyr_nat_policy CASCADE;
CREATE UNLOGGED TABLE pyr_nat_policy (
    id       integer PRIMARY KEY,
    sid      integer,

    -- Matches
    dstip    varchar(16),
    srcip    varchar(16),
    dstmac   varchar(17),
    srcmac   varchar(17),
    inport   integer,
    dltype   integer,

    -- Rewrite
    rewrite        boolean,
    rewrite_srcip  varchar(16),
    rewrite_dstip  varchar(16),

    -- Actions
    drop boolean,
    fwd integer,
    xfwd integer
);



------------------------------------------------------------
-- PYRETIC POLICY <--> RAVEL OBJECT MAPPINGS
------------------------------------------------------------
-- Map rm to to header fields (ip, mac)
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

-- Map pyretic policy to node IDs
CREATE OR REPLACE VIEW pyr_nat_translation AS (
    SELECT p.id,
           src.hid AS src,
           dst.hid AS dst,
           rewrite,
           drop
    FROM pyr_nat_policy p
    LEFT JOIN hosts src
      ON src.ip = p.srcip
    LEFT JOIN hosts dst
      ON dst.ip = p.dstip
);



------------------------------------------------------------
-- POLICY ACTION-SPECIFIC VIEWS
------------------------------------------------------------
CREATE OR REPLACE VIEW pyr_nat_drops AS (
    SELECT src, dst
    FROM pyr_nat_translation
    WHERE drop = true
);

CREATE OR REPLACE VIEW pyr_nat_srcip_rewrites AS (
    SELECT srcip, rewrite_srcip
    FROM pyr_nat_policy
    WHERE rewrite = true AND rewrite_srcip != ''
);

CREATE OR REPLACE VIEW pyr_nat_dstip_rewrites AS (
    SELECT dstip, rewrite_dstip
    FROM pyr_nat_policy
    WHERE rewrite = true AND rewrite_dstip != ''
);



------------------------------------------------------------
-- VIOLATIONS
------------------------------------------------------------
CREATE OR REPLACE VIEW pyr_nat_drop_violation AS (
    SELECT fid
    FROM rm
    WHERE (src, dst) in (SELECT src, dst FROM pyr_nat_drops)
);

CREATE OR REPLACE VIEW pyr_nat_rewrite_srcip_violation AS (
    SELECT fid
    FROM rm_match
    WHERE srcip IN (SELECT srcip FROM pyr_nat_srcip_rewrites)
);

CREATE OR REPLACE VIEW pyr_nat_rewrite_dstip_violation AS (
    SELECT fid
    FROM rm_match
    WHERE dstip IN (SELECT dstip FROM pyr_nat_dstip_rewrites)
);

CREATE OR REPLACE VIEW pyr_nat_rewrite_violation AS (
    SELECT * FROM pyr_nat_rewrite_srcip_violation
        UNION
     SELECT * from pyr_nat_rewrite_dstip_violation
);

-- Application's violation view: union of each action violation
CREATE OR REPLACE VIEW pyr_nat_violation AS (
    SELECT fid FROM pyr_nat_drop_violation
        UNION
    SELECT fid FROM pyr_nat_rewrite_violation
);



------------------------------------------------------------
-- REPAIR
------------------------------------------------------------
CREATE OR REPLACE RULE pyr_nat_repair AS
   ON DELETE TO pyr_nat_violation
   DO INSTEAD (
       DELETE FROM pyr_nat_drop_violation WHERE fid = OLD.fid;
       DELETE FROM pyr_nat_rewrite_violation WHERE fid = OLD.fid;       
   );

-- Drop repair - remove the violating entry from rm
CREATE OR REPLACE RULE pyr_nat_drop_repair AS
    ON DELETE TO pyr_nat_drop_violation
    DO INSTEAD
        DELETE FROM rm WHERE fid = OLD.fid;



INSERT INTO pyr_nat_policy (id, srcip, rewrite, rewrite_srcip) VALUES (1, '10.0.0.1', true, '10.0.0.11');
INSERT INTO pyr_nat_policy (id, dstip, rewrite, rewrite_dstip) VALUES (2, '10.0.0.11', true, '10.0.0.1');
