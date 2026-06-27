# Building AI FORGE: An Enterprise AI Agent Operating System with RAG, AI Gateways, and Future MCP Integration

*By Vikash Jaiswal — Lead Platform Engineer & AI Systems Architect*

---

![AI FORGE](Marketing/AI%20Forge%20Flyer_1.png)

---

## The Problem That Wouldn't Go Away

Every senior Platform Engineer has lived this scenario. An AI assistant generates a syntactically perfect Kubernetes command — the wrong namespace, the wrong cluster, and for a region that has been deprecated for eight months. The AI was impressive. The command was catastrophic.

This is not an intelligence problem. It is an **infrastructure problem**.

General-purpose AI assistants are trained on the internet. Your enterprise is not on the internet. Your Maqui LINQ syntax, your 19-cluster EKS topology, your Vault paths, your region-specific security constraints — none of it exists in the training data. And even if it did, the AI has no persistent context between sessions, no memory of last week's incident, and no understanding of why a particular table requires a mandatory `where client = 'self'` filter to avoid a 60-second timeout.

I spent months watching experienced engineers hit this same wall. They would painstakingly set up a session — explaining the platform, loading context, specifying the region — then lose it all when the conversation ended. The next engineer on call would repeat the process from scratch. Knowledge was being regenerated, not accumulated.

This is the **AI Execution Gap**: the distance between what an AI agent knows in principle and what it can execute safely in a specific enterprise environment.

I built **AI FORGE** to close that gap.

---

## What AI FORGE Actually Is

AI FORGE is not another wrapper around an AI API. It is an **Enterprise AI Agent Operating System** — a structured operational layer that transforms a general-purpose AI assistant into a domain-expert platform engineer.

The distinction matters. An API wrapper gives you convenience. An operating system gives you:

- **Domain expertise** that is codified, versioned, and loaded on demand
- **Persistent memory** that survives sessions and accumulates institutional knowledge
- **Security boundaries** that prevent the AI from taking actions it should not take
- **Execution infrastructure** that connects AI intent to real platform operations

AI FORGE runs on **Claude Code** via **AWS Bedrock**, operating within a local engineer environment. It is not a SaaS product. It is not a hosted service. It is an operational capability deployed to the machine of every platform engineer on the team.

---

## The Crescent Architecture: Wrapping, Not Replacing

The core architectural insight behind AI FORGE is counterintuitive: **do not give the AI direct access to your platform APIs**.

Instead, give it the same abstractions your engineers use.

We call this the **Crescent Architecture**. Every platform interaction — querying Maqui, accessing Vault secrets, managing EKS clusters, running MySQL queries — routes through a unified wrapper layer. These wrapper scripts handle authentication, regional endpoint resolution, and error normalization. The AI uses `maquieu` for EU queries exactly the way a human engineer does. Same alias. Same safety filters. Same behavior.

This produces a structural benefit that becomes obvious in production: when an engineer and the AI use the same interface, there is no dual maintenance burden. When the EU endpoint changes, you update one wrapper script. The AI inherits the change automatically.

The wrapper layer also solves the credential problem fundamentally. Credentials live in `~/.devo/credentials` with `chmod 600` permissions. They are sourced at runtime by the wrapper scripts. They never appear in the AI context window, in git history, or in log output. This is not a security feature that was added later — it is the structural property of the architecture.

We currently have 15 wrapper scripts covering: Maqui LINQ (7 regions), MySQL/Adolfo, Vault/OpenBao (5 regions), Kubernetes/EKS, GitLab, Jenkins, Jira, Confluence, AWS SSO, and the model-switching script for AI FORGE itself.

---

## Skills: Codified Domain Expertise

The wrapper layer handles execution. The skills layer handles knowledge.

AI FORGE organizes domain expertise into 11 modular "Brain Packs" — directories containing a `SKILL.md` with full domain knowledge and a `claude-skills.json` registration file. Invoking a skill (e.g., `/devo-query`) loads that SKILL.md into the agent's context. The agent is immediately operating with expert-level knowledge for that domain.

Here is why this matters at scale: without modular skills, you face an impossible tradeoff. Load everything into every session and you bloat the context window, degrading accuracy and burning API tokens. Load nothing and the agent operates blind. Skills solve this with **just-in-time context loading** — the right knowledge, at the right time, for the current task.

The `/devo-query` skill, for example, contains:

- 97 Maqui LINQ function signatures
- Region-to-alias mapping for all 7 regions
- A library of 75+ copy-paste query patterns organized by table
- Mandatory safety filters (e.g., `siem.logtrust.*` always requires `where client = 'self'`)
- Time-window escalation rules (start at `now()-5m`, expand only if needed)
- Cross-references to related skills

