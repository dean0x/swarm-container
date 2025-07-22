#!/bin/bash

# SwarmContainer tmux 6-pane layout script
# Creates different 6-pane layouts for development

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

show_help() {
    echo "Usage: tmux-6pane.sh [LAYOUT]"
    echo ""
    echo "Creates a 6-pane tmux layout. Must be run inside a tmux session."
    echo ""
    echo "LAYOUT options:"
    echo "  2x3     Two columns, three rows (default)"
    echo "  3x2     Three columns, two rows" 
    echo "  grid    2x3 grid layout"
    echo "  main    Main pane with 5 smaller panes"
    echo "  dev     Development layout (code + terminals + logs)"
    echo ""
    echo "Examples:"
    echo "  tmux-6pane.sh          # Default 2x3 layout"
    echo "  tmux-6pane.sh 3x2      # 3 columns, 2 rows"
    echo "  tmux-6pane.sh main     # Main pane layout"
    echo "  tmux-6pane.sh dev      # Development workflow layout"
}

# Check if we're in a tmux session
if [ -z "$TMUX" ]; then
    echo -e "${YELLOW}Warning: Not in a tmux session. Starting new session...${NC}"
    tmux new-session -d -s swarm-dev
    tmux attach-session -t swarm-dev
    exit 0
fi

# Get layout from argument (default to 2x3)
LAYOUT=${1:-2x3}

case $LAYOUT in
    "2x3"|"grid"|"")
        echo -e "${GREEN}Creating 2x3 grid layout...${NC}"
        
        # Start with one pane, split to create 6 total
        tmux split-window -h                    # Split horizontally (2 panes)
        tmux split-window -v                    # Split right pane vertically (3 panes)
        tmux select-pane -t 0
        tmux split-window -v                    # Split left pane vertically (4 panes)
        tmux select-pane -t 2
        tmux split-window -v                    # Split bottom-right vertically (5 panes)
        tmux select-pane -t 1
        tmux split-window -v                    # Split middle-left vertically (6 panes)
        
        # Select the first pane
        tmux select-pane -t 0
        ;;
        
    "3x2")
        echo -e "${GREEN}Creating 3x2 layout...${NC}"
        
        # Split horizontally twice to get 3 columns
        tmux split-window -h
        tmux split-window -h
        
        # Split each column vertically
        tmux select-pane -t 0
        tmux split-window -v
        tmux select-pane -t 2
        tmux split-window -v
        tmux select-pane -t 4
        tmux split-window -v
        
        # Select the first pane
        tmux select-pane -t 0
        ;;
        
    "main")
        echo -e "${GREEN}Creating main pane layout...${NC}"
        
        # Create a main pane on the left, smaller panes on the right
        tmux split-window -h -p 30              # Right side gets 30%
        tmux split-window -v                    # Split right side in half
        tmux split-window -v                    # Split bottom-right
        tmux select-pane -t 1
        tmux split-window -v                    # Split top-right
        tmux select-pane -t 1
        tmux split-window -v                    # Split middle-right
        
        # Select the main pane
        tmux select-pane -t 0
        ;;
        
    "dev")
        echo -e "${GREEN}Creating development layout...${NC}"
        
        # Main editor pane (60%), terminal column (40%)
        tmux split-window -h -p 40
        
        # Split right side into 5 panes for different purposes
        tmux split-window -v                    # Top-right: file browser
        tmux split-window -v                    # Middle-right: git status
        tmux select-pane -t 1
        tmux split-window -v                    # Split top terminal area
        tmux select-pane -t 3
        tmux split-window -v                    # Split bottom terminal area
        
        # Add labels for development workflow
        tmux send-keys -t 0 'echo "Main Editor Pane - Use for code editing"' C-m
        tmux send-keys -t 1 'echo "File Operations - ls, find, etc."' C-m
        tmux send-keys -t 2 'echo "Build/Test Commands"' C-m
        tmux send-keys -t 3 'echo "Git Commands"' C-m
        tmux send-keys -t 4 'echo "Logs/Monitoring"' C-m
        tmux send-keys -t 5 'echo "General Terminal"' C-m
        
        # Select the main editor pane
        tmux select-pane -t 0
        ;;
        
    "help"|"-h"|"--help")
        show_help
        exit 0
        ;;
        
    *)
        echo -e "${YELLOW}Unknown layout: $LAYOUT${NC}"
        echo "Run 'tmux-6pane.sh help' for available options."
        exit 1
        ;;
esac

# Set pane titles if tmux version supports it
if tmux display-message -p "#{version}" | grep -q "^3\|^[4-9]"; then
    for i in {0..5}; do
        tmux select-pane -t $i -T "Pane $((i+1))"
    done
fi

echo -e "${GREEN}✅ 6-pane layout '$LAYOUT' created successfully!${NC}"
echo ""
echo "Tips:"
echo "  - Use Ctrl-a + h/j/k/l to navigate between panes"
echo "  - Use Ctrl-a + \\ for tmux menus"
echo "  - Use Ctrl-a + r to reload tmux config"
echo "  - Use Ctrl-a + 6 to recreate this layout"