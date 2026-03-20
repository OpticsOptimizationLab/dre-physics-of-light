"""
run_all_tests.py
Run all validation tests for the DRE Vol.1 companion code.

Usage: python tests/run_all_tests.py
Requirements: pip install numpy
"""

import subprocess
import sys
import os

TESTS = [
    ("White Furnace Test (energy conservation)", "tests/test_white_furnace.py"),
]

def main():
    print()
    print("=" * 65)
    print("  DRE Vol.1 — Companion Code Validation Suite")
    print("  Digital Rendering Engineering: The Physics of Light")
    print("  github.com/OpticsOptimizationLab/dre-physics-of-light")
    print("=" * 65)
    print()

    passed = 0
    failed = 0

    for name, path in TESTS:
        print(f"Running: {name}")
        result = subprocess.run(
            [sys.executable, path],
            capture_output=False
        )
        if result.returncode == 0:
            passed += 1
        else:
            failed += 1
        print()

    print("=" * 65)
    print(f"  Results: {passed} passed, {failed} failed")
    if failed == 0:
        print("  ALL TESTS PASSED")
    else:
        print(f"  {failed} TEST(S) FAILED — see output above")
    print("=" * 65)
    print()

    return 0 if failed == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
