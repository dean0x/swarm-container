#!/bin/bash
# Modular postCreate.sh - orchestrates setup modules
# Tracks failures and reports them at the end

# Source logging library if available
LOGGING_LIB="/scripts/lib/logging.sh"
if [ -f "$LOGGING_LIB" ]; then
    # shellcheck source=/dev/null
    source "$LOGGING_LIB"
else
    log_info() { echo "[INFO] $1"; }
    log_warn() { echo "[WARN] $1"; }
    log_error() { echo "[ERROR] $1" >&2; }
fi

echo "Setting up Claude Code development environment..."

# Define the modules directory
# Use absolute path from workspace
MODULES_DIR="/workspace/.devcontainer/scripts/hooks/modules"

# Define required and optional modules
# Required modules: failure causes non-zero exit
# Optional modules: failure is logged but doesn't affect exit code
REQUIRED_MODULES=("init-npm.sh" "init-claude-code.sh")
OPTIONAL_MODULES=("setup-permissions.sh" "setup-npm-permissions.sh" "setup-workspace.sh" "setup-shell.sh")

# Track failures
declare -a FAILED_REQUIRED_MODULES=()
declare -a FAILED_OPTIONAL_MODULES=()

# Function to check if a module is required
is_required_module() {
    local module_name="$1"
    for req_module in "${REQUIRED_MODULES[@]}"; do
        if [[ "$req_module" == "$module_name" ]]; then
            return 0
        fi
    done
    return 1
}

# Function to run a module with error handling
run_module() {
    local module_name=$1
    local module_path="$MODULES_DIR/$module_name"
    local is_required=false

    if is_required_module "$module_name"; then
        is_required=true
    fi

    if [ -f "$module_path" ]; then
        echo ""
        echo "Running module: $module_name"
        local output
        local exit_code

        # Capture output and exit code
        output=$(bash "$module_path" 2>&1)
        exit_code=$?

        # Show output
        if [ -n "$output" ]; then
            echo "$output"
        fi

        if [ $exit_code -ne 0 ]; then
            if [ "$is_required" = true ]; then
                log_error "REQUIRED module failed" "{\"module\":\"$module_name\",\"exit_code\":$exit_code}"
                echo "ERROR: Required module $module_name failed with code $exit_code"
                FAILED_REQUIRED_MODULES+=("$module_name (exit code: $exit_code)")
            else
                log_warn "Optional module failed" "{\"module\":\"$module_name\",\"exit_code\":$exit_code}"
                echo "WARNING: Optional module $module_name failed with code $exit_code (continuing...)"
                FAILED_OPTIONAL_MODULES+=("$module_name (exit code: $exit_code)")
            fi
            return $exit_code
        else
            log_info "Module completed successfully" "{\"module\":\"$module_name\"}"
            return 0
        fi
    else
        if [ "$is_required" = true ]; then
            log_error "Required module not found" "{\"module\":\"$module_name\",\"path\":\"$module_path\"}"
            echo "ERROR: Required module not found: $module_path"
            FAILED_REQUIRED_MODULES+=("$module_name (not found)")
            return 1
        else
            log_warn "Optional module not found" "{\"module\":\"$module_name\",\"path\":\"$module_path\"}"
            echo "WARNING: Optional module not found: $module_path (skipping)"
            return 0
        fi
    fi
}

# Run setup modules in order
# First run optional setup modules that prepare the environment
run_module "setup-permissions.sh"

# Then run required modules
run_module "init-npm.sh"
run_module "setup-npm-permissions.sh"
run_module "init-claude-code.sh"

# Finally run remaining optional modules
run_module "setup-workspace.sh"
run_module "setup-shell.sh"

# Report summary
echo ""
echo "============================================"
echo "  Post-Create Setup Summary"
echo "============================================"

# Report any failures
if [ ${#FAILED_REQUIRED_MODULES[@]} -gt 0 ]; then
    echo ""
    echo "FAILED REQUIRED MODULES:"
    for module in "${FAILED_REQUIRED_MODULES[@]}"; do
        echo "  - $module"
    done
fi

if [ ${#FAILED_OPTIONAL_MODULES[@]} -gt 0 ]; then
    echo ""
    echo "Failed optional modules (non-critical):"
    for module in "${FAILED_OPTIONAL_MODULES[@]}"; do
        echo "  - $module"
    done
fi

if [ ${#FAILED_REQUIRED_MODULES[@]} -eq 0 ] && [ ${#FAILED_OPTIONAL_MODULES[@]} -eq 0 ]; then
    echo "All modules completed successfully!"
fi

echo "============================================"
echo ""

# Show next steps
echo "Next steps:"
echo "   1. Set your ANTHROPIC_API_KEY environment variable (or use /login command)"
echo "   2. Run 'claude --dangerously-skip-permissions' to activate Claude Code"
echo "      (If no API key is set, use the /login command when prompted)"
echo ""
echo "Quick tip: Press arrow-up for command history"
echo ""
echo "Documentation:"
echo "   - Claude Code: https://claude.ai/code"

# Exit with error if any required modules failed
if [ ${#FAILED_REQUIRED_MODULES[@]} -gt 0 ]; then
    log_error "PostCreate failed due to required module failures" "{\"failed_modules\":[\"${FAILED_REQUIRED_MODULES[*]}\"]}"
    echo ""
    echo "ERROR: Setup incomplete due to failed required modules."
    echo "Please check the errors above and rebuild the container."
    exit 1
fi

log_info "PostCreate completed successfully"
exit 0
