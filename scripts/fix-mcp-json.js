#!/usr/bin/env node

// Script to fix mcp.json by replacing npx commands with global commands
// This is more reliable than regex-based replacements

const fs = require('fs');
const path = require('path');

const filePath = process.argv[2] || '/workspace/.mcp.json';

if (!fs.existsSync(filePath)) {
    console.log('No .mcp.json file found, skipping update');
    process.exit(0);
}

try {
    const content = fs.readFileSync(filePath, 'utf8');
    const config = JSON.parse(content);
    
    let updated = false;
    
    if (config.mcpServers) {
        // Update claude-flow if it uses npx
        if (config.mcpServers['claude-flow'] && 
            config.mcpServers['claude-flow'].command === 'npx' &&
            config.mcpServers['claude-flow'].args &&
            config.mcpServers['claude-flow'].args[0] === 'claude-flow@alpha') {
            
            config.mcpServers['claude-flow'].command = 'claude-flow';
            config.mcpServers['claude-flow'].args = ['mcp', 'start'];
            updated = true;
            console.log('✅ Updated claude-flow from npx to global command');
        }
        
        // Update ruv-swarm if it uses npx
        if (config.mcpServers['ruv-swarm'] && 
            config.mcpServers['ruv-swarm'].command === 'npx' &&
            config.mcpServers['ruv-swarm'].args &&
            config.mcpServers['ruv-swarm'].args[0] === 'ruv-swarm@latest') {
            
            config.mcpServers['ruv-swarm'].command = 'ruv-swarm';
            config.mcpServers['ruv-swarm'].args = ['mcp', 'start'];
            updated = true;
            console.log('✅ Updated ruv-swarm from npx to global command');
        }
    }
    
    if (updated) {
        // Create backup
        fs.writeFileSync(filePath + '.bak', content);
        
        // Write updated config
        fs.writeFileSync(filePath, JSON.stringify(config, null, 2));
        console.log('✅ .mcp.json updated successfully');
    } else {
        console.log('ℹ️  No updates needed - commands already using global packages');
    }
    
} catch (error) {
    console.error('❌ Error updating .mcp.json:', error.message);
    process.exit(1);
}