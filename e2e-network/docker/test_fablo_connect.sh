#!/usr/bin/env bash

################################################################################
# Fablo Connect - End-to-End Integration Test
#
# USAGE:
#   cd fablo
#   chmod +x e2e-network/docker/test_fablo_connect.sh
#   ./e2e-network/docker/test_fablo_connect.sh
#
# This script provides a comprehensive, production-grade test for the
# 'fablo connect' command. It validates real network functionality by:
#
# 1. Starting a full Fabric network from fablo-config
# 2. Verifying all containers are healthy
# 3. Connecting a second Fablo instance to the running network
# 4. Executing chaincode operations (invoke/query)
# 5. Verifying ledger synchronization
# 6. Validating block height increases
#
# PREREQUISITES:
#   - Docker (running)
#   - Bash 4.0+
#   - jq (for JSON parsing)
#   - curl (for health checks)
#   - 4GB+ free disk space
#   - 2GB+ free RAM
#
# INSTALL DEPENDENCIES (Ubuntu/Debian):
#   sudo apt-get update
#   sudo apt-get install -y docker.io jq curl
#   sudo systemctl start docker
#
# EXIT CODES:
#   0 - All tests passed
#   1 - Test failed
#   2 - Prerequisites not met
#   3 - Configuration error
#
# TEST LOGS:
#   Logs are saved in: e2e-network/docker/test_fablo_connect.logs/
#   Main log: test.log
#   Container logs: <container_name>.log
#
# CI/CD:
#   This test runs automatically in GitHub Actions on:
#   - Push to main, develop, or feature/fablo-connect
#   - Pull requests to main or develop
#
################################################################################

set -euo pipefail

################################################################################
# Configuration
################################################################################

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly FABLO_HOME="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
readonly TEST_ROOT="$(mktemp -d -t fablo-connect-test.XXXXXXXX)"
readonly TEST_LOGS="${SCRIPT_DIR}/test_fablo_connect.logs"
readonly NETWORK_DIR="${TEST_ROOT}/network1"
readonly CONNECT_DIR="${TEST_ROOT}/network2"

# Timeouts (seconds)
readonly CONTAINER_READY_TIMEOUT=180
readonly CHAINCODE_READY_TIMEOUT=180
readonly CONNECT_READY_TIMEOUT=60
readonly HEALTH_CHECK_TIMEOUT=30
readonly BLOCK_SYNC_TIMEOUT=60

# Retry configuration
readonly MAX_RETRIES=30
readonly RETRY_INTERVAL=2

# Network configuration
readonly CHANNEL_NAME="my-channel1"
readonly CHAINCODE_NAME="chaincode1"
readonly CHAINCODE_VERSION="0.0.1"
readonly ORG_NAME="org1"
readonly PEER_0="peer0.org1.example.com"
readonly PEER_1="peer1.org1.example.com"
readonly ORDERER="orderer0.group1.orderer.example.com"
readonly CA="ca.org1.example.com"

# Color codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# State tracking
TEST_FAILED=false
CLEANUP_DONE=false
INITIAL_BLOCK_HEIGHT=0
FINAL_BLOCK_HEIGHT=0

################################################################################
# Logging Functions
################################################################################

log_info() {
  echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $*" | tee -a "${TEST_LOGS}/test.log"
}

log_success() {
  echo -e "${GREEN}[✓]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $*" | tee -a "${TEST_LOGS}/test.log"
}

log_error() {
  echo -e "${RED}[✗]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $*" | tee -a "${TEST_LOGS}/test.log" >&2
}

log_warn() {
  echo -e "${YELLOW}[!]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $*" | tee -a "${TEST_LOGS}/test.log"
}

log_section() {
  echo "" | tee -a "${TEST_LOGS}/test.log"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" | tee -a "${TEST_LOGS}/test.log"
  echo -e "${CYAN}$*${NC}" | tee -a "${TEST_LOGS}/test.log"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" | tee -a "${TEST_LOGS}/test.log"
}

################################################################################
# Cleanup Functions
################################################################################

dump_container_logs() {
  local container_name="$1"
  local log_file="${TEST_LOGS}/${container_name}.log"
  
  log_info "Collecting logs for container: $container_name"
  
  if docker logs "$container_name" >"$log_file" 2>&1; then
    log_info "Logs saved: $log_file"
  else
    log_warn "Failed to collect logs for: $container_name"
  fi
}

