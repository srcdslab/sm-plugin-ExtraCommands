# Copilot Instructions for ExtraCommands SourceMod Plugin

## Repository Overview

This repository contains **ExtraCommands**, a comprehensive SourceMod plugin that provides advanced administrative commands for Source engine games (primarily CS:GO/CS2). The plugin offers 30+ admin commands for player manipulation, game control, and server administration.

**Key Facts:**
- **Language:** SourcePawn
- **Target Platform:** SourceMod 1.11+ for Source engine games (minimum 1.12+ recommended)
- **Plugin Type:** Single-file admin utility plugin (~2000 lines)
- **Build System:** SourceKnight with automated CI/CD

## Project Structure

```
addons/sourcemod/scripting/
├── ExtraCommands.sp          # Main plugin source (single file)
sourceknight.yaml            # Build configuration and dependencies
.github/
├── workflows/ci.yml         # CI/CD pipeline
└── dependabot.yml          # Dependency management
```

## Development Environment Setup

### Build System
The project uses **SourceKnight** for building:
- Configuration in `sourceknight.yaml`
- Dependencies: SourceMod 1.11.0, MultiColors, ZombieReloaded (optional)
- Output: Compiled `.smx` plugins in `/addons/sourcemod/plugins`
- Build command: `sourceknight build` (handled by CI)

### Dependencies
1. **SourceMod 1.11.0-git6934** - Core SourceMod framework (minimum 1.12+ recommended for production)
2. **MultiColors** - Enhanced colored chat functionality
3. **ZombieReloaded** - Optional include for ZR-specific features

## Code Style & Standards

### SourcePawn Conventions
```sourcepawn
#pragma semicolon 1           // Required semicolons
#pragma newdecls required     // New declaration syntax

// Variable naming (as seen in ExtraCommands.sp)
bool g_bInBuyZoneAll;                    // Global bools with g_b prefix
bool g_bInBuyZone[MAXPLAYERS + 1];      // Per-player arrays
ConVar g_CVar_sv_pausable;              // ConVars with g_CVar_ prefix  
StringMap g_hServerCanExecuteCmds;      // Handles with g_h prefix
float coords[MAX_CLIENTS][3];           // Simple arrays without prefix

// Function naming
public Action Command_Health(int client, int args)  // Commands: PascalCase
void someHelperFunction()                           // Helpers: camelCase

// Constants
#define MAX_CLIENTS 129      // ALL_CAPS for defines
#define MAX_BUFF    512
#define MAXPLAYERS  64       // Use MAXPLAYERS for player arrays
```

### Indentation & Formatting
- **Tabs:** 4 spaces equivalent
- **Braces:** K&R style (opening brace on same line)
- **Comments:** Only for complex logic, avoid unnecessary headers
- **Strings:** Use proper escaping and buffer sizes

## Plugin Architecture

### Core Components

1. **Command Registration** (OnPluginStart)
   - 30+ RegAdminCmd calls with proper flag permissions
   - Command syntax in description strings  
   - Multiple permission levels (GENERIC, KICK, BAN, CHEATS)

2. **Event Handling**
   - Bomb events (planted/defused) 
   - Round end events
   - Player connection events

3. **Per-Player State Management**
   - Buy zone status arrays: `g_bInBuyZone[MAXPLAYERS + 1]`
   - Infinite ammo tracking: `g_bInfAmmo[MAXPLAYERS + 1]`
   - Player coordinates storage: `coords[MAX_CLIENTS][3]`

4. **Hook Management**
   - SDKHook for player think functions (OnPreThink/OnPostThinkPost)
   - Event hooks for game state
   - Command listeners for pause commands

### Key Features
- **Player Manipulation:** Health, armor, weapons, respawn, team changes
- **Game Control:** Round restart, team management, score modification  
- **Admin Tools:** God mode, teleportation, model scaling, fake commands
- **Server Utilities:** Uptime, balance, shuffle, WAILA (What Am I Looking At)

### ExtraCommands-Specific Patterns

#### Target Processing
```sourcepawn
// Standard pattern used throughout the plugin
char sArgs[32], sArgs2[32];
GetCmdArg(1, sArgs, sizeof(sArgs));
GetCmdArg(2, sArgs2, sizeof(sArgs2));

int iTargets[MAXPLAYERS], iTargetCount;
char sTargetName[MAX_TARGET_LENGTH];
bool bIsML;

if ((iTargetCount = ProcessTargetString(sArgs, client, iTargets, MAXPLAYERS, 
    COMMAND_FILTER_ALIVE | COMMAND_FILTER_NO_IMMUNITY, 
    sTargetName, sizeof(sTargetName), bIsML)) <= 0)
{
    ReplyToTargetError(client, iTargetCount);
    return Plugin_Handled;
}

// Process each target
for (int i = 0; i < iTargetCount; i++)
{
    int target = iTargets[i];
    // Perform action on target
}
```

