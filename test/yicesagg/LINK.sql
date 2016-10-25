DROP TABLE IF EXISTS link CASCADE;
CREATE UNLOGGED TABLE link (
S      integer,
D      integer,
C      integer,
type   integer
);
CREATE INDEX ON link (s,d);

CREATE OR REPLACE VIEW hop AS (
       SELECT r1.S, r2.D,r1.c+r2.c as C,r1.type 
       FROM link r1, link r2
       WHERE r1.d=r2.s);

CREATE OR REPLACE VIEW min_hop AS (
       SELECT S,D,min(C) AS M
       FROM HOP
       GROUP BY S,D 
);
CREATE OR REPLACE VIEW min_hop AS (
       SELECT S,D,min(C) AS M
       FROM min_hop
       GROUP BY S,D 
);

modify sth unrelated to gb variables
update link set type=1 where s=1 and d=7;
modify sth unrelated to view condition
(not only its own condition but also condition of its base view)
update link set c=1 where s=10 and d=11;
modify sth unrelated to agg()
update link set c=10 where s=1 and d=2;    

insert into link values(4,3,3,1);   
insert into link values(6,2,5,1),(2,4,8,0),(4,3,2,1),(5,7,2,1);
insert into link values(1,2,5,1),(2,3,2,0),(1,7,2,0),(7,3,2,0),(5,2,6,1),(5,4,2,0),(6,5,9,1);





    CREATE OR REPLACE VIEW tri_hop AS (
       SELECT min_hop.s,link.d,(min_hop.m+link.c) as C
       FROM link,min_hop
       WHERE min_hop.d=link.s);

CREATE OR REPLACE VIEW min_tri_hop AS (
       SELECT S,D,min(C) AS M
       FROM tri_hop
       GROUP BY S,D);