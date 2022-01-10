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
- [ ] Data backup
- [ ] [Proxy the tracking JS](https://plausible.io/docs/proxy/introduction)
- [ ] Tests in CI
- [ ] HA

## Installation Notes

1. I opted to simplify the provided k8s config a little into a single secret with the required variables set it in. That's slightly sub-optimal from a least privilege perspective (means all three Pods can see all the secret values, even if they don't need all of them).
2. I set up some kustomization with a SecretGenerator so that whenever I change secret values, the system restarts to pick it up.
3. Found that the separate smtp server was not required when using Sendgrid - the app I assume picks up directly from there instead of going local to the cluster.
4. I switched out `latest` tags for pinned versions. This is good practice to get into imho - less surprises / more deterministic, versus needing to review and keep up to date yourself.
5. I needed to edit my `Type: LoadBalancer` `Service` to `spec.externalTrafficPolicy: Local`. This affects evenness of load balancing a little, but I think this will be tolerable.

---

## To Investigate

Multi-user setup - is this an option in the self-hosted? Compare it to the cloud version to see how that works.