#### Client Validation Pattern
```sourcepawn
// Standard validation used in the plugin
if (IsClientConnected(i) && IsClientInGame(i))
{
    // Client is valid for processing
}

// For alive players specifically
if (IsClientInGame(client) && IsPlayerAlive(client))
{
    // Player-specific actions
}
```

## Development Guidelines

### Adding New Commands
```sourcepawn
// 1. Register in OnPluginStart()
RegAdminCmd("sm_newcmd", Command_NewCmd, ADMFLAG_GENERIC, "sm_newcmd <target> <value>");

// 2. Implement command function
public Action Command_NewCmd(int client, int argc)
{
    if (argc < 2)
    {
        ReplyToCommand(client, "[SM] Usage: sm_newcmd <target> <value>");
        return Plugin_Handled;
    }
    
    // Target processing using built-in functions
    char arg1[32], arg2[32];
    GetCmdArg(1, arg1, sizeof(arg1));
    GetCmdArg(2, arg2, sizeof(arg2));
    
    // Always validate targets and parameters
    int target = FindTarget(client, arg1, true);
    if (target == -1) return Plugin_Handled;
    
    // Implementation here
    return Plugin_Handled;
}
```

### Memory Management
```sourcepawn
// StringMaps and ArrayLists
StringMap g_hMap = new StringMap();  // Create
delete g_hMap;                       // Cleanup (no null check needed)
g_hMap = new StringMap();            // Recreate if needed

// NEVER use .Clear() - causes memory leaks
// ALWAYS use delete + recreate pattern
```

### Error Handling & Validation
```sourcepawn
// Always validate client indices
if (!IsValidClient(client)) return;

// Validate array bounds
if (client < 1 || client > MaxClients) return;

// Check game state
if (!IsClientInGame(client)) return;

// Validate parameters before use
int value = StringToInt(arg);
if (value < 0 || value > MAX_VALUE) 
{
    ReplyToCommand(client, "Invalid value range");
    return Plugin_Handled;
}
```

## Testing & Validation

### Local Testing Strategy
1. **Syntax Validation:** SourceKnight build process checks compilation
2. **Plugin Loading:** Test on development server with `-insecure` flag
3. **Command Testing:** Systematically test each command category:
   - Player manipulation: `sm_hp`, `sm_armor`, `sm_weapon`, `sm_respawn`
   - Game control: `sm_restartround`, `sm_team`, `sm_balance`
   - Admin tools: `sm_god`, `sm_teleport`, `sm_setmodel`
   - Server utilities: `sm_uptime`, `sm_waila`, `sm_querycvar`

### Testing Commands Categories
```sourcepawn
// Basic player commands (ADMFLAG_GENERIC)
sm_hp <target> <value>          // Health: 1-999999
sm_armor <target> <value>       // Armor: 0-100  
sm_weapon <target> <weapon>     // Give weapon
sm_speed <target> <multiplier>  // Speed: 0.1-10.0

// Team management (ADMFLAG_KICK)  
sm_balance                      // Auto-balance teams
sm_shuffle                      // Shuffle all players
sm_teamswap                     // Swap team scores
sm_forcespec <target>          // Force to spectator

// Advanced admin (ADMFLAG_BAN)
sm_god <target> <0|1>          // God mode toggle
sm_teleport <from> <to>        // Teleport player
sm_getloc <target>             // Get coordinates

// Server control (ADMFLAG_CHEATS)
sm_fcvar <target> <cvar> <val> // Force client cvar
sm_fakecommand <target> <cmd>  // Execute as client
```

### Automated Testing
- **CI Pipeline:** GitHub Actions builds on every commit
- **Build Validation:** SourceKnight verifies dependencies and compilation
- **Artifact Generation:** Compiled `.smx` files available for download
- **Release Automation:** Tags and releases created automatically on main branch

