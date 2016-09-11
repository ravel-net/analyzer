DROP TABLE IF EXISTS rm CASCADE;
CREATE UNLOGGED TABLE rm (
fid      integer,
src      integer,
dst      integer,
FW       integer,
NAT      integer,
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
       FROM rm,
       WHERE FW = 1 AND (src, dst) IN (SELECT end1, end2 FROM FW_blacklist)
);

/* If flow is in the blacklist, drop it */
CREATE OR REPLACE RULE FW_repair AS
       ON DELETE TO FW_violation
       DO INSTEAD
          DELETE FROM rm WHERE src=old.src and dst= old.dst;

/* NAT Members */
DROP TABLE IF EXISTS NAT_Members CASCADE;
CREATE UNLOGGED TABLE NAT_Members (
       NATid         integer,/*service_id in Jason's output*/
       serviceID     integer,/*hostname in Jason's output*/
       hostIP        integer /*host_ip in Jason's output*/       
);
CREATE INDEX ON NAT_Members(NATid,SERVICEid);


CREATE OR REPLACE VIEW traffic_in AS (
       SELECT fid,src,dst,fw,nat,hostIP
       FROM rm, NAT_Members
       WHERE NAT = 1 AND dst=serviceID 
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
INSERT INTO rm (fid,src,dst,fw,nat) values (1,20,32,1,1);
INSERT INTO rm (fid,src,dst,fw,nat) values (2,24,23,1,1);
INSERT INTO rm (fid,src,dst,fw,nat) values (3,22,27,1,1);
INSERT INTO rm (fid,src,dst,fw,nat) values (4,100033,20,1,1);
INSERT INTO rm (fid,src,dst,fw,nat) values (5,100024,24,1,1);
INSERT INTO rm (fid,src,dst,fw,nat) values (6,100028,22,1,1);
insert into FW_blacklist (end1,end2,allow) values(27,22,0);
insert into FW_blacklist (end1,end2,allow) values(20,32,0); 
INSERT INTO  NAT_Members(NATid,SERVICEid,hostIP) values (0,32,100033);
INSERT INTO  NAT_Members(NATid,SERVICEid,hostIP) values (0,23,100024);
INSERT INTO  NAT_Members(NATid,SERVICEid,hostIP) values (0,27,100028);
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

