#!/usr/bin/env bash
# =============================================================================
# Mini Pupper BSP — Noble/Jazzy Hardware Verification Script
# Run this on your Raspberry Pi after setup_jazzy.sh completes.
# Usage: sudo bash verify_noble.sh
# =============================================================================

set -euo pipefail

PASS=0
FAIL=0
WARN=0

# Colours
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
RESET='\033[0m'

pass() { echo -e "  ${GREEN}[PASS]${RESET} $1"; PASS=$((PASS+1)); }
fail() { echo -e "  ${RED}[FAIL]${RESET} $1"; FAIL=$((FAIL+1)); }
warn() { echo -e "  ${YELLOW}[WARN]${RESET} $1"; WARN=$((WARN+1)); }
header() { echo -e "\n${BOLD}==> $1${RESET}"; }

# =============================================================================
# Pre-flight checks
# =============================================================================
header "Pre-flight"

if [[ $EUID -ne 0 ]]; then
    fail "This script must be run as root (sudo bash verify_noble.sh)"
    exit 1
fi

CODENAME=$(lsb_release -cs 2>/dev/null || echo "unknown")
KERNEL=$(uname -r)

if [[ "$CODENAME" == "noble" ]]; then
    pass "Ubuntu codename is Noble (24.04)"
else
    fail "Expected Noble, got: $CODENAME — run this on your Pi with Ubuntu 24.04"
    exit 1
fi

KERNEL_MAJOR=$(echo "$KERNEL" | cut -d. -f1)
KERNEL_MINOR=$(echo "$KERNEL" | cut -d. -f2)
if [[ "$KERNEL_MAJOR" -gt 6 ]] || { [[ "$KERNEL_MAJOR" -eq 6 ]] && [[ "$KERNEL_MINOR" -ge 8 ]]; }; then
    pass "Kernel $KERNEL is >= 6.8"
else
    warn "Kernel $KERNEL is < 6.8 — GPIO_BASE detection may behave differently"
fi

# =============================================================================
# CHECK 1: nvmem device path (3-00500 vs 3-00501)
# =============================================================================
header "Check 1 — nvmem device path (install.sh TODO at line 133)"

NVMEM_BASE="/sys/bus/nvmem/devices"
NVMEM_501="${NVMEM_BASE}/3-00501/nvmem"
NVMEM_500="${NVMEM_BASE}/3-00500/nvmem"

echo "  Devices found under ${NVMEM_BASE}:"
ls "$NVMEM_BASE" 2>/dev/null | grep "3-005" | sed 's/^/    /' || echo "    (none matching 3-005xx)"

if [[ -e "$NVMEM_501" ]]; then
    pass "3-00501 exists"
    if hexdump "$NVMEM_501" 2>/dev/null | head -1 | grep -qv "^$"; then
        pass "3-00501 is readable — install.sh patch (3-00500 → 3-00501) is CORRECT for Noble"
        NVMEM_VERDICT="3-00501 (correct)"
    else
        fail "3-00501 exists but could not be read — check EEPROM/DKMS"
        NVMEM_VERDICT="3-00501 (unreadable)"
    fi
elif [[ -e "$NVMEM_500" ]]; then
    warn "Only 3-00500 exists — install.sh patch may be wrong for this hardware"
    if hexdump "$NVMEM_500" 2>/dev/null | head -1 | grep -qv "^$"; then
        warn "3-00500 is readable — consider reverting the nvmem patch for Noble"
        NVMEM_VERDICT="3-00500 (patch may be wrong)"
    else
        fail "3-00500 exists but could not be read"
        NVMEM_VERDICT="3-00500 (unreadable)"
    fi
else
    fail "Neither 3-00500 nor 3-00501 found — EEPROM driver not loaded (check DKMS)"
    NVMEM_VERDICT="not found"
fi

# =============================================================================
# CHECK 2: at24.c DKMS module status on kernel 6.8
# =============================================================================
header "Check 2 — at24 DKMS build status (prepare_dkms.sh TODO at line 23)"

if command -v dkms &>/dev/null; then
    DKMS_STATUS=$(dkms status 2>/dev/null | grep at24 || true)
    if [[ -n "$DKMS_STATUS" ]]; then
        echo "  dkms status: $DKMS_STATUS"
        if echo "$DKMS_STATUS" | grep -q "installed"; then
            pass "at24 DKMS module is installed for kernel $KERNEL"
        else
            fail "at24 DKMS module found but not installed — build may have failed"
        fi
    else
        fail "at24 not found in dkms status — prepare_dkms.sh may not have run"
    fi
else
    warn "dkms command not found — skipping DKMS check"
fi

echo "  dmesg at24 entries (last 5):"
dmesg 2>/dev/null | grep -i at24 | tail -5 | sed 's/^/    /' || echo "    (none)"

if dmesg 2>/dev/null | grep -qi "at24.*error\|at24.*fail"; then
    fail "dmesg contains at24 error/fail messages — driver may have loaded with errors"
else
    pass "No at24 error messages in dmesg"
fi

