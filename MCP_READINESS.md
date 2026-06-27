# MCP Readiness Assessment

**Project:** AI FORGE — Enterprise AI Agent Operating System  
**Protocol:** Model Context Protocol (MCP) — open standard for AI-tool interoperability  
**Author:** Vikash Jaiswal  
**Assessment Date:** 2026-06  
**Verdict:** Architecturally aligned. MCP adoption is an evolution path, not a rewrite.

---

## What Is MCP and Why Does It Matter

The Model Context Protocol is an open standard, originally published by Anthropic, that defines how AI agents interact with external tools, data sources, and execution environments. It specifies four primitives:

| MCP Primitive | What It Is |
|---|---|
| **Tools** | Executable functions the model can call — with defined schemas, parameters, and results |
| **Resources** | Structured data the model can read — documents, schemas, live data, file contents |
| **Prompts** | Pre-defined instruction templates the model can be initialized with |
| **Servers** | The local or remote process that hosts and exposes tools, resources, and prompts |

MCP matters because it decouples the AI client from the AI's tools. Any MCP-compliant client (Claude Code, Cursor, VS Code Copilot, custom agents) can consume any MCP server's capabilities without custom integration code per client. It is the difference between a platform API and a point-to-point integration.

---

## The Core Finding: AI FORGE Is an Accidental MCP Implementation

AI FORGE was not designed for MCP. It was designed for operational safety, knowledge modularity, and secure execution in a multi-region enterprise platform environment. It followed the same architectural principles — abstraction, modularity, separation of concerns, security — and arrived at natural structural alignment with what MCP would later formalize.

This is not marketing. It is an observation about architectural convergence.

---

## Structural Mapping: AI FORGE to MCP

The following mapping is precise. Each AI FORGE component is matched to the MCP primitive it most closely implements, with the specific mechanism described.

### Wrapper Scripts → MCP Tools

AI FORGE's 15 wrapper scripts are executable functions that accept inputs, validate them, inject credentials at runtime, and return structured results. This is exactly what MCP Tools are.

| AI FORGE Wrapper | MCP Tool Name (proposed) | Inputs | Auth Injection |
|---|---|---|---|
| `maqui-wrapper.sh` | `maqui_query` | region, query string, time window | MAQUI_TOKEN from `~/.devo/credentials` |
| `vault-wrapper.sh` | `vault_read`, `vault_write` | path, operation | VAULT_TOKEN per region |
| `kubectl-wrapper.sh` | `kubectl_get`, `kubectl_apply` | cluster, namespace, resource | AWS SSO session token |
| `mysql-wrapper.sh` | `sql_query` | environment, query | Database credentials |
| `git-wrapper.sh` | `git_push`, `git_status` | repo, branch, operation | GITLAB_TOKEN |
| `jenkins-wrapper.sh` | `jenkins_trigger` | job name, parameters | JENKINS_API_TOKEN |
| `switch-model.sh` | `model_switch` | model profile | BEDROCK_KEY |

The structural difference between the current wrapper and a formal MCP Tool: the MCP Tool has a JSON schema definition for inputs and outputs, discoverable by any MCP client. The wrapper has implicit parameter conventions understood by engineers. The implementation is identical; the declaration is what is missing.

### Skills (SKILL.md files) → MCP Resources

MCP Resources are structured data that the model reads for context — documents, schemas, live data. AI FORGE Skills are structured Markdown files containing domain knowledge that the model reads for context. The mapping is direct.

| AI FORGE Skill | MCP Resource URI (proposed) |
|---|---|
| `devo-query/SKILL.md` | `mcp://devo/skills/query` |
| `devo-infra/SKILL.md` | `mcp://devo/skills/infra` |
| `devo-security/SKILL.md` | `mcp://devo/skills/security` |
| `devo-alert/SKILL.md` | `mcp://devo/skills/alert` |
| `automation-offboarding/SKILL.md` | `mcp://devo/automation/offboarding` |

Currently, skills are loaded via slash commands (`/devo-query`). In MCP, a client requests the resource by URI. The content is the same; the retrieval mechanism is formalized and discoverable.

### CLAUDE.md (Global Brain) → MCP Prompts

MCP Prompts are pre-defined instruction templates that initialize the model with a system context. AI FORGE's `CLAUDE.md` initializes every agent session with: model configuration, security rules, wrapper protocols, timezone handling, and operational constraints. This is an MCP Prompt. The format is Markdown rather than JSON, and it is loaded by Claude Code's file-loading convention rather than by a protocol call — but the purpose and function are identical.

### claude-skills.json → MCP Tool Definitions

Each skill's `claude-skills.json` file declares: the skill name, a description, a trigger pattern, and an argument hint. This is the metadata layer that allows Claude Code to discover and invoke skills. MCP Tool Definitions serve the same purpose — they declare what a tool does, its parameter schema, and its identifier — in a machine-readable format that any compliant client can parse.

### Full Mapping Table

| AI FORGE Component | MCP Primitive | Gap to Close |
|---|---|---|
| Wrapper scripts | MCP Tools | Add JSON schema declarations for inputs/outputs |
| SKILL.md files | MCP Resources | Add URI scheme, serve via MCP server |
| CLAUDE.md | MCP Prompts | Formalize as MCP Prompt template |
| claude-skills.json | MCP Tool Definitions | Convert to MCP-compliant schema format |
| `~/Documents/Scripts/` directory | MCP Server | Wrap in lightweight MCP server process |
| Persistent memory files | MCP Resources (dynamic) | Serve memory files as addressable resources |

