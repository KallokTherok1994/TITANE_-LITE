# Phase 6: Rust Performance Benchmarks — Guide d'Implémentation

**Date**: 2026-02-07  
**Version**: v27.4.1  
**Baseline**: 756 tests Rust passés (100%)

---

## Objectif

Établir des benchmarks de performance pour les composants critiques du backend Rust afin de:
1. Détecter les régressions de performance dans CI/CD
2. Optimiser les hot paths (chat engine, memory, cycle engine)
3. Documenter les performances baseline pour comparaison

---

## Composants à Benchmarker

### 1. Chat Engine (Priorité: 🔴 HIGH)

**Fichier**: `src-tauri/benches/chat_engine_bench.rs`

**Métriques**:
- `generate_response` latency (p50, p95, p99)
- `stream_response` throughput (tokens/s)
- Conversation context loading time
- Memory allocation per request

**Exemple**:
```rust
use criterion::{black_box, criterion_group, criterion_main, Criterion};
use titane_lite::chat_engine::Engine;

fn bench_generate_response(c: &mut Criterion) {
    let engine = Engine::new();
    let message = "Test prompt for benchmarking performance";
    
    c.bench_function("generate_response_latency", |b| {
        b.iter(|| {
            engine.generate(black_box(message), black_box("test-convo"))
        });
    });
}

criterion_group!(benches, bench_generate_response);
criterion_main!(benches);
```

**Commande**:
```bash
cargo bench --bench chat_engine_bench
```

---

### 2. Unified Memory (Priorité: 🔴 HIGH)

**Fichier**: `src-tauri/benches/memory_bench.rs`

**Métriques**:
- `save_memory` write latency
- `load_memory` read latency
- Memory tier promotion time
- Cognitive field indexing performance

**Tests**:
- Small payload (1KB): typique message chat
- Medium payload (100KB): conversation avec historique
- Large payload (1MB): synchronisation complète

**Exemple**:
```rust
fn bench_memory_write(c: &mut Criterion) {
    let mut group = c.benchmark_group("memory_write");
    let memory = UnifiedMemory::new();
    
    for size in [1, 100, 1000].iter() {
        let data = vec![0u8; size * 1024]; // KB
        group.bench_with_input(
            BenchmarkId::from_parameter(format!("{}KB", size)),
            &data,
            |b, data| {
                b.iter(|| memory.save(black_box(data), MemoryTier::MediumTerm));
            },
        );
    }
    group.finish();
}
```

---

### 3. Cycle Engine (Priorité: 🟡 MEDIUM)

**Fichier**: `src-tauri/benches/cycle_engine_bench.rs`

**Métriques**:
- Cycle computation time (breath, attention, rhythm)
- Phase transition latency
- Fractal synchronization overhead

**Tests**:
- Idle cycle (no input): baseline overhead
- Active cycle (with stimuli): realistic workload
- Phase transition: critical path performance

---

### 4. Kernel Integration (Priorité: 🟢 LOW)

**Fichier**: `src-tauri/benches/kernel_bench.rs`

**Métriques**:
- Cold start time (kernel initialization)
- Hot path (typical request → response)
- End-to-end latency (IPC overhead included)

---

## Configuration Cargo.toml

Ajouter section `[[bench]]`:

```toml
# src-tauri/Cargo.toml

[dev-dependencies]
criterion = { version = "0.5", features = ["html_reports"] }

[[bench]]
name = "chat_engine_bench"
harness = false

[[bench]]
name = "memory_bench"
harness = false

[[bench]]
name = "cycle_engine_bench"
harness = false

[[bench]]
name = "kernel_bench"
harness = false
```

---

## Exécution des Benchmarks

### Commande Complète

```bash
# Exécuter tous les benchmarks
cargo bench --workspace

# Benchmark spécifique
cargo bench --bench chat_engine_bench

# Avec rapports HTML
cargo bench -- --output-format bencher
```

### Baseline Capture

```bash
# Capturer baseline pour comparaison future
cargo bench --bench chat_engine_bench -- --save-baseline v27.4.1

# Comparer avec baseline
cargo bench --bench chat_engine_bench -- --baseline v27.4.1
```

---

## Métriques Cibles (Baseline v27.4.1)

Valeurs à établir lors de la première exécution:

| Composant | Métrique | Cible (v27.4.1) | Notes |
|-----------|----------|-----------------|-------|
| Chat Engine | `generate_response` p50 | TBD ms | Sans LLM (mock) |
| Chat Engine | `generate_response` p95 | TBD ms | Incluant outliers |
| Memory | `save_memory` 1KB | TBD µs | Write latency |
| Memory | `load_memory` 1KB | TBD µs | Read latency |
| Cycle Engine | Single cycle | TBD ms | Breath + attention |
| Kernel | Cold start | TBD ms | Full initialization |
| Kernel | Hot path | TBD µs | Request → response |

---

## Intégration CI/CD (Phase 7)

### Détection de Régression

```yaml
# .github/workflows/performance.yml
name: Performance Benchmarks

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  benchmark:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions-rs/toolchain@v1
        with:
          toolchain: stable
      - name: Run benchmarks
        run: |
          cd src-tauri
          cargo bench --workspace -- --output-format bencher > bench_results.txt
      - name: Compare with baseline
        run: |
          # Parse results and fail if >10% regression
          python scripts/ci/compare_benchmarks.py bench_results.txt baseline_v27.4.1.txt
```

---

## Actions Post-Benchmark

1. **Documenter Baseline**: Créer `reports/PERFORMANCE_BASELINE_v27.4.1.json`
2. **Identifier Hot Paths**: Utiliser `flamegraph` pour CPU profiling
3. **Optimiser**: Focus sur p95/p99 outliers
4. **Re-benchmark**: Valider améliorations avec `--baseline`

---

## Outils Complémentaires

### Flamegraph (CPU Profiling)

```bash
# Installation
cargo install flamegraph

# Générer flamegraph
cargo flamegraph --bench chat_engine_bench
```

### Memory Profiling

```bash
# Valgrind + massif
valgrind --tool=massif target/release/titane-lite

# Analyse
ms_print massif.out.*
```

### Perf (Linux)

```bash
# Record
perf record --call-graph dwarf target/release/titane-lite

# Report
perf report
```

---

## Notes d'Implémentation

**⚠️ Attention**:
- Les benchmarks doivent tourner sur du hardware consistent (CI runners)
- Éviter de benchmarker I/O réseau (trop variable)
- Utiliser `black_box()` pour éviter optimisations compiler
- Warmup iterations nécessaires pour JIT/cache

**Recommandations**:
- Benchmarker code Rust pur (pas d'IPC Tauri dans benches)
- Mock les LLMs pour isoler performance backend
- 100+ iterations pour statistiques fiables
- Documenter environnement (CPU, RAM, OS) dans baseline

---

## Prochaines Étapes (Phase 7)

Une fois les benchmarks établis:
1. Intégrer dans CI/CD pipeline
2. Configurer seuils de régression (10% max)
3. Documenter hot paths identifiés
4. Créer rapport d'optimisation si nécessaire