# =============================================================================
# CHECK 3: JointChecker / HardwareInterface regression
# =============================================================================
header "Check 3 — HardwareInterface JointChecker (upstream PR #52 regression)"

BSP_DIR="$(cd "$(dirname "$0")" && pwd)"
PYTHON_MODULE="${BSP_DIR}/Python_Module"

if [[ ! -d "$PYTHON_MODULE" ]]; then
    warn "Python_Module not found at ${PYTHON_MODULE} — skipping Python checks"
    warn "Re-run this script from the root of the mini_pupper_bsp directory"
else
    PYTHONPATH="$PYTHON_MODULE" python3 - <<'PYEOF' 2>&1 | sed 's/^/  /'
import sys
try:
    from MangDang.mini_pupper.HardwareInterface import HardwareInterface
    import inspect
    sig = inspect.signature(HardwareInterface.__init__)
    if 'joint_checker_flag' in sig.parameters:
        print("PASS: joint_checker_flag parameter exists in HardwareInterface.__init__")
        sys.exit(0)
    else:
        print("FAIL: joint_checker_flag parameter MISSING from HardwareInterface.__init__")
        print("      Upstream PR #52 (JointChecker class) has not been merged into this fork.")
        print("      Any caller using HardwareInterface(joint_checker_flag=True) will crash.")
        sys.exit(1)
except ImportError as e:
    print(f"FAIL: Could not import HardwareInterface: {e}")
    sys.exit(2)
PYEOF
    PYEXIT=${PIPESTATUS[0]}
    if [[ $PYEXIT -eq 0 ]]; then
        PASS=$((PASS+1))
    else
        FAIL=$((FAIL+1))
    fi
fi

# =============================================================================
# CHECK 4: GPIO_BASE detection and sysfs paths
# =============================================================================
header "Check 4 — GPIO_BASE offset and sysfs paths (test.sh fix verification)"

GPIO_SYSFS="/sys/class/gpio"

# Detect GPIO_BASE the same way battery_monitor and test.sh now do
GPIO_BASE=0
for chip in /sys/class/gpio/gpiochip*/; do
    label_file="${chip}label"
    if [[ -f "$label_file" ]]; then
        label=$(cat "$label_file")
        if [[ "$label" == "pinctrl-bcm2711" || "$label" == "pinctrl-rp1" ]]; then
            GPIO_BASE=$(cat "${chip}base")
            break
        fi
    fi
done

if [[ $GPIO_BASE -gt 0 ]]; then
    pass "GPIO_BASE detected: $GPIO_BASE"
else
    fail "Could not detect GPIO_BASE — no pinctrl-bcm2711 or pinctrl-rp1 gpiochip found"
    GPIO_BASE=0
fi

GPIO21_PATH="${GPIO_SYSFS}/gpio$((GPIO_BASE + 21))"
GPIO25_PATH="${GPIO_SYSFS}/gpio$((GPIO_BASE + 25))"

echo "  Expected GPIO paths:"
echo "    gpio21 → gpio$((GPIO_BASE + 21)): ${GPIO21_PATH}"
echo "    gpio25 → gpio$((GPIO_BASE + 25)): ${GPIO25_PATH}"

# Export to check
for PIN in 21 25; do
    OFFSET=$((GPIO_BASE + PIN))
    echo "$OFFSET" > /sys/class/gpio/export 2>/dev/null || true
    if [[ -d "${GPIO_SYSFS}/gpio${OFFSET}" ]]; then
        pass "gpio${OFFSET} (gpio${PIN} + base ${GPIO_BASE}) is accessible"
        echo "$OFFSET" > /sys/class/gpio/unexport 2>/dev/null || true
    else
        fail "gpio${OFFSET} path does not exist — GPIO_BASE detection may be wrong"
    fi
done

# =============================================================================
# SUMMARY
# =============================================================================
TOTAL=$((PASS + FAIL + WARN))
echo ""
echo -e "${BOLD}============================================================${RESET}"
echo -e "${BOLD}  VERIFICATION SUMMARY${RESET}"
echo -e "${BOLD}============================================================${RESET}"
echo -e "  ${GREEN}PASS${RESET}: $PASS"
echo -e "  ${RED}FAIL${RESET}: $FAIL"
echo -e "  ${YELLOW}WARN${RESET}: $WARN"
echo ""
echo "  Findings:"
echo "    nvmem path:    $NVMEM_VERDICT"
echo "    Kernel:        $KERNEL"
echo "    GPIO_BASE:     $GPIO_BASE"
echo ""

if [[ $FAIL -eq 0 && $WARN -eq 0 ]]; then
    echo -e "  ${GREEN}${BOLD}All checks passed — BSP is ready for Noble/Jazzy.${RESET}"
elif [[ $FAIL -eq 0 ]]; then
    echo -e "  ${YELLOW}${BOLD}All checks passed with warnings — review WARN items above.${RESET}"
else
    echo -e "  ${RED}${BOLD}$FAIL check(s) failed — resolve FAIL items before publishing.${RESET}"
fi
echo -e "${BOLD}============================================================${RESET}"
