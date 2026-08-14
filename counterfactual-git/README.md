# Counterfactual Git

`counterfactual-git` is a dependency-free Rust program that generates impossible historical events, commits them to an in-memory universe, and rejects changes that violate its extremely selective causality policy.

```bash
cargo run --release -- --seed 1982 --events 20
cargo test
```

The output resembles a Git log from a historical repository administered by an ontological zoning committee. A seed is deterministic, rejected events remain visible in the audit history, and `HEAD` advances only when causality reluctantly accepts a commit.

The crate uses Rust 2024 and no external dependencies. Release builds enable LTO, symbol stripping, a single code-generation unit, and abort-on-panic.
