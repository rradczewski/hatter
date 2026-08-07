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
# subcommand: analyze  (per-session report from the CSV)
#
# Groups consecutive samples into contiguous "sessions". A session is a
# maximal run of intervals of the same kind:
#   - suspend : the interval preceding the row is >= NOMINAL*SUSPEND_FACTOR
#   - active  : the interval preceding the row is <  NOMINAL*SUSPEND_FACTOR
# Charging/Full/Not-charging intervals break the current session (energy
# accounting during charge is not comparable) and are reported separately.
# Each session is printed as an aligned line-item block so two sleep
# cycles or two awake cycles can be compared directly.
# -------------------------------------------------------------------
cmd_analyze() {
    if [[ ! -s "$LOGFILE" ]]; then
        echo "No log file at $LOGFILE" >&2
        exit 1
    fi

    awk -F',' -v nominal="$NOMINAL_INTERVAL" -v factor="$SUSPEND_FACTOR" '
    function fmt_dur(s,    h,m,sec,out) {
        s=int(s+0.5); h=int(s/3600); s-=h*3600; m=int(s/60); sec=s-m*60
        if (h>0) return sprintf("%dh%02dm", h, m)
        if (m>0) return sprintf("%dm%02ds", m, sec)
        return sprintf("%ds", sec)
    }
    # flush the currently-accumulating session to the sessions[] arrays
    function flush_session(    idx) {
        if (cur_kind=="" || cur_n==0) { cur_kind=""; return }
        idx = ++sess_count
        s_kind[idx]    = cur_kind
        s_start[idx]   = cur_start_ts
        s_end[idx]     = cur_end_ts
        s_time[idx]    = cur_time
        s_energy[idx]  = cur_energy
        s_n[idx]       = cur_n
        s_max[idx]     = cur_max
        s_max_ts[idx]  = cur_max_ts
        s_e_start[idx] = cur_e_start
        s_e_end[idx]   = cur_e_end
        s_wake[idx]    = cur_wake
        # reset accumulator
        cur_kind=""; cur_n=0; cur_time=0; cur_energy=0
        cur_max=-1e9; cur_max_ts=""; cur_wake=""
    }
    NR==1 { next }  # header
    {
        ts=$1; status=$3; energy=$4; pct=$10; health=$11; cycles=$12
        efull=$5; edesign=$6
        wsrc=$18
        elapsed=$20+0; drain=$21
        epoch=$2

        # overall span & latest battery snapshot
        if (first_epoch=="") { first_epoch=epoch; first_energy=energy; first_ts=ts }
        last_epoch=epoch; last_energy=energy; last_ts=ts
        last_pct=pct; last_health=health; last_cycles=cycles
        last_efull=efull; last_edesign=edesign

        # rows without a usable interval cannot be classified; they still
        # mark energy endpoints but do not extend a session on their own
        if (drain=="" || elapsed<=0) next

        # charging/full breaks any running session and is tallied apart
        if (status=="Charging" || status=="Full" || status=="Not charging") {
            flush_session()
            charge_n++
            next
        }

        threshold = nominal*factor
        kind = (elapsed >= threshold) ? "suspend" : "active"

        # start a new session when the kind changes
        if (kind != cur_kind) {
            flush_session()
            cur_kind    = kind
            cur_start_ts= ts
            cur_e_start = energy
            cur_max     = -1e9
        }

        cur_end_ts = ts
        cur_e_end  = energy
        cur_time  += elapsed
        cur_energy+= (drain*elapsed/3600)   # Wh consumed this interval
        cur_n++
        if (drain > cur_max) { cur_max=drain; cur_max_ts=ts }
        if (wsrc!="" && cur_wake=="") cur_wake=wsrc

        rows++
    }
    END {
        flush_session()
        if (rows==0) { print "No usable data rows."; exit }

        span = last_epoch - first_epoch
        printf "Battery Log Analysis\n"
        printf "====================\n"
        printf "Samples analyzed : %d\n", rows
        if (charge_n>0)
            printf "Charging intervals excluded : %d\n", charge_n
        printf "Time span        : %s  ->  %s  (%s)\n", first_ts, last_ts, fmt_dur(span)
        printf "Sessions found   : %d\n", sess_count
        printf "\n"

        printf "Battery health\n"
        printf "  Charge now     : %s%%\n", last_pct
        printf "  Capacity health: %s%% of design (%.1f of %.1f Wh)\n", last_health, last_efull, last_edesign
        printf "  Cycle count    : %s\n", last_cycles
        printf "\n"

        # ---- all cycles, grouped by kind, as line items ---------------
        # Every awake/sleep cycle in the log is listed. "Avg delta" on each
        # cycle compares it against the previous cycle of the same kind, so
        # you can read any two cycles against each other down the column.
        # Awake cycles
        na=0; for (i=1;i<=sess_count;i++) if (s_kind[i]=="active") ai[++na]=i
        if (na>=1) {
            printf "Awake cycles (%d)\n", na
            prev_avg=""
            for (k=1;k<=na;k++) {
                idx=ai[k]
                avg=s_energy[idx]/(s_time[idx]/3600)
                printf "  Awake #%d\n", k
                printf "    %-16s %s  ->  %s\n", "Window:",   s_start[idx], s_end[idx]
                printf "    %-16s %s\n",         "Duration:", fmt_dur(s_time[idx])
                printf "    %-16s %d\n",         "Samples:",  s_n[idx]
                printf "    %-16s %.3f W\n",     "Avg draw:", avg
                printf "    %-16s %.2f Wh\n",    "Energy used:", s_energy[idx]
                printf "    %-16s %.3f W  (at %s)\n", "Peak draw:", s_max[idx], s_max_ts[idx]
                printf "    %-16s %.4f -> %.4f Wh\n", "Battery span:", s_e_start[idx], s_e_end[idx]
                if (prev_avg!="" && prev_avg>0)
                    printf "    %-16s %+.1f%% vs Awake #%d\n", "Avg draw delta:", (avg-prev_avg)/prev_avg*100, k-1
                prev_avg=avg
            }
            printf "\n"
        }
        # Sleep cycles
        ns=0; for (i=1;i<=sess_count;i++) if (s_kind[i]=="suspend") si[++ns]=i
        if (ns>=1) {
            printf "Sleep cycles (%d)\n", ns
            prev_avg=""
            for (k=1;k<=ns;k++) {
                idx=si[k]
                avg=s_energy[idx]/(s_time[idx]/3600)
                printf "  Sleep #%d\n", k
                printf "    %-16s %s  ->  %s\n", "Window:",   s_start[idx], s_end[idx]
                printf "    %-16s %s\n",         "Duration:", fmt_dur(s_time[idx])
                printf "    %-16s %d\n",         "Samples:",  s_n[idx]
                printf "    %-16s %.3f W\n",     "Avg draw:", avg
                printf "    %-16s %.2f Wh\n",    "Energy used:", s_energy[idx]
                printf "    %-16s %.3f W  (at %s)\n", "Peak draw:", s_max[idx], s_max_ts[idx]
                printf "    %-16s %.4f -> %.4f Wh\n", "Battery span:", s_e_start[idx], s_e_end[idx]
                if (s_wake[idx]!="")
                    printf "    %-16s %s\n",     "Wake source:", s_wake[idx]
                if (last_edesign+0 > 0 && avg>0)
                    printf "    %-16s %s\n",     "Est. sleep life:", fmt_dur(last_edesign/avg*3600)
                if (prev_avg!="" && prev_avg>0)
                    printf "    %-16s %+.1f%% vs Sleep #%d\n", "Avg draw delta:", (avg-prev_avg)/prev_avg*100, k-1
                prev_avg=avg
            }
            printf "\n"
        }

        # ---- aggregate totals -----------------------------------------
        for (i=1;i<=sess_count;i++) {
            if (s_kind[i]=="active") { tot_act_e+=s_energy[i]; tot_act_t+=s_time[i] }
            else                     { tot_sus_e+=s_energy[i]; tot_sus_t+=s_time[i] }
        }
        printf "Totals\n"
        if (tot_act_t>0)
            printf "  %-16s %.2f Wh over %s  (avg %.3f W)\n", "Awake:", tot_act_e, fmt_dur(tot_act_t), tot_act_e/(tot_act_t/3600)
        if (tot_sus_t>0)
            printf "  %-16s %.2f Wh over %s  (avg %.3f W)\n", "Sleep:", tot_sus_e, fmt_dur(tot_sus_t), tot_sus_e/(tot_sus_t/3600)
        net = first_energy - last_energy
        if (span>0)
            printf "  %-16s %.3f W  (%.2f Wh over %s)\n", "Net avg draw:", net/(span/3600), net, fmt_dur(span)
    }' "$LOGFILE"
}

# -------------------------------------------------------------------
usage() {
    cat >&2 <<EOF
Usage: $(basename "$0") {log|test|analyze}

  log      Collect one sample and append it to $LOGFILE
  test     Collect one sample and print it human-readably (no write)
  analyze  Per-cycle report: every awake and sleep cycle in the log as
           aligned line items, each with a delta vs the previous cycle
           of the same kind
EOF
    exit 1
}

case "${1:-}" in
    log)     cmd_log ;;
    test)    cmd_test ;;
    analyze) cmd_analyze ;;
    *)       usage ;;
esac