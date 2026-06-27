# Enterprise RAG Evolution Roadmap

**Project:** AI FORGE — Enterprise AI Agent Operating System  
**Author:** Vikash Jaiswal  
**Status:** Phase 1 Complete · Phases 2–7 Planned  
**Last Updated:** 2026-06

---

## Executive Summary

AI FORGE already implements Retrieval-Augmented Generation. Not in the enterprise vector-database sense, but in the foundational sense that RAG actually means: retrieving relevant external knowledge and injecting it into the model's context to ground responses in private, domain-specific data. The current implementation is functional, deterministic, and production-proven. This document maps the evolution from today's file-based primitive RAG toward a semantic enterprise knowledge fabric — identifying what exists, why each phase matters, and which technology choices are justified.

The forge-router AI Gateway is ready for integration and becomes the routing backbone in Phase 5 onward.

---

## Current State Audit: What RAG Exists Today

Before planning an evolution, it is worth documenting what already works. AI FORGE implements three distinct RAG mechanisms today.

### Mechanism 1 — Skill-Based Knowledge Retrieval

| RAG Component | AI FORGE Implementation |
|---|---|
| Knowledge Store | `claude-skills/` — 11 SKILL.md files totaling ~22,000 tokens |
| Retrieval Trigger | Slash command invocation (`/devo-query`, `/devo-infra`, etc.) |
| Retrieval Unit | Entire SKILL.md document |
| Context Injection | SKILL.md content loaded into active Claude Code context |
| Index | `claude-skills.json` — registration metadata per skill |

When an engineer invokes `/devo-query`, 97 Maqui LINQ function signatures, 7 regional aliases, 75+ query patterns, and mandatory safety filters are injected into the agent's context. The agent does not guess. It retrieves.

### Mechanism 2 — Memory-Based Behavioral Retrieval

| RAG Component | AI FORGE Implementation |
|---|---|
| Knowledge Store | `memory/` directory — typed Markdown files |
| Index | `MEMORY.md` — pointer index auto-loaded every session |
| Retrieval Trigger | Session start (index) + reference matching (individual files) |
| Retrieval Unit | Specific memory file (feedback, project, reference, user) |
| Context Injection | Memory content augments every agent response |

The memory system implements Long-Term Memory RAG. Behavioral corrections, incident context, and architectural references accumulate across sessions. New engineers inherit an agent that already knows the platform. This is not a simulation of RAG — it is the pattern, implemented in files.

### Mechanism 3 — Operational Context Injection (CLAUDE.md)

The Global Brain (`CLAUDE.md`) performs what is called Operational RAG: injecting structured, private operational knowledge into every session automatically. Regional aliases, timezone conversion rules, mandatory safety filters, wrapper protocols — none of this exists in Claude's training data. It is retrieved from a file and injected every session.

### Classification

> **Current State: Primitive RAG**  
> Deterministic. Trigger-based. File-level retrieval unit. No semantic understanding. No vector similarity. Fully functional for known domains, brittle for cross-domain or partial-match queries.

**Token cost baseline:**  
CLAUDE.md: ~1,200 tokens | MEMORY.md index: ~200 tokens | One full skill: ~2,000 tokens | Three skills active: ~7,400 tokens total session baseline.

---

## The Limitation That Drives Evolution

The retrieval unit is the entire document. Loading `/devo-query` loads 2,000 tokens whether the engineer needs one function signature or all 97. There is no way to retrieve only the 3 most relevant Maqui patterns for a specific table type. There is no way to query across skills — asking "what are all the mandatory safety filters across all skills" requires loading every SKILL.md.

This is the ceiling of file-based primitive RAG. The phases below remove that ceiling.

---

## Phase 1 — Current State (Complete)

**Architecture:** File-based memory + modular skills + operational context injection  
**Infrastructure:** Zero additional dependencies beyond Claude Code  
**Retrieval precision:** High for on-skill queries, low for cross-domain synthesis  

This phase is done. Document it, do not redesign it.

---

## Phase 2 — Compact Skill Headers (Zero Infrastructure)

**Goal:** 40–60% token reduction with no new tooling.  
**Status:** Planned. Implementation: one afternoon.

Add a `SKILL-COMPACT.md` to each skill directory — a 200-token summary designed for quick agent orientation. The compact header answers: what domain does this skill cover, what are the 3 most important patterns, when should the full skill be loaded, and which adjacent skills compose with this one.

**Example — devo-query compact header:**

```
SKILL: devo-query
DOMAIN: Maqui LINQ query engine — log investigation, customer data analysis
REGIONS: EU(maquieu) US(maquius) US3(maquius3) APAC(maquiapac) SANT(maquisant) GCP(maquigcp) NCSC(maquincsc)
SAFETY: siem.logtrust.* → where client='self' | syslog.alcohol.stats → where client='self'
PATTERNS: Start at now()-5m, expand if needed | 60s timeout on large tables
COMPOSE: /devo-tools for Asilo status | /devo-database for affinity lookups
LOAD_FULL: When writing complex LINQ | 97 function signatures | table-specific schemas
```

Loading all 11 compact headers: ~2,200 tokens  
Loading all 11 full SKILL.md files: ~22,000 tokens  
Token reduction: **90% for exploration, 60% for typical single-skill workflows**

The agent loads compact headers by default. It loads full SKILL.md only when deep domain knowledge is explicitly needed.

---

## Phase 3 — Embedded Semantic Search (ChromaDB)

**Goal:** Chunk-level retrieval — get 3–5 relevant 200-token sections instead of one 2,000-token document.  
**Infrastructure:** ChromaDB — Python library, embedded, no server required.  
**Status:** Planned.

### Why ChromaDB first

ChromaDB runs embedded inside the same Python process. There is no Docker container, no network dependency, no infrastructure provisioning. For the prototype phase, this is the right tool: install once, index once, retrieve constantly.

### Chunking Strategy

Do not chunk by line count. Chunk by semantic boundary:

- One command pattern with its safety filter = one chunk
- One function signature with its parameters = one chunk  
- One cross-reference block = one chunk
- One safety rule with rationale = one chunk

Each chunk is tagged with structured metadata:

```python
{
  "skill": "devo-query",
  "region": "EU",
  "command_type": "logtrust_query",
  "table_pattern": "siem.logtrust.flow.out",
  "safety_required": True,
  "chunk_index": 14,
  "tokens": 187
}
```

Metadata filtering means retrieval can scope to: only EU chunks, only safety-relevant chunks, only chunks for a specific table pattern.

### Token Impact

| Retrieval Mode | Tokens Loaded |
|---|---|
| Current: full SKILL.md | ~2,000 per skill |
| Phase 3: top-5 chunks | ~1,000 (5 × 200) |
| Phase 3: top-3 chunks | ~600 (3 × 200) |
| Session baseline (Phase 1) | ~3,200 |
| Session baseline (Phase 3) | ~600 |

**83% token reduction** with equivalent or superior precision for known-domain queries.

---

## Phase 4 — Production Vector Search (Qdrant)

**Goal:** Production-grade hybrid search on existing EKS infrastructure.  
**Infrastructure:** Qdrant deployed on EKS management cluster (`eu-west-1`).  
**Status:** Planned.

### Why Qdrant over alternatives

| Vector DB | Why Considered | Why Not Selected |
|---|---|---|
| ChromaDB | Embedded, zero infra | Limited scalability, no native hybrid search |
| Weaviate | Rich query language | Complex operator model for this use case |
| Pinecone | Managed SaaS | SaaS dependency, data leaves on-premise boundary |
| pgvector | Uses existing PostgreSQL | No native hybrid search, performance ceiling |
| OpenSearch | Already deployed | Vector performance overhead, operational cost |
| **Qdrant** | **Rust performance, hybrid BM25+dense, self-hosted** | **Selected** |

Qdrant is selected because:

1. **Hybrid search is native** — BM25 keyword + dense vector in one query, no custom fusion layer
2. **Self-hostable on EKS** — deploys as a Kubernetes Deployment + PVC, no SaaS dependency
3. **Rust implementation** — sub-millisecond p99 latency for the corpus size involved
4. **Python client** — `qdrant-client` integrates cleanly with the existing skill loading logic
5. **Payload filtering** — structured metadata filtering on skill, region, table_pattern during retrieval

### Corpus Expansion

Phase 4 is not limited to SKILL.md files. The same indexing pipeline can ingest:

- Confluence runbook pages (export via Confluence API)
- Jira resolution summaries for recurring incident patterns
- Architecture decision records from GitLab
- Post-incident review documents

This transforms AI FORGE from a skills-retrieval system into a searchable institutional knowledge base.

### Why Hybrid Search Matters for Platform Engineering

Platform engineering queries do not fit neatly into either semantic or keyword categories:

- "Why is the metamalote overloaded" — semantic (no exact keyword match in docs)
- "QDRANT-1234 error code on Vault renewal" — keyword (exact error code required)
- "What's the precedent for this kind of ingestion lag" — both

BM25 handles the keyword cases. Dense vectors handle the semantic cases. Qdrant's hybrid mode runs both and fuses scores. Engineers do not need to know which retrieval mode is appropriate — the system handles it.

---

## Phase 5 — Cross-Encoder Reranking

**Goal:** Precision improvement for complex, multi-part queries.  
**Infrastructure:** A cross-encoder model (small, CPU-hostable).  
**Status:** Planned — depends on Phase 4.

Initial retrieval (BM25 + dense) returns 20–40 candidate chunks based on individual similarity scores. Reranking reads each candidate chunk together with the full query in context, producing a joint relevance score. This is fundamentally more accurate than embedding similarity for nuanced queries.

A cross-encoder reads "why is the metamalote overloaded and what did we do the last time this happened in EU" alongside each candidate chunk and scores how directly the chunk answers that specific question. Embedding similarity cannot do this — it measures how the chunk sounds like the query, not whether it answers it.

For routine queries, reranking adds marginal latency with marginal benefit. For incident triage queries, it materially improves the first 3 results returned to the agent.

Recommended starting model: `cross-encoder/ms-marco-MiniLM-L-6-v2` — 22MB, CPU-deployable, benchmarked well on technical Q&A.

---

## Phase 6 — AI Gateway Integration (forge-router)

**Goal:** Route RAG-augmented prompts through forge-router's provider chain for cost, availability, and sensitivity optimization.  
**Status:** forge-router is production-ready. Integration is an implementation task, not a design task.

The integration point is clean. After Phase 3 or 4 assembles the augmented prompt (retrieved context + memory context + user query), that prompt is handed to `forge-router`'s `RouterEngine.route()` instead of directly to AWS Bedrock.

forge-router then:

1. Checks health of all 8 providers
2. Routes to the highest-priority healthy provider
3. Falls back automatically on failure or rate limit

