# 07: Phased Rollout Plan

This document provides a detailed, phase-by-phase implementation plan. This approach allows for incremental development, testing, and value delivery.

---

### Phase 1: Router & Catalog (The Foundation)

**Goal:** Implement the core routing mechanism. The agent will be able to understand a natural language command and execute the correct *single* PowerShell script with the correct parameters.

**Key Tasks:**
1.  **Setup Agent Service:** Create the initial Python `AgentService` structure.
2.  **Implement Serenade Listener:** Write the WebSocket client to connect to Serenade and receive transcripts.
3.  **Create Metadata for Core Scripts:** Select a "starter set" of ~25 high-value, low-risk scripts and write their comment-based metadata.
    - **Target Scripts:** `open-*` (apps), `close-*` (apps), `check-time`, `check-weather`, `check-battery`, `roll-a-dice`, `tell-me-a-joke`, `list-running-processes`.
4.  **Build Tool Catalog Generator:** Implement the logic to parse script metadata and generate the `tools.json` file for Gemini.
5.  **Implement PowerShell Executor:** Create the `run-script.ps1` wrapper and the corresponding Python `subprocess` logic to run it.
6.  **Develop Basic Agent Loop:** Implement the initial `handle_command` logic that sends the transcript and tools to Gemini and executes the returned function call.

**Success Metric:** The agent can reliably translate at least 80% of the commands listed in the `README.md` for the target scripts into the correct PowerShell execution (e.g., "Windows, what's the weather like?" successfully runs `check-weather.ps1`).

---

### Phase 2: Plans & Confirmations

**Goal:** Enable the agent to handle multi-step commands and implement the critical safety confirmation layer.

**Key Tasks:**
1.  **Enhance Planner Prompt:** Modify the prompt to Gemini to ask for a `plan` with ordered steps for complex requests.
2.  **Implement Plan Executor:** Update the `AgentService` to iterate through the steps of a plan, executing each one in sequence.
3.  **Implement Safety Policy:** Code the confirmation logic in the `AgentService`. Before calling the executor, check the tool's `risk_level` from the metadata and trigger the appropriate confirmation flow (silent, yes/no, or passphrase).
4.  **Expand Metadata:** Add metadata to `medium` and `high` risk scripts like `reboot-computer`, `empty-recycle-bin`, `install-*`.
5.  **Implement Memory Store:** Add a basic memory store to remember the last action and provide context (e.g., for "undo that").

**Success Metric:** The agent can handle a command like "Check my internet speed and then tell me a joke" by executing two scripts in order. The agent refuses to execute `reboot-computer` without explicit user confirmation.

---

### Phase 3: Watchers & Schedulers

**Goal:** Make the agent proactive by allowing it to monitor the system and run tasks on a schedule.

**Key Tasks:**
1.  **Implement FileSystemWatcher:** Create a new PowerShell script (`start-watcher.ps1`) that uses `System.IO.FileSystemWatcher` to monitor a directory (e.g., Downloads) and can call back to the agent.
2.  **Implement Scheduler:** Create scripts to interface with the Windows Task Scheduler (`Register-ScheduledTask`).
3.  **Add Watcher/Scheduler Tools:** Add metadata for these new scripts to the Tools Catalog.
4.  **Enhance Agent Logic:** The agent will need a mechanism to manage these background tasks.

**Success Metric:** The user can say "Windows, let me know if I download any new zip files" and the agent will configure a watcher. The user can schedule a daily "good morning" script to run at 8 AM.

---

### Phase 4: Web & Comms

**Goal:** Extend the agent's reach into the browser and communication applications.

**Key Tasks:**
1.  **Setup Selenium:** Install Selenium and the Edge WebDriver.
2.  **Create Web Automation Scripts:** Develop a set of PowerShell scripts that use Selenium to perform actions like "search for X on YouTube" or "log into Y and download my latest bill".
3.  **Setup MS Graph API:** Guide the user through the OAuth flow to grant the agent permissions to their Outlook/Teams.
4.  **Create Graph API Scripts:** Develop scripts for sending emails and Teams messages, which will require approval.
5.  **Implement Secret Management:** Integrate `Microsoft.PowerShell.SecretManagement` for storing API keys and session tokens securely.

**Success Metric:** The agent can successfully control a YouTube search in Edge. The agent can draft an email for the user and only send it after they give approval.

---

### Phase 5: Dynamic Script Factory

**Goal:** Allow the agent to "learn" new, simple skills by proposing its own PowerShell scripts.

**Key Tasks:**
1.  **Develop "Propose Script" Logic:** Create a Gemini prompt that, when no tool is found, asks the model to write a simple, safe PowerShell script to accomplish the task.
2.  **Implement Sandbox Executor:** Create a highly constrained execution environment for testing proposed scripts.
3.  **Create Approval Workflow:** When a script is proposed, the agent presents it to the user for approval. If approved, it is saved to the `scripts` directory and its metadata is generated.
4.  **Implement Pester Test Generation:** As a stretch goal, have the agent propose a Pester test alongside the new script.

**Success Metric:** For a simple request like "create a file on my desktop named my-notes.txt", the agent can generate, get approval for, and execute a new script.

---

### Phase 6: Learning & Proactivity

**Goal:** Make the agent truly intelligent by having it learn from user behavior.

**Key Tasks:**
1.  **Log Analysis:** The agent will analyze its own action logs to identify frequently chained commands.
2.  **Workflow Suggestion:** If the agent notices the user always runs `open-outlook`, `open-teams`, and `open-browser` in the morning, it will ask: "I've noticed you run the same three apps every morning. Would you like me to create a 'start my day' routine for you?"
3.  **Preference Learning:** The agent will remember user choices (e.g., "always open web links in Firefox") and use them as context for future plans.

**Success Metric:** The agent successfully identifies a user pattern and gets approval to create a new custom workflow, which then appears as a new tool in its catalog.
