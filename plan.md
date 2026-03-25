# Radius Codebase Study Plan

A structured reading order to get you fully comfortable with the fstester framework — from entry point to test execution.

---

## Phase 1: The Front Door (How a Test Run Starts)

Read these first. They're short and give you the mental model for everything else.

### 1. [fstester.py](radius/fstester.py)

**TLDR:** CLI entry point. Parses args, calls `runner()`.

**What to study:**
- The CLI arguments: `-t` (test file), `-config` (YAML), `-report` (output name)
- Note: `-debug`, `-v`, `-l`, `-u`, `-ctlog` are parsed but **never passed downstream** — dead args

**Key function:** `main()` — that's the whole file.

---

### 2. [runner.py](radius/runner.py)

**TLDR:** The engine. Discovers test classes from a file, instantiates them with dependency injection, runs the lifecycle, generates reports.

**What to study:**
- `runner()` (line ~264) — the main flow: logging setup → collect classes → inject dependencies → run tests → flush report
- `collect_test_classes()` — dynamic module loading via `importlib`, supports `file.py::ClassName` filtering
- `get_objects_from_classes()` — creates a `Configurator`, calls `inject()` per class, handles `@parametrize`
- `run_tests()` — the lifecycle engine: `suite_setup` (once) → [`do_setup` → `do_test` → `do_teardown`] per instance → `suite_teardown` (once)
- `_flush_report()` — generates both HTML and JSON reports

**Gotchas:**
- `AssertionError` typo on line ~127 — harmless because `Exception` catches everything anyway
- `run_class()` is dead code (legacy path, never called by `runner()`)
- `testbed_config` param is accepted but never used

---

### 3. [test_config/radius/radius.yml](radius/test_config/radius/radius.yml)

**TLDR:** The real config with lab IPs, credentials, ports, VLANs.

**What to study:**
- Top-level keys: `ca`, `em`, `radius`, `switch`, `passthrough`, `ocsp` — each becomes a domain object
- Switch `port1`/`port2` configs with `interface` and `vlan`
- Credentials for all devices (root/aristo pattern)
- This is the file you pass with `-config`

---

## Phase 2: The Wiring (Dependency Injection & Object Creation)

### 4. [framework/configurator/configurator.py](radius/framework/configurator/configurator.py)

**TLDR:** Reads YAML, creates domain objects, injects them into test class constructors by matching parameter names to config keys.

**What to study:**
- `eyesight_config()` — iterates config keys, calls factory methods to create CA, EM, switch, passthrough, RADIUS, OCSP objects
- `inject(cls, dependencies)` — introspects `cls.__init__` signature, matches param names to dependency dict keys, calls `cls(**matched_kwargs)`
- `PLUGIN_LIST = ["radius"]` — only "radius" is treated as a plugin

**Key insight:** If your test class `__init__` has a param named `ca`, it gets the `CouterActAppliance` instance. Named `switch`, gets `CiscoIOS`. This is how DI works here — **parameter name matching**.

---

### 5. [framework/configurator/eyesight_factory.py](radius/framework/configurator/eyesight_factory.py)

**TLDR:** Factory that instantiates domain objects from config dicts.

**What to study:**
- `PLUGIN_MAPPING` — maps `"ca"` → `CouterActAppliance`, `"em"` → `EnterpriseManager`, `"radius"` → `Radius`
- `get_ca()` / `get_plugin()` — use `importlib` for dynamic class loading
- `get_switch()` — hardcoded to `CiscoIOS`
- `get_passthrough()` — hardcoded to `WindowsPassthrough`
- `get_plugin(ca_instance, ...)` — plugins always receive the CA as their first arg

---

### 6. [framework/connection/connection_pool.py](radius/framework/connection/connection_pool.py)

**TLDR:** Singleton connection cache with health checks and retry.

**What to study:**
- `CONNECTION_POOL` — the module-level singleton, imported everywhere
- `get(key, creator)` — checks health (Netmiko `is_alive()` or Paramiko `get_transport().is_active()`), retries 3x with 5s/10s backoff
- `close_all()` — called at end of test run
- `evict()` does NOT close the connection — just removes the reference (potential leak)

---

## Phase 3: The Test Hierarchy (Base Classes)

Read these top-down. Each layer adds capabilities.

