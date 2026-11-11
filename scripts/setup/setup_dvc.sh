#!/bin/bash
################################################################################
# DVC (Data Version Control) Setup Script
# 
# Module 02: Version Control (Git + DVC)
# 
# This script:
# - Installs DVC if not present
# - Initializes DVC in the project
# - Configures remote storage (local/S3/GCS/Azure)
# - Sets up .gitignore patterns
# - Tracks models and data files
# - Demonstrates basic DVC workflows
#
# Usage: 
#   ./scripts/setup/setup_dvc.sh [--remote-type TYPE] [--remote-url URL]
#
# Remote types: local, s3, gs, azure, ssh
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Default values
REMOTE_TYPE="local"
REMOTE_URL=""
REMOTE_NAME="storage"
AUTO_TRACK=true
SKIP_INSTALL=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --remote-type)
            REMOTE_TYPE="$2"
            shift 2
            ;;
        --remote-url)
            REMOTE_URL="$2"
            shift 2
            ;;
        --remote-name)
            REMOTE_NAME="$2"
            shift 2
            ;;
        --skip-install)
            SKIP_INSTALL=true
            shift
            ;;
        --no-auto-track)
            AUTO_TRACK=false
            shift
            ;;
        -h|--help)
            cat << 'EOF'
DVC Setup Script

Usage: ./scripts/setup/setup_dvc.sh [OPTIONS]

Options:
  --remote-type TYPE      Remote storage type (local, s3, gs, azure, ssh)
                          Default: local
  
  --remote-url URL        Remote storage URL
                          Examples:
                            local:  /path/to/storage
                            s3:     s3://my-bucket/dvc-storage
                            gs:     gs://my-bucket/dvc-storage
                            azure:  azure://container/path
  
  --remote-name NAME      Remote storage name (default: storage)
  
  --skip-install          Skip DVC installation
  
  --no-auto-track         Don't automatically track models/data
  
  -h, --help             Show this help message

Examples:
  # Local storage (default)
  ./scripts/setup/setup_dvc.sh
  
  # AWS S3 storage
  ./scripts/setup/setup_dvc.sh --remote-type s3 --remote-url s3://my-bucket/dvc
  
  # Google Cloud Storage
  ./scripts/setup/setup_dvc.sh --remote-type gs --remote-url gs://my-bucket/dvc
  
  # Custom local path
  ./scripts/setup/setup_dvc.sh --remote-type local --remote-url /mnt/storage/dvc

For course purposes, default local storage is recommended.
EOF
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Functions
print_header() {
    echo -e "\n${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}\n"
}

print_step() {
    echo -e "${YELLOW}▶ $1${NC}"
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

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Get project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"

cd "$PROJECT_ROOT"

print_header "DVC Setup for MLOps Course"

echo -e "Project root: ${CYAN}$PROJECT_ROOT${NC}"
echo -e "Remote type:  ${CYAN}$REMOTE_TYPE${NC}"

################################################################################
# STEP 1: Install DVC
################################################################################

print_step "Step 1: Installing DVC"

if [ "$SKIP_INSTALL" = true ]; then
    print_info "Skipping DVC installation (--skip-install flag)"
elif command -v dvc &> /dev/null; then
    DVC_VERSION=$(dvc version)
    print_success "DVC already installed: $DVC_VERSION"
else
    print_info "Installing DVC..."
    
    # Detect Python package manager
    if command -v pip3 &> /dev/null; then
        PIP_CMD="pip3"
    elif command -v pip &> /dev/null; then
        PIP_CMD="pip"
    else
        print_error "pip not found. Please install Python pip first."
        exit 1
    fi
    
    # Install DVC with appropriate extras based on remote type
    case $REMOTE_TYPE in
        s3)
            print_info "Installing DVC with S3 support..."
            $PIP_CMD install -q "dvc[s3]"
            ;;
        gs)
            print_info "Installing DVC with Google Cloud Storage support..."
            $PIP_CMD install -q "dvc[gs]"
            ;;
        azure)
            print_info "Installing DVC with Azure support..."
            $PIP_CMD install -q "dvc[azure]"
            ;;
        ssh)
            print_info "Installing DVC with SSH support..."
            $PIP_CMD install -q "dvc[ssh]"
            ;;
        *)
            print_info "Installing DVC (basic)..."
            $PIP_CMD install -q dvc
            ;;
    esac
    
    if command -v dvc &> /dev/null; then
        DVC_VERSION=$(dvc version)
        print_success "DVC installed successfully: $DVC_VERSION"
    else
        print_error "DVC installation failed"
        exit 1
    fi
fi

################################################################################
# STEP 2: Initialize DVC
################################################################################

print_step "Step 2: Initializing DVC"

