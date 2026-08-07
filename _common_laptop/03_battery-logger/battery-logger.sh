#!/usr/bin/env bash
set -euo pipefail

LOGFILE="${BATTERY_LOGFILE:-/var/log/battery-log.csv}"
BAT=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -n1)

# Nominal seconds between "log" samples. Intervals longer than
# SUSPEND_FACTOR * this are treated as suspend gaps by "analyze".
NOMINAL_INTERVAL=60
SUSPEND_FACTOR=5

HEADER="timestamp,epoch,status,energy_now_wh,energy_full_wh,energy_full_design_wh,voltage_v,power_rate_w,time_to_empty_h,percentage,capacity_health_pct,cycle_count,brightness_pct,cpu_governor,cpu_freq_mhz,wakeup_irq,wakeup_device,wakeup_source,delta_wh,elapsed_s,avg_drain_w"

read_int() { [[ -r "$1" ]] && cat "$1" 2>/dev/null || echo ""; }

# Map an IRQ number to a device/handler name via /proc/interrupts
irq_to_device() {
    local irq="$1"
    [[ -z "$irq" || "$irq" == "-1" ]] && { echo ""; return; }
    awk -v want="$irq" '
        {
            n=$1; sub(/:$/,"",n)
            if (n == want) { print $NF; exit }
        }' /proc/interrupts 2>/dev/null || echo ""
}

