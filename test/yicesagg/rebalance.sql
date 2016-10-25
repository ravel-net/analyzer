DROP TABLE IF EXISTS rm CASCADE;
CREATE UNLOGGED TABLE rm (
fid      integer,
src      integer,
dst      integer,
FW       integer,
LB       integer,
PRIMARY KEY (fid)
);
CREATE INDEX ON rm (fid,src,dst);


/* LB Members */
/* LB has a public ID for incoming requests 
   and several backend servers with different IDs 
   to process incoming requests
*/
DROP TABLE IF EXISTS LB_Members CASCADE;
CREATE UNLOGGED TABLE LB_Members (
       LBid         integer,
       publicID     integer,/*public address for client to visit*/
       serverID     integer /*backend server, generally many for one publicID*/       
PRIMARY KEY (serverID)
);
CREATE INDEX ON LB_Members(serverID);


CREATE OR REPLACE VIEW CIF AS (
       SELECT fid,src,dst
       FROM rm
       WHERE rm.dst IN (32,100033,100034,100035));


/*LB monitors its total loads from all members*/
CREATE OR REPLACE VIEW load1 AS (
       SELECT 32 AS publicid,count(dst) as loadsum
       FROM CIF
      /* WHERE rm.dst = LB_Members.serverID*/
       group by publicid 
);
/*having  count(dst)=10 
If the HAVING clause is present, 
it eliminates groups that do not satisfy the given condition.*/ 


/*LB finds total loads are more than threshold*/
/*this is a violation */
CREATE OR REPLACE VIEW overload AS (
       SELECT fid,src,dst,loadsum
       FROM rm,load
       WHERE loadsum=12 and rm.dst=publicID
);
/*If LB is overloaded, then rebalance(drop one of its processing flow) */
CREATE OR REPLACE RULE rebalance AS
       ON delete TO overload
       DO INSTEAD
            delete from rm 
                where fid in ( select fid from rm 
                                  where dst in (select serverID from LB_Members) 
                                  limit 1);

DROP TABLE IF EXISTS FW_blacklist CASCADE;
CREATE UNLOGGED TABLE FW_blacklist (
       end1           integer,
       end2           integer,
       allow          integer,             /*default:0*/
       PRIMARY key (end1, end2)
);
CREATE INDEX ON FW_blacklist (end1,end2);


CREATE OR REPLACE RULE FW_repair AS
       ON DELETE TO FW_violation
       DO INSTEAD
          DELETE FROM rm WHERE src=old.src and dst= old.dst;
/**
INSERT INTO rm  values (1,1,25,1,1);
INSERT INTO rm  values (2,2,100025,1,1);
INSERT INTO rm  values (3,3,100026,1,1);
INSERT INTO rm  values (4,4,100033,1,1);
INSERT INTO rm  values (5,5,100034,1,1);
INSERT INTO rm  values (6,6,100035,1,1);
INSERT INTO rm  values (7,1,100035,1,1);
INSERT INTO rm  values (8,2,100035,1,1);
INSERT INTO rm  values (9,3,100034,1,1);
INSERT INTO rm  values (10,4,100033,1,1);
INSERT INTO rm  values (11,1,100035,1,1);
INSERT INTO rm  values (12,2,100034,1,1);
INSERT INTO rm  values (13,3,100033,1,1);
INSERT INTO rm  values (14,2,100034,1,1);
INSERT INTO rm  values (15,27,32,1,1);
INSERT INTO rm  values (16,30,32,1,1);
