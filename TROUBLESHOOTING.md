# Troubleshooting Guide

## Common Issues

### Services Won't Start

**Problem:** `docker-compose up -d` fails

**Solutions:**
```bash
# Check Docker is running
docker info

# Check ports are free
lsof -i :8001,8002,8003,5000

# View detailed errors
docker-compose logs
```

### Model File Not Found

**Problem:** ML service can't load model

**Solution:**
```bash
# Pull models from DVC
dvc pull

# Or regenerate dummy model
python scripts/setup/init_project.sh
```

... (more issues)