# -------------------------------------------------------------------
# collect_data: populates global vars used by log/test.
# -------------------------------------------------------------------
collect_data() {
    TS=$(date '+%Y-%m-%d %H:%M:%S')
    EPOCH=$(date '+%s')
    STATUS=$(read_int "$BAT/status")

    local energy_now energy_full energy_full_design voltage power_now
    if [[ -r "$BAT/energy_now" ]]; then
        energy_now=$(read_int "$BAT/energy_now")
        energy_full=$(read_int "$BAT/energy_full")
        energy_full_design=$(read_int "$BAT/energy_full_design")
        power_now=$(read_int "$BAT/power_now")
        voltage=$(read_int "$BAT/voltage_now")
    else
        local charge_now charge_full charge_full_design current_now
        charge_now=$(read_int "$BAT/charge_now")
        charge_full=$(read_int "$BAT/charge_full")
        charge_full_design=$(read_int "$BAT/charge_full_design")
        current_now=$(read_int "$BAT/current_now")
        voltage=$(read_int "$BAT/voltage_now")
        energy_now=$(( charge_now * voltage / 1000000 ))
        energy_full=$(( charge_full * voltage / 1000000 ))
        energy_full_design=$(( charge_full_design * voltage / 1000000 ))
        power_now=$(( current_now * voltage / 1000000 ))
    fi

    ENERGY_NOW_WH=$(awk "BEGIN{printf \"%.4f\", ${energy_now:-0}/1000000}")
    ENERGY_FULL_WH=$(awk "BEGIN{printf \"%.3f\", ${energy_full:-0}/1000000}")
    ENERGY_FULL_DESIGN_WH=$(awk "BEGIN{printf \"%.3f\", ${energy_full_design:-0}/1000000}")
    VOLTAGE_V=$(awk "BEGIN{printf \"%.3f\", ${voltage:-0}/1000000}")
    POWER_RATE_W=$(awk "BEGIN{printf \"%.3f\", ${power_now:-0}/1000000}")

    TTE=""
    if [[ "$STATUS" == "Discharging" && "${power_now:-0}" -gt 0 ]]; then
        TTE=$(awk "BEGIN{printf \"%.3f\", $energy_now/$power_now}")
    fi

    PCT=$(read_int "$BAT/capacity")

    HEALTH=""
    if [[ "${energy_full_design:-0}" -gt 0 ]]; then
        HEALTH=$(awk "BEGIN{printf \"%.1f\", ${energy_full}*100/${energy_full_design}}")
    fi

    CYCLES=$(read_int "$BAT/cycle_count")

    BRIGHT=""
    local bl
    bl=$(ls -d /sys/class/backlight/* 2>/dev/null | head -n1)
    if [[ -n "$bl" && -r "$bl/brightness" && -r "$bl/max_brightness" ]]; then
        local b m
        b=$(cat "$bl/brightness"); m=$(cat "$bl/max_brightness")
        [[ "$m" -gt 0 ]] && BRIGHT=$(awk "BEGIN{printf \"%.0f\", $b*100/$m}")
    fi

    GOV=$(read_int /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)
    FREQ=""
    local f
    f=$(read_int /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq)
    [[ -n "$f" ]] && FREQ=$(awk "BEGIN{printf \"%.0f\", $f/1000}")

    WAKEUP_IRQ=$(cat /sys/power/pm_wakeup_irq 2>/dev/null || echo "")
    WAKEUP_DEVICE=$(irq_to_device "$WAKEUP_IRQ")
    WAKEUP_SRC=$(grep -m1 -E '\s(active|enabled)\s' /sys/kernel/debug/wakeup_sources 2>/dev/null | awk '{print $1}' || echo "")

    # diff against previous data row
    PREV_ENERGY=""; PREV_EPOCH=""; DELTA_WH=""; ELAPSED=""; AVG_DRAIN=""
    if [[ -s "$LOGFILE" ]]; then
        local last
        last=$(tail -n1 "$LOGFILE")
        if [[ "$last" != "$HEADER" && -n "$last" ]]; then
            PREV_EPOCH=$(echo "$last" | cut -d',' -f2)
            PREV_ENERGY=$(echo "$last" | cut -d',' -f4)
        fi
    fi
    if [[ -n "$PREV_ENERGY" && -n "$PREV_EPOCH" ]]; then
        DELTA_WH=$(awk "BEGIN{printf \"%.4f\", $ENERGY_NOW_WH - $PREV_ENERGY}")
        ELAPSED=$(( EPOCH - PREV_EPOCH ))
        if [[ "$ELAPSED" -gt 0 ]]; then
            AVG_DRAIN=$(awk "BEGIN{printf \"%.3f\", ($PREV_ENERGY - $ENERGY_NOW_WH) / ($ELAPSED/3600)}")
        fi
    fi
}

csv_line() {
    echo "$TS,$EPOCH,$STATUS,$ENERGY_NOW_WH,$ENERGY_FULL_WH,$ENERGY_FULL_DESIGN_WH,$VOLTAGE_V,$POWER_RATE_W,$TTE,$PCT,$HEALTH,$CYCLES,$BRIGHT,$GOV,$FREQ,$WAKEUP_IRQ,$WAKEUP_DEVICE,$WAKEUP_SRC,$DELTA_WH,$ELAPSED,$AVG_DRAIN"
}

# -------------------------------------------------------------------
# subcommand: log
# -------------------------------------------------------------------
cmd_log() {
    if [[ ! -s "$LOGFILE" ]]; then
        mkdir -p "$(dirname "$LOGFILE")"
        echo "$HEADER" >> "$LOGFILE"
    fi
    collect_data
    csv_line | tee -a "$LOGFILE"
}

# -------------------------------------------------------------------
# subcommand: test  (readable dump, no file write)
# -------------------------------------------------------------------
cmd_test() {
    collect_data
    printf '%-22s %s\n' "Timestamp:"        "$TS"
    printf '%-22s %s\n' "Status:"           "$STATUS"
    printf '%-22s %s Wh\n' "Energy now:"    "$ENERGY_NOW_WH"
    printf '%-22s %s Wh\n' "Energy full:"   "$ENERGY_FULL_WH"
    printf '%-22s %s Wh\n' "Energy design:" "$ENERGY_FULL_DESIGN_WH"
    printf '%-22s %s V\n' "Voltage:"        "$VOLTAGE_V"
    printf '%-22s %s W\n' "Power draw now:" "$POWER_RATE_W"
    printf '%-22s %s%%\n' "Charge:"         "${PCT:-?}"
    printf '%-22s %s h\n' "Time to empty:"  "${TTE:-n/a}"
    printf '%-22s %s%%\n' "Battery health:" "${HEALTH:-?}"
    printf '%-22s %s\n' "Cycle count:"      "${CYCLES:-?}"
    printf '%-22s %s%%\n' "Display bright:" "${BRIGHT:-?}"
    printf '%-22s %s\n' "CPU governor:"     "${GOV:-?}"
    printf '%-22s %s MHz\n' "CPU frequency:" "${FREQ:-?}"
    printf '%-22s %s\n' "Wakeup IRQ:"       "${WAKEUP_IRQ:-none}"
    printf '%-22s %s\n' "Wakeup device:"    "${WAKEUP_DEVICE:-none}"
    printf '%-22s %s\n' "Wakeup source:"    "${WAKEUP_SRC:-none}"
    if [[ -n "$AVG_DRAIN" ]]; then
        printf '%-22s %s W over %s s\n' "Since last sample:" "$AVG_DRAIN" "$ELAPSED"
    fi
}

# -------------------------------------------------------------------
# subcommand: analyze  (human-readable report from the CSV)
# -------------------------------------------------------------------
cmd_analyze() {
    if [[ ! -s "$LOGFILE" ]]; then
        echo "No log file at $LOGFILE" >&2
        exit 1
    fi

    awk -F',' -v nominal="$NOMINAL_INTERVAL" -v factor="$SUSPEND_FACTOR" '
    NR==1 { next }  # header
    {
        status=$3; energy=$4; pct=$10; health=$11; cycles=$12
        efull=$5; edesign=$6
        elapsed=$20+0; drain=$21
        epoch=$2

        # track overall span & battery snapshots
        if (first_epoch=="") { first_epoch=epoch; first_energy=energy; first_ts=$1 }
        last_epoch=epoch; last_energy=energy; last_ts=$1
        last_pct=pct; last_health=health; last_cycles=cycles
        last_efull=efull; last_edesign=edesign

        # need a valid drain and elapsed to classify
        if (drain=="" || elapsed<=0) next

        # only count on-battery intervals; charging/full skew the averages
        if (status=="Charging" || status=="Full" || status=="Not charging") {
            skipped++
            next
        }

        threshold = nominal*factor
        if (elapsed >= threshold) {
            # suspend window
            sus_energy += (drain*elapsed/3600)   # Wh consumed
            sus_time   += elapsed
            sus_n++
            if (drain > sus_max) { sus_max=drain; sus_max_ts=$1 }
        } else {
            # active window
            act_energy += (drain*elapsed/3600)
            act_time   += elapsed
            act_n++
            if (drain > act_max) { act_max=drain; act_max_ts=$1 }
        }
        rows++
    }
    END {
        if (rows==0) { print "No usable data rows."; exit }

        span = last_epoch - first_epoch
        printf "Battery Log Analysis\n"
        printf "====================\n"
        printf "Samples analyzed : %d\n", rows
        if (skipped>0)
            printf "Skipped (charge) : %d intervals excluded (charging/full)\n", skipped
        printf "Time span        : %s  ->  %s  (%.1f h)\n", first_ts, last_ts, span/3600
        printf "\n"

        printf "Battery health\n"
        printf "  Charge now     : %s%%\n", last_pct
        printf "  Capacity health: %s%% of design", last_health
        printf "  (%.1f of %.1f Wh)\n", last_efull, last_edesign
        printf "  Cycle count    : %s\n", last_cycles
        printf "\n"

        printf "Active operation (intervals < %d s)\n", nominal*factor
        if (act_n>0) {
            printf "  Windows        : %d\n", act_n
            printf "  Avg power draw : %.3f W\n", act_energy/(act_time/3600)
            printf "  Energy used    : %.2f Wh over %.2f h\n", act_energy, act_time/3600
            printf "  Peak draw      : %.3f W  (at %s)\n", act_max, act_max_ts
        } else { printf "  (no active intervals)\n" }
        printf "\n"

        printf "Suspend / deep sleep (intervals >= %d s)\n", nominal*factor
        if (sus_n>0) {
            printf "  Windows        : %d\n", sus_n
            printf "  Avg power draw : %.3f W\n", sus_energy/(sus_time/3600)
            printf "  Energy used    : %.2f Wh over %.2f h\n", sus_energy, sus_time/3600
            printf "  Worst window   : %.3f W  (resume at %s)\n", sus_max, sus_max_ts
            self_disch = sus_energy/(sus_time/3600)
            if (last_edesign+0 > 0) {
                printf "  Est. full-charge suspend life: %.1f h\n", last_edesign/self_disch
            }
        } else { printf "  (no suspend windows detected)\n" }
        printf "\n"

        printf "Overall\n"
        net = first_energy - last_energy
        if (span>0)
            printf "  Net avg draw   : %.3f W  (%.2f Wh over %.1f h)\n", net/(span/3600), net, span/3600
    }' "$LOGFILE"
}

# -------------------------------------------------------------------
usage() {
    cat >&2 <<EOF
Usage: $(basename "$0") {log|test|analyze}

  log      Collect one sample and append it to $LOGFILE
  test     Collect one sample and print it human-readably (no write)
  analyze  Summarize the CSV: active vs suspend power draw, battery health
EOF
    exit 1
}

case "${1:-}" in
    log)     cmd_log ;;
    test)    cmd_test ;;
    analyze) cmd_analyze ;;
    *)       usage ;;
esac