### 7. [tests/fs_test_common_base/test_base.py](radius/tests/fs_test_common_base/test_base.py)

**TLDR:** Abstract root. Defines the 5-method lifecycle contract.

**What to study:**
- `suite_setup()` — runs once before all tests
- `do_setup()` — runs before each test
- `do_test()` — the actual test
- `do_teardown()` — runs after each test (in `finally`)
- `suite_teardown()` — runs once after all tests

---

### 8. [tests/radius/radius_test_base.py](radius/tests/radius/radius_test_base.py)

**TLDR:** The heavyweight base. This is where 80% of the framework logic lives. Every RADIUS test inherits from this.

**What to study — Constructor (`__init__`):**
- Accepts `ca`, `em`, `switch`, `passthrough`, `radius` (dot1x), `ocsp` — all injected
- Creates `RadiusFactory` for switch RADIUS setup/teardown
- Sets up `RemoteLogStreamer` references

**What to study — `do_setup()`:**
1. Starts two `RemoteLogStreamer`s tailing `dot1x.log` and `radiusd.log` from the CA
2. Calls `build_ad_config()` to resolve AD domains from the CA
3. Calls `add_auth_source()`, `join_domain()`, `set_null()` for AD
4. Calls `configure_radius_settings()` (unless test sets `configure_radius_settings_in_test = True`)
5. Cleans up stale endpoints by MAC
6. Derives IP range from VLAN via `get_ip_range_from_vlan()`
7. Calls `self.rf.setup()` — configures the switch port for 802.1X

**What to study — Assertion helpers (these are the ones tests call):**
- `assert_nic_authentication_status(expected)` — polls Windows NIC until auth status matches
- `verify_nic_ip_in_range()` / `verify_nic_has_no_ip_in_range()` — checks IP assignment
- `verify_authentication_on_ca()` — checks ~10 host properties on CounterAct via `fstool hostinfo`
- `verify_pre_admission_rule(rule_number)` — checks `dot1x_auth_source`
- `verify_wired_properties()` / `verify_wireless_properties()` — NAS Port checks
- `assert_dot1x_plugin_running()` — verifies plugin health
- `assert_mac_in_mar()` / `assert_mac_not_in_mar()` — MAR presence checks

**What to study — Helper methods:**
- `configure_lan_profile(profile)` — writes XML to file, copies to Windows, sets via `netsh lan add profile`
- `toggle_nic()` / `enable_nic()` / `disable_nic()` — trigger 802.1X by bouncing the NIC
- `configure_radius_settings()` — applies `RadiusPluginSettings` to the dot1x plugin
- `setup_pre_admission_and_toggle(rules, cert_config)` — common pattern: set rules → import cert → wait for plugin → configure profile → toggle NIC
- `cleanup_endpoint_by_mac()` — removes stale host entries from CounterAct
- `build_ad_config()` — queries `get_ad_domain_name_mapping()` on the CA

**What to study — `do_teardown()`:**
- Stops both log streamers

**What to study — `suite_teardown()`:**
- Calls `self.rf.teardown()` to unconfigure the switch

---

### 9. [tests/radius/functional/base_classes/radius_certificates_test_base.py](radius/tests/radius/functional/base_classes/radius_certificates_test_base.py)

**TLDR:** Adds certificate management on top of RadiusTestBase. Used by EAP-TLS and PEAP-EAP-TLS tests.

