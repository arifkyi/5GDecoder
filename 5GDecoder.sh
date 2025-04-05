#!/bin/bash

# === DISSECTOR LIST ===
DISSECTORS=(
  "nr-rrc.bcch.bch"
  "nr-rrc.bcch.dl.sch"
  "nr-rrc.dl.ccch"
  "nr-rrc.dl.dcch"
  "nr-rrc.pcch"
  "nr-rrc.ul.ccch"
  "nr-rrc.ul.ccch1"
  "nr-rrc.ul.dcch"
  "nr-rrc.sbcch.sl.bch"
  "nr-rrc.scch"
  "nr-rrc.ueradiopaginginformation"
  "nr-rrc.ueradioaccesscapabilityinformation"
  "nr-rrc.rrc_reconf"
  "nr-rrc.uemrdccapability"
  "nr-rrc.uennrcapability"
  "nr-rrc.radiobearerconfig"
  "nas-5gs"
  "mac-nr"
)

# === INPUT VALIDATION ===
if [ -z "$1" ]; then
  echo "Usage: $0 <hex_string> [dissector_name or number (1-${#DISSECTORS[@]})]"
  echo "Available dissectors:"
  for i in "${!DISSECTORS[@]}"; do
    printf "  %2d) %s\n" $((i+1)) "${DISSECTORS[$i]}"
  done
  echo " $((${#DISSECTORS[@]}+1))) all"
  exit 1
fi

HEX_STRING=$1

# === DISSECTOR SELECTION ===
if [ -n "$2" ]; then
  SELECTED="$2"
else
  echo "Select dissector:"
  for i in "${!DISSECTORS[@]}"; do
    printf "  %2d) %s\n" $((i+1)) "${DISSECTORS[$i]}"
  done
  echo " $((${#DISSECTORS[@]}+1))) not sure/all"
  read -p "Enter number [1-$((${#DISSECTORS[@]}+1))]: " SELECTED
fi

# === TIMESTAMP ===
TIMESTAMP=$(date +"%Y%m%d%H%M%S")
OUT_ALL="${TIMESTAMP}_decoded_output.txt"

# === FUNCTION TO CONVERT ONE DISSECTOR ===
convert_hex() {
  local DISSECTOR="$1"
  local OUT_TXT="${TIMESTAMP}_${DISSECTOR//./_}.tmp.txt"
  local OUT_PCAP="${TIMESTAMP}_${DISSECTOR//./_}.tmp.pcap"

  echo ""
  echo "=== Processing with dissector: $DISSECTOR ===" | tee -a "$OUT_ALL"

  echo "$HEX_STRING" | xxd -r -p | xxd -g 1 -c 16 | awk '{printf "%06X  %s\n", NR*16-16, substr($0, 10)}' > "$OUT_TXT"

  /Applications/Wireshark.app/Contents/MacOS/text2pcap -E wireshark-upper-pdu -P "$DISSECTOR" "$OUT_TXT" "$OUT_PCAP" >/dev/null 2>&1

  /Applications/Wireshark.app/Contents/MacOS/tshark -r "$OUT_PCAP" -V 2>/dev/null | tee -a "$OUT_ALL"

  # Cleanup
  rm -f "$OUT_TXT" "$OUT_PCAP"
}

# === PROCESS ===
if [[ "$SELECTED" == "$(( ${#DISSECTORS[@]} + 1 ))" || "$SELECTED" == "all" ]]; then
  for dissector in "${DISSECTORS[@]}"; do
    convert_hex "$dissector"
  done
else
  if [[ "$SELECTED" =~ ^[0-9]+$ ]] && [ "$SELECTED" -ge 1 ] && [ "$SELECTED" -le "${#DISSECTORS[@]}" ]; then
    DISSECTOR=${DISSECTORS[$((SELECTED-1))]}
  else
    DISSECTOR="$SELECTED"  # Use string directly
  fi
  convert_hex "$DISSECTOR"
fi

echo ""
echo "✅ All decoded output saved to: $OUT_ALL"
