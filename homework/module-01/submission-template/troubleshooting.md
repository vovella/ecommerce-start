# Troubleshooting — Module 1

## Typical errors and their solutions

### 1. FileNotFoundError: products.csv / products.json
**Symptom:** the application says "Data not found" or crashes while reading the file.

**Solution:**
- Run the generator again:
```bash
python scripts/data/generate_ecommerce_data.py

Check if the files appeared in data/:Bashls -la data/
In docker-compose.yml check volume:YAMLvolumes:
- ./data:/app/data
Restart: docker compose down && docker compose up --build

2. docker compose up gives the error "No such file or directory"
Solution:

Check for docker-compose.yml and Dockerfile
If compose is empty — copy the minimal version from README or from the example above
If Dockerfile is missing — create it (example in README)

3. Streamlit starts, but shows 0 products
Solution:

Check the debug information on the page (if you added debug code)
Make sure that the path in the code is /app/data/products.csv or data/products.csv
Regenerate data with --output data flag
Check file size: ls -lh data/products.csv — if 0 bytes, run generator again

4. ModuleNotFoundError error (e.g. sentence_transformers)
Solution:

If you use embeddings — install the package: Bashpip install sentence-transformers

If you don't want heavy dependencies — use the generator version without embeddings

5. Container doesn't see changes in code/data
Solution:

Make sure volume mounts the folder with the code: YAMLvolumes:
- .:/app
Use --build when starting: Bashdocker compose up --build

6. Other problems

Restart Docker Desktop
Clear cache: docker compose down --volumes --remove-orphans
Check logs: docker compose logs -f

If something doesn't work — create an issue in the repository with the full text of the error and screenshots.
