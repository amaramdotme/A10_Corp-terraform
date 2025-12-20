#!/bin/bash
# ============================================================
# Terraform Deployment Helper Script
# ============================================================
# Simplifies deployment of foundation and workloads modules
#
# Usage:
#   ./init-plan-apply.sh --foundation [init|plan|apply|destroy]
#   ./init-plan-apply.sh --workloads --env [dev|stage|prod] [init|plan|apply|destroy]
#
# Examples:
#   ./init-plan-apply.sh --foundation init
#   ./init-plan-apply.sh --foundation plan
#   ./init-plan-apply.sh --foundation apply
#   ./init-plan-apply.sh --workloads --env dev init
#   ./init-plan-apply.sh --workloads --env dev plan
#   ./init-plan-apply.sh --workloads --env prod apply

set -e  # Exit on error

# ============================================================
# Color output
# ============================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================
# Helper functions
# ============================================================
print_usage() {
    echo -e "${BLUE}Terraform Deployment Helper${NC}"
    echo ""
    echo "Usage:"
    echo "  $0 --foundation [init|plan|apply|destroy]"
    echo "  $0 --workloads --env [dev|stage|prod] [init|plan|apply|destroy]"
    echo ""
    echo "Examples:"
    echo -e "  ${GREEN}$0 --foundation init${NC}        # Initialize foundation"
    echo -e "  ${GREEN}$0 --foundation plan${NC}        # Plan foundation deployment"
    echo -e "  ${GREEN}$0 --foundation apply${NC}       # Deploy foundation"
    echo ""
    echo -e "  ${GREEN}$0 --workloads --env dev init${NC}   # Initialize workloads for dev"
    echo -e "  ${GREEN}$0 --workloads --env dev plan${NC}   # Plan workloads dev deployment"
    echo -e "  ${GREEN}$0 --workloads --env prod apply${NC} # Deploy workloads to prod"
    echo ""
}

error_exit() {
    echo -e "${RED}Error: $1${NC}" >&2
    echo ""
    print_usage
    exit 1
}

# ============================================================
# Parse arguments
# ============================================================
MODULE=""
ENVIRONMENT=""
ACTION=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --foundation)
            MODULE="foundation"
            shift
            ;;
        --workloads)
            MODULE="workloads"
            shift
            ;;
        --env)
            ENVIRONMENT="$2"
            shift 2
            ;;
        init|plan|apply|destroy)
            ACTION="$1"
            shift
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            error_exit "Unknown argument: $1"
            ;;
    esac
done

# ============================================================
# Validate arguments
# ============================================================
if [ -z "$MODULE" ]; then
    error_exit "Module not specified. Use --foundation or --workloads"
fi

if [ -z "$ACTION" ]; then
    error_exit "Action not specified. Use: init, plan, apply, or destroy"
fi

if [ "$MODULE" = "workloads" ] && [ -z "$ENVIRONMENT" ]; then
    error_exit "Workloads requires --env [dev|stage|prod]"
fi

if [ "$MODULE" = "foundation" ] && [ -n "$ENVIRONMENT" ]; then
    echo -e "${YELLOW}Warning: Foundation does not use environments. Ignoring --env flag.${NC}"
    ENVIRONMENT=""
fi

if [ -n "$ENVIRONMENT" ] && [ "$ENVIRONMENT" != "dev" ] && [ "$ENVIRONMENT" != "stage" ] && [ "$ENVIRONMENT" != "prod" ]; then
    error_exit "Invalid environment: $ENVIRONMENT. Must be dev, stage, or prod"
fi

# ============================================================
# Check prerequisites
# ============================================================
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}Warning: .env file not found. Make sure Azure credentials are set.${NC}"
    echo "You can create .env from .env.example: cp .env.example .env"
fi

# ============================================================
# Build terraform command
# ============================================================
if [ "$MODULE" = "foundation" ]; then
    WORK_DIR="foundation"
    BACKEND_CONFIG="environments/backend.hcl"
    VAR_FILE=""
    DISPLAY_NAME="Foundation"
else
    WORK_DIR="workloads"
    BACKEND_CONFIG="environments/backend-${ENVIRONMENT}.hcl"
    VAR_FILE="environments/${ENVIRONMENT}.tfvars"
    DISPLAY_NAME="Workloads ($ENVIRONMENT)"
fi

# ============================================================
# Display operation
# ============================================================
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Terraform Deployment${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "Module:      ${GREEN}$DISPLAY_NAME${NC}"
echo -e "Action:      ${GREEN}$ACTION${NC}"
echo -e "Directory:   ${GREEN}$WORK_DIR${NC}"
echo -e "Backend:     ${GREEN}$BACKEND_CONFIG${NC}"
if [ -n "$VAR_FILE" ]; then
    echo -e "Variables:   ${GREEN}$VAR_FILE${NC}"
fi
echo -e "${BLUE}========================================${NC}"
echo ""

# ============================================================
# Change to working directory
# ============================================================
cd "$WORK_DIR" || error_exit "Failed to change to $WORK_DIR directory"

# ============================================================
# Execute terraform command
# ============================================================
case $ACTION in
    init)
        echo -e "${GREEN}Initializing Terraform...${NC}"
        # Dynamically pass backend config from environment variables
        # This allows for easy DR and parallel stack deployments
        terraform init \
            -backend-config="resource_group_name=${TF_VAR_root_resource_group_name}" \
            -backend-config="storage_account_name=${TF_VAR_root_storage_account_name}" \
            -backend-config="$BACKEND_CONFIG"
        ;;
    plan)
        if [ -n "$VAR_FILE" ]; then
            echo -e "${GREEN}Planning deployment...${NC}"
            terraform plan -var-file="$VAR_FILE"
        else
            echo -e "${GREEN}Planning deployment...${NC}"
            terraform plan
        fi
        ;;
    apply)
        if [ -n "$VAR_FILE" ]; then
            echo -e "${GREEN}Applying deployment...${NC}"
            terraform apply -var-file="$VAR_FILE"
        else
            echo -e "${GREEN}Applying deployment...${NC}"
            terraform apply
        fi
        ;;
    destroy)
        echo -e "${RED}WARNING: This will destroy infrastructure!${NC}"
        if [ -n "$VAR_FILE" ]; then
            terraform destroy -var-file="$VAR_FILE"
        else
            terraform destroy
        fi
        ;;
esac

# ============================================================
# Success message
# ============================================================
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Operation completed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