dump_all_container_logs() {
  log_info "Collecting logs from all containers..."
  
  local containers
  containers=$(docker ps -a --format '{{.Names}}' 2>/dev/null || echo "")
  
  if [ -z "$containers" ]; then
    log_warn "No containers found"
    return 0
  fi
  
  while IFS= read -r container; do
    if [[ "$container" == *"org1"* ]] || [[ "$container" == *"orderer"* ]] || [[ "$container" == *"ca"* ]] || [[ "$container" == *"ccaas"* ]]; then
      dump_container_logs "$container"
    fi
  done <<< "$containers"
}

cleanup() {
  if [ "$CLEANUP_DONE" = true ]; then
    return 0
  fi
  
  log_section "Cleanup"
  
  # Dump logs before cleanup
  dump_all_container_logs
  
  # Stop networks
  log_info "Stopping primary network..."
  if [ -d "$NETWORK_DIR" ]; then
    (cd "$NETWORK_DIR" && "$FABLO_HOME/fablo.sh" down 2>/dev/null || true)
  fi
  
  log_info "Stopping connected network..."
  if [ -d "$CONNECT_DIR" ]; then
    (cd "$CONNECT_DIR" && "$FABLO_HOME/fablo.sh" down 2>/dev/null || true)
  fi
  
  # Remove temporary directory
  log_info "Removing temporary test directory: $TEST_ROOT"
  rm -rf "$TEST_ROOT"
  
  CLEANUP_DONE=true
  log_success "Cleanup completed"
}

on_exit() {
  local exit_code=$?
  
  if [ "$TEST_FAILED" = true ] || [ $exit_code -ne 0 ]; then
    log_section "Test Result: FAILED ❌"
    cleanup
    exit 1
  else
    log_section "Test Result: PASSED ✅"
    cleanup
    exit 0
  fi
}

on_error() {
  local line_number=$1
  log_error "Script failed at line $line_number"
  TEST_FAILED=true
}

trap on_exit EXIT
trap 'on_error ${LINENO}' ERR

################################################################################
# Validation Functions
################################################################################

validate_prerequisites() {
  log_section "Validating Prerequisites"
  
  # Check Docker
  if ! command -v docker &> /dev/null; then
    log_error "Docker is not installed"
    exit 2
  fi
  log_success "Docker is installed"
  
  # Check Docker daemon
  if ! docker ps &> /dev/null; then
    log_error "Docker daemon is not running"
    exit 2
  fi
  log_success "Docker daemon is running"
  
  # Check jq
  if ! command -v jq &> /dev/null; then
    log_error "jq is not installed (required for JSON parsing)"
    exit 2
  fi
  log_success "jq is installed"
  
  # Check curl
  if ! command -v curl &> /dev/null; then
    log_error "curl is not installed (required for health checks)"
    exit 2
  fi
  log_success "curl is installed"
  
  # Check Fablo scripts
  if [ ! -f "$FABLO_HOME/fablo.sh" ]; then
    log_error "Fablo script not found: $FABLO_HOME/fablo.sh"
    exit 2
  fi
  log_success "Fablo script found"
  
  if [ ! -f "$FABLO_HOME/fablo-build.sh" ]; then
    log_error "fablo-build.sh not found: $FABLO_HOME/fablo-build.sh"
    exit 2
  fi
  log_success "fablo-build.sh found"
  
  # Create test directories
  mkdir -p "$NETWORK_DIR" "$CONNECT_DIR" "$TEST_LOGS"
  log_success "Test directories created"
  
  # Check disk space
  local available_space
  available_space=$(df "$TEST_ROOT" | awk 'NR==2 {print $4}')
  if [ "$available_space" -lt 4194304 ]; then  # 4GB in KB
    log_error "Insufficient disk space (need 4GB+, have $(( available_space / 1048576 ))GB)"
    exit 2
  fi
  log_success "Sufficient disk space available"
}

################################################################################
# Network Setup Functions
################################################################################

build_fablo() {
  log_section "Building Fablo"
  
  log_info "Running fablo-build.sh..."
  if ! "$FABLO_HOME/fablo-build.sh" >> "${TEST_LOGS}/fablo-build.log" 2>&1; then
    log_error "Fablo build failed"
    cat "${TEST_LOGS}/fablo-build.log"
    exit 1
  fi
  log_success "Fablo build completed"
}