**What to study:**
- `do_setup()` — calls `cleanup_all_test_certificates()` (bulk PowerShell delete from My + Root stores)
- `import_certificates(cert_config)` — the full PFX import workflow:
  1. Parse PFX locally with `cryptography` lib → extract personal + CA thumbprints
  2. Copy PFX to `C:\Certificates\` on Windows
  3. Delete old certs by thumbprint
  4. Import PFX into Personal store
  5. Extract CA cert as DER → write `.cer` → copy to Windows → import into Root store
- `_get_pfx_thumbprints_local()` — local PFX parsing
- `move_ca_cert_to_personal_store()` — negative test helper (breaks trust chain)
- `do_teardown()` — removes certs by thumbprint

---

### 10. [tests/radius/functional/base_classes/radius_eap_tls_test_base.py](radius/tests/radius/functional/base_classes/radius_eap_tls_test_base.py)

**TLDR:** Thin wrapper. Sets `DEFAULT_EAP_TYPE = "EAP-TLS"` and `DEFAULT_LAN_PROFILE = LanProfile.eap_tls()`.

---

### 11. [tests/radius/functional/base_classes/radius_peap_test_base.py](radius/tests/radius/functional/base_classes/radius_peap_test_base.py)

**TLDR:** Adds PEAP credential injection. Downloads PsExec, runs a PowerShell script to set 802.1X credentials on the Windows NIC.

**What to study:**
- `do_setup()` — downloads PsExec to the passthrough
- `configure_peap_credentials(peap_config)` — the credential injection workflow:
  1. Attach to the disconnected RDP session via PsExec
  2. Copy the PEAP PowerShell script to the endpoint
  3. Build a launcher script that calls the PEAP script with credentials
  4. Execute via PsExec in the interactive session
  5. Wait for log file to show "Script Execution Completed"
- Uses `PEAPCredentialsConfig` and `LauncherScriptConfig` dataclasses

---

### 12. [tests/radius/functional/base_classes/radius_peap_eap_tls_test_base.py](radius/tests/radius/functional/base_classes/radius_peap_eap_tls_test_base.py)

**TLDR:** Thin wrapper. Sets `DEFAULT_EAP_TYPE = "PEAP-EAP-TLS"` and `DEFAULT_LAN_PROFILE = LanProfile.peap_eap_tls()`.

---

### 13. [tests/radius/functional/base_classes/radius_mab_test_base.py](radius/tests/radius/functional/base_classes/radius_mab_test_base.py)

**TLDR:** MAB-specific setup. Configures the switch port for MAB (not dot1x), sets a MAB LAN profile (802.1X supplicant disabled).

**What to study:**
- `do_setup()` — does NOT start log streamers. Calls `rf.setup(mab=True)`, configures MAB profile, reads NIC MAC
- `do_teardown()` — removes test MAC from MAR if present

---

### 14. [tests/radius/functional/base_classes/radius_eap_ttls_test_base.py](radius/tests/radius/functional/base_classes/radius_eap_ttls_test_base.py)

**TLDR:** Multiple inheritance — combines `RadiusCertificatesTestBase` + `RadiusPeapTestBase`. Adds outer-tunnel root cert import.

**What to study:**
- Inherits from both certificate and PEAP bases (needs certs for the outer TLS tunnel + credentials for inner methods)
- `do_setup()` — calls `super().do_setup()` (chains through MRO), then imports the root certificate for the outer tunnel

---

## Phase 4: The Domain Libraries (What Tests Control)

### 15. [lib/ca/ca_common_base.py](radius/lib/ca/ca_common_base.py)

**TLDR:** SSH client to CounterACT appliances. The workhorse for running `fstool` commands.

**Key methods:**
- `exec_command(cmd)` — SSH execute with connection pool + one retry
- `scp_file(local, remote, direction)` — SFTP upload/download (name says SCP, uses SFTP)
- `get_host_ip_by_mac(mac)` — resolves MAC → IP via `fstool hostinfo`, with retry and preferred-range selection
- `check_properties(id, check_list)` — polls host properties until they match expected values
- `simple_policy_condition()` / `simple_policy_action()` — build and import CounterACT policy XML
- `add_mac_to_mar()` / `remove_mac_from_mar()` / `get_mar_entry()` — MAC Address Repository ops

**Gotcha:** `is_ipv4` is always forced to `True` regardless of what you pass.

---

### 16. [lib/ca/ca.py](radius/lib/ca/ca.py)

**TLDR:** Extends `CounterActBase` with property checking and AD queries.

**Key methods:**
- `get_property_value(id, field)` — gets a single host property value
- `_property_check(id, field, expected, timeout)` — polls until property matches
- `check_properties(id, check_list)` — iterates a list of checks, raises on mismatch
- `get_ad_domain_name_mapping()` — queries PostgreSQL on the CA for AD domain mappings

**Gotcha:** `__int__` instead of `__init__` — typo, but works because `CounterActBase.__init__` does the real work.

---

### 17. [lib/plugin/radius/radius.py](radius/lib/plugin/radius/radius.py)

**TLDR:** The RADIUS/dot1x plugin controller. Manages plugin lifecycle, settings, pre-admission rules, auth sources, domain joining.

**Key methods:**
- `restart_dot1x_plugin()` — restarts via `fstool dot1x restart`, waits for "Done starting RADIUS."
- `wait_until_running(timeout=300)` — polls until radiusd, winbindd, redis-server are all up and radiusd has been running >45s
- `configure_radius_plugin(conf_dict)` — applies settings via `fstool dot1x set_property`, skips unchanged values, restarts if changed
- `set_pre_admission_rules(rules)` — dispatches to single-condition or multi-condition format, restarts plugin
- `add_auth_source(name)` — adds AD auth source, handles 8.x vs 9.x format differences
- `join_domain(domain, user, password)` — joins AD domain via `fstool dot1x join`

**Key constants:**
- `DOT1X_RESTART_TIMEOUT = 300` (5 minutes)
- `DOT1X_MIN_RADIUSD_UPTIME_SECONDS = 45`
- `DOT1X_REQUIRED_PROCESSES = ("radiusd", "winbindd", "redis-server")`

**Design pattern:** Dirty-tracking via `self.has_change` flag — changes batch up, single restart at the end via `apply_dot1x_changes()`.

---

### 18. [lib/plugin/radius/pre_admission_rule.py](radius/lib/plugin/radius/pre_admission_rule.py)

**TLDR:** Builds pre-admission rule JSON and writes it to `local.properties` on the CA via SFTP.

**What to study:**
- `Context` class — dispatcher mapping criterion names to handler classes
- Criterion classes: `D1XComboStringCriterion`, `D1XStringCriterion`, `D1XSimpleStringCriterion`, `D1XEKUCheckboxListCriterion`, `D1XMSCACheckboxListCriterion`, `D1XBooleanCriterion`
- `D1XStringCriterion.map` — match types: `startswith`, `endswith`, `contains`, `matches`, `matchesexpression`, `anyvalue`
- `set_pre_admission_rules_remote()` — multi-rule writer with slot management
- `to_file()` / `_to_file_multi()` — SFTP read-modify-write to `local.properties`

**Gotcha:** Quadruple-escaped backslashes (`\\\\\\\\Q`) — goes through Python string → JSON → Java properties → Java regex engine.

---

### 19. [lib/plugin/radius/enums.py](radius/lib/plugin/radius/enums.py)

**TLDR:** All the enums. Skim this for reference.

**Important ones:**
- `RadiusAuthStatus` — `ACCESS_ACCEPT`, `ACCESS_REJECT`
- `PreAdmissionAuth` — `ACCEPT = "vlan:\tIsCOA:false"`, `REJECT_DUMMY = "reject=dummy"`
- `EKUEntry` — 29 Extended Key Usage OIDs
- `MSCAEntry` — 27 Microsoft CA OIDs
- `Dot1xAttribute` — certificate attribute field names

---

### 20. [lib/switch/cisco_ios_radius_configure.py](radius/lib/switch/cisco_ios_radius_configure.py)

**TLDR:** Full RADIUS setup/teardown on a Cisco IOS switch. This is the most complex single file.

**What to study:**
- `RadiusCmd` enum — all Cisco CLI command templates (20 entries)
- `setup_radius_config()` — 6 steps: dot1x global → RADIUS server → RADIUS group → AAA → CoA → port config
- `teardown_radius_config()` — reverses setup in 5 steps
- State tracking: `_original_*` fields snapshot the switch config before modification for clean teardown
- `_configure_radius_server()` — handles conflicts when another server owns the same address
- `_configure_dot1x_on_port()` — interface-level: switchport mode, VLAN, auth, dot1x/MAB

**Key design:** Idempotent automation — snapshots original state on first setup, restores on teardown.

---

### 21. [lib/passthrough/windows_passthrough.py](radius/lib/passthrough/windows_passthrough.py)

**TLDR:** WinRM client to the Windows test endpoint. Controls NICs, files, certs, auth status.

**Key methods:**
- `execute_command(cmd, is_ps=True)` — run PowerShell remotely, with retry on transport failure
- `toggle_nic()` / `enable_nic()` / `disable_nic()` — trigger 802.1X by bouncing the NIC
- `wait_for_nic_authentication(nicname, expected_status, timeout=90)` — polls `netsh lan show interfaces`
- `wait_for_nic_ip_in_range(nicname, ip_range, timeout=90)` — polls until NIC gets an IP in CIDR range
- `add_lan_profile()` / `delete_lan_profile()` — `netsh lan` profile management
- `copy_file_to_remote()` — uses `pypsrp` for file transfer
- `get_session_id()` / `attach_disconnected_session()` — PsExec session management for PEAP credential injection

---

### 22. [lib/passthrough/lan_profile_builder.py](radius/lib/passthrough/lan_profile_builder.py)

**TLDR:** Builds Windows 802.1X LAN profile XML. Factory methods for every EAP type.

**What to study:**
- `LanProfile` dataclass with factory class methods:
  - `.eap_tls()`, `.peap()`, `.peap_eap_tls()`, `.mab()`
  - `.eap_ttls_eap_cert()`, `.eap_ttls_eap_mschapv2()`
  - `.eap_ttls_non_eap_pap()`, `.eap_ttls_non_eap_chap()`, `.eap_ttls_non_eap_mschap()`, `.eap_ttls_non_eap_mschapv2()`
- `to_xml()` — builds the complete XML tree
- `_pretty()` — post-processes XML to match the format Windows `netsh lan` expects
- EAP config dataclasses: `EapTlsConfig`, `PeapMsChapV2Config`, `PeapEapTlsConfig`, `EapTtlsConfig`
- TTLS inner method strategy: `TtlsInnerPap`, `TtlsInnerChap`, `TtlsInnerMsChap`, `TtlsInnerMsChapV2`, `TtlsInnerEapMsChapV2`, `TtlsInnerEapTls`

---

## Phase 5: Walk Through Real Tests

Now that you know the infrastructure, trace through these tests end-to-end. For each one, mentally follow: what does `do_setup()` do (through the full inheritance chain) → what does `do_test()` do → what assertions fire → what does `do_teardown()` clean up.

### 23. [tests/radius/functional/radius_functional_eap_tls.py](radius/tests/radius/functional/radius_functional_eap_tls.py)

**Start with `EAPTLSBasicAuthWiredTest` (T1316931) — the simplest EAP-TLS test:**

```
Setup chain: RadiusEapTlsTestBase → RadiusCertificatesTestBase → RadiusTestBase
  → Start log streamers
  → Configure AD auth source + join domain
  → Configure RADIUS plugin settings
  → Clean up stale endpoints
  → Configure switch port for 802.1X
  → Clean up all test certificates on Windows
