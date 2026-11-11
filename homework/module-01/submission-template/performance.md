# Module 1: Performance Notes

**Date:** [due date]
**Student:** [your name]

## Performance at the end of module 1

The system is currently very light — no LLM, no vector search, no complex calculations.

### Key metrics (measured manually)

- Streamlit startup time: ~2–4 seconds (local), ~5–10 seconds (first run in Docker)
- Query response time: < 0.1 seconds (keyword search on 500–1000 pandas rows)
- Memory usage (Streamlit + pandas): ~150–300 MB
- Dataset size:
- products.parquet: ~150–300 KB
- products.csv: ~400–800 KB
- all files together: < 5 MB

### Bottlenecks (already noticeable)

- If the number of products grows to 50,000+ — search via `str.contains()` becomes slow (O(n) operation)
- Without indexing or vector search — linear search does not scale
- Docker image (~800 MB–1.2 GB) — can be optimized later multi-stage build

### Optimization Suggestions (for the future)

- Switch to Polars or DuckDB instead of Pandas for faster filtering
- Add FAISS or Chroma for semantic search (module 11)
- Cache data loading (Streamlit @st.cache_data is already used)
- Use lightweight image (python:3.11-slim + multi-stage)

Performance is not an issue at the moment - the system responds instantly.
