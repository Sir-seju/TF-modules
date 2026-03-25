# Radius Plugin Test Automation — Project Summary

## What This Project Is

**fstester** is a Python-based end-to-end test automation framework that validates Forescout's 802.1X / RADIUS plugin ("dot1x") across real hardware. It orchestrates actual network authentication flows — EAP-TLS, PEAP, EAP-TTLS, MAB — against a physical lab of CounterACT appliances, Cisco switches, and Windows endpoints, then asserts correctness.

**The contract:** Upstart Cyber (you) is delivering ~90–100 automated test cases to Forescout over 6 months ($50K/month, $300K total). Forescout's QA must be able to re-execute every test independently, without modification. Signed September/October 2025.

---

## The Protocols Being Tested

**802.1X** is a port-based network access control protocol with three parties:

| Role | Device | Protocol |
|------|--------|----------|
| **Supplicant** (host) | Windows endpoint | EAPOL to switch |
| **Authenticator** (NAD) | Cisco switch | RADIUS to server |
| **Authentication Server** | Forescout + RADIUS plugin | EAP inside RADIUS |

The server returns policy decisions: VLAN assignment, downloadable ACLs (dACLs), SGTs. It can also issue **CoA** (Change of Authorization) to re-evaluate posture mid-session.

**Authentication methods under test:**
- **EAP-TLS** — mutual certificate-based auth (client + server certs)
- **PEAP/MSCHAPv2** — TLS tunnel, then username/password inside
- **PEAP/EAP-TLS** — TLS tunnel, then certificate auth inside
- **EAP-TTLS** — TLS tunnel with various inner methods (PAP, CHAP, MSCHAPv2, EAP-MD5, EAP-MSCHAPv2, EAP-TLS)
- **MAB** — MAC Authentication Bypass for non-802.1X devices (printers, IoT)
- **MAR** — MAC Address Repository for MAC-based lookups

**Also in scope:** TLS 1.0–1.3, RadSec, EAP-TEAP, iPSK, MFA/SSO with Entra ID.

---

## Lab Topology

Three-lane architecture:

```
CONTROL/MANAGEMENT (VLAN 1823, 10.100.49.0/24)
├── Forescout CounterACT + RADIUS Plugin (10.100.49.67, 10.100.49.78)
├── Enterprise Manager (EM)
├── Active Directory / DNS (10.100.49.20)
└── Cisco 4503 SVI (10.100.49.10, RADIUS client)

NAD / ACCESS (VLANs 120/130)
├── Cisco 4503 switch (authenticator)
├── NetScout port controller (patches endpoints to switch ports)
└── VoIP Gateway (VLAN 130)

ENDPOINTS (VLANs 120/130/140)
├── Windows Passthrough VMs (dual-NIC: vmxnet3 for mgmt, pciPassthru0 for 802.1X)
├── IP Phones
└── Optional Wi-Fi AP/WLC
```

The passthrough VM's physical NIC is cabled through NetScout to a Cisco 4503 access port — that NIC is the actual 802.1X supplicant.

---

## Codebase Architecture

```
radius/
├── fstester.py              # CLI entry point
├── runner.py                # Test runner engine
├── framework/               # Core infrastructure
│   ├── configurator/        #   YAML config → dependency injection
│   ├── connection/          #   SSH/Netmiko connection pool
│   ├── log/                 #   Rotating file + console logger
│   ├── report/              #   HTML + JSON test reports
│   ├── decorator/           #   @parametrize for test variations
│   └── ca_log_handler/      #   Remote log streaming + pattern matching
├── lib/                     # Domain libraries
│   ├── ca/                  #   CounterACT appliance control (SSH, fstool, SCP, policies)
│   ├── plugin/radius/       #   RADIUS plugin management (settings, pre-admission rules, EAP config)
│   ├── switch/              #   Cisco IOS switch automation (dot1x, VLAN, CoA via Netmiko)
│   ├── passthrough/         #   Windows endpoint control (WinRM, cert import, NIC toggle, LAN profiles)
│   ├── external_servers/    #   OCSP server placeholder
│   └── utils/               #   VLAN-to-subnet mapping
├── tests/                   # Test suites
│   └── radius/
│       ├── functional/      #   Real e2e tests (EAP-TLS, PEAP, MAB, etc.)
│       └── radius_test.py   #   Base/example tests
├── test_config/radius/      # YAML configs with real lab IPs
├── config/                  # Template/skeleton config
├── web/                     # Flask dashboard for test results
├── scripts/                 # PowerShell for Windows NIC/credential config
└── resources/               # Test certificates, policy XML templates
```

### Key Design Patterns

- **Dependency Injection via YAML**: The `Configurator` reads YAML config, `EyesightFactory` instantiates domain objects (CA, EM, switch, passthrough, RADIUS), and `inject()` matches YAML keys to test class `__init__` parameter names.
- **Connection Pooling**: Global `CONNECTION_POOL` manages SSH/Netmiko connections with retry logic (3 attempts, backoff).
- **Template Method**: `FSTestCommonBase` defines the lifecycle: `suite_setup` → `do_setup` → `do_test` → `do_teardown` → `suite_teardown`. All tests implement these.
- **Test Parametrization**: `@parametrize("args", values)` creates multiple test instances from one class.