```

```
do_test():
  1. Set pre-admission rules: EAP-Type=TLS → ACCEPT, User-Name=anyvalue → REJECT
  2. Import valid certificate (Dot1x-CLT-G.pfx)
  3. Wait for dot1x plugin to be running
  4. Configure EAP-TLS LAN profile on Windows
  5. Toggle NIC → triggers 802.1X auth
  6. Assert: NIC auth status = SUCCEEDED
  7. Assert: NIC IP is in VLAN range
  8. Assert: CA host properties show Access-Accept, correct EAP type, etc.
  9. Assert: Pre-admission rule 1 matched
  10. Assert: Wired properties correct
  --- Negative test ---
  11. Move CA cert from Root to Personal store (breaks trust)
  12. Toggle NIC → triggers re-auth
  13. Assert: CA shows RADIUS-Rejected
```

**Then study `EAPTLSPreAdmissionSANTest` (T1316924):**
- Same setup, but tests Subject Alternative Name matching
- Pre-admission rule: Certificate-From-Subject-Alternative-Name contains "san-testid"
- After auth, verifies SAN value appears as a host property on CounterAct

**Then study `EAPTLSPreAdmissionMSCATemplateTest` (T1316960):**
- Multi-step test with 6 sub-tests in one `do_test()`
- Tests certificate template OID matching: exact, invalid, anyvalue, regex, startswith, endswith
- Each sub-step: set new rules → import cert → toggle NIC → assert accept/reject

---

### 24. [tests/radius/functional/radius_functional_peap.py](radius/tests/radius/functional/radius_functional_peap.py)

**Study `TC_9342_PEAPHostAuthenticationWired` first (simplest PEAP):**

```
Setup chain: RadiusPeapTestBase → RadiusTestBase
  → (everything from RadiusTestBase setup)
  → Download PsExec to Windows endpoint
