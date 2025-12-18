#!/usr/bin/env python3
"""
OIDC Authentication Test Script

This script tests the OIDC authentication setup by:
1. Verifying Azure CLI authentication
2. Checking access to all subscriptions
3. Testing Key Vault access
4. Testing Storage Account access
"""

import json
import os
import subprocess
import sys
from typing import Dict, List, Tuple


class Colors:
    """ANSI color codes for terminal output"""
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    BOLD = '\033[1m'
    END = '\033[0m'


def run_command(cmd: List[str], capture_output: bool = True) -> Tuple[int, str, str]:
    """Run a shell command and return (returncode, stdout, stderr)"""
    result = subprocess.run(
        cmd,
        capture_output=capture_output,
        text=True
    )
    return result.returncode, result.stdout, result.stderr


def print_header(text: str):
    """Print a formatted header"""
    print(f"\n{Colors.BOLD}{Colors.BLUE}{'='*60}{Colors.END}")
    print(f"{Colors.BOLD}{Colors.BLUE}{text}{Colors.END}")
    print(f"{Colors.BOLD}{Colors.BLUE}{'='*60}{Colors.END}\n")


def print_success(text: str):
    """Print success message"""
    print(f"{Colors.GREEN}✓ {text}{Colors.END}")


def print_error(text: str):
    """Print error message"""
    print(f"{Colors.RED}✗ {text}{Colors.END}")


def print_info(text: str):
    """Print info message"""
    print(f"{Colors.YELLOW}ℹ {text}{Colors.END}")


def test_azure_login() -> bool:
    """Test Azure CLI authentication"""
    print_header("Test 1: Azure CLI Authentication")

    returncode, stdout, stderr = run_command(['az', 'account', 'show', '--output', 'json'])

    if returncode != 0:
        print_error("Failed to authenticate with Azure CLI")
        print(f"Error: {stderr}")
        return False

    account = json.loads(stdout)
    print_success("Successfully authenticated with Azure CLI")
    print_info(f"Logged in as: {account.get('user', {}).get('name', 'Unknown')}")
    print_info(f"Subscription: {account.get('name')} ({account.get('id')})")

    return True


def test_subscription_access() -> bool:
    """Test access to all subscriptions"""
    print_header("Test 2: Subscription Access")

    # Expected subscriptions
    expected_subs = {
        'fdb297a9-2ece-469c-808d-a8227259f6e8': 'Root',
        'da1ba383-2bf5-4ee9-8b5f-fc6effb0a100': 'HQ',
        '385c6fcb-c70b-4aed-b745-76bd608303d7': 'Sales',
        'aef7255d-42b5-4f84-81f2-202191e8c7d1': 'Service'
    }

    returncode, stdout, stderr = run_command(['az', 'account', 'list', '--output', 'json'])

    if returncode != 0:
        print_error("Failed to list subscriptions")
        print(f"Error: {stderr}")
        return False

    subscriptions = json.loads(stdout)
    found_subs = {sub['id']: sub['name'] for sub in subscriptions}

    print_info(f"Found {len(found_subs)} accessible subscriptions")

    all_found = True
    for sub_id, expected_name in expected_subs.items():
        if sub_id in found_subs:
            print_success(f"{expected_name}: {found_subs[sub_id]} ({sub_id})")
        else:
            print_error(f"{expected_name} subscription ({sub_id}) not accessible")
            all_found = False

    return all_found


def test_key_vault_access() -> bool:
    """Test Key Vault access"""
    print_header("Test 3: Key Vault Access")

    vault_name = "kv-root-terraform"

    # Test listing secrets
    print_info(f"Testing access to Key Vault: {vault_name}")

    returncode, stdout, stderr = run_command([
        'az', 'keyvault', 'secret', 'list',
        '--vault-name', vault_name,
        '--output', 'json'
    ])

    if returncode != 0:
        print_error(f"Failed to access Key Vault: {vault_name}")
        print(f"Error: {stderr}")
        return False

    secrets = json.loads(stdout)
    print_success(f"Successfully accessed Key Vault: {vault_name}")
    print_info(f"Found {len(secrets)} secrets")

    # Test reading a specific secret
    test_secret = "terraform-dev-hq-sub-id"
    print_info(f"Testing read access to secret: {test_secret}")

    returncode, stdout, stderr = run_command([
        'az', 'keyvault', 'secret', 'show',
        '--vault-name', vault_name,
        '--name', test_secret,
        '--output', 'json'
    ])

    if returncode != 0:
        print_error(f"Failed to read secret: {test_secret}")
        print(f"Error: {stderr}")
        return False

    secret = json.loads(stdout)
    print_success(f"Successfully read secret: {test_secret}")
    print_info(f"Secret value: {secret.get('value')[:8]}... (truncated)")

    return True