### Test Execution Flow

```bash
python fstester.py -t tests/radius/functional/radius_functional_eap_tls.py \
                   -config test_config/radius/radius.yml \
                   -report radius_report
```

1. CLI parses args → `runner()` loads test module via `importlib`
2. Collects test classes (optionally filtered by `::ClassName`)
3. `Configurator.inject()` wires up dependencies from YAML
4. Runs `suite_setup` once, then per-instance: `do_setup` → `do_test` → `do_teardown`
5. `suite_teardown`, close connections, generate HTML + JSON reports

### A Typical EAP-TLS Test Does This

1. Configure a Windows LAN profile for EAP-TLS (XML-based)
2. Set pre-admission rules on the RADIUS plugin via `fstool`
3. Import client certificates to the Windows endpoint
4. Wait for the dot1x plugin to be ready
5. Toggle the NIC to trigger 802.1X authentication
6. Assert authentication succeeded
7. Verify IP is in the expected VLAN
8. Check pre-admission rule match, wired/auth properties, and SAN values on CounterACT

---

## Key Libraries and What They Do

| Library | Role |
|---------|------|
| `lib/ca/ca.py` | SSH into CounterACT appliances. Run `fstool` commands, SCP file transfers, manage policies, check host properties (IPv4/IPv6/MAC), query AD domain mappings. Retry/timeout on property checks. |
| `lib/ca/em.py` | Enterprise Manager — extends CounterACT for EM-specific operations (service restart). |
| `lib/plugin/radius/radius.py` | Core RADIUS plugin controller. Restart dot1x, configure settings via `fstool dot1x set_property`, manage pre-admission rules, configure auth sources, join AD domains. |
| `lib/plugin/radius/pre_admission_rule.py` | Builds pre-admission rules with multiple criterion types (combo strings, EKU checklists, MSCA checklists, booleans, regex). Writes rules to `local.properties` on remote CA via SFTP. |
| `lib/switch/cisco_ios.py` | Netmiko-based Cisco IOS controller. Normalizes interface names, connection pooling. |
| `lib/switch/cisco_ios_radius_configure.py` | Full switch RADIUS setup/teardown: AAA model, radius server, dot1x/MAB per-port config, CoA, VLANs. |
| `lib/passthrough/windows_passthrough.py` | WinRM/NTLM to Windows endpoints. File ops, NIC enable/disable/toggle, 802.1X auth status monitoring, LAN profile management, PsExec. |
| `lib/passthrough/lan_profile_builder.py` | XML builder for Windows 802.1X LAN profiles. Factory methods for every EAP type. |

---

## Dependencies

**Runtime:** `paramiko` (SSH), `netmiko` (Cisco automation), `pywinrm` + `pypsrp` (Windows Remote Management), `pyyaml`, `cryptography`

**Dev:** `black`, `isort`, `ruff`, `pylint`, `mypy`, `pre-commit` — line length 130 chars everywhere.

---

## Current Project Status (as of Feb 2026 Gap Analysis)

### Issues Identified

1. **Flaky/non-deterministic appliance behavior** — inconsistent test outcomes, difficult triage
2. **Harness refactors happening while QA is baselining** — QA becomes the first gate for harness correctness
3. **Left-shift gap** — limited unit/integration test coverage before end-to-end lab runs
4. **Testers not formally trained** on the appliance; triage is slow

### Remediation Plan

| Phase | Timeline | Focus |
|-------|----------|-------|
| **Phase 0** | 0–2 weeks | Determinism contracts per scenario. Automated preflight health checks. Freeze baseline harness for QA. |
| **Phase 1** | 2–6 weeks | Dev-owned unit tests + controlled integration suite. Separate Ansible (orchestration) from Python harness (assertions). JUnit output. |
| **Phase 2** | 6–12 weeks | Flake management (quarantine, consecutive-pass promotion). CI gating. Full training/KT. QA runbook. |

### Definition of Done (per test case)

1. Passes in engineering lab with documented prerequisites
2. Solution QA re-executes without modification using the runbook
3. All ~90–100 cases pass acceptance

---

## Key People

| Role | Person |
|------|--------|
| **Forescout Manager** | Orone Laizerovich (Sr. Director, Global QA) |
| **Upstart Consultant** | Joshua Loatman (COO, Upstart Cyber LLC) |

---

## Quick Reference — Running Tests

```bash
# Run a specific test file
python fstester.py -t tests/radius/functional/radius_functional_eap_tls.py \
                   -config test_config/radius/radius.yml \
                   -report my_report

# Run a specific test class
python fstester.py -t tests/radius/functional/radius_functional_eap_tls.py::EAPTLSPreAdmissionSANTest \
                   -config test_config/radius/radius.yml

# Start the results dashboard
python web/dashboard.py  # http://localhost:5000

# Dev setup
./setup-dev.sh
./generate-requirements.sh
```