if [ -d .dvc ]; then
    print_success "DVC already initialized"
    
    # Check if git is initialized
    if [ ! -d .git ]; then
        print_warning "Git not initialized. DVC works best with Git."
        read -p "Initialize Git repository? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git init
            print_success "Git repository initialized"
        fi
    fi
else
    # Check if git is initialized first
    if [ ! -d .git ]; then
        print_warning "Git not initialized. Initializing Git first..."
        git init
        print_success "Git repository initialized"
    fi
    
    print_info "Initializing DVC..."
    dvc init
    
    # Commit DVC initialization
    git add .dvc .dvcignore
    git commit -m "Initialize DVC" 2>/dev/null || print_info "DVC files already committed"
    
    print_success "DVC initialized successfully"
fi

################################################################################
# STEP 3: Configure Remote Storage
################################################################################

print_step "Step 3: Configuring remote storage"

# Determine remote URL
if [ -z "$REMOTE_URL" ]; then
    case $REMOTE_TYPE in
        local)
            REMOTE_URL="$PROJECT_ROOT/.dvc-storage"
            print_info "Using default local storage: $REMOTE_URL"
            ;;
        s3|gs|azure)
            print_error "Remote URL required for $REMOTE_TYPE storage"
            print_info "Use: --remote-url <url>"
            exit 1
            ;;
    esac
fi

# Create local storage directory if needed
if [ "$REMOTE_TYPE" = "local" ]; then
    mkdir -p "$REMOTE_URL"
    print_success "Created local storage directory: $REMOTE_URL"
fi

# Check if remote already exists
if dvc remote list | grep -q "^$REMOTE_NAME"; then
    print_warning "Remote '$REMOTE_NAME' already exists"
    
    # Show current config
    CURRENT_URL=$(dvc remote list | grep "^$REMOTE_NAME" | awk '{print $2}')
    print_info "Current URL: $CURRENT_URL"
    
    read -p "Update remote URL? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        dvc remote modify "$REMOTE_NAME" url "$REMOTE_URL"
        print_success "Remote URL updated"
    else
        print_info "Keeping existing remote configuration"
    fi
else
    # Add new remote
    print_info "Adding remote '$REMOTE_NAME'..."
    dvc remote add -d "$REMOTE_NAME" "$REMOTE_URL"
    
    print_success "Remote storage configured: $REMOTE_NAME"
fi

# Configure remote-specific settings
case $REMOTE_TYPE in
    s3)
        print_info "Configuring S3 settings..."
        
        # Check for AWS credentials
        if [ -z "$AWS_ACCESS_KEY_ID" ] && [ -z "$AWS_PROFILE" ]; then
            print_warning "AWS credentials not detected"
            print_info "Set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY, or configure AWS_PROFILE"
        else
            print_success "AWS credentials detected"
        fi
        
        # Optional: configure region
        read -p "AWS region (default: us-east-1): " AWS_REGION
        AWS_REGION=${AWS_REGION:-us-east-1}
        dvc remote modify "$REMOTE_NAME" region "$AWS_REGION"
        print_success "S3 region set to: $AWS_REGION"
        ;;
        
    gs)
        print_info "Configuring Google Cloud Storage settings..."
        
        if [ -z "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
            print_warning "GOOGLE_APPLICATION_CREDENTIALS not set"
            print_info "Set this environment variable to your service account key JSON file"
        else
            print_success "GCS credentials detected"
        fi
        ;;
        
    azure)
        print_info "Configuring Azure Blob Storage settings..."
        
        if [ -z "$AZURE_STORAGE_CONNECTION_STRING" ] && [ -z "$AZURE_STORAGE_ACCOUNT" ]; then
            print_warning "Azure credentials not detected"
            print_info "Set AZURE_STORAGE_CONNECTION_STRING or AZURE_STORAGE_ACCOUNT"
        else
            print_success "Azure credentials detected"
        fi
        ;;
esac

# Commit remote configuration
git add .dvc/config
git commit -m "Configure DVC remote: $REMOTE_NAME ($REMOTE_TYPE)" 2>/dev/null || print_info "DVC config already committed"

################################################################################
# STEP 4: Setup .dvcignore
################################################################################

print_step "Step 4: Configuring .dvcignore"

if [ -f .dvcignore ]; then
    print_success ".dvcignore already exists"
else
    print_info "Creating .dvcignore..."
    
    cat > .dvcignore << 'EOF'
# DVC ignore file
# Add patterns of files that DVC should ignore

# Python cache
__pycache__/
*.pyc
*.pyo

# Jupyter checkpoints
.ipynb_checkpoints/

# Temporary files
*.tmp
*.temp
.DS_Store
Thumbs.db

# Logs
*.log