```

```
do_test():
  1. Set pre-admission rules: EAP-Type=PEAP → ACCEPT, catch-all → REJECT
  2. Wait for dot1x plugin
  3. Configure PEAP LAN profile
  4. Configure PEAP credentials (via PsExec + PowerShell script)
  5. Toggle NIC → triggers PEAP auth with username/password
  6. Assert: auth succeeded, IP in range, CA properties correct
  --- Negative test ---
  7. Reconfigure with invalid user "joenotfound"
  8. Toggle NIC
  9. Assert: RADIUS-Rejected
```

**Then study `TC_9340_PEAPAuthenticationUsingLdapGroup`:**
- Tests LDAP-Group pre-admission rules
- Multiple steps: "Domain*" rule, "Domain Admins" rule, "Domain Users" rule
- Each with different users that should/shouldn't match

**Note:** All PEAP tests use `@parametrize("ldap_port", [...])` to run against 4 different LDAP port modes.

---

### 25. [tests/radius/functional/radius_functional_eap_ttls.py](radius/tests/radius/functional/radius_functional_eap_ttls.py)

**Study `TC_9311_EAPTTLSHostAuthenticationWithEAPMethod`:**
- Multiple inheritance (certs + PEAP credentials)
- Tests two inner methods in one test: EAP-TLS then EAP-MSCHAPv2
- Includes negative test with invalid credentials
- Watch how `configure_lan_profile()` switches between `LanProfile.eap_ttls_eap_cert()` and `LanProfile.eap_ttls_eap_mschapv2()`

---

### 26. [tests/radius/functional/radius_functional_mab.py](radius/tests/radius/functional/radius_functional_mab.py)

**Study `MABMACInMARMismatchTest` (T1316942):**
- Completely different setup path (no log streamers, no 802.1X supplicant)
- Uses `RadiusMabTestBase` → switch configured with `mab=True`
- Tests MAR (MAC Address Repository) pre-admission rules
- Step 1: Add MAC to MAR with Deny → assert auth fails
- Step 2: Update MAR to Allow → assert auth succeeds

---

### 27. [tests/radius/functional/radius_functional_peap_eap_tls.py](radius/tests/radius/functional/radius_functional_peap_eap_tls.py)

**Study both tests:**
- `PEAPEAPTLSBasicAuthWiredTest` — basic cert-based auth inside a PEAP tunnel
- `PEAPEAPTLSRegexpPreAdmissionTest` — regex pre-admission rule on User-Name: `host/(.*)`

---

## Phase 6: Supporting Infrastructure (Read as Needed)

These are reference files. Skim them, then come back when you need details.

### [framework/log/logger.py](radius/framework/log/logger.py)
- Singleton logger named `"myframework"`, console at INFO, file at DEBUG
- `runner.py` replaces handlers at startup

### [framework/report/html_report.py](radius/framework/report/html_report.py) + [test_result.py](radius/framework/report/test_result.py)
- HTML report with green/red/yellow badges
- `TestResult` has `test_name`, `status`, `details`, `logs` (logs always empty)
- Duplicate `TestResult` dataclass in html_report.py (harmless, duck typing)

### [framework/decorator/prametrizor.py](radius/framework/decorator/prametrizor.py)
- `@parametrize("arg1,arg2", [(v1,v2), ...])` — sets `_parametrize_args` on class
- Runner creates one instance per value set, populates `self.test_params`

### [framework/ca_log_handler/remote_log_streamer.py](radius/framework/ca_log_handler/remote_log_streamer.py) + [log_pattern_listener.py](radius/framework/ca_log_handler/log_pattern_listener.py)
- `RemoteLogStreamer` — daemon thread that tails a remote log via SSH `tail -F`
- `PatternWatcher` — thread-safe regex matcher, signals when all patterns found
- Used by RadiusTestBase to tail dot1x.log and radiusd.log
- Used by TC_9348 to assert a pattern does NOT appear in radiusd.log

### [lib/plugin/radius/radius_plugin_settings.py](radius/lib/plugin/radius/radius_plugin_settings.py)
- `RadiusPluginSettings` dataclass with all config fields
- `radius_setting_option_mapping` — maps human names → internal property keys

### [lib/plugin/radius/models/](radius/lib/plugin/radius/models/)
- `CertificateAuthConfig` — cert paths, filenames, NIC name (EAP-TLS)
- `PEAPCredentialsConfig` — script paths, domain/user/password (PEAP)
- `MABConfig` — minimal config for MAB

### [lib/switch/cisco_ios.py](radius/lib/switch/cisco_ios.py)
- Netmiko-based switch client
- `normalize_interface()` — `fa0/1` → `FastEthernet0/1`
- List commands → config mode, string commands → exec mode

### [lib/switch/radius_factory.py](radius/lib/switch/radius_factory.py)
- Vendor-agnostic orchestrator, caches instances by switch IP
- Currently only supports `cisco_ios`

### [lib/passthrough/enums.py](radius/lib/passthrough/enums.py)
- `AuthenticationStatus` — SUCCEEDED, FAILED, IN_PROGRESS, NOT_STARTED, DISABLED, MAB
- `WindowsCert` — all test certificate filenames as an enum

### [lib/utils/vlan_mapping.py](radius/lib/utils/vlan_mapping.py)
- `VLAN_MAPPING` — ~240 VLAN IDs → CIDR subnets for the Plano Colo lab
- `get_ip_range_from_vlan(vlan)` / `get_vlan_from_ip(ip)`

### [scripts/radius_nic_PEAP_credentials_config.ps1](radius/scripts/radius_nic_PEAP_credentials_config.ps1)
- PowerShell UI automation that sets 802.1X PEAP credentials on the Windows NIC
- Uses Windows Forms + UI Automation APIs
- Launched on the endpoint via PsExec

### [resources/radius/certificates/](radius/resources/radius/certificates/)
- Test certificates organized by CA: `Dot1x-CA/` (primary), `CA2/` (secondary)
- Good, Revoked, Expired, various EKU/MSCA variants

---

## Quick Reference: The Complete Test Execution Flow

```
CLI: python fstester.py -t tests/.../file.py -config test_config/radius/radius.yml -report my_report

