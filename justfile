# justfile

set shell := ["bash", "-eu", "-o", "pipefail", "-c"]
set dotenv-load := true

export ANSIBLE_CONFIG := "{{ justfile_directory() }}/ansible.cfg"

ci := env_var_or_default("CI", "false")
force_doppler := env_var_or_default("FORCE_DOPPLER", "0")
doppler := env_var_or_default("DOPPLER", "1")

run_prefix := if doppler == "0" {
  ""
} else if ci == "true" {
  if force_doppler == "1" {
    "doppler run --"
  } else {
    ""
  }
} else {
  "doppler run --"
}

# Remove all non-versioned build artifacts and temporary files
clean:
  {{run_prefix}} bash -lc 'scripts/clean.sh'

# Runway checks (OS/persona independent)
l0-runway:
  {{run_prefix}} bash -lc 'scripts/l0/runway.sh'
