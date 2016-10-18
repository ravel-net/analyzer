## Pyretic Translation

#### Overview

* Assume we can structure any Pyretic policy as a match >> action rule
* A Pyretic (match, action) can apply network-wide or locally to a specific switch
    * If no switch is specified for a drop rule, we can treat it as a global blacklist rule
    * If a drop rule applies to a specific switch, it is only a local policy rule
* Translate Pyretic (match, action) pairs into policy table
    * TODO: Network-wide and per-switch configuration tables
    * Eg: pyretic_app_rm, pyretic_app_cf


#### Pyretic Action
A Pyretic action can be one of:

* Drop
* Forward
* Flood

These can also be combined with:

* Rewrite, of a header field value

#### Action: Drop
A drop rule in Pyretic maps to an entry in the view pyr_APPNAME_drops.  For example, for the firewall app PYFW, the policy table pyr_pyfw_policy will contain the row:

| id  | srcip    | dstip    | drop |
|-----|----------|----------|------|
| 1   | 10.0.0.1 | 10.0.0.2 | true |

And the drop view pyr_pyfw_drops will contain:

| src | dst |
|-----|-----|
| 1   | 2   |

Where host IDs 1 and 2 correspond to IPs 10.0.0.1 and 10.0.0.0.2, respectively.

The violation view is constructed from this view:

```
CREATE VIEW pyr_pyfw_drop_violation AS (
   SELECT fid FROM rm
   WHERE (src, dst) IN (SELECT src, dst FROM pyr_pyfw_drops)
);
```