When an engineer needs to investigate a data ingestion issue, they invoke `/devo-query`. The agent immediately knows the Maqui LINQ syntax, the correct regional alias, and the query patterns that have worked before. It does not guess. It retrieves.

The skill interaction map is also important: `/devo-query` references `/devo-tools` for Asilo job status. `/devo-infra` references `/devo-devtool` for SSH and Ansible operations. `/automation-*` skills reference `/devo-infra` for Ansible playbooks. This composition means complex operations — investigate a query bottleneck, trace it to an Asilo job, restart the job via Ansible — flow naturally across skill boundaries.

---

## Persistent Memory: The Accumulating Brain

The single most-requested capability in enterprise AI deployments is session continuity. Engineers do not want to re-explain the platform. They do not want to repeat behavioral corrections. They do not want to lose incident context when a chat session closes.

AI FORGE implements a **typed, file-based memory system** that addresses this directly. Memory is categorized into four types:

**Feedback memory** stores behavioral rules — what the agent should and should not do, with the reasoning behind each rule. These are not just instructions; they are the accumulated result of real interactions. "Never start Maqui queries with a time window larger than 5 minutes — large windows on busy tables cause 60-second timeouts." This correction, made once, becomes a permanent behavioral rule.

**Project memory** stores active incident and project context. When an incident spans multiple sessions, the current state, affected customers, and investigated hypotheses persist across shifts. The engineer coming on call inherits context, not a blank slate.

**Reference memory** stores pointers to external systems. Grafana dashboard URLs, Confluence runbook locations, Jira ticket patterns — these are indexed and retrievable without the agent needing to search for them.

**User memory** stores the profile of the engineer: their domain expertise, their communication style, their current focus areas. This allows the agent to calibrate its responses — detailed explanations for a new team member, concise output for a senior engineer who just needs the command.

The memory index (`MEMORY.md`) is auto-loaded at the start of every session. Individual memory files are fetched on reference. This index-first pattern is itself a RAG pattern — more on that below.

The practical outcome: the agent matures. After several months of operation, AI FORGE's memory contains dozens of behavioral rules, incident patterns, and architectural references. A new engineer inheriting the system gets an AI agent that already knows the platform.

---

## Safe AI Operations: Blast-Proof Guardrails

Enterprise AI faces a paradox: the more capable the agent, the more dangerous an error becomes. A sufficiently capable AI that can restart a Kubernetes deployment can accidentally restart the wrong one.

AI FORGE resolves this with three layers of safety enforcement.

**Layer 1 — Deny-list at the shell level.** Commands matching a deny-list pattern in `settings.json` are intercepted before execution. They are displayed to the engineer, and a `yes` confirmation is required before they run. The list covers file deletion (`rm -rf`, `find -delete`), service operations (`systemctl restart/stop`), server operations (`reboot`, `shutdown`), Kubernetes restarts (`kubectl rollout restart`), process termination, protected branch pushes (`git push origin master/main`), and Asilo data wipes.

**Layer 2 — Wrapper-level validation.** The wrapper scripts themselves validate inputs before forwarding to platform APIs. A Maqui query without the mandatory client filter is rejected at the wrapper level, not at the API level. This prevents timeout-inducing queries before they hit the platform.

**Layer 3 — Human-in-the-loop confirmation.** For operations outside the deny-list but identified as high-risk, the agent presents the proposed action and waits for explicit confirmation. This is not a prompt-level instruction — it is an operational protocol enforced by the CLAUDE.md global brain.

This architecture means the AI can be genuinely autonomous for safe operations while remaining human-supervised for destructive ones. Engineers trust the system precisely because they know what it cannot do without their approval.

---

## Existing RAG Foundations: Already Doing RAG

Here is something important that is easy to miss: **AI FORGE already implements Retrieval-Augmented Generation**. Not in the vector database sense — not yet — but in the foundational sense that RAG actually means.

RAG, at its core, is the pattern of retrieving relevant external knowledge and injecting it into the prompt to ground the LLM's response in specific, private data. AI FORGE does exactly this:

The **skill system** retrieves domain-specific knowledge on demand and injects it into the agent's context. When `/devo-query` is invoked, 97 Maqui function signatures are retrieved from `SKILL.md` and augmented into the prompt. This is retrieval-augmented generation.

The **memory system** retrieves behavioral corrections, incident context, and architectural references from the memory directory and injects them into every session. The `MEMORY.md` index functions as a retrieval index — a pointer store that enables targeted document retrieval rather than loading everything. This is retrieval-augmented generation.

The **wrapper metadata** in `CLAUDE.md` injects operational context — regional aliases, timezone rules, mandatory safety filters — that grounds every command execution in the specifics of the Devo platform. This is retrieval-augmented generation.

The current implementation is **Primitive RAG**: deterministic, trigger-based, and file-level. The retrieval unit is an entire document, not a semantic chunk. The trigger is a manual slash command, not an embedding similarity query. But the pattern is real and functional.

The limitation is scale efficiency. Loading `/devo-query` injects ~2,000 tokens. Loading two or three skills simultaneously consumes 4,000–6,000 tokens before the task prompt even begins. This is where the evolution roadmap begins.

---

## The AI Gateway Layer: forge-router

Parallel to AI FORGE, a second project was taking shape: **forge-router** — a multi-LLM routing library built in Python.

forge-router implements a `RouterEngine` with 8 provider adapters, each with a defined priority and a `check_health()` method. On every request:

1. The engine checks all providers' health (fast, in-memory checks for API key presence)
2. Routes to the highest-priority healthy provider
3. On failure or rate limit, automatically falls back to the next provider in the chain

The current provider priority chain: Antigravity (OAuth Gemini 1.5 Flash, priority 0) → Gemini CLI (priority 1) → Groq LLaMA 3.3 70B (priority 2) → Claude Anthropic API (priority 3) → Codex → Copilot → OpenAI GPT-4o → Ollama local models (priority 7, final fallback).

forge-router is already production-ready as a standalone tool. `forge chat` starts an interactive TUI with command history, multiline input, and vision attachment support. `forge ask` handles one-shot queries. `forge status` checks all provider health. `forge doctor` runs environment diagnostics.

The AI Gateway story emerges from combining these two systems:

AI FORGE assembles the augmented prompt (retrieved skill context + memory context + user query) and hands it to forge-router, which routes it to the optimal available model. This separates concerns cleanly: AI FORGE manages knowledge and context; forge-router manages model access and resilience.

This enables capabilities that neither system has alone:

**Cost optimization:** Simple status queries route to Groq (LLaMA 3.3 70B, near-zero API cost). Complex incident analysis routes to Claude Sonnet. The routing decision can be based on query complexity, token budget, or explicit user preference.

**Availability resilience:** If AWS Bedrock has a regional issue, forge-router falls back to the direct Anthropic API without any intervention from the engineer. The platform engineering team does not lose AI assistance because of a model provider outage.

**Data sensitivity routing:** Queries that involve internal IP ranges, customer domain names, or other sensitive identifiers can be configured to route to a local Ollama instance, keeping sensitive context entirely on-premise.

**Rate limit absorption:** During incident triage, when query volume spikes, forge-router's fallback chain absorbs rate limits across providers. The engineer sees no interruption; the router simply tries the next provider.

---

## The Enterprise RAG Roadmap

Moving from today's file-based Primitive RAG to a semantic enterprise knowledge fabric is a phased journey. Each phase builds on the previous one and delivers standalone value.

**The immediate opportunity** requires no new infrastructure: add a `SKILL-COMPACT.md` to each skill — a 200-token summary that loads by default, with the full SKILL.md available on explicit deep-dive. All 11 skills in compact format consume ~2,200 tokens total versus ~22,000 for all full SKILL.md files. A 10x reduction with a text editor.

**The semantic retrieval phase** introduces ChromaDB (embedded Python library, no server required) to chunk and index SKILL.md files at the section level. Each 200-token chunk is tagged with metadata: skill name, region scope, command category, table pattern. A query like "Maqui query for investigating Santander ingestion" retrieves the 3–5 most relevant chunks (~400 tokens) rather than the entire SKILL.md (~2,000 tokens). Session baseline drops from ~3,200 tokens to ~600 tokens — an 83% reduction.

**The production vector phase** moves from ChromaDB to **Qdrant** deployed on the existing EKS management cluster. Qdrant supports hybrid search — BM25 keyword matching combined with dense vector semantic search. This is the right combination for platform engineering queries, which often mix known error codes (BM25 territory) with semantic intent. Qdrant also ingests the Confluence knowledge base, making the full internal runbook library searchable through the same interface as the skill system.

**The reranking phase** adds a cross-encoder pass after initial retrieval. Where embedding similarity measures how much a chunk sounds like the query, a cross-encoder reads them together and scores precision. For complex, multi-part queries — "why is the metamalote overloaded and what is the precedent from the last three incidents" — reranking substantially improves the quality of retrieved context.

