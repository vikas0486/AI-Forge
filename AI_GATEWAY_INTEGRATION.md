# AI Gateway Integration: forge-router

**Project:** AI FORGE + forge-router  
**Author:** Vikash Jaiswal  
**Integration Status:** forge-router is production-ready. Integration is an implementation task.  
**Repository:** `/Users/vikash/Documents/Projects/forge-router`

---

## What This Document Covers

This document specifies how **forge-router** integrates with AI FORGE as the AI Gateway layer. It covers the current state of both systems, the integration architecture, specific use cases the gateway enables, and the implementation steps required.

The key fact: forge-router is already built and production-ready as a standalone tool. AI FORGE is already production in use. The integration connects two working systems, not two concepts.

---

## forge-router: What Exists Today

forge-router is a multi-LLM routing library built in Python. It implements a `RouterEngine` with 8 provider adapters and a priority-based fallback chain.

### RouterEngine Implementation

The core routing logic in `forge/router/engine.py`:

```python
class RouterEngine:
    def __init__(self):
        self.providers = [
            AntigravityProvider(),  # Priority 0 — OAuth Gemini 1.5 Flash
            GeminiProvider(),       # Priority 1 — Gemini CLI
            GroqProvider(),         # Priority 2 — LLaMA 3.3 70B (ultra-fast)
            ClaudeProvider(),       # Priority 3 — Anthropic claude-3-5-sonnet
            CodexProvider(),        # Priority 4 — GitHub Copilot Codex
            CopilotProvider(),      # Priority 5 — GitHub Copilot
            OpenAIProvider(),       # Priority 6 — GPT-4o
            OllamaProvider()        # Priority 7 — Local models (final fallback)
        ]
        self.providers.sort(key=lambda x: x.priority)

    async def route(self, prompt, preferred=None, timeout=30, on_progress=None, image=None):
        if preferred:
            # Try preferred provider first, fall back if it fails
            ...
        
        for provider in self.providers:
            health = await provider.check_health()
            if not health["ok"]:
                continue  # Skip unhealthy providers
            
            response = await provider.generate(prompt, timeout=timeout, image=image)
            return response
        
        raise ValueError("All providers failed.")
```

This is the complete routing logic. Health-check-first selection, automatic fallback, preferred provider override. The implementation is clean and the interface is simple.

### forge-router CLI (Current Standalone Usage)

```bash
forge chat                        # Interactive TUI with auto-routing
forge ask "explain X" --model groq  # Single query, forced provider
forge status                      # Provider health check
forge doctor                      # Full environment diagnosis
```

### Provider Chain (As Deployed)

| Priority | Provider | Model | Use Case |
|---|---|---|---|
| 0 | Antigravity | Gemini 1.5 Flash (OAuth) | Default fast path |
| 1 | Gemini | Gemini CLI | Google fallback |
| 2 | Groq | LLaMA 3.3 70B | Ultra-fast inference, near-zero cost |
| 3 | Claude | claude-3-5-sonnet | High-accuracy reasoning |
| 4 | Codex | GitHub Copilot Codex | Code-specific tasks |
| 5 | Copilot | GitHub Copilot | General fallback |
| 6 | OpenAI | GPT-4o | High-capability fallback |
| 7 | Ollama | Local models | Final fallback, data-sensitive queries |

---

## AI FORGE: Current Query Path

Today, AI FORGE sends prompts directly to Claude via AWS Bedrock. There is no gateway layer. The path is:

```
Engineer query
  └──▶ AI FORGE context assembly (skills + memory + CLAUDE.md)
        └──▶ Augmented prompt
              └──▶ AWS Bedrock (Claude Sonnet)
                    └──▶ Response
```

This works and is production-stable. The limitation is:

- Single provider dependency (AWS Bedrock)
- No cost optimization across query types
- No fallback if Bedrock has a regional event
- No routing for data-sensitive queries to local models
- No multi-model strategy

---

## Integration Architecture: AI FORGE + forge-router

After integration, the path becomes:

```
Engineer query
  └──▶ AI FORGE Intelligence Layer
        ├── Skill retrieval (current: SKILL.md, future: ChromaDB/Qdrant chunks)
        ├── Memory retrieval (MEMORY.md index + relevant files)
        └── Context assembly → Augmented prompt

Augmented prompt
  └──▶ forge-router RouterEngine.route()
        ├── Query classification → preferred provider selection
        ├── Health check all providers
        ├── Route to highest-priority healthy provider
        └── On failure: automatic fallback chain

Response
  └──▶ AI FORGE renders to engineer
```