1. fstester.main()
   → argparse → runner(test_suite, config, report)

2. runner()
   → set_up_logging() → creates timestamped log dir
   → collect_test_classes() → importlib loads the .py file, finds test classes
   → get_objects_from_classes() →
       Configurator(yaml) → eyesight_config() →
         EyesightFactory creates: CA, EM, Switch, Passthrough, Radius, OCSP
       For each class: inject(cls, dependencies) → matches __init__ params to objects
       Handles @parametrize → creates N instances
   → run_tests(objects) →
       suite_setup() [once]
       For each test instance:
         do_setup()    → [base class chain: log streamers, AD, plugin config, switch, certs, PsExec]
         do_test()     → [concrete test: set rules, import certs, toggle NIC, assert results]
         do_teardown() → [cleanup: stop logs, remove certs, remove MAR entries]
       suite_teardown() [once] → switch RADIUS teardown
   → CONNECTION_POOL.close_all()
   → _flush_report() → HTML + JSON output
```

---

## Known Gotchas & Bugs to Be Aware Of

| Issue | Location | Impact |
|-------|----------|--------|
| `__int__` instead of `__init__` | `ca.py`, `em.py` | Harmless — parent `__init__` does the work |
| `AssertionError` typo | `runner.py:~127` | Harmless — `Exception` catches all |
| `is_ipv4` always forced `True` | `ca_common_base.py:59` | IPv6 tests may not work as expected |
| `get_id_by_ipv6()` broken | `ca.py` | Calls `exec_command()` with no args |
| Dead code: `run_class()` | `runner.py` | Legacy path, never called |
| Dead code: `@requires` decorator | `configurator/requires.py` | Defined but not used by injection |
| `evict()` doesn't close connections | `connection_pool.py` | Potential connection leak |
| No thread safety in ConnectionPool | `connection_pool.py` | Not currently an issue (single-threaded test runner) |
| Duplicate `TestResult` classes | `test_result.py` vs `html_report.py` | Works via duck typing |
| Unused CLI args | `fstester.py` | `-debug`, `-v`, `-l`, `-u`, `-ctlog` are parsed but discarded |
