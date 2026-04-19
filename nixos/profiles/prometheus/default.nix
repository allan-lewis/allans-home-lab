{ config, lib, pkgs, ... }:

let
  cfg = config.services.homelab.prometheus;

  rulesFile = pkgs.writeText "prometheus-rules.yml" ''
    groups:
      - name: homelab.rules
        rules:
          - record: homelab_task_allowed_age_seconds
            expr: |
              label_replace(vector(3600), "task", "backup_runner", "", "")
              or label_replace(vector(3600), "task", "managed_state", "", "")
              or label_replace(vector(3600), "task", "media_sync", "", "")
              or label_replace(vector(25 * 3600), "task", "postgres_db_backup", "", "")
              or label_replace(vector(7 * 24 * 3600), "task", "s3_local_mirror", "", "")

          - alert: Watchdog
            expr: vector(1)
            for: 0m
            labels:
              severity: info
              rulegroup: homelabRules
            annotations:
              summary: "Watchdog"
              description: "This alert is always firing to verify Prometheus → Alertmanager delivery."

          - alert: WatchdogMissing
            expr: absent(ALERTS{alertname="Watchdog", alertstate="firing"})
            for: 5m
            labels:
              severity: critical
              rulegroup: homelabRules
            annotations:
              summary: "Watchdog is NOT firing"
              description: "Prometheus is not observing the Watchdog alert firing (rules not loaded/evaluating, config issue, or Prometheus trouble)."

          - alert: HomelabPublicIPPatternInvalid
            expr: |
              count(count_values("ip", homelab_public_ip_numeric)) != 2
              or
              min(count_values("ip", homelab_public_ip_numeric)) != 1
            for: 5m
            labels:
              severity: critical
              rulegroup: homelabRules
            annotations:
              summary: "Unexpected public IP distribution across homelab nodes"
              description: |
                Expected exactly one node to report a different public IP address.
                This alert fires when all nodes agree or when multiple nodes disagree,
                and persists in that state for at least 10 minutes.

          - alert: HomelabPublicIPMetricStale
            expr: time() - homelab_public_ip_last_success_unix > 1200
            for: 5m
            labels:
              severity: critical
              rulegroup: homelabRules
            annotations:
              summary: "Public IP update metric is stale"
              description: |
                The public IP update metric has not refreshed in over 20 minutes.

          - alert: HomelabGatusFailures
            expr: |
              gatus_results_endpoint_success == 0
            for: 5m
            labels:
              severity: critical
              rulegroup: homelabRules
            annotations:
              summary: "Gatus check failure: {{ $labels.name }}"
              description: |
                The Gatus endpoint "{{ $labels.name }}" has been failing
                for at least 5 minutes.

          - alert: HomelabHighCPUUsage
            expr: 100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
            for: 5m
            labels:
              severity: critical
              rulegroup: homelabRules
            annotations:
              summary: "High CPU usage detected on {{ $labels.instance }}"
              description: |
                Host {{ $labels.instance }} has had CPU usage over 80% for more than 5 minutes. Current usage: {{ $value | printf "%.2f" }}%

          - alert: HomelabHighTemperature
            expr: |
              max by(instance) (
                node_hwmon_temp_celsius{chip=~"platform_coretemp_0|pci0000:00_0000:00:18_3"}
              ) > 80
            for: 5m
            labels:
              severity: critical
              rulegroup: homelabRules
            annotations:
              summary: "High temperature detected on {{ $labels.instance }}"
              description: |
                Host {{ $labels.instance }} has had a sensor reporting temperature over 80°C for more than 5 minutes.
                Current temperature: {{ $value | printf "%.1f" }}°C

          - alert: HomelabHighMemoryUsage
            expr: |
              100 - (
                (node_memory_MemAvailable_bytes{job="node-exporter", instance!~"pennywise|gilead"} * 100)
                / node_memory_MemTotal_bytes{job="node-exporter", instance!~"pennywise|gilead"}
              ) > 90
            for: 5m
            labels:
              severity: critical
              rulegroup: homelabRules
            annotations:
              summary: "High memory usage detected on {{ $labels.instance }}"
              description: |
                Host {{ $labels.instance }} has had memory usage above 90% for more than 5 minutes.
                Current usage: {{ $value | printf "%.1f" }}%

          - alert: PrometheusTargetDown
            expr: |
              max_over_time(up[5m]) == 0
            for: 5m
            labels:
              severity: critical
              rulegroup: homelabRules
            annotations:
              summary: "Prometheus scrape target down: {{ $labels.job }} / {{ $labels.instance }}"
              description: |
                Prometheus has been unable to scrape the target
                job="{{ $labels.job }}", instance="{{ $labels.instance }}"
                for at least 5 minutes.

          - alert: HomelabTaskMetricsCountMismatch
            expr: |
              count(homelab_task_last_run_unix{task!~"^(hello|managed_state_restore|managed_dirs_rehydrate|dev_checkouts_sync)$"}) != 10
            labels:
              severity: critical
              rulegroup: homelabRules
            annotations:
              summary: "Homelab task metric count mismatch (expected 10, got {{ $value }})"
              description: |
                The global count of published homelab task metrics does not match the expected value.
                This usually indicates that one or more tasks are missing, duplicated, or misconfigured.
                expected="10", observed="{{ $value }}"

          - alert: HomelabTaskFailed
            expr: |
              homelab_task_last_exit_code != 0
            labels:
              severity: critical
              rulegroup: homelabRules
            annotations:
              summary: "Homelab task failed: {{ $labels.instance }} / {{ $labels.task }}"
              description: |
                A homelab task reported a non-zero exit code on the latest run.
                instance="{{ $labels.instance }}"
                task="{{ $labels.task }}"
                exit_code="{{ $value }}"

          - alert: HomelabTaskStaleSuccess
            expr: |
              (
                (time() - homelab_task_last_success_unix)
                /
                on(task) group_left
                homelab_task_allowed_age_seconds
              ) > 1.15
            labels:
              severity: critical
              rulegroup: homelabRules
            annotations:
              summary: "Homelab task overdue: {{ $labels.instance }} / {{ $labels.task }}"
              description: |
                Task has exceeded its allowed success window by more than 15%.

                instance="{{ $labels.instance }}"
                task="{{ $labels.task }}"
                utilization="{{ printf "%.2f" $value }}"
  '';