---

## What Would Change Under Formal MCP Adoption

### What changes

**Discovery mechanism:** Today, slash commands (`/devo-query`) are statically registered in Claude Code. Under MCP, any client connecting to the `mcp-server-devo-platform` server automatically discovers all available tools and resources. No manual registration per client.

**Client interoperability:** Today, AI FORGE runs exclusively in Claude Code. Under MCP, any MCP-compliant client — a custom agentic loop, VS Code Copilot with MCP support, a CI/CD automation framework — can consume the same wrapper tools and skill resources without custom integration.

**Schema enforcement:** Today, wrappers accept whatever inputs are passed and handle validation internally. Under MCP, tool inputs are schema-validated before the wrapper executes. This makes misuse detectable at the protocol layer rather than in wrapper error messages.

**Resource versioning:** SKILL.md files are git-versioned. Under MCP, resources can expose version metadata, enabling clients to request a specific version of a skill — useful when a platform migration changes the correct query syntax for a given release.

### What does not change

The following are not MCP concerns and would be unaffected by MCP adoption:

- The `~/.devo/credentials` credential security model
- The deny-list safety architecture in `settings.json`
- The multi-region wrapper design
- The persistent memory system structure
- The prompt augmentation patterns in CLAUDE.md
- The human-in-the-loop confirmation for destructive operations

These are infrastructure decisions. MCP is a protocol layer above the infrastructure. The hard problems in AI FORGE are solved at the infrastructure level. MCP adoption formalizes the interface, it does not redesign the foundation.

---

## MCP Adoption Roadmap

### Phase 1 — Wrapper-to-Tool Translation (Low effort, high interoperability gain)

Create `mcp-server-devo-platform` — a lightweight Python process using the MCP Python SDK that wraps the existing wrapper scripts.

```
mcp-server-devo-platform/
├── server.py              ← MCP server entry point
├── tools/
│   ├── maqui.py           ← MCP Tool wrapper for maqui-wrapper.sh
│   ├── vault.py           ← MCP Tool wrapper for vault-wrapper.sh
│   ├── kubernetes.py      ← MCP Tool wrapper for kubectl-wrapper.sh
│   └── database.py        ← MCP Tool wrapper for mysql-wrapper.sh
└── resources/
    ├── skills.py           ← Serves SKILL.md files as MCP Resources
    └── memory.py           ← Serves memory files as MCP Resources
```

The wrapper scripts remain unchanged. The MCP server is a thin adapter. Estimated effort: 1–2 engineer-weeks.

### Phase 2 — Skills as Structured Resources (Medium effort, retrieval precision gain)

Expose skill content as fine-grained MCP Resources rather than monolithic documents. A client can request `mcp://devo/skills/query/function/last_error` to retrieve only the function signature for error introspection, rather than the entire SKILL.md.

This is the MCP-native version of Phase 3 in the RAG roadmap (chunk-level retrieval).

### Phase 3 — Centralized MCP Hub (Higher effort, cross-team value)

Deploy the MCP server as a shared internal service (Lambda or EKS Deployment, `eu-west-1` management cluster) rather than a local process. Engineers across teams can connect their MCP clients to the same hub, accessing the same verified skill set and platform wrappers without local installation.

This transforms AI FORGE from a per-engineer tool into a shared platform capability.

---

## Technical Feasibility Assessment

| MCP Feature | AI FORGE Readiness | Work Required |
|---|---|---|
| Tool exposure (wrappers) | High | JSON schema definitions, MCP server adapter |
| Resource exposure (skills) | High | URI scheme, server endpoint per resource |
| Prompt templates (CLAUDE.md) | Medium | Format conversion to MCP Prompt spec |
| Security model preservation | High | Wrapper credentials remain unchanged |
| Deny-list enforcement | High | Deny-list moves to MCP Tool pre-execution hooks |
| Multi-region routing | High | Wrapper region logic unchanged |
| Memory as resources | Medium | Memory files served with freshness metadata |
| Dynamic discovery | High | Native MCP feature, no custom work |

**Overall readiness: High.** The conceptual and structural work is complete. What remains is adaptation of interfaces to the MCP protocol format — essentially, adding documentation that machines can read.

---

## Honest Assessment

AI FORGE is not an MCP implementation today. It is a pre-MCP implementation of the same principles. The distinction is interface formalization, not architectural substance.

Formal MCP adoption provides:

1. **Client interoperability** — other engineering teams, other AI clients, automated workflows
2. **Dynamic tool discovery** — no manual slash command registration per engineer
3. **Schema validation** — protocol-level input checking rather than wrapper-level
4. **Industry alignment** — as MCP adoption grows, AI FORGE capabilities become accessible to a wider ecosystem

Formal MCP adoption does **not** require rewriting the security model, the wrapper architecture, or the memory system. The hard decisions are already made correctly.

The recommended approach: implement Phase 1 (MCP server adapter) when a second engineering team or a second AI client needs to consume AI FORGE capabilities. Until then, the current implementation is operationally sufficient and the evolution path is clear.

---

*This document reflects an honest technical assessment. No MCP capabilities are claimed that do not exist. The mapping identifies genuine structural alignment, not aspirational positioning.*