initialize_network() {
  log_section "Initializing Primary Network"
  
  log_info "Initializing Fablo config in: $NETWORK_DIR"
  if ! (cd "$NETWORK_DIR" && "$FABLO_HOME/fablo.sh" init node dev >> "${TEST_LOGS}/init.log" 2>&1); then
    log_error "Failed to initialize Fablo config"
    cat "${TEST_LOGS}/init.log"
    exit 1
  fi
  
  if [ ! -f "$NETWORK_DIR/fablo-config.json" ]; then
    log_error "Fablo config not generated"
    exit 1
  fi
  log_success "Fablo config initialized"
}

start_network() {
  log_section "Starting Primary Network"
  
  log_info "Bringing up network in: $NETWORK_DIR"
  if ! (cd "$NETWORK_DIR" && "$FABLO_HOME/fablo.sh" up >> "${TEST_LOGS}/network-startup.log" 2>&1); then
    log_error "Failed to start network"
    cat "${TEST_LOGS}/network-startup.log"
    exit 1
  fi
  log_success "Network startup command completed"
}

################################################################################
# Health Check Functions
################################################################################

wait_for_container_ready() {
  local container_name="$1"
  local expected_message="$2"
  local timeout="${3:-$CONTAINER_READY_TIMEOUT}"
  
  log_info "Waiting for container: $container_name (timeout: ${timeout}s)"
  log_info "  Expected message: '$expected_message'"
  
  local elapsed=0
  local interval=2
  
  while [ $elapsed -lt $timeout ]; do
    if docker logs "$container_name" 2>/dev/null | grep -q "$expected_message"; then
      log_success "Container '$container_name' is ready"
      return 0
    fi
    
    sleep $interval
    elapsed=$((elapsed + interval))
    
    if [ $((elapsed % 20)) -eq 0 ]; then
      log_info "Still waiting for '$container_name'... (${elapsed}s/${timeout}s)"
    fi
  done
  
  log_error "Timeout waiting for container '$container_name'"
  log_error "Expected message not found: '$expected_message'"
  dump_container_logs "$container_name"
  return 1
}

check_container_health() {
  local container_name="$1"
  
  log_info "Checking health of container: $container_name"
  
  if ! docker ps --filter "name=$container_name" --filter "status=running" | grep -q "$container_name"; then
    log_error "Container is not running: $container_name"
    return 1
  fi
  
  log_success "Container is running: $container_name"
  return 0
}

wait_for_chaincode_ready() {
  local peer="$1"
  local channel="$2"
  local chaincode="$3"
  local version="$4"
  local timeout="${5:-$CHAINCODE_READY_TIMEOUT}"
  
  log_info "Waiting for chaincode: $chaincode/$version on $channel/$peer (timeout: ${timeout}s)"
  
  local elapsed=0
  local interval=3
  local search_string="Name: $chaincode, Version: $version"
  
  while [ $elapsed -lt $timeout ]; do
    if (cd "$NETWORK_DIR" && "$FABLO_HOME/fablo.sh" chaincodes list "$peer" "$channel" 2>/dev/null | grep -q "$search_string"); then
      log_success "Chaincode '$chaincode/$version' is ready on $channel/$peer"
      return 0
    fi
    
    sleep $interval
    elapsed=$((elapsed + interval))
    
    if [ $((elapsed % 20)) -eq 0 ]; then
      log_info "Still waiting for chaincode... (${elapsed}s/${timeout}s)"
    fi
  done
  
  log_error "Timeout waiting for chaincode '$chaincode/$version'"
  return 1
}