### Manual Validation Checklist
- [ ] Plugin loads without errors (`sm plugins list`)
- [ ] All commands registered (`sm cmds | grep sm_`)  
- [ ] No memory leaks during extended use
- [ ] Commands work with multiple target formats (@all, @ct, @t, names, #userid)
- [ ] Proper error messages for invalid parameters
- [ ] Admin flag restrictions work correctly

## Common Tasks

### Adding New Global Variables
```sourcepawn
// At top of file with other globals
bool g_bNewFeature[MAXPLAYERS + 1] = {false, ...};

// Initialize in OnMapStart if needed
public void OnMapStart()
{
    for (int i = 1; i <= MaxClients; i++)
        g_bNewFeature[i] = false;
}

// Reset in OnClientDisconnect
public void OnClientDisconnect(int client)
{
    g_bNewFeature[client] = false;
}
```

### Adding ConVars
```sourcepawn
// Declare at top
ConVar g_CVar_newSetting;

// Create in OnPluginStart
g_CVar_newSetting = CreateConVar("sm_plugin_setting", "1", "Description", FCVAR_NOTIFY);

// Use AutoExecConfig to generate config file
AutoExecConfig(true);  // Already present

// Access value
bool enabled = g_CVar_newSetting.BoolValue;
```

### Debugging Tips
```sourcepawn
// Use PrintToServer for debugging
PrintToServer("[DEBUG] Variable value: %d", someValue);

// Use LogMessage for persistent logging  
LogMessage("Player %N executed command", client);

// Client-specific debug messages
PrintToChat(client, "Debug: %s", someString);
```

## Performance Considerations

### Optimization Guidelines
1. **Minimize Timer Usage:** Prefer event-driven architecture
2. **Cache Expensive Operations:** Store results of complex calculations
3. **Efficient Loops:** Use early breaks and continues
4. **String Operations:** Minimize formatting in frequently called functions
5. **Hook Management:** Only hook what's necessary, unhook properly

### Critical Performance Areas
- **OnPreThink/OnPostThinkPost:** Called every server tick per player
- **Event Handlers:** Keep processing minimal
- **Command Functions:** Validate quickly, fail fast

## Troubleshooting

### Common Issues
1. **Compilation Errors:** Check include paths and SourceMod version compatibility
2. **Runtime Errors:** Validate all client indices and game state
3. **Memory Leaks:** Use delete instead of .Clear() for StringMaps/ArrayLists
4. **Command Registration:** Ensure unique command names and proper syntax strings

### Build Issues
- **SourceKnight Errors:** Check `sourceknight.yaml` dependency versions and URLs
- **Missing Includes:** Verify MultiColors and ZombieReloaded dependencies are accessible
- **Include Path Issues:** Ensure includes are in `/addons/sourcemod/scripting/include/`
- **CI Failures:** Check GitHub Actions logs for specific SourceKnight error output
- **Dependency Version Conflicts:** Update `sourceknight.yaml` if dependencies change

### Runtime Issues  
- **Plugin Load Failures:** Check SourceMod logs for missing dependencies
- **Command Not Found:** Verify `RegAdminCmd` registration in `OnPluginStart()`
- **Target Errors:** Ensure `ProcessTargetString` handles edge cases properly
- **Memory Issues:** Use `delete` instead of `.Clear()` for StringMaps/ArrayLists
- **Hook Conflicts:** Check for multiple plugins hooking same events/functions

### Dependency Troubleshooting
```bash
# Check if includes are properly available  
ls -la addons/sourcemod/scripting/include/multicolors.inc
ls -la addons/sourcemod/scripting/include/zombiereloaded.inc

# Verify SourceKnight dependencies
sourceknight deps  # Check dependency status

# Test compilation manually
spcomp ExtraCommands.sp -i"include/" -o"compiled/ExtraCommands.smx"
```

## Development Workflows

### Adding a New Command
1. **Plan:** Define command syntax, permission level, and functionality
2. **Register:** Add `RegAdminCmd()` call in `OnPluginStart()`
3. **Implement:** Create command function following existing patterns
4. **Test:** Verify with different target types and edge cases
5. **Document:** Update command list in this file if significant

### Modifying Existing Commands  
1. **Understand:** Study existing implementation and dependencies
2. **Backup:** Test changes on development server first
3. **Validate:** Ensure backwards compatibility with existing usage
4. **Test:** Verify edge cases and error handling still work

### Performance Optimization
1. **Profile:** Use SourceMod's built-in profiler (`sm prof`)
2. **Identify:** Find bottlenecks in frequently called functions
3. **Optimize:** Cache results, reduce string operations, minimize loops
4. **Verify:** Measure performance impact before/after changes

## External Resources

- **SourceMod API:** https://sm.alliedmods.net/new-api/
- **SourcePawn Syntax:** https://wiki.alliedmods.net/SourcePawn  
- **SourceKnight:** Build tool for SourceMod plugins
- **MultiColors Include:** https://github.com/srcdslab/sm-plugin-MultiColors
- **ZombieReloaded Include:** https://github.com/srcdslab/sm-plugin-zombiereloaded

## Quick Reference

### Essential Plugin Info
- **Plugin Name:** Advanced Commands  
- **Current Version:** 2.7.12
- **File:** `/addons/sourcemod/scripting/ExtraCommands.sp`
- **Compiled Output:** `/addons/sourcemod/plugins/ExtraCommands.smx`
- **Config File:** Auto-generated via `AutoExecConfig(true)`

### Key Global Variables
```sourcepawn
g_bInBuyZoneAll              // Global buy zone state
g_bInBuyZone[MAXPLAYERS + 1] // Per-player buy zone
g_bInfAmmo[MAXPLAYERS + 1]   // Per-player infinite ammo
g_hServerCanExecuteCmds      // StringMap for server commands
g_hEntitiesListToKill        // StringMap for entity cleanup
coords[MAX_CLIENTS][3]       // Player position storage
```

Remember: This plugin manages extensive game state. Always validate client indices, handle disconnections gracefully, and maintain compatibility with existing server configurations. The plugin is designed for CS:GO/CS2 servers but should work on other Source engine games with appropriate modifications.