**The observability phase** instruments the full pipeline: which chunks were retrieved, which provider was used, latency per phase, and a feedback signal from the engineer (was this response useful?). Over time, this data drives continuous improvement — chunk boundaries are refined, metadata tags are improved, provider routing rules are calibrated.

---

## MCP: A Future-Ready Architecture

The Model Context Protocol (MCP) is an open standard for how AI agents interact with tools and data sources. It defines servers (which expose capabilities), tools (executable functions), resources (data context), and prompts (system instructions).

AI FORGE did not design for MCP. It designed for operational safety and knowledge modularity — and arrived at natural alignment with MCP:

The 15 wrapper scripts would become MCP Tools within a local `mcp-server-devo-platform`. The 11 SKILL.md files would become MCP Resources with structured URIs. The CLAUDE.md Global Brain would become an MCP Prompt template. The slash command registry (`claude-skills.json`) would become MCP Tool definitions.

What would formal MCP adoption change? Interoperability. Any MCP-compliant client — not just Claude Code — could consume AI FORGE's skills and wrappers. This opens AI FORGE capabilities to other engineering teams, other AI clients, and potentially a formalized internal API surface.

What would not change? The credential security model. The deny-list safety architecture. The multi-region wrapper design. The persistent memory system. These are not MCP concerns — they are infrastructure concerns that MCP adoption would not touch.

The assessment is that MCP adoption is a Phase 2 evolution, not a prerequisite. The hard architecture decisions are already made correctly.

---

## Lessons Learned

**Wrapping is more durable than replacing.** Early AI integrations in enterprise environments often try to build new interfaces to existing systems. The wrapper-first approach proved more durable — because it reuses the authentication, validation, and error-handling logic that already exists and is already trusted.

**Safety guardrails need to be structural, not instructional.** Telling an AI "do not run destructive commands" in a prompt is not reliable. Blocking those commands at the shell level is. The distinction between instructional safety (what you tell the model) and structural safety (what the environment permits) is critical for enterprise deployments.

**Context bloat is a real performance problem.** Loading everything into every session is tempting but counterproductive. After a certain token threshold, LLM accuracy degrades measurably. The modular skills architecture — load only what the task requires — directly addresses this. It also produces a better user experience: a focused agent is a more accurate agent.

**Memory accumulates faster than you expect.** After a few weeks of active use, the memory system contained dozens of behavioral rules, architectural references, and incident patterns. New engineers onboarding to the team received an AI agent that already knew the platform. This is the compounding return on the initial investment in memory infrastructure.

**The AI gateway solves a problem you do not know you have until you hit it.** The first time AWS Bedrock had a regional issue during incident triage, the value of forge-router became obvious. A gateway that absorbs provider failures transparently is not a nice-to-have — it is operational reliability.

---

## What Comes Next

AI FORGE is an active platform capability, not a completed project. The immediate priorities are:

- **SKILL-COMPACT.md** for all 11 skills — zero-infrastructure 40% token reduction
- **forge-router integration** as the AI Gateway layer — multi-model routing with fallback resilience
- **ChromaDB indexing** of the skill corpus — semantic chunk retrieval replacing full-file loading
- **NOC Agent skill** — dedicated capability for real-time monitoring and alert triage
- **Qdrant on EKS** — production vector search with Confluence corpus ingestion

The longer trajectory is toward a platform where AI FORGE proactively surfaces relevant context — suggesting which skill to load before the engineer asks, identifying similar past incidents before the engineer searches, routing to the right model before the engineer specifies.

That is not a prediction about AI capabilities. It is an architecture decision: build the retrieval infrastructure now, and intelligence can be layered on top.

---

## Closing Thoughts

The enterprise AI adoption story is not primarily about model capability. It is about infrastructure. The models are already capable enough for most operational tasks. The gap is the operational layer that connects model capability to enterprise-specific knowledge, tools, and constraints.

AI FORGE is one implementation of that operational layer. The specific technology choices — Claude Code, AWS Bedrock, file-based memory, wrapper scripts — are less important than the architectural pattern: knowledge codified as retrievable artifacts, execution abstracted through secure wrappers, memory accumulated across sessions, safety enforced at the structural level.

That pattern works. It is working in production today, across 7 global regions, managing 19 Kubernetes clusters, querying petabytes of log data, and returning answers that are grounded in the actual state of the actual infrastructure.

The Execution Gap is real. The architecture to close it is not complicated. It just has to be built.

---

*Vikash Jaiswal is a Lead Platform Engineer and AI Systems Architect at Devo, focused on the intersection of Generative AI and Enterprise Operations. AI FORGE is an active internal platform capability.*
