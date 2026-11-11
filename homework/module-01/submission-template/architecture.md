# Module 1: E-commerce Chat Agent System Architecture

**Student:** [Your name / GitHub nickname]
**Date:** [submission date]
**Branch:** module-1-setup / [your other branch]

## 1. General architecture overview (at the end of module 1)

At this stage, the system consists of the following main components:

- **Frontend / User interface**
Streamlit application (`src/app.py`) — a simple chat interface for entering requests.

- **Data**
Synthetic product dataset generated using `scripts/data/generate_ecommerce_data.py`.
Main files:
- `data/products.csv` / `products.parquet` — product catalog
- `data/reviews.csv` — reviews
- `data/user_queries.csv` — query examples
- `data/interactions.csv` — user interactions

- **Agent logic**
So far — basic keyword search by product names, descriptions and categories (without LLM and RAG).
Implemented in `src/app.py`.

- **Infrastructure**
- Docker + docker-compose.yml — for containerization
- Local launch or in a container (port 8501)