wait_for_network_ready() {
  log_section "Waiting for Network Components"
  
  # Wait for orderer
  wait_for_container_ready "$ORDERER" "Channel created" || return 1
  
  # Wait for CA
  wait_for_container_ready "$CA" "Listening on https://0.0.0.0:7054" || return 1
  
  # Wait for peers to join channel
  wait_for_container_ready "$PEER_0" "Joining gossip network of channel $CHANNEL_NAME with 1 organizations" || return 1
  wait_for_container_ready "$PEER_1" "Joining gossip network of channel $CHANNEL_NAME with 1 organizations" || return 1
  
  # Wait for anchor peer learning
  wait_for_container_ready "$PEER_0" "Learning about the configured anchor peers of Org1MSP for channel $CHANNEL_NAME" || return 1
  
  # Wait for chaincodes to be ready
  wait_for_chaincode_ready "$PEER_0" "$CHANNEL_NAME" "$CHAINCODE_NAME" "$CHAINCODE_VERSION" || return 1
  wait_for_chaincode_ready "$PEER_1" "$CHANNEL_NAME" "$CHAINCODE_NAME" "$CHAINCODE_VERSION" || return 1
  
  # Verify container health
  check_container_health "$ORDERER" || return 1
  check_container_health "$CA" || return 1
  check_container_health "$PEER_0" || return 1
  check_container_health "$PEER_1" || return 1
  
  log_success "All network components are ready"
}

################################################################################
# Chaincode Operation Functions
################################################################################

get_block_height() {
  local peer="$1"
  local channel="$2"
  
  log_info "Fetching block height from $peer on $channel"
  
  local block_info
  block_info=$(cd "$NETWORK_DIR" && "$FABLO_HOME/fablo.sh" channel getinfo "$channel" "$ORG_NAME" "$peer" 2>/dev/null || echo "")
  
  if [ -z "$block_info" ]; then
    log_error "Failed to get block info"
    return 1
  fi
  
  local height
  height=$(echo "$block_info" | grep -oP '"height":\s*\K[0-9]+' | head -1)
  
  if [ -z "$height" ]; then
    log_error "Could not parse block height from: $block_info"
    return 1
  fi
  
  echo "$height"
}

invoke_chaincode() {
  local peer="$1"
  local channel="$2"
  local chaincode="$3"
  local command="$4"
  
  log_info "Invoking chaincode: $chaincode on $channel/$peer"
  log_info "  Command: $command"
  
  local response
  response=$(cd "$NETWORK_DIR" && "$FABLO_HOME/fablo.sh" chaincode invoke "$peer" "$channel" "$chaincode" "$command" 2>&1)
  
  if echo "$response" | grep -qi "error\|failed"; then
    log_error "Chaincode invoke failed"
    log_error "Response: $response"
    return 1
  fi
  
  log_success "Chaincode invoke succeeded"
  log_info "Response: $response"
  return 0
}

query_chaincode() {
  local peer="$1"
  local channel="$2"
  local chaincode="$3"
  local command="$4"
  local expected_response="$5"
  
  log_info "Querying chaincode: $chaincode on $channel/$peer"
  log_info "  Command: $command"
  log_info "  Expected response: $expected_response"
  
  local response
  response=$(cd "$NETWORK_DIR" && "$FABLO_HOME/fablo.sh" chaincode query "$peer" "$channel" "$chaincode" "$command" 2>&1)
  
  if echo "$response" | grep -q "$expected_response"; then
    log_success "Chaincode query succeeded"
    log_info "Response: $response"
    return 0
  else
    log_error "Chaincode query failed"
    log_error "Response: $response"
    log_error "Expected: $expected_response"
    return 1
  fi
}

query_chaincode_with_retry() {
  local peer="$1"
  local channel="$2"
  local chaincode="$3"
  local command="$4"
  local expected_response="$5"
  local max_retries="${6:-$MAX_RETRIES}"
  
  log_info "Querying chaincode with retry (max retries: $max_retries)..."
  
  for i in $(seq 1 $max_retries); do
    if query_chaincode "$peer" "$channel" "$chaincode" "$command" "$expected_response"; then
      return 0
    fi
    
    if [ $i -lt $max_retries ]; then
      log_warn "Query attempt $i failed, retrying in ${RETRY_INTERVAL}s..."
      sleep "$RETRY_INTERVAL"
    fi
  done
  
  log_error "Query failed after $max_retries attempts"
  return 1
}

################################################################################
# Block Synchronization Functions
################################################################################

fetch_latest_block() {
  local channel="$1"
  local org="$2"
  local peer="$3"
  
  log_info "Fetching latest block from $channel/$org/$peer"
  
  if ! (cd "$NETWORK_DIR" && "$FABLO_HOME/fablo.sh" channel fetch newest "$channel" "$org" "$peer" >> "${TEST_LOGS}/block-fetch.log" 2>&1); then
    log_error "Failed to fetch latest block"
    return 1
  fi
  
  if [ ! -f "$NETWORK_DIR/newest.block" ]; then
    log_error "Block file not found after fetch"
    return 1
  fi
  
  log_success "Latest block fetched successfully"
  return 0
}