**Query-type routing (with forge-router's preferred provider mechanism):**

| Query Type | Preferred Provider | Rationale |
|---|---|---|
| Status check, simple lookup | Groq (LLaMA 3.3 70B) | Sub-second, near-zero cost |
| Incident analysis, complex reasoning | Claude Sonnet | Maximum accuracy |
| Queries with internal customer identifiers | Ollama (local) | Data stays on-premise |
| Bedrock regional outage | Direct Anthropic API | Automatic fallback |

See [AI_GATEWAY_INTEGRATION.md](AI_GATEWAY_INTEGRATION.md) for the full integration specification.

---

## Phase 7 — Observability and Continuous Improvement

**Goal:** Instrument the retrieval pipeline for measurement, feedback, and systematic improvement.  
**Status:** Architecture defined. Implementation follows Phase 6.

### What to Instrument

Every retrieval event should emit a structured log record:

```
{
  "session_id": "...",
  "query_text": "...",
  "skill_triggered": "devo-query",
  "chunks_retrieved": [{"chunk_id": "...", "score": 0.87, "tokens": 187}],
  "provider_used": "claude",
  "provider_latency_ms": 1240,
  "total_tokens": 2847,
  "retrieval_latency_ms": 43,
  "engineer_feedback": null
}
```

### Observability Stack

| Layer | Tool | Integration |
|---|---|---|
| LLM traces | Langfuse | Open-source, self-hostable, trace per query |
| Pipeline metrics | OpenTelemetry | Standard spans for retrieval, reranking, routing |
| Operational dashboards | Grafana | Integrates with existing Prometheus infrastructure |
| Quality evaluation | LLM-as-a-Judge | Claude evaluates retrieval quality on sampled queries |

### Continuous Improvement Loop

1. Langfuse collects traces for every query
2. Weekly: LLM-as-a-Judge scores retrieval quality on 50 sampled queries
3. Low-scoring queries identify chunk boundary problems or missing metadata
4. Chunks are re-split or re-tagged
5. Re-indexing runs against Qdrant
6. Quality metrics compared pre/post improvement

This produces a knowledge base that improves with use rather than degrading as the platform evolves.

---

## Phase Summary Table

| Phase | Capability | Infrastructure | Token Impact | Status |
|---|---|---|---|---|
| 1 | File-based primitive RAG | None | Baseline (~3,200/session) | **Complete** |
| 2 | Compact skill headers | Text files only | -60% typical | Planned |
| 3 | ChromaDB chunk retrieval | Python library | -83% baseline | Planned |
| 4 | Qdrant hybrid search + corpus expansion | EKS deployment | Sub-millisecond retrieval | Planned |
| 5 | Cross-encoder reranking | CPU model | Improved precision | Planned |
| 6 | forge-router AI Gateway integration | Already built | Multi-model, cost routing | Ready |
| 7 | Observability + continuous improvement | Langfuse + OTel | Systematic quality gain | Planned |

---

## Vector Database Decision Record

The following evaluation was performed for Phase 4 selection.

**Evaluation criteria:**

- Self-hostable on existing EKS infrastructure
- Native hybrid search (BM25 + dense)
- Python client quality
- Operational overhead
- Data sovereignty (no SaaS dependency for sensitive platform data)

**Decision: Qdrant**

Qdrant satisfies all criteria. It runs as a Kubernetes Deployment backed by a PersistentVolumeClaim. The `qdrant-client` Python library is mature and actively maintained. Hybrid search is a first-class feature, not a workaround. The Rust implementation handles the expected corpus size (11 skills + Confluence corpus ~50,000 chunks) with sub-millisecond p99 latency.

ChromaDB is the correct choice for Phase 3 (local prototype) and is not replaced by Qdrant — it serves a different deployment context.

---

## Appendix: Current SKILL.md Token Budget

| Skill | Estimated Tokens | Domain |
|---|---|---|
| devo-query | ~2,200 | Maqui LINQ — 97 functions, 7 regions |
| devo-infra | ~1,800 | EKS 19 clusters, Ansible |
| devo-alert | ~1,600 | Flow, Pilot, Cockpit, XSOAR |
| devo-security | ~1,400 | Vault/OpenBao, 5 regions |
| devo-tools | ~1,500 | Mason, Lomana, Asilo |
| devo-database | ~1,200 | Adolfo ORM, MySQL |
| devo-devtool | ~1,300 | Jenkins, GitLab, Grafana |
| devo-jira | ~900 | Jira JQL, Confluence CQL |
| automation-offboarding | ~1,100 | Probio API, decommission |
| automation-resilience | ~1,000 | Resilience agents |
| automation-tabularasa | ~1,100 | Affinity rebalancing |
| **Total (all skills loaded)** | **~15,100** | — |

Phase 2 compact headers for all 11 skills: ~2,200 tokens. Phase 3 top-5 chunk retrieval per query: ~1,000 tokens.

---

*This document reflects the actual current state and real planned evolution of AI FORGE. No capabilities are claimed that do not exist.*