# IDE files
.vscode/
.idea/
EOF
    
    print_success ".dvcignore created"
fi

################################################################################
# STEP 5: Setup .gitignore for DVC
################################################################################

print_step "Step 5: Updating .gitignore for DVC"

# DVC-specific gitignore patterns
DVC_GITIGNORE_PATTERNS=(
    "/models/*.pkl"
    "/models/*.h5"
    "/models/*.pth"
    "/data/*.csv"
    "/data/*.json"
    "/data/*.pkl"
    "/data/*.parquet"
)

if [ -f .gitignore ]; then
    print_info "Updating existing .gitignore..."
    
    # Add DVC patterns if not present
    for pattern in "${DVC_GITIGNORE_PATTERNS[@]}"; do
        if ! grep -qF "$pattern" .gitignore; then
            echo "$pattern" >> .gitignore
        fi
    done
    
    print_success ".gitignore updated with DVC patterns"
else
    print_info "Creating .gitignore..."
    
    cat > .gitignore << 'EOF'
# DVC tracked files
/models/*.pkl
/models/*.h5
/models/*.pth
/data/*.csv
/data/*.json
/data/*.pkl
/data/*.parquet

# Python
__pycache__/
*.py[cod]
*$py.class
venv/
env/

# IDE
.vscode/
.idea/
*.swp

# OS
.DS_Store
Thumbs.db

# Logs
*.log
EOF
    
    print_success ".gitignore created"
fi

git add .gitignore
git commit -m "Update .gitignore for DVC" 2>/dev/null || print_info ".gitignore already committed"

################################################################################
# STEP 6: Track Models and Data (if enabled)
################################################################################

if [ "$AUTO_TRACK" = true ]; then
    print_step "Step 6: Tracking models and data with DVC"
    
    # Track models directory
    if [ -d models ] && [ -n "$(ls -A models 2>/dev/null)" ]; then
        print_info "Tracking models directory..."
        
        # Track individual model files
        for model_file in models/*.pkl models/*.h5 models/*.pth 2>/dev/null; do
            if [ -f "$model_file" ]; then
                if [ ! -f "${model_file}.dvc" ]; then
                    print_info "Tracking: $model_file"
                    dvc add "$model_file"
                    
                    # Commit .dvc file
                    git add "${model_file}.dvc" .gitignore
                    git commit -m "Track $model_file with DVC" 2>/dev/null || true
                else
                    print_success "Already tracked: $model_file"
                fi
            fi
        done
    else
        print_warning "No models found in models/ directory"
        print_info "Add models later with: dvc add models/your_model.pkl"
    fi
    
    # Track data directory (selective)
    if [ -d data ] && [ -n "$(ls -A data 2>/dev/null)" ]; then
        print_info "Tracking data files..."
        
        # Track large data files
        for data_file in data/*.csv data/*.json data/*.pkl data/*.parquet 2>/dev/null; do
            if [ -f "$data_file" ]; then
                # Check file size (track if > 1MB)
                FILE_SIZE=$(stat -f%z "$data_file" 2>/dev/null || stat -c%s "$data_file" 2>/dev/null)
                if [ "$FILE_SIZE" -gt 1048576 ]; then  # 1MB
                    if [ ! -f "${data_file}.dvc" ]; then
                        print_info "Tracking: $data_file ($(numfmt --to=iec-i --suffix=B $FILE_SIZE 2>/dev/null || echo ${FILE_SIZE}B))"
                        dvc add "$data_file"
                        
                        git add "${data_file}.dvc" .gitignore
                        git commit -m "Track $data_file with DVC" 2>/dev/null || true
                    else
                        print_success "Already tracked: $data_file"
                    fi
                fi
            fi
        done
    else
        print_warning "No data files found in data/ directory"
        print_info "Add data later with: dvc add data/your_data.csv"
    fi
    
else
    print_step "Step 6: Skipping auto-tracking (--no-auto-track flag)"
    print_info "Track files manually with:"
    print_info "  dvc add models/your_model.pkl"
    print_info "  dvc add data/your_data.csv"
fi

################################################################################
# STEP 7: Create DVC Pipeline Template (optional)
################################################################################

print_step "Step 7: Creating DVC pipeline template"

if [ -f dvc.yaml ]; then
    print_success "dvc.yaml already exists"
else
    print_info "Creating template dvc.yaml..."
    
    cat > dvc.yaml << 'EOF'
# DVC Pipeline Configuration
# Module 04: Orchestration Pipelines
# 
# This file will be populated in Module 04 with:
# - Data preparation stage
# - Training stage  
# - Evaluation stage
# - Model registration stage
#
# For now, this is a placeholder.
# Learn more: https://dvc.org/doc/user-guide/pipelines

stages:
  # Example stage (will be replaced in Module 04)
  # prepare_data:
  #   cmd: python scripts/prepare_data.py
  #   deps:
  #     - data/raw/
  #   outs:
  #     - data/processed/
  
  # train_model:
  #   cmd: python scripts/train.py
  #   deps:
  #     - data/processed/
  #     - scripts/train.py
  #   params:
  #     - train.learning_rate
  #     - train.epochs
  #   outs:
  #     - models/model.pkl
  #   metrics:
  #     - metrics/train_metrics.json
EOF
    
    git add dvc.yaml
    git commit -m "Add DVC pipeline template" 2>/dev/null || print_info "dvc.yaml already committed"
    
    print_success "DVC pipeline template created"
fi

################################################################################
# STEP 8: Create params.yaml Template
################################################################################

print_step "Step 8: Creating params.yaml template"

if [ -f params.yaml ]; then
    print_success "params.yaml already exists"
else
    print_info "Creating template params.yaml..."
    
    cat > params.yaml << 'EOF'
# DVC Parameters File
# Module 04: Orchestration Pipelines
#
# Store hyperparameters and configuration here
# DVC tracks changes to these parameters

train:
  learning_rate: 0.001
  epochs: 10
  batch_size: 32
  test_split: 0.2
  random_seed: 42

model:
  type: "collaborative_filtering"
  n_factors: 50
  regularization: 0.01

data:
  min_interactions: 5
  max_products: 1000
EOF
    
    git add params.yaml
    git commit -m "Add DVC parameters template" 2>/dev/null || print_info "params.yaml already committed"
    
    print_success "Parameters template created"
fi

################################################################################
# STEP 9: Push to Remote (if data exists)
################################################################################

print_step "Step 9: Pushing data to remote storage"

# Check if there are any .dvc files
if ls *.dvc models/*.dvc data/*.dvc 2>/dev/null | grep -q .; then
    print_info "Pushing tracked files to remote storage..."
    
    if dvc push; then
        print_success "Data pushed to remote storage successfully"
    else
        print_warning "DVC push failed or no new data to push"
        print_info "This is normal if remote is not configured or data already exists"
    fi
else
    print_info "No tracked files to push yet"
    print_info "Track files with: dvc add <file>"
fi

################################################################################
# COMPLETION SUMMARY
################################################################################

print_header "✓ DVC Setup Complete!"

echo -e "${GREEN}DVC is now configured and ready to use!${NC}\n"

echo -e "${CYAN}Configuration Summary:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "  Remote name:  ${BLUE}$REMOTE_NAME${NC}"
echo -e "  Remote type:  ${BLUE}$REMOTE_TYPE${NC}"
echo -e "  Remote URL:   ${BLUE}$REMOTE_URL${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo -e "\n${CYAN}Common DVC Commands:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Track a file:          dvc add data/myfile.csv"
echo "  Push to remote:        dvc push"
echo "  Pull from remote:      dvc pull"
echo "  Check status:          dvc status"
echo "  List tracked files:    dvc list . --dvc-only"
echo "  Show file info:        dvc list . data/ --dvc-only"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo -e "\n${CYAN}Git Integration:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  After 'dvc add':"
echo "    1. git add <file>.dvc .gitignore"
echo "    2. git commit -m 'Track <file> with DVC'"
echo "    3. dvc push"
echo "    4. git push"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo -e "\n${CYAN}Example Workflow:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cat << 'EOF'
  # Track a new model
  dvc add models/model_v2.pkl
  git add models/model_v2.pkl.dvc .gitignore
  git commit -m "Add model v2"
  dvc push
  git push

  # Teammate pulls the model
  git pull
  dvc pull

  # Switch to different model version
  git checkout <commit-with-model-v1>
  dvc checkout
EOF
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo -e "\n${CYAN}Next Steps:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  1. Read docs/ops-guides/module-02-version-control.md"
echo "  2. Track your models: dvc add models/*.pkl"
echo "  3. Track your data: dvc add data/*.csv"
echo "  4. Push to remote: dvc push"
echo "  5. Commit .dvc files: git add *.dvc && git commit"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo -e "\n${CYAN}Documentation:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  DVC Docs:        https://dvc.org/doc"
echo "  Course Guide:    docs/ops-guides/module-02-version-control.md"
echo "  Troubleshooting: TROUBLESHOOTING.md"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Create completion marker
cat > .dvc_setup_complete << EOF
DVC setup completed at: $(date)
Remote type: $REMOTE_TYPE
Remote name: $REMOTE_NAME
Remote URL: $REMOTE_URL
EOF

echo -e "\n${GREEN}DVC is ready for Module 02! 🚀${NC}\n"

exit 0