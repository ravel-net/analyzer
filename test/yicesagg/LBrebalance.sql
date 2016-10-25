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

/* Flow blacklist */
DROP TABLE IF EXISTS FW_blacklist CASCADE;
CREATE UNLOGGED TABLE FW_blacklist (
       end1           integer,
       end2           integer,
       allow          integer,             /*default:0*/
       PRIMARY key (end1, end2)
);
CREATE INDEX ON FW_blacklist (end1,end2);


CREATE OR REPLACE VIEW FW_violation AS (
       SELECT fid,src,dst
       FROM rm
       WHERE (src, dst) IN (SELECT end1, end2 FROM FW_blacklist)
);

/* If flow is in the blacklist, drop it */
CREATE OR REPLACE RULE FW_repair AS
       ON DELETE TO FW_violation
       DO INSTEAD
          DELETE FROM rm WHERE src=old.src and dst= old.dst;

/* NAT Members */
DROP TABLE IF EXISTS LB_Members CASCADE;
CREATE UNLOGGED TABLE LB_Members (
       LBid         integer,
       publicID     integer,/*public address for client to visit*/
       serverID     integer /*backend server, generally many for one publicID*/       
);
CREATE INDEX ON LB_Members(LBid,publicID);


CREATE OR REPLACE VIEW traffic_in AS (
       SELECT fid,src,dst,fw,nat,hostIP
       FROM rm, NAT_Members
       WHERE NAT = 1 AND dst=serviceID 
);
/*LB sees its total loads are overloaded, then drop a random flow*/
CREATE OR REPLACE VIEW overload AS (
       SELECT publicID,count(dst)
       FROM rm,LB_Members
       WHERE count(dst)>5
       group by publicID
);



/*if NAT see an incoming traffic, translate its serviceID into a hostIP*/

CREATE OR REPLACE RULE in_translation AS
       ON DELETE TO traffic_in
       DO INSTEAD
            /*DELETE FROM rm WHERE fid = old.fid;
            INSERT INTO rm (fid,src,dst,fw,nat) values(OLD.fid,OLD.src,OLD.hostIP,OLd.fw,OLD.nat);*/
            UPDATE rm
            SET dst=old.hostIP
            where fid=old.fid;

         -- 

CREATE OR REPLACE VIEW traffic_out AS (
       SELECT fid,src,dst,fw,nat,serviceID
       FROM rm, NAT_Members
       WHERE NAT = 1 AND src =hostIP
);

/*if NAT see a returning traffic, translate its hostIP into a serviceID*/
CREATE OR REPLACE RULE out_translation AS
       ON delete TO traffic_out
       DO INSTEAD
            /*DELETE FROM rm WHERE fid = new.fid;
            INSERT INTO rm (fid,src,dst,fw,nat) values(OLD.fid,OLD.serviceID,OLD.dst,OLd.fw,OLD.nat);*/
            UPDATE rm
            SET src=old.serviceID
            where fid=old.fid;



/*testing
INSERT INTO rm  values (1,1,100025,1,1);
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

INSERT INTO rm  values (14,4,100030,1,1);
INSERT INTO rm  values (15,4,100030,1,1);
INSERT INTO rm  values (16,1,100030,1,1);
INSERT INTO rm  values (17,2,100028,1,1);
INSERT INTO rm  values (18,3,100029,1,1);
INSERT INTO rm  values (19,4,100028,1,1);
INSERT INTO rm  values (20,4,100024,1,1);

insert into FW_blacklist (end1,end2,allow) values(27,32,0);
insert into FW_blacklist (end1,end2,allow) values(20,31,0); 
INSERT INTO  lb_Members values (0,32,100033),(0,32,100034),(0,32,100035);
INSERT INTO  lb_Members values (1,23,100024),(1,23,100025),(1,23,100026);
INSERT INTO  lb_Members values (2,27,100028),(2,27,100029),(2,27,100030);
select * from rm;
select * from fw_blacklist;
select * from NAT_Members;
select * from fw_violation;
select * from traffic_in;
delete from fw_violation;
select * from rm;
select * from traffic_in;
select * from traffic_out;
select * from fw_violation;
delete from traffic_out;
select * from rm;
select * from fw_violation;
*/   