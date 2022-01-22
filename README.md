# plausible-on-kubernetes

Repo for self-hosting Plausible on a Kubernetes cluster

---

## To Do

- [x] Sort out secrets
- [x] Sort out database
- [x] Deploy main app into GKE
- [x] Secret generator so it restarts on config change
- [x] Test email works
- [x] Try without SMTP relay process
- [x] Deal with latest tags
- [-] _skipped: seems to work fine with the DB-IP option_ MaxMind GeoIP
- [x] _edit on ingress service needed_ Check X-Forwarded-For header bit
- [x] [Outbound link tracking test](https://plausible.io/docs/outbound-link-click-tracking)
- [x] [404 tracking test](https://plausible.io/docs/404-error-pages-tracking)
- [ ] _waiting for_ Google Search integration
- [ ] _waiting for_ Twitter integration
- [x] Data backup
- [ ] _done for mw - works fine_ [Proxy the tracking JS](https://plausible.io/docs/proxy/introduction)
- [x] Tests in CI
- [x] _only frontend_ HA

## Installation Notes

1. I opted to simplify the provided k8s config a little into a single secret with the required variables set it in. That's slightly sub-optimal from a least privilege perspective (means all three Pods can see all the secret values, even if they don't need all of them).
2. I set up some kustomization with a SecretGenerator so that whenever I change secret values, the system restarts to pick it up.
3. Found that the separate smtp server was not required when using Sendgrid - the app I assume picks up directly from there instead of going local to the cluster.
4. I switched out `latest` tags for pinned versions. This is good practice to get into imho - less surprises / more deterministic, versus needing to review and keep up to date yourself.
5. I needed to edit my `Type: LoadBalancer` `Service` to `spec.externalTrafficPolicy: Local`. This affects evenness of load balancing a little, but I think this will be tolerable.
6. The choice of Clickhouse database used by Plausible means you can't use the standard backup tool used by Clickhouse. I am experimenting with a Velero snapshot of the PV instead.

## Backup / Restore

**Note:** This is not codified here - Velero requires high privilege to install, which this repo does not have.

Whilst backing up the Postgres database is possible with a range of options, the Clickhouse DB is a little more unusual and the type of tables used precent some of their tools being used. [This github discussion](https://github.com/plausible/analytics/discussions/1226)  provides some good background.

I solved this for my needs using [Velero](https://velero.io/) and its ability to backup PVs and PVCs, with its backups saved to a GCS bucket. I've tested this (only ...) once (at time of writing ...) by restoring into another namespace as follows:

```bash
kubectl create ns plausible-test
velero restore create --from-backup $BACKUP_NAME --include-resources persistentvolumeclaims,persistentvolumes --include-namespaces=plausible --namespace-mappings plausible:plausible-test --restore-volumes=true
# and then running deploy.sh against the plausible-test namespace instead
```

Workload came up without issue, with data up to the point of last backup. Obviously in a real recovery scenario this would be run against the original namespace name but in a new Kubernetes cluster.

There are caveats with this approach - I don't that much about the frequency of backup and risk of data loss (it's far from point-in-time recovery!). There are also risks associated with snapshotting the disk of a running database - if it's in the middle of a write for example.

Keeping a few backups is recommended, as well as alerting on failures in those backups, and of course testing it frequently. I've got reminders in place for every 3 months.