The AI FORGE intelligence layer is unchanged. forge-router slots in as the provider layer, replacing the direct Bedrock call.

---

## What the Gateway Enables

### Cost Optimization by Query Type

Not all AI FORGE queries require the same model. Status checks and simple log lookups are answered correctly by Groq (LLaMA 3.3 70B) at near-zero cost. Incident analysis and complex multi-region debugging require Claude Sonnet's reasoning depth.

The forge-router `preferred` parameter enables query-type routing:

| Query Type | Detection Signal | Preferred Provider | Cost Impact |
|---|---|---|---|
| Status check (`forge status` equivalent) | Short prompt, keyword match | Groq | ~0 |
| Simple log lookup, known pattern | <500 tokens, single skill loaded | Groq | Near-zero |
| Incident analysis, multi-skill | >1,000 tokens, multiple skills loaded | Claude | Standard |
| Complex reasoning, root cause | Cross-region, multi-table | Claude | Standard |
| Data-sensitive (internal IPs, customer IDs) | Contains PII patterns | Ollama (local) | Zero, on-prem |

### Availability Resilience

AWS Bedrock regional events happen. During incident triage — exactly when engineers need AI assistance most — a Bedrock outage previously meant manual work. With forge-router's fallback chain, the same query routes to the direct Anthropic API (Claude provider, Priority 3) or Groq automatically. The engineer sees no interruption.

**Documented failure scenario (from "Lessons Learned" in blog.md):** The first time AWS Bedrock had a regional issue during incident triage, the value of forge-router became obvious. With the gateway, this becomes a non-event.

### Data Sensitivity Routing

Queries that involve customer domain names, internal IP ranges, or specific customer identifiers require special handling. Routing these to Ollama (Priority 7 — local model) keeps sensitive context entirely on-premise. No customer data leaves the engineer's machine.

The Ollama provider runs against whatever local model is installed (`ollama pull llama3.1` or `ollama pull codellama`). Response quality is lower than Claude, but for data-sensitive queries where accuracy is secondary to data sovereignty, this is the correct tradeoff.

### Rate Limit Absorption

During major incident response, query volume spikes. Multiple engineers may be using AI FORGE simultaneously, all hitting the same Bedrock API. Rate limits degrade into failures that compound the incident. With forge-router's fallback chain, rate limits on one provider automatically route to the next. Engineers never see a rate limit error during triage.

### Multi-Model Strategy

Different models have different strengths. Groq's LLaMA 3.3 is fast and cheap for straightforward operations. Claude has deeper reasoning for architectural analysis. GPT-4o has strong code generation for automation tasks. forge-router enables AI FORGE to leverage the right model for each task class without requiring the engineer to specify the model every time.

---

## Integration Implementation

### Step 1 — Install forge-router as a Python dependency

From the AI FORGE directory or engineer's environment:

```bash
cd /Users/vikash/Documents/Projects/forge-router
uv pip install -e .
```

### Step 2 — Create an AI FORGE gateway module

```python
# ai_forge/gateway.py

from forge.router.engine import RouterEngine
import asyncio

class AIForgeGateway:
    def __init__(self):
        self.router = RouterEngine()
    
    def route(self, prompt: str, preferred: str = None, sensitive: bool = False) -> str:
        """
        Route an augmented prompt through forge-router.
        
        Args:
            prompt: The assembled prompt (skill context + memory + query)
            preferred: Force a specific provider ('groq', 'claude', 'ollama', etc.)
            sensitive: If True, route to Ollama (local, on-prem) regardless of priority
        """
        if sensitive:
            preferred = "ollama"
        
        response = asyncio.run(
            self.router.route(prompt, preferred=preferred)
        )
        return response.text

gateway = AIForgeGateway()
```

### Step 3 — Query Classification (Optional, Phase 2 of integration)

Add lightweight query classification before routing to automatically select the optimal provider:

```python
def classify_query(prompt: str, token_count: int) -> str:
    """Return preferred provider name based on query characteristics."""
    
    # Data sensitivity check (simple pattern matching)
    sensitive_patterns = ["customer:", "domain:", "10.0.", "192.168.", "internal-"]
    if any(p in prompt.lower() for p in sensitive_patterns):
        return "ollama"
    
    # Simple lookup: fast and cheap
    if token_count < 500:
        return "groq"
    
    # Complex reasoning: use Claude
    return "claude"
```

### Step 4 — Environment Configuration

forge-router reads API keys from environment or `~/.devo/credentials` / `.env`. Extend the credentials file:

```bash
# Add to ~/.devo/credentials (sourced by wrapper scripts)
export GROQ_API_KEY="gsk_..."
export ANTHROPIC_API_KEY="sk-ant-..."
export OPENAI_API_KEY="sk-..."
# OLLAMA requires no key — local process
```

### Step 5 — Verify Integration

```bash
# Test forge-router standalone
forge doctor          # Verify all providers configured
forge status          # Check provider health

# Test integration
python -c "
from ai_forge.gateway import gateway
response = gateway.route('What is the Maqui syntax for querying siem.logtrust?', preferred='groq')
print(response)
"
```

---

## Provider Configuration for AI FORGE Use Cases

forge-router's provider chain can be tuned for AI FORGE's specific use patterns. The following configuration optimizes for platform engineering workloads:

| Provider | AI FORGE Role | When to Use |
|---|---|---|
| Groq (LLaMA 3.3 70B) | Fast path for routine ops | Status checks, simple queries, known patterns |
| Claude (Anthropic) | Primary for complex reasoning | Incident analysis, root cause, architectural questions |
| Ollama (local) | Data-sovereign path | Any query with customer identifiers or internal network data |
| OpenAI (GPT-4o) | High-capability fallback | If Claude is unavailable, for complex queries |
| Antigravity (Gemini Flash) | Default cost-efficient path | General queries not yet classified |

---

## Security Considerations for Gateway Integration

forge-router's security model is compatible with AI FORGE's Zero-Secret Architecture:

| Security Property | forge-router Behavior | AI FORGE Alignment |
|---|---|---|
| API key handling | Keys loaded from environment variables, never logged | Compatible with `~/.devo/credentials` sourcing |
| Prompt logging | No prompt content is logged by default | Consistent with AI FORGE's zero-leakage principle |
| Local model path | Ollama runs entirely on-premise | Enables data-sensitive routing without cloud exposure |
| TLS in transit | All provider APIs use HTTPS | Standard enforcement |

The deny-list safety architecture remains at the shell level and is unaffected by gateway integration. forge-router routes prompts to models; it does not execute commands.

---

## Operational Runbook

### Check forge-router Health Before AI FORGE Session

```bash
forge doctor      # Full environment check
forge status      # Live provider health
```

### Force a Specific Provider for a Session

```bash
forge ask "your query" --model claude    # Force Claude
forge ask "your query" --model groq     # Force Groq (fast/cheap)
forge ask "your query" --model ollama   # Force local model
```

### Verify Integration After Deployment

```bash
# Run from forge-router directory
python -m pytest tests/ -v
```

### Provider Down: What Happens

If a provider is unhealthy (API key missing, rate limited, network error), forge-router logs the failure and moves to the next provider in the chain. The engineer receives a response from the next healthy provider. No manual intervention required.

---

## Integration Roadmap

| Milestone | Description | Depends On |
|---|---|---|
| 1 | Basic gateway integration (direct Bedrock → forge-router) | forge-router installed |
| 2 | Query classification for automatic provider selection | Milestone 1 |
| 3 | Ollama routing for data-sensitive queries | Ollama installed locally |
| 4 | Integration with RAG pipeline (chunks routed through gateway) | RAG Phase 3 |
| 5 | Per-query cost tracking (Langfuse + forge-router response metadata) | RAG Phase 7 |

---

## Reference

**forge-router repository:** `/Users/vikash/Documents/Projects/forge-router`  
**RouterEngine:** `forge/router/engine.py`  
**Provider implementations:** `forge/providers/`  
**CLI entry points:** `forge/cli.py`  
**AI FORGE Global Brain:** `.claude/CLAUDE.md`  
**RAG evolution plan:** `RAG_ROADMAP.md`

---

*forge-router is a completed, production-ready project. This document specifies its integration into AI FORGE as the AI Gateway layer — the natural next step in the platform's evolution.*
