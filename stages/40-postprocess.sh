post_stage() {
  resolv_conf_teardown

  chroot_teardown "${DEST_IMG}"
}

# PUMP increases the image's size about the given amount.
#
# Usage: PUMP SIZE_IN_MB
PUMP() {
  echo -e "\033[0;32m### PUMP ${1}; file system usage:\033[0m"
  df -h "${CHROOT_MOUNT}"
}

ZERO() {
  echo -e "\033[0;32m### ZERO; filling the filesystem with zeros...\033[0m"
  zero_fill
}

# SHRINK shrinks the image to its minimal size using PiShrink.
# Optionally, a size parameter can be provided to shrink to a specific size.
#
# Usage: SHRINK [SIZE]
SHRINK() {
  if [[ -b "${DEST_IMG}" ]]; then
    echo -e "\033[0;31m### Error: Block device ${DEST_IMG} cannot be shrunk.\033[0m"
    return 1
  fi

  echo -e "\033[0;32m### SHRINK${1:+ ${1}}\033[0m"

  # Download PiShrink if not already cached
  local pishrink_script="${PIMOD_CACHE}/pishrink.sh"
  
  if [[ ! -f "${pishrink_script}" ]]; then
    echo "Downloading PiShrink..."
    mkdir -p "${PIMOD_CACHE}"
    if ! wget -q -O "${pishrink_script}" "https://raw.githubusercontent.com/Drewsif/PiShrink/master/pishrink.sh"; then
      echo -e "\033[0;31m### Error: Failed to download PiShrink.\033[0m"
      return 1
    fi
    chmod +x "${pishrink_script}"
  fi

  # If size parameter is provided, shrink to that size
  if [[ -n "${1:-}" ]]; then
    echo "Shrinking image to specific size: ${1}"
    
    # Mount the image to get the current filesystem size
    local loop
    loop=$(mount_image "${DEST_IMG}")
    
    # Get the root partition device
    local root_dev="/dev/mapper/${loop}p${IMG_ROOT}"
    
    # Check current filesystem size
    local current_size
    current_size=$(df -B1 "${CHROOT_MOUNT}" 2>/dev/null | tail -1 | awk '{print $3}')
    
    umount_image "${loop}"
    
    if [[ -z "${current_size}" ]]; then
      echo -e "\033[0;31m### Error: Could not determine current filesystem size.\033[0m"
      return 1
    fi

    # Convert target size to bytes
    local target_bytes
    if ! target_bytes=$(units -t "${1}B" "B" 2>/dev/null); then
      echo -e "\033[0;31m### Error: Invalid size format. Use suffixes K, M, G (e.g., 2G).\033[0m"
      return 1
    fi
    
    # Remove decimal if present
    target_bytes=${target_bytes%.*}
    
    if [[ ${target_bytes} -lt ${current_size} ]]; then
      echo -e "\033[0;33m### Warning: Target size (${1}) is smaller than current filesystem usage. Will shrink to minimum possible size instead.\033[0m"
      # Run PiShrink without size parameter to get minimum size
      if ! "${pishrink_script}" -s "${DEST_IMG}"; then
        echo -e "\033[0;31m### Error: PiShrink failed.\033[0m"
        return 1
      fi
    else
      # First shrink to minimum, then expand to target size
      if ! "${pishrink_script}" -s "${DEST_IMG}"; then
        echo -e "\033[0;31m### Error: PiShrink failed.\033[0m"
        return 1
      fi
      
      # Calculate how much to expand
      local current_img_size
      current_img_size=$(stat -c%s "${DEST_IMG}")
      local expand_size=$((target_bytes - current_img_size))
      
      if [[ ${expand_size} -gt 0 ]]; then
        echo "Expanding image to target size..."
        local expand_mb=$((expand_size / 1048576 + 1))
        PUMP "${expand_mb}M"
      fi
    fi
  else
    # No size parameter, shrink to minimum
    echo "Shrinking image to minimum size..."
    if ! "${pishrink_script}" -s "${DEST_IMG}"; then
      echo -e "\033[0;31m### Error: PiShrink failed.\033[0m"
      return 1
    fi
  fi

  echo -e "\033[0;32m### SHRINK complete.\033[0m"
  ls -lh "${DEST_IMG}"
}