def test_storage_account_access() -> bool:
    """Test Storage Account access"""
    print_header("Test 4: Storage Account Access")

    storage_account = "storerootblob"

    # Test listing containers
    print_info(f"Testing access to Storage Account: {storage_account}")

    returncode, stdout, stderr = run_command([
        'az', 'storage', 'container', 'list',
        '--account-name', storage_account,
        '--auth-mode', 'login',
        '--output', 'json'
    ])

    if returncode != 0:
        print_error(f"Failed to access Storage Account: {storage_account}")
        print(f"Error: {stderr}")
        return False

    containers = json.loads(stdout)
    print_success(f"Successfully accessed Storage Account: {storage_account}")
    print_info(f"Found {len(containers)} containers:")

    for container in containers:
        print_info(f"  - {container['name']}")

    # Check for expected containers
    expected_containers = {'foundation', 'workloads-dev', 'workloads-stage', 'workloads-prod'}
    found_containers = {c['name'] for c in containers}

    if expected_containers.issubset(found_containers):
        print_success("All expected Terraform state containers found")
    else:
        missing = expected_containers - found_containers
        print_error(f"Missing containers: {', '.join(missing)}")
        return False

    return True


def test_rbac_permissions() -> bool:
    """Test RBAC role assignments"""
    print_header("Test 5: RBAC Permissions")

    client_id = os.getenv('AZURE_CLIENT_ID')

    if not client_id:
        print_error("AZURE_CLIENT_ID environment variable not set")
        return False

    print_info(f"Checking role assignments for: {client_id}")

    # Get service principal object ID
    returncode, stdout, stderr = run_command([
        'az', 'ad', 'sp', 'list',
        '--filter', f"appId eq '{client_id}'",
        '--output', 'json'
    ])

    if returncode != 0:
        print_error("Failed to get service principal")
        print(f"Error: {stderr}")
        return False

    sps = json.loads(stdout)
    if not sps:
        print_error("Service principal not found")
        return False

    sp_object_id = sps[0]['id']
    print_info(f"Service Principal Object ID: {sp_object_id}")

    # List role assignments
    returncode, stdout, stderr = run_command([
        'az', 'role', 'assignment', 'list',
        '--assignee', sp_object_id,
        '--all',
        '--output', 'json'
    ])

    if returncode != 0:
        print_error("Failed to list role assignments")
        print(f"Error: {stderr}")
        return False

    assignments = json.loads(stdout)
    print_success(f"Found {len(assignments)} role assignments:")

    for assignment in assignments:
        role = assignment['roleDefinitionName']
        scope = assignment['scope']
        print_info(f"  - {role} on {scope.split('/')[-1]}")

    return True


def main():
    """Main test runner"""
    print_header("OIDC Authentication Test Suite")

    environment = os.getenv('ENVIRONMENT', 'unknown')
    print_info(f"Testing environment: {environment}")
    print_info(f"Client ID: {os.getenv('AZURE_CLIENT_ID', 'Not set')}")
    print_info(f"Tenant ID: {os.getenv('AZURE_TENANT_ID', 'Not set')}")

    tests = [
        ("Azure CLI Authentication", test_azure_login),
        ("Subscription Access", test_subscription_access),
        ("Key Vault Access", test_key_vault_access),
        ("Storage Account Access", test_storage_account_access),
        ("RBAC Permissions", test_rbac_permissions)
    ]

    results = {}

    for test_name, test_func in tests:
        try:
            results[test_name] = test_func()
        except Exception as e:
            print_error(f"Test failed with exception: {e}")
            results[test_name] = False

    # Print summary
    print_header("Test Summary")

    passed = sum(1 for result in results.values() if result)
    total = len(results)

    for test_name, result in results.items():
        if result:
            print_success(f"{test_name}: PASSED")
        else:
            print_error(f"{test_name}: FAILED")

    print(f"\n{Colors.BOLD}Results: {passed}/{total} tests passed{Colors.END}\n")

    if passed == total:
        print_success("All tests passed! OIDC authentication is working correctly.")
        sys.exit(0)
    else:
        print_error("Some tests failed. Please review the output above.")
        sys.exit(1)


if __name__ == "__main__":
    main()
