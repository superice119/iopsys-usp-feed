#!/bin/sh

. /usr/share/libubox/jshn.sh

# Default temporary file for timezone mapping
TMP_MAP="/tmp/timezone_map.txt"

# -----------------------------------------------------------------------------
# Function: generate_supported_zones
# Description: Generates a JSON array of supported zones in the format:
# [
#   { "time_zone": "TZ_STRING", "zone_name": "Region/City,Region/City" },
#   ...
# ]
# Output: Prints the JSON to stdout (caller can redirect to a file)
# -----------------------------------------------------------------------------
generate_supported_zones() {
    : > "$TMP_MAP"

    # Step 1: Collect zonename -> timezone mappings into TMP_MAP
    for entry in /usr/share/zoneinfo/*; do
        [ -d "$entry" ] || continue
        region=$(basename "$entry")

        for zonefile in "$entry"/*; do
            [ -f "$zonefile" ] || continue
            city=$(basename "$zonefile")
            zonename="${region}/${city}"

            tz_string=$(tail -n 1 "$zonefile" 2>/dev/null)
            [ -n "$tz_string" ] && echo "$tz_string|$zonename" >> "$TMP_MAP"
        done
    done

    # Step 2: Group zone names by tz_string and format to intermediate file
    TMP_LINES="/tmp/timezone_lines.txt"
    awk -F'|' '
    {
        tz = $1
        zn = $2
        if (tz in tzmap) {
            tzmap[tz] = tzmap[tz] "," zn
        } else {
            tzmap[tz] = zn
        }
    }
    END {
        for (tz in tzmap) {
            printf("TZSEP%sSEPZN%s\n", tz, tzmap[tz])
        }
    }
    ' "$TMP_MAP" > "$TMP_LINES"

    # Step 3: Convert the grouped result to JSON output
    json_init
    json_add_array "supported_zones"

    while IFS= read -r line; do
        timezone=$(echo "$line" | sed -n 's/^TZSEP\(.*\)SEPZN.*/\1/p')
        zonenames=$(echo "$line" | sed -n 's/^TZSEP.*SEPZN\(.*\)/\1/p')
        [ -n "$timezone" ] || continue

        json_add_object ""
        json_add_string "time_zone" "$timezone"
        json_add_string "zone_name" "$zonenames"
        json_close_object
    done < "$TMP_LINES"

    json_close_array
    json_dump

    # Cleanup
    rm -f "$TMP_MAP" "$TMP_LINES"
}