in
{
  options.services.homelab.prometheus = {
    enable = lib.mkEnableOption "homelab Prometheus";

    port = lib.mkOption {
      type = lib.types.port;
      default = 3072;
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };

    retentionTime = lib.mkOption {
      type = lib.types.str;
      default = "14d";
    };
  };

  config = lib.mkIf cfg.enable {
    services.prometheus = {
      enable = true;
      port = cfg.port;
      retentionTime = cfg.retentionTime;

      globalConfig = {
        scrape_interval = "15s";
        evaluation_interval = "15s";
      };

      scrapeConfigs = [
        {
          job_name = "node-exporter";
          static_configs = [
            {
              targets = [ "192.168.86.222:9100" ];
              labels.__meta_friendly_instance = "blaine";
            }
            {
              targets = [ "192.168.86.228:9100" ];
              labels.__meta_friendly_instance = "carrie";
            }
            {
              targets = [ "192.168.86.219:9100" ];
              labels.__meta_friendly_instance = "cujo";
            }
            {
              targets = [ "192.168.86.217:9100" ];
              labels.__meta_friendly_instance = "dandelo";
            }
            {
              targets = [ "192.168.86.210:9100" ];
              labels.__meta_friendly_instance = "derry";
            }
            {
              targets = [ "192.168.86.204:9100" ];
              labels.__meta_friendly_instance = "flagg";
            }
            {
              targets = [ "100.95.108.6:9100" ];
              labels.__meta_friendly_instance = "gilead";
            }
            {
              targets = [ "192.168.86.218:9100" ];
              labels.__meta_friendly_instance = "langolier";
            }
            {
              targets = [ "192.168.86.200:9100" ];
              labels.__meta_friendly_instance = "maturin";
            }
            {
              targets = [ "192.168.86.227:9100" ];
              labels.__meta_friendly_instance = "misery";
            }
            {
              targets = [ "192.168.86.229:9100" ];
              labels.__meta_friendly_instance = "overlook";
            }
            {
              targets = [ "192.168.86.224:9100" ];
              labels.__meta_friendly_instance = "patricia";
            }
            {
              targets = [ "192.168.86.220:9100" ];
              labels.__meta_friendly_instance = "pennywise";
            }
            {
              targets = [ "192.168.86.206:9100" ];
              labels.__meta_friendly_instance = "roland";
            }
          ];
          relabel_configs = [
            {
              action = "replace";
              source_labels = [ "__address__" ];
              target_label = "target";
            }
            {
              action = "replace";
              source_labels = [ "__meta_friendly_instance" ];
              target_label = "instance";
            }
          ];
        }

        {
          job_name = "cloudflare";
          static_configs = [
            {
              targets = [ "192.168.86.204:2000" ];
              labels.__meta_friendly_instance = "flagg";
            }
          ];
          relabel_configs = [
            {
              action = "replace";
              source_labels = [ "__address__" ];
              target_label = "target";
            }
            {
              action = "replace";
              source_labels = [ "__meta_friendly_instance" ];
              target_label = "instance";
            }
          ];
        }

        {
          job_name = "gatus";
          static_configs = [
            {
              targets = [ "192.168.86.204:8080" ];
              labels.__meta_friendly_instance = "flagg";
            }
          ];
          relabel_configs = [
            {
              action = "replace";
              source_labels = [ "__address__" ];
              target_label = "target";
            }
            {
              action = "replace";
              source_labels = [ "__meta_friendly_instance" ];
              target_label = "instance";
            }
          ];
        }

        {
          job_name = "homelab-metrics";
          static_configs = [
            {
              targets = [ "192.168.86.228:9102" ];
              labels.__meta_friendly_instance = "carrie";
            }
            {
              targets = [ "192.168.86.219:9102" ];
              labels.__meta_friendly_instance = "cujo";
            }
            {
              targets = [ "192.168.86.204:9102" ];
              labels.__meta_friendly_instance = "flagg";
            }
            {
              targets = [ "192.168.86.218:9102" ];
              labels.__meta_friendly_instance = "langolier";
            }
            {
              targets = [ "192.168.86.227:9102" ];
              labels.__meta_friendly_instance = "misery";
            }
            {
              targets = [ "192.168.86.224:9102" ];
              labels.__meta_friendly_instance = "patricia";
            }
          ];
          relabel_configs = [
            {
              action = "replace";
              source_labels = [ "__address__" ];
              target_label = "target";
            }
            {
              action = "replace";
              source_labels = [ "__meta_friendly_instance" ];
              target_label = "instance";
            }
          ];
        }
      ];

      alertmanagers = [
        {
          static_configs = [
            {
              targets = [ "127.0.0.1:3070" ];
            }
          ];
        }
      ];
      
      ruleFiles = [ rulesFile ];
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];
  };
}