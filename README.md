# plausible-on-kubernetes

Repo for self-hosting Plausible on a Kubernetes cluster

---

## To Do

- [x] Sort out secrets
- [x] Sort out database
- [x] Deploy main app into GKE
- [x] Secret generator so it restarts on config change
- [ ] Test email works
- [ ] Try without SMTP relay process
  - [ ] If not, deal with high privilege PSP
- [ ] Deal with latest tags
- [ ] Data backup
- [ ] MaxMind GeoIP
- [ ] Google Search integration
- [ ] Twitter integration
- [ ] Check X-Forwarded-For header bit
- [ ] Proxy the tracking JS - https://plausible.io/docs/proxy/introduction
- [ ] Outbound link tracking test - https://plausible.io/docs/outbound-link-click-tracking
- [ ] 404 tracking test - https://plausible.io/docs/404-error-pages-tracking
- [ ] Tests in CI
