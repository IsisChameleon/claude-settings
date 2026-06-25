---
name: toocan-app-k8s-apps-relationship
description: How toocan-app (app source) and k8s-apps (GitOps deploy repo) are coupled — by container image name+tag, not code edges
metadata:
  type: project
---

`toocan-app` and `k8s-apps` (github.com/quarterzip/k8s-apps) are an app-repo ↔ deploy-repo pair.

- **toocan-app** = application source: SvelteKit `client/` + Python FastAPI `server/`. Its `client/Dockerfile` and `server/Dockerfile` build the `toocan/client` and `toocan/server` images.
- **k8s-apps** = GitOps / infra-as-code: Kustomize manifests + ArgoCD/Argo Rollouts. Top-level dirs are deployable apps (`toocan/`, `redactive/`, `librechat/`, `opensearch/`, `scrapy-boy/`, `twilio-agent/`, `mcp-servers/`), each with `base/` + `overlays/{staging,production}`. `cli/` is the `qz` deploy/monitor CLI; `tests/playwright/` are E2E smoke tests.

**The coupling is image name + tag, not a code-level call edge.** toocan-app produces `australia-southeast1-docker.pkg.dev/redactive-registry/container-images/toocan/{server,client}:vX`; k8s-apps consumes that exact coordinate:
- Rollouts: `toocan/base/res/{server,call-server,client}.rollout.yaml` reference those images.
- `qz deploy` (`cli/lib/k8s.py:38,244-246`) runs `kustomize edit set image .../toocan/{client,server}=*:{next_tag}`. The `v1.1.xx` commits on the `staging` branch are those tag bumps.

Deploy flow (k8s-apps README): `qz deploy` → ArgoCD PreSync job runs Firebase sync + DB migrations (toocan-app's `server/src/scripts/run_migrations.py`, `sync_firebase_project.py`) → Sync applies remaining manifests. Runtime routes: `api.quarterzip.ai`, `app.quarterzip.ai`, `call.quarterzip.ai` → toocan-app server + client.

Because the link is image-tag (not HTTP), the codebase-memory `cross-repo-intelligence` index mode (which matches routes/channels) won't surface it.