verify_block_contains_transaction() {
  local block_file="$1"
  local search_string="$2"
  
  log_info "Verifying block contains transaction: '$search_string'"
  
  if [ ! -f "$block_file" ]; then
    log_error "Block file not found: $block_file"
    return 1
  fi
  
  if cat "$block_file" | grep -q "$search_string"; then
    log_success "Block contains expected transaction"
    return 0
  else
    log_error "Block does not contain expected transaction"
    return 1
  fi
}

wait_for_block_height_increase() {
  local peer="$1"
  local channel="$2"
  local initial_height="$3"
  local timeout="${4:-$BLOCK_SYNC_TIMEOUT}"
  
  log_info "Waiting for block height to increase from $initial_height (timeout: ${timeout}s)"
  
  local elapsed=0
  local interval=2
  
  while [ $elapsed -lt $timeout ]; do
    local current_height
    if current_height=$(get_block_height "$peer" "$channel"); then
      log_info "Current block height: $current_height"
      
      if [ "$current_height" -gt "$initial_height" ]; then
        log_success "Block height increased to $current_height"
        return 0
      fi
    fi
    
    sleep $interval
    elapsed=$((elapsed + interval))
    
    if [ $((elapsed % 10)) -eq 0 ]; then
      log_info "Still waiting for block height increase... (${elapsed}s/${timeout}s)"
    fi
  done
  
  log_error "Timeout waiting for block height increase"
  return 1
}

################################################################################
# Connect Functions
################################################################################

connect_to_network() {
  log_section "Connecting Second Fablo Instance"
  
  log_info "Connecting to network at: $NETWORK_DIR/fablo-target"
  
  if [ ! -d "$NETWORK_DIR/fablo-target" ]; then
    log_error "Network target directory not found: $NETWORK_DIR/fablo-target"
    return 1
  fi
  
  log_info "Executing fablo connect command..."
  if ! (cd "$CONNECT_DIR" && "$FABLO_HOME/fablo.sh" connect "$NETWORK_DIR/fablo-target" >> "${TEST_LOGS}/connect.log" 2>&1); then
    log_error "Connect command failed"
    cat "${TEST_LOGS}/connect.log"
    return 1
  fi
  
  log_success "Connect command executed successfully"
  
  # Wait for connection to be established
  log_info "Waiting for connection to be established (${CONNECT_READY_TIMEOUT}s)..."
  sleep "$CONNECT_READY_TIMEOUT"
  
  log_success "Connection wait completed"
}

################################################################################
# Test Execution Functions
################################################################################

run_initial_tests() {
  log_section "Running Initial Chaincode Tests"
  
  # Test 1: Get initial block height
  log_info "Test 1: Get initial block height"
  if ! INITIAL_BLOCK_HEIGHT=$(get_block_height "$PEER_0" "$CHANNEL_NAME"); then
    log_error "Failed to get initial block height"
    return 1
  fi
  log_success "Initial block height: $INITIAL_BLOCK_HEIGHT"
  
  # Test 2: Invoke chaincode
  log_info "Test 2: Invoke chaincode to write data"
  if ! invoke_chaincode "$PEER_0" "$CHANNEL_NAME" "$CHAINCODE_NAME" \
    '{"Args":["KVContract:put", "test_key_1", "test_value_1"]}'; then
    log_error "Chaincode invoke failed"
    return 1
  fi
  
  # Test 3: Query from different peer
  log_info "Test 3: Query data from different peer"
  if ! query_chaincode_with_retry "$PEER_1" "$CHANNEL_NAME" "$CHAINCODE_NAME" \
    '{"Args":["KVContract:get", "test_key_1"]}' "test_value_1"; then
    log_error "Chaincode query failed"
    return 1
  fi
  
  # Test 4: Verify block height increased
  log_info "Test 4: Verify block height increased"
  if ! wait_for_block_height_increase "$PEER_0" "$CHANNEL_NAME" "$INITIAL_BLOCK_HEIGHT"; then
    log_error "Block height did not increase"
    return 1
  fi
  
  # Test 5: Fetch and verify block
  log_info "Test 5: Fetch and verify block"
  if ! fetch_latest_block "$CHANNEL_NAME" "$ORG_NAME" "$PEER_0"; then
    log_error "Failed to fetch latest block"
    return 1
  fi
  
  if ! verify_block_contains_transaction "$NETWORK_DIR/newest.block" "KVContract:put"; then
    log_error "Block verification failed"
    return 1
  fi
  
  log_success "All initial tests passed"
}

