# 02: Script Metadata and Tools Catalog

This document defines the strategy for making the existing PowerShell scripts discoverable and usable by the Gemini model. This is achieved through a combination of human-readable metadata and a machine-readable tools catalog.

## 1. Script Metadata

To avoid creating a separate, hard-to-maintain metadata file for each script, we will embed the metadata directly into the PowerShell scripts themselves using a **comment-based header block**. This keeps the documentation and the code in the same place, making it easier for developers to keep them in sync.

The header will be a YAML block inside a PowerShell comment block (`<# ... #>`).

### Metadata Schema

Here is the proposed schema for the metadata header.

| Field             | Type          | Required | Description                                                                                             |
|-------------------|---------------|----------|---------------------------------------------------------------------------------------------------------|
| `id`              | `string`      | Yes      | The unique identifier for the script, matching the filename without extension (e.g., `open-calculator`).      |
| `name`            | `string`      | Yes      | A short, human-readable name for the tool (e.g., "Open Calculator").                                    |
| `description`     | `string`      | Yes      | A detailed explanation of what the script does, used to help Gemini choose the right tool.              |
| `category`        | `string`      | Yes      | A classification for the tool (e.g., `AppLauncher`, `SystemCheck`, `FileManagement`, `Web`).              |
| `risk_level`      | `string`      | Yes      | The potential impact of the script. Enum: `low`, `medium`, `high`.                                      |
| `side_effects`    | `string[]`    | Yes      | A list of potential effects. Enum: `filesystem_read`, `filesystem_write`, `process`, `network`, `registry`. |
| `requires_admin`  | `boolean`     | No       | Whether the script needs to be run with administrator privileges. Defaults to `false`.                  |
| `parameters`      | `object[]`    | No       | An array of objects describing the script's parameters.                                                 |
| `examples`        | `string[]`    | No       | Example phrases a user might say to invoke this command.                                                |

### Parameter Schema

For each parameter in the `parameters` array:

| Field         | Type       | Required | Description                                                              |
|---------------|------------|----------|--------------------------------------------------------------------------|
| `name`        | `string`   | Yes      | The exact name of the parameter in the `param()` block (e.g., `ProgramName`). |
| `type`        | `string`   | Yes      | The data type (e.g., `string`, `integer`, `boolean`).                        |
| `description` | `string`   | Yes      | A clear description of what the parameter is for.                        |
| `required`    | `boolean`  | No       | Whether the parameter is mandatory. Defaults to `false`.                 |
| `default`     | `any`      | No       | The default value if the parameter is not provided.                      |

### Example: `close-program.ps1` Metadata

Here is how the header for `scripts/close-program.ps1` would look:

```powershell
<#
.SYNOPSIS
	Closes a program's processes 

id: close-program
name: Close Program
description: Finds and gracefully closes a running application's main window and process.
category: ProcessManagement
risk_level: low
side_effects: [process]
requires_admin: false
parameters:
  - name: ProgramName
    type: string
    description: The process name of the application to close (e.g., "chrome", "notepad").
    required: true
  - name: FullProgramName
    type: string
    description: The user-facing full name of the application (e.g., "Google Chrome"). Used for descriptive output.
    required: false
  - name: ProgramAliasName
    type: string
    description: An alternative process name for the application.
    required: false
examples:
  - "close chrome"
  - "shut down notepad plus plus"
  - "terminate spotify"
#>

param([string]$FullProgramName = "", [string]$ProgramName = "", [string]$ProgramAliasName = "")

# ... rest of the script
```

## 2. Tools Catalog (`tools.json`)

The **Agent Service** will be responsible for generating a `tools.json` file. This file will contain a list of tool definitions formatted according to the Gemini API's [Function Calling specification](https://ai.google.dev/docs/function_calling).

### Generation Process

1.  **Scan:** The agent will scan all `.ps1` files in the `scripts` directory.
2.  **Parse:** For each script, it will read the content and parse the YAML block from the comment header.
3.  **Transform:** It will transform the parsed YAML into the JSON schema required by Gemini.
4.  **Write:** It will write the final JSON array to `tools.json`.

This process should be run once at agent startup, and can be re-run if the script library changes.

### Example `tools.json` Entry

Based on the `close-program.ps1` metadata above, the corresponding entry in `tools.json` would look like this:

```json
[
  {
    "name": "close-program",
    "description": "Finds and gracefully closes a running application's main window and process.",
    "parameters": {
      "type": "OBJECT",
      "properties": {
        "ProgramName": {
          "type": "STRING",
          "description": "The process name of the application to close (e.g., 'chrome', 'notepad')."
        },
        "FullProgramName": {
          "type": "STRING",
          "description": "The user-facing full name of the application (e.g., 'Google Chrome'). Used for descriptive output."
        },
        "ProgramAliasName": {
          "type": "STRING",
          "description": "An alternative process name for the application."
        }
      },
      "required": ["ProgramName"]
    }
  }
]
```

This structured approach ensures that Gemini has all the information it needs to accurately and reliably select the correct PowerShell script and populate its parameters based on the user's natural language command.
