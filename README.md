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
- [x] _[this](https://plausible.io/docs/google-search-console-integration) worked fine but takes a few days to kick in_ Google Search integration
- [ ] _waiting for_ Twitter integration
- [x] Data backup
- [x] _done for mw - works fine_ [Proxy the tracking JS](https://plausible.io/docs/proxy/introduction)
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

### Moving between Projects

> Still not properly codified - sorry!

The steps below allowed me to restore into a new GCP project within the same namespace - a more interesting test:

1. Manually grant the new velero Service Account access to the old bucket
2. Manually grant the new velero Service Account the custom role for handling compute snapshots in the old project
3. Create a second backupLocation which I named `old` (matters for the `jq` below) - see yaml below
4. Edited the `VolumeStorageLocation` to make it aware of the old project - `.spec.config.project=old-project`
5. Restore as usual:

```sh
velero client config set namespace=velero
# note storageLocation==old must match backuplocation above if not using shared bucket
BACKUP_NAME=$(velero backup get --output=json | jq -r '[ .items[] | select(.spec.storageLocation=="old") | select(.status.phase=="Completed") | {"name": .metadata.name, "startTimestamp": (.status.startTimestamp | fromdateiso8601)} ]| sort_by(.startTimestamp)[-1].name')

# ... depending on state of previous deployment, may need to delete old PVs
velero restore create --from-backup "${BACKUP_NAME}" --include-resources persistentvolumeclaims,persistentvolumes --include-namespaces=plausible --restore-volumes=true
```

Additional backup location:

```yaml
---
apiVersion: velero.io/v1
kind: BackupStorageLocation
metadata:
  name: old
  namespace: velero
spec:
  provider: velero.io/gcp
  objectStorage:
    bucket: ${OLD_BACKUP_BUCKET}
```

## Proxying the Request

I followed the guidance [here](https://plausible.io/docs/proxy/guides/nginx) in the Plausible docs for this for NGINX, and it worked well for the site I tested it with. You can see the NGINX modifications I used in [this file](https://gitlab.com/alexos-dev/moss-work/-/blob/master/config/default.conf).

Stripping this down, it amounted to more or less what the docs said:

```sh
# my cache path was different
proxy_cache_path /var/cache/nginx/data/jscache levels=1:2 keys_zone=jscache:100m inactive=30d  use_temp_path=off max_size=100m;

server {

  # proxy to plausible script - my self-hosted copy
  location = /js/visits.js {
      proxy_pass https://plausible.alexos.dev/js/plausible.outbound-links.js;
      proxy_buffering on;

      # Cache the script for 6 hours, as long as plausible returns a valid response
      proxy_cache jscache;
      proxy_cache_valid 200 6h;
      proxy_cache_use_stale updating error timeout invalid_header http_500;
      add_header X-Cache $upstream_cache_status;

      proxy_set_header Host plausible.alexos.dev;
      proxy_ssl_name plausible.alexos.dev;
      proxy_ssl_server_name on;
      proxy_ssl_session_reuse off;
  }

  # proxy to plausible API - my self-hosted copy
  location = /api/event {
      proxy_pass https://plausible.alexos.dev/api/event;
      proxy_buffering on;
      proxy_http_version 1.1;
      
      proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;
      proxy_set_header X-Forwarded-Host  $host;

      proxy_set_header Host plausible.alexos.dev;
      proxy_ssl_name plausible.alexos.dev;
      proxy_ssl_server_name on;
      proxy_ssl_session_reuse off;
  }

}
```