run_connected_instance_tests() {
  log_section "Running Connected Instance Tests"
  
  # Test 1: Query existing data through connected instance
  log_info "Test 1: Query existing data through connected instance"
  if ! query_chaincode_with_retry "$PEER_0" "$CHANNEL_NAME" "$CHAINCODE_NAME" \
    '{"Args":["KVContract:get", "test_key_1"]}' "test_value_1"; then
    log_error "Failed to query existing data"
    return 1
  fi
  
  # Test 2: Invoke new transaction
  log_info "Test 2: Invoke new transaction through connected instance"
  if ! invoke_chaincode "$PEER_0" "$CHANNEL_NAME" "$CHAINCODE_NAME" \
    '{"Args":["KVContract:put", "test_key_2", "test_value_2"]}'; then
    log_error "Failed to invoke new transaction"
    return 1
  fi
  
  # Test 3: Verify new data is visible
  log_info "Test 3: Verify new data is visible across network"
  if ! query_chaincode_with_retry "$PEER_1" "$CHANNEL_NAME" "$CHAINCODE_NAME" \
    '{"Args":["KVContract:get", "test_key_2"]}' "test_value_2"; then
    log_error "New data not visible across network"
    return 1
  fi
  
  # Test 4: Verify block height increased again
  log_info "Test 4: Verify block height increased after new transaction"
  if ! wait_for_block_height_increase "$PEER_0" "$CHANNEL_NAME" "$INITIAL_BLOCK_HEIGHT"; then
    log_error "Block height did not increase after new transaction"
    return 1
  fi
  
  # Test 5: Fetch and verify new block
  log_info "Test 5: Fetch and verify new block"
  if ! fetch_latest_block "$CHANNEL_NAME" "$ORG_NAME" "$PEER_0"; then
    log_error "Failed to fetch latest block"
    return 1
  fi
  
  if ! verify_block_contains_transaction "$NETWORK_DIR/newest.block" "KVContract:put"; then
    log_error "New block verification failed"
    return 1
  fi
  
  # Test 6: Get final block height
  log_info "Test 6: Get final block height"
  if ! FINAL_BLOCK_HEIGHT=$(get_block_height "$PEER_0" "$CHANNEL_NAME"); then
    log_error "Failed to get final block height"
    return 1
  fi
  log_success "Final block height: $FINAL_BLOCK_HEIGHT"
  
  # Verify block height increased
  if [ "$FINAL_BLOCK_HEIGHT" -le "$INITIAL_BLOCK_HEIGHT" ]; then
    log_error "Block height did not increase: $INITIAL_BLOCK_HEIGHT -> $FINAL_BLOCK_HEIGHT"
    return 1
  fi
  
  log_success "All connected instance tests passed"
}

################################################################################
# Main Execution
################################################################################

main() {
  log_section "Fablo Connect - End-to-End Integration Test"
  log_info "Test started at: $(date)"
  log_info "Test root: $TEST_ROOT"
  log_info "Test logs: $TEST_LOGS"
  
  # Validate prerequisites
  validate_prerequisites
  
  # Build Fablo
  build_fablo
  
  # Initialize and start network
  initialize_network
  start_network
  
  # Wait for network to be ready
  wait_for_network_ready
  
  # Run initial tests
  run_initial_tests
  
  # Connect second instance
  connect_to_network
  
  # Run connected instance tests
  run_connected_instance_tests
  
  log_section "Test Summary"
  log_success "Initial block height: $INITIAL_BLOCK_HEIGHT"
  log_success "Final block height: $FINAL_BLOCK_HEIGHT"
  log_success "Block height increase: $((FINAL_BLOCK_HEIGHT - INITIAL_BLOCK_HEIGHT))"
  log_success "All tests completed successfully"
  log_info "Test logs available at: $TEST_LOGS"
}

# Run main function
main "$@"
