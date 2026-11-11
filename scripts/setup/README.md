```bash
./scripts/setup/init_project.sh              # full setup
```
```bash
./scripts/setup/init_project.sh --quick      # quickly 
```
```bash
./scripts/setup/init_project.sh --skip-build # No Docker build
```
```bash
./scripts/setup/init_project.sh --skip-data  # No data generation
```
```bash
./scripts/setup/init_project.sh --help       # Help
```

✅ **Color output:**
- 🔵 Info messages
- 🟢 Success messages
- 🟡 Step indicators
- 🔴 Error messages

✅ **Smart checks:**
- Is Docker running
- Is Python 3.10+
- Is there enough disk space (10GB+)
- Is there enough RAM (8GB+)

✅ **Graceful failures:**
- If a step falls - clear messages
- Suggestions on how to fix it
- Exit codes для automation

✅ **Progress tracking:**
- Dots для довгих операцій
- Timestamps для кожного кроку
- Clear summary в кінці

✅ **Service health checks:**
- Автоматична перевірка доступності
- Retry logic з timeout
- Clear status для кожного сервісу

## 📋 Приклад виводу:
```
==============================================================================
  E-commerce Agent System - Project Initialization
==============================================================================

Course: End-to-End MLOps, LLMOps & AgenticOps

Module: 01 - Foundations & Project Setup

[10:30:15] [1/9] Checking prerequisites...
✓ docker found: /usr/local/bin/docker
  Version: Docker version 24.0.6
✓ Docker daemon is running
✓ Docker Compose found (Plugin): v2.21.0
✓ python3 found: /usr/bin/python3
  Version: Python 3.10.12
✓ git found: /usr/bin/git
✓ Sufficient disk space available: 45GB
✓ All prerequisites met!

[10:30:22] [2/9] Setting up environment...
✓ Created necessary directories
✓ Created docker/.env from template
✓ Virtual environment created
✓ Python dependencies installed

...

==============================================================================
  ✓ Setup Complete!
==============================================================================

All services are now running!

Service URLs:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  Agent Service:   http://localhost:8501     (Health: /health)
    
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Happy Learning! 🚀
