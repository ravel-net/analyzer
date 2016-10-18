# Pyretic Translation

### Overview

* Assume we can structure any Pyretic policy as a match >> action rule
* A Pyretic (match, action) can apply network-wide or locally to a specific switch
    * If no switch is specified for a drop rule, we can treat it as a global blacklist rule
    * If a drop rule applies to a specific switch, it is only a local policy rule
* Translate Pyretic (match, action) pairs into policy table
    * TODO: Network-wide and per-switch configuration tables
    * Eg: `pyretic_app_rm`, `pyretic_app_cf`


### Pyretic Action
A Pyretic action can be one (and only one) of:

* Drop
* Forward
* Flood

These can also be combined with:

* Rewrite, of a header field value

### Action: Drop
A drop rule in Pyretic maps to an entry in the view `pyr_APPNAME_drops`.  For example, consider the Pyretic app PYFW implemented as:

```python
(match(srcip="10.0.0.1") & match(dstip="10.0.0.2")) >> drop
```

This will translate to a row in the policy table `pyr_pyfw_policy` with the values:

**pyr_pyfw_policy**

| id  | srcip    | dstip    | drop |
|-----|----------|----------|------|
| 1   | 10.0.0.1 | 10.0.0.2 | true |

The drop view pyr_pyfw_drops will map these IP addresses to node IDs (hid's) and contain the row:

**pyr_pyfw_drops**

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

### Action: Rewrite
A rewrite in Pyretic maps to an entry in `pyr_APPNAME_srcip_rewrites` or `pyr_APPNAME_dstip_rewrites`.  For example, consider the Pyretic app NAT implemented as:

```python
match(srcip="10.0.0.1") >> rewrite(srcip="10.0.0.11")
```

This will translate to a row in the policy table `pyr_nat_policy` with the values:

**pyr_nat_policy**

| id  | srcip    | rewrite_srcip | rewrite |
|-----|----------|---------------|---------|
| 1   | 10.0.0.1 | 10.0.0.11     |  true   |

The srcip-specific rewrite view will contain the row:

**pyr_nat_srcip_rewrites**

| srcip    | rewrite_srcips |
|----------|----------------|
| 10.0.0.1 | 10.0.0.11      |

The srcip-rewrite violation view is constructed from this view:
```
CREATE VIEW pyr_nat_rewrite_srcip_violation AS (
   SELECT fid FROM rm_match
   WHERE srcip IN (SELECT srcip FROM pyr_nat_srcip_rewrites)
);
```
