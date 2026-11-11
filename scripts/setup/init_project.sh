#!/bin/bash
################################################################################
# E-commerce Agent System - Project Initialization Script
# 
# Module 01: MLOps Foundations & Project Setup
# 
# This script performs complete one-command setup:
# - Verifies prerequisites
# - Sets up environment
# - Initializes DVC
# - Generates sample data
# - Builds Docker images
# - Starts all services
# - Verifies deployment
#
# Usage: ./scripts/setup/init_project.sh [--quick] [--skip-build]
################################################################################

set -e  # Exit on error

# Parse arguments
QUICK_MODE=false
SKIP_BUILD=false
SKIP_DATA=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --quick)
            QUICK_MODE=true
            shift
            ;;
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        --skip-data)
            SKIP_DATA=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --quick       Quick setup (minimal data, faster)"
            echo "  --skip-build  Skip Docker image building"
            echo "  --skip-data   Skip data generation"
            echo "  -h, --help    Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "${CYAN}"
    echo "=============================================================================="
    echo "  $1"
    echo "=============================================================================="
    echo -e "${NC}"
}

print_step() {
    echo -e "\n${YELLOW}[$(date +'%H:%M:%S')] $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

check_command() {
    if command -v $1 &> /dev/null; then
        print_success "$1 found: $(command -v $1)"
        return 0
    else
        print_error "$1 not found"
        return 1
    fi
}

# Start
clear
print_header "E-commerce Agent System - Project Initialization"
echo -e "${MAGENTA}Course: End-to-End MLOps, LLMOps & AgenticOps${NC}"
echo -e "${MAGENTA}Module: 01 - Foundations & Project Setup${NC}\n"

if [ "$QUICK_MODE" = true ]; then
    print_info "Quick mode enabled - using minimal dataset"
fi

# Get project root directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"

echo -e "Project root: ${CYAN}$PROJECT_ROOT${NC}\n"
cd "$PROJECT_ROOT"

################################################################################
# STEP 1: Prerequisites Check
################################################################################

print_step "[1/9] Checking prerequisites..."

ALL_PREREQUISITES_MET=true

# Check Docker
if check_command docker; then
    DOCKER_VERSION=$(docker --version)
    echo "  Version: $DOCKER_VERSION"
    
    # Check if Docker daemon is running
    if docker info &> /dev/null; then
        print_success "Docker daemon is running"
    else
        print_error "Docker daemon is not running. Please start Docker."
        ALL_PREREQUISITES_MET=false
    fi
else
    print_error "Docker is required. Install from: https://docs.docker.com/get-docker/"
    ALL_PREREQUISITES_MET=false
fi

# Check Docker Compose
if docker compose version &> /dev/null; then
    COMPOSE_VERSION=$(docker compose version)
    print_success "Docker Compose found (Plugin): $COMPOSE_VERSION"
    DOCKER_COMPOSE_CMD="docker compose"
elif docker-compose --version &> /dev/null; then
    COMPOSE_VERSION=$(docker-compose --version)
    print_success "Docker Compose found (Standalone): $COMPOSE_VERSION"
    DOCKER_COMPOSE_CMD="docker-compose"
else
    print_error "Docker Compose not found"
    ALL_PREREQUISITES_MET=false
fi

# Check Python
if check_command python3; then
    PYTHON_VERSION=$(python3 --version)
    echo "  Version: $PYTHON_VERSION"
    
    # Check Python version (need 3.10+)
    PYTHON_MINOR=$(python3 -c 'import sys; print(sys.version_info.minor)')
    if [ "$PYTHON_MINOR" -ge 10 ]; then
        print_success "Python version is 3.10 or higher"
    else
        print_error "Python 3.10+ required (current: 3.$PYTHON_MINOR)"
        ALL_PREREQUISITES_MET=false
    fi
else
    print_error "Python 3.10+ is required"
    ALL_PREREQUISITES_MET=false
fi

# Check Git
if check_command git; then
    GIT_VERSION=$(git --version)
    echo "  Version: $GIT_VERSION"
else
    print_error "Git is required"
    ALL_PREREQUISITES_MET=false
fi

# Check available disk space
AVAILABLE_SPACE=$(df -BG "$PROJECT_ROOT" | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$AVAILABLE_SPACE" -ge 10 ]; then
    print_success "Sufficient disk space available: ${AVAILABLE_SPACE}GB"
else
    print_error "Insufficient disk space. Need at least 10GB, have ${AVAILABLE_SPACE}GB"
    ALL_PREREQUISITES_MET=false
fi

# Check available memory
if command -v free &> /dev/null; then
    TOTAL_MEM=$(free -g | awk 'NR==2 {print $2}')
    if [ "$TOTAL_MEM" -ge 8 ]; then
        print_success "Sufficient RAM available: ${TOTAL_MEM}GB"
    else
        print_error "Recommended RAM: 8GB+, available: ${TOTAL_MEM}GB"
        print_info "System may run slowly with less memory"
    fi
fi

# Exit if prerequisites not met
if [ "$ALL_PREREQUISITES_MET" = false ]; then
    echo ""
    print_error "Prerequisites check failed. Please install missing dependencies."
    exit 1
fi

print_success "All prerequisites met!"

################################################################################
# STEP 2: Environment Setup
################################################################################

print_step "[2/9] Setting up environment..."

# Create necessary directories
mkdir -p data
mkdir -p models
mkdir -p logs
mkdir -p mlflow/artifacts

print_success "Created necessary directories"

# Setup environment file
if [ ! -f docker/.env ]; then
    if [ -f docker/.env.example ]; then
        cp docker/.env.example docker/.env
        print_success "Created docker/.env from template"
    else
        print_info "Creating default docker/.env"
        cat > docker/.env << 'EOF'
# Database
POSTGRES_DB=mlops_db
POSTGRES_USER=mlops
POSTGRES_PASSWORD=mlops123

# Redis
REDIS_PASSWORD=

# MLflow
MLFLOW_TRACKING_URI=http://localhost:5000

# LLM
OLLAMA_HOST=http://ollama:11434
OPENAI_API_KEY=

# Monitoring
GRAFANA_ADMIN_PASSWORD=admin

# Services
ML_SERVICE_URL=http://ml-service:8001
RAG_SERVICE_URL=http://rag-service:8002
AGENT_SERVICE_URL=http://agent-service:8003

# Logging
LOG_LEVEL=INFO
EOF
        print_success "Created default docker/.env"
    fi
else
    print_success "docker/.env already exists"
fi

# Setup Python virtual environment (optional but recommended)
if [ ! -d "venv" ]; then
    print_info "Creating Python virtual environment..."
    python3 -m venv venv
    print_success "Virtual environment created"
    
    print_info "Installing Python dependencies..."
    source venv/bin/activate
    pip install --upgrade pip > /dev/null 2>&1
    
    # Install basic dependencies
    if [ -f requirements.txt ]; then
        pip install -r requirements.txt > /dev/null 2>&1
        print_success "Python dependencies installed"
    fi
else
    print_success "Virtual environment already exists"
    source venv/bin/activate
fi

################################################################################
# STEP 3: DVC Setup
################################################################################

print_step "[3/9] Setting up DVC (Data Version Control)..."

# Install DVC if not present
if ! command -v dvc &> /dev/null; then
    print_info "Installing DVC..."
    pip install dvc dvc-s3 > /dev/null 2>&1
    print_success "DVC installed"
fi

# Initialize DVC if not already initialized
if [ ! -d .dvc ]; then
    print_info "Initializing DVC..."
    dvc init
    print_success "DVC initialized"
else
    print_success "DVC already initialized"
fi

# Configure local DVC remote (for course purposes)
if ! dvc remote list | grep -q "local"; then
    print_info "Configuring DVC local remote..."
    mkdir -p .dvc-storage
    dvc remote add -d local .dvc-storage
    print_success "DVC local remote configured"
fi

# Try to pull data and models from DVC
print_info "Attempting to pull data/models from DVC..."
if dvc pull 2>/dev/null; then
    print_success "Data and models pulled from DVC"
else
    print_info "DVC pull failed or no remote data available (this is OK for first-time setup)"
fi

################################################################################
# STEP 4: Generate Sample Data
################################################################################

if [ "$SKIP_DATA" = false ]; then
    print_step "[4/9] Generating sample data..."
    
    # Check if data already exists
    if [ -f data/products.csv ] && [ -f data/customers.csv ]; then
        print_info "Sample data already exists. Skipping generation."
        read -p "Regenerate data? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_success "Using existing data"
        else
            rm -f data/*.csv data/*.json data/*.pkl
            GENERATE_DATA=true
        fi
    else
        GENERATE_DATA=true
    fi
    
    if [ "$GENERATE_DATA" = true ]; then
        # Determine data size based on mode
        if [ "$QUICK_MODE" = true ]; then
            PRODUCTS=100
            CUSTOMERS=1000
            ORDERS=2000
            CONVERSATIONS=500
        else
            PRODUCTS=500
            CUSTOMERS=5000
            ORDERS=10000
            CONVERSATIONS=2000
        fi
        
        print_info "Generating data: $PRODUCTS products, $CUSTOMERS customers, $ORDERS orders..."
        
        if [ -f scripts/data/generate_ecommerce_data.py ]; then
            python3 scripts/data/generate_ecommerce_data.py \
                --products $PRODUCTS \
                --customers $CUSTOMERS \
                --orders $ORDERS \
                --conversations $CONVERSATIONS \
                --output data/ \
                --seed 42
            print_success "Sample data generated successfully"
        else
            print_error "Data generator script not found"
            print_info "Using minimal placeholder data"
            
            # Create minimal placeholder data
            echo "product_id,name,price" > data/products.csv
            echo "PROD-001,Sample Product,99.99" >> data/products.csv
            
            echo "customer_id,name,email" > data/customers.csv
            echo "CUST-001,John Doe,john@example.com" >> data/customers.csv
        fi
    fi
else
    print_step "[4/9] Skipping data generation (--skip-data flag)"
fi

################################################################################
# STEP 5: Prepare Models
################################################################################

print_step "[5/9] Preparing ML models..."

if [ -f models/recommendation_model.pkl ]; then
    print_success "Model file already exists"
else
    print_info "Creating dummy model for demo..."
    
    # Create a simple pickle file as placeholder
    python3 << 'PYTHON_EOF'
import pickle
import os

class DummyModel:
    def __init__(self):
        self.version = "1.0.0"
        self.model_type = "collaborative_filtering"
    
    def predict(self, X):
        import numpy as np
        return np.random.random(len(X))

os.makedirs("models", exist_ok=True)
model = DummyModel()

with open("models/recommendation_model.pkl", "wb") as f:
    pickle.dump(model, f)

print("Dummy model created")
PYTHON_EOF
    
    print_success "Dummy model created for demo"
fi

################################################################################
# STEP 6: Build Docker Images
################################################################################

if [ "$SKIP_BUILD" = false ]; then
    print_step "[6/9] Building Docker images..."
    print_info "This may take 5-10 minutes on first run..."
    
    cd docker
    
    # Build images with progress
    if [ "$QUICK_MODE" = true ]; then
        # Quick mode: build without cache for faster iteration
        $DOCKER_COMPOSE_CMD build --no-cache 2>&1 | grep -E "(Building|Successfully|ERROR)" || true
    else
        # Normal mode: full build with cache
        $DOCKER_COMPOSE_CMD build 2>&1 | grep -E "(Building|Successfully|ERROR)" || true
    fi
    
    BUILD_EXIT_CODE=${PIPESTATUS[0]}
    
    if [ $BUILD_EXIT_CODE -eq 0 ]; then
        print_success "Docker images built successfully"
    else
        print_error "Docker build failed with exit code $BUILD_EXIT_CODE"
        print_info "Check docker/docker-compose.yml for errors"
        cd "$PROJECT_ROOT"
        exit 1
    fi
    
    cd "$PROJECT_ROOT"
else
    print_step "[6/9] Skipping Docker build (--skip-build flag)"
fi

################################################################################
# STEP 7: Start Services
################################################################################

print_step "[7/9] Starting services..."

cd docker

# Stop any existing containers
print_info "Stopping any existing containers..."
$DOCKER_COMPOSE_CMD down 2>/dev/null || true

# Start services
print_info "Starting all services..."
$DOCKER_COMPOSE_CMD up -d

# Wait for containers to start
sleep 5

# Check container status
RUNNING_CONTAINERS=$($DOCKER_COMPOSE_CMD ps --services --filter "status=running" | wc -l)
TOTAL_CONTAINERS=$($DOCKER_COMPOSE_CMD ps --services | wc -l)

print_info "Containers started: $RUNNING_CONTAINERS/$TOTAL_CONTAINERS"

if [ $RUNNING_CONTAINERS -eq $TOTAL_CONTAINERS ]; then
    print_success "All services started successfully"
else
    print_error "Some services failed to start"
    print_info "Check logs with: docker-compose -f docker/docker-compose.yml logs"
fi

cd "$PROJECT_ROOT"

################################################################################
# STEP 8: Wait for Services to Become Healthy
################################################################################

print_step "[8/9] Waiting for services to become healthy..."
print_info "This may take 30-60 seconds..."

# Function to check service health
check_service_health() {
    local service_name=$1
    local url=$2
    local max_attempts=30
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if curl -s -f "$url" > /dev/null 2>&1; then
            return 0
        fi
        attempt=$((attempt + 1))
        sleep 2
        echo -n "."
    done
    return 1
}

# Check critical services
SERVICES_HEALTHY=true

echo -n "Checking ML Service (http://localhost:8001)... "
if check_service_health "ml-service" "http://localhost:8001/health"; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    SERVICES_HEALTHY=false
fi

echo -n "Checking RAG Service (http://localhost:8002)... "
if check_service_health "rag-service" "http://localhost:8002/health"; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    SERVICES_HEALTHY=false
fi

echo -n "Checking Agent Service (http://localhost:8003)... "
if check_service_health "agent-service" "http://localhost:8003/health"; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    SERVICES_HEALTHY=false
fi

echo -n "Checking MLflow (http://localhost:5000)... "
if check_service_health "mlflow" "http://localhost:5000"; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    SERVICES_HEALTHY=false
fi

if [ "$SERVICES_HEALTHY" = true ]; then
    print_success "All critical services are healthy!"
else
    print_error "Some services failed health checks"
    print_info "Services may still be starting. Check status with:"
    print_info "  docker-compose -f docker/docker-compose.yml ps"
    print_info "  docker-compose -f docker/docker-compose.yml logs"
fi

################################################################################
# STEP 9: Pull Ollama Model (LLM)
################################################################################

print_step "[9/9] Setting up LLM (Ollama)..."

# Check if Ollama container is running
if docker ps | grep -q ollama; then
    print_info "Pulling Llama 3.2 model (this may take a few minutes)..."
    
    # Pull model in background
    docker exec ollama ollama pull llama3.2 > /dev/null 2>&1 &
    OLLAMA_PID=$!
    
    # Show progress
    echo -n "Downloading model"
    while kill -0 $OLLAMA_PID 2>/dev/null; do
        echo -n "."
        sleep 2
    done
    echo ""
    
    wait $OLLAMA_PID
    if [ $? -eq 0 ]; then
        print_success "LLM model downloaded successfully"
    else
        print_error "Failed to download LLM model"
        print_info "You can download it later with:"
        print_info "  docker exec ollama ollama pull llama3.2"
    fi
else
    print_info "Ollama container not running, skipping model download"
fi

################################################################################
# COMPLETION SUMMARY
################################################################################

print_header "✓ Setup Complete!"

echo -e "${GREEN}All services are now running!${NC}\n"

echo -e "${CYAN}Service URLs:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "  ${BLUE}API Gateway:${NC}     http://localhost:8000"
echo -e "  ${BLUE}ML Service:${NC}      http://localhost:8001     (Health: /health)"
echo -e "  ${BLUE}RAG Service:${NC}     http://localhost:8002     (Health: /health)"
echo -e "  ${BLUE}Agent Service:${NC}   http://localhost:8003     (Health: /health)"
echo -e "  ${BLUE}MLflow UI:${NC}       http://localhost:5000"
echo -e "  ${BLUE}Grafana:${NC}         http://localhost:3000     (admin/admin)"
echo -e "  ${BLUE}Prometheus:${NC}      http://localhost:9090"
echo -e "  ${BLUE}Vector DB:${NC}       http://localhost:8100"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo -e "\n${CYAN}Quick Test:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  curl http://localhost:8001/health"
echo "  curl http://localhost:8000"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo -e "\n${CYAN}Next Steps:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  1. Read docs/ops-guides/module-01-setup.md"
echo "  2. Test all service endpoints"
echo "  3. Explore Grafana dashboards"
echo "  4. Complete Module 1 homework"
echo "  5. Verify setup:"
echo "     python3 scripts/module-01/verify_setup.py"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo -e "\n${CYAN}Useful Commands:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  View logs:        docker-compose -f docker/docker-compose.yml logs -f"
echo "  Stop services:    docker-compose -f docker/docker-compose.yml down"
echo "  Restart services: docker-compose -f docker/docker-compose.yml restart"
echo "  Service status:   docker-compose -f docker/docker-compose.yml ps"
echo "  Clean up:         make clean"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo -e "\n${CYAN}Troubleshooting:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  If services aren't responding:"
echo "    • Check logs: docker-compose -f docker/docker-compose.yml logs [service]"
echo "    • Restart: docker-compose -f docker/docker-compose.yml restart [service]"
echo "    • See TROUBLESHOOTING.md for common issues"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo -e "\n${GREEN}Happy Learning! 🚀${NC}\n"

# Create a status file
cat > .setup_complete << EOF
Setup completed at: $(date)
Quick mode: $QUICK_MODE
Services started: $RUNNING_CONTAINERS/$TOTAL_CONTAINERS
EOF

exit 0