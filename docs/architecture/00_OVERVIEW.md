# 00: Project Overview and Vision

This document outlines the high-level vision and phased plan for transforming the **Talk2Windows** project into an autonomous Windows agent.

## 1. Core Vision

The goal is to evolve Talk2Windows from a tool that maps static voice phrases to specific PowerShell scripts into a dynamic, conversational AI agent. This agent will leverage the power of Google's Gemini models as its "brain" to understand natural language, formulate multi-step plans, and interact with the user. The existing, comprehensive library of PowerShell scripts will serve as the "hands" of the agent, providing a robust and safe foundation for performing actions on the Windows OS.

The target user experience is a seamless, conversational interaction where the user can state high-level goals (e.g., "Windows, get ready for my workday") and the agent can intelligently execute the necessary sequence of actions (e.g., open specific apps, check for new emails, play a focus playlist).

## 2. Key Principles

- **Keep PowerShell Core:** The extensive `.ps1` script library is the project's greatest asset. We will wrap it, not replace it. All OS interactions will be performed by executing these scripts.
- **Gemini-Powered Intelligence:** Gemini 2.5 Flash will be the default model for planning, routing, and reflection due to its speed and cost-effectiveness.
- **Function Calling & Structured Outputs:** The agent will use Gemini's native function calling capabilities to reliably map user intent to the appropriate PowerShell scripts and their parameters.
- **Safety First:** A strict, multi-tiered safety policy will be implemented. Destructive operations will require explicit user confirmation, and secrets will be managed securely, never exposed to the LLM.
- **Phased Rollout:** The project will be implemented in distinct phases to manage complexity and deliver value incrementally. Each phase will build upon the last, starting with a simple router and progressively adding more complex capabilities like multi-step planning, proactive watchers, and web automation.

## 3. Phased Rollout Plan Summary

This table summarizes the planned phases for development. Each phase is a stepping stone towards the full vision.

| Phase | Title                       | Core Deliverable                                                              |
|-------|-----------------------------|-------------------------------------------------------------------------------|
| **1** | **Router & Catalog**        | A service that can take a natural language command and map it to a single, appropriate PowerShell script with the correct parameters. |
| **2** | **Plans & Confirmations**   | The agent can create and execute multi-step plans, chaining multiple scripts together. Implements the core safety confirmation loop. |
| **3** | **Watchers & Schedulers**   | The agent can proactively monitor system events (e.g., file downloads, high CPU) and run scheduled tasks. |
| **4** | **Web & Comms**             | The agent can perform browser automation (via Selenium) and communicate via email/Teams (via Microsoft Graph API). |
| **5** | **Dynamic Script Factory**  | The agent can propose new, simple PowerShell scripts for approval when no existing tool fits a user's request. |
| **6** | **Learning & Proactivity**  | The agent learns from user interactions to suggest personalized workflows and automations. |

This overview serves as the entry point to the detailed planning documents that follow. Each subsequent document will elaborate on the architecture, components, and policies required to bring this vision to life.
