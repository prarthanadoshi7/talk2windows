# 06: Testing Strategy

A comprehensive testing strategy is essential for ensuring the reliability of the agent's "hands"—the PowerShell scripts. As we add metadata and new capabilities, we must be able to verify that existing functionality does not break. **Pester**, the de-facto standard for testing PowerShell, will be our framework of choice.

## 1. Goals

- **Ensure Correctness:** Verify that scripts perform their intended actions correctly.
- **Prevent Regressions:** Create a safety net that catches unintended side effects introduced by new changes.
- **Validate Metadata:** Ensure that the parameters and behavior described in a script's metadata accurately reflect its implementation.
- **Facilitate Development:** Allow for Test-Driven Development (TDD) of new scripts.

## 2. Test Structure

- **Test File Location:** For each script in `scripts/`, a corresponding test file will be created in `scripts/tests/`.
- **Naming Convention:** The test file will be named after the script it tests, with a `.Tests.ps1` suffix. For example, `scripts/open-calculator.ps1` will be tested by `scripts/tests/open-calculator.Tests.ps1`.

## 3. Pester Implementation

Pester uses a Behavior-Driven Development (BDD) style with `Describe`, `Context`, and `It` blocks.

### Key Testing Techniques

1.  **Mocking:** Pester's powerful mocking capabilities are crucial. We do not want our tests to *actually* open applications or reboot the computer.
    - We will use `Mock` to replace dangerous or environment-dependent cmdlets like `Start-Process`, `Stop-Process`, `Restart-Computer`, and `Get-WMIObject`.
    - The mock will allow us to assert that the cmdlet was called with the correct parameters, without actually executing it.

2.  **Parameter Validation:** Tests will ensure the script behaves correctly when given valid, invalid, or missing parameters.

3.  **Output Validation:** Tests will check the `stdout` of a script to ensure it produces the expected output on success.

4.  **Error Handling:** Tests will verify that the script throws an exception or returns a non-zero exit code when it fails, and that the `stderr` contains a meaningful error message.

### Example: `close-program.Tests.ps1`

This example illustrates how we might test the `close-program.ps1` script.

```powershell
# In scripts/tests/close-program.Tests.ps1

# Import the script to be tested
. "$PSScriptRoot/../close-program.ps1"

Describe "close-program.ps1" {
    # Mock the dangerous cmdlets before each test
    BeforeEach {
        Mock Stop-Process { } -Verifiable
        Mock Get-Process { return [pscustomobject]@{ Name = 'mocked_process'; MainWindowTitle = 'Mocked Process' } } -Verifiable
    }

    Context "With valid parameters" {
        It "Should attempt to stop the correct process" {
            # Run the function/script with test parameters
            close-program -ProgramName "chrome"

            # Assert that the mock was called as expected
            Assert-VerifiableMocks
        }

        It "Should call Stop-Process with the 'chrome' name" {
            close-program -ProgramName "chrome"
            
            # Assert that Stop-Process was called once with the -Name 'chrome'
            Assert-MockCalled Stop-Process -Exactly 1 -ParameterFilter { $Name -eq 'chrome' }
        }
    }

    Context "When the process is not running" {
        It "Should throw an error" {
            # Override the mock for this specific test
            Mock Get-Process { return $null }

            # Assert that calling the script throws an exception
            { close-program -ProgramName "nonexistent" } | Should -Throw "*isn't running*"
        }
    }
}
```

## 4. Test Execution

- **CI/CD:** A GitHub Action or similar CI/CD pipeline will be configured to automatically run all Pester tests on every push and pull request.
- **Local Execution:** Developers will be instructed on how to run the test suite locally to validate their changes before committing. A simple helper script can be provided to invoke Pester.

By integrating Pester tests into the development workflow, we can build a more robust, reliable, and maintainable library of agent capabilities. The initial phase of the project will involve writing tests for the first batch of scripts being integrated into the Tools Catalog.
