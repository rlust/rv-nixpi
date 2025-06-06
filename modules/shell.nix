{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    fish
  ];

  programs.fish.enable = true;

  # Custom greeting message
  programs.fish.interactiveShellInit = ''
    function fish_greeting
      # System Info
      set -l system_path (readlink /run/current-system)
      set -l system_label (basename $system_path)
      set -l kernel_version (uname -r)
      set -l current_hostname (hostname)

      # Performance Metrics
      # Calculate uptime directly from /proc/uptime using awk to get integer seconds
      set -l uptime_sec (cat /proc/uptime | awk '{print int($1)}')

      # Calculate total minutes, total hours, days, remaining hours, remaining minutes with defaults
      set -l total_mins (math --scale=0 "$uptime_sec / 60" || echo 0)
      set -l total_hours (math --scale=0 "$total_mins / 60" || echo 0)
      set -l days (math --scale=0 "$total_hours / 24" || echo 0)
      set -l hours (math --scale=0 "$total_hours % 24" || echo 0)
      set -l mins (math --scale=0 "$total_mins % 60" || echo 0)

      # Use correct fish variable expansion ($var) and escape $ for Nix ($$var)
      set -l uptime_direct_str "$$days d $$hours h $$mins m"

      set -l load_avg (uptime | command awk -F 'load average: ' '{print $2}' | command awk -F, '{print $1}')
      set -l mem_info (free -h | command awk '/^Mem:/ {print $3" / "$2}') # Used / Total RAM
      set -l disk_usage (df -h / | command awk 'NR==2 {print $5}') # Root partition usage %

      # Define colors (vibrant for dark backgrounds)
      set -l color_host brcyan
      set -l color_kernel brgreen
      set -l color_system bryellow
      set -l color_load brmagenta
      set -l color_mem brblue
      set -l color_disk brred
      set -l color_uptime brwhite # Bright White for uptime
      set -l color_reset normal

      # Define box characters
      set -l box_tl "╭"
      set -l box_tr "╮"
      set -l box_bl "╰"
      set -l box_br "╯"
      set -l box_h "─"
      set -l box_v "│"

      # Define dimensions (adjust width as needed)
      set -l width 95 # Increased width again
      set -l inner_width (math $width - 4) # Width inside the box borders │  ...  │

      # Create horizontal line
      set -l h_line (string repeat -n (math $width - 2) $box_h)

      # --- Prepare content strings with colors ---
      set -l welcome_content "Welcome to "(set_color $color_host)$current_hostname(set_color $color_reset)
      set -l kernel_content "  Kernel: "(set_color $color_kernel)$kernel_version(set_color $color_reset)
      set -l system_content "  System: "(set_color $color_system)$system_label(set_color $color_reset)
      set -l uptime_direct_content "  Uptime (boot): "(set_color $color_uptime)$uptime_direct_str(set_color $color_reset)
      set -l load_content "  Load (1m): "(set_color $color_load)$load_avg(set_color $color_reset)
      set -l memory_content "  Memory: "(set_color $color_mem)$mem_info(set_color $color_reset)
      set -l disk_content "  Disk /: "(set_color $color_disk)$disk_usage(set_color $color_reset)

      # --- Prepare plain text versions for length calculation ---
      set -l welcome_plain "Welcome to $current_hostname"
      set -l kernel_plain "  Kernel: $kernel_version"
      set -l system_plain "  System: $system_label"
      set -l uptime_direct_plain "  Uptime (boot): $uptime_direct_str"
      set -l load_plain "  Load (1m): $load_avg"
      set -l memory_plain "  Memory: $mem_info"
      set -l disk_plain "  Disk /: $disk_usage"

      # --- Print Box ---
      # Top border
      printf "%s%s%s\n" $box_tl $h_line $box_tr

      # Welcome line
      set -l welcome_padding (string repeat -n (math $inner_width - (string length $welcome_plain)) " ")
      printf "%s %s%s %s\n" $box_v $welcome_content $welcome_padding $box_v

      # Kernel line
      set -l kernel_padding (string repeat -n (math $inner_width - (string length $kernel_plain)) " ")
      printf "%s %s%s %s\n" $box_v $kernel_content $kernel_padding $box_v

      # System line
      set -l system_padding (string repeat -n (math $inner_width - (string length $system_plain)) " ")
      printf "%s %s%s %s\n" $box_v $system_content $system_padding $box_v

      # Uptime line (calculated)
      set -l uptime_direct_padding (string repeat -n (math $inner_width - (string length $uptime_direct_plain)) " ")
      printf "%s %s%s %s\n" $box_v $uptime_direct_content $uptime_direct_padding $box_v

      # Load line
      set -l load_padding (string repeat -n (math $inner_width - (string length $load_plain)) " ")
      printf "%s %s%s %s\n" $box_v $load_content $load_padding $box_v

      # Memory line
      set -l memory_padding (string repeat -n (math $inner_width - (string length $memory_plain)) " ")
      printf "%s %s%s %s\n" $box_v $memory_content $memory_padding $box_v

      # Disk line
      set -l disk_padding (string repeat -n (math $inner_width - (string length $disk_plain)) " ")
      printf "%s %s%s %s\n" $box_v $disk_content $disk_padding $box_v

      # Bottom border
      printf "%s%s%s\n" $box_bl $h_line $box_br
    end
  '';

  # Optional: Set fish as the default shell system-wide (you already set it per user)
  # users.defaultUserShell = pkgs.fish;

  # Set the Message of the Day (MOTD)
  programs.bash.loginShellInit = ''
    # Only run this if we're in an interactive shell
    case "$-,$TERM" in
      *i*,xterm*|*i*,vt*|*i*,screen*|*i*,tmux*|*i*,linux)
        # Clear the screen
        clear

        # Display system information using fastfetch (excluding uptime)
        ${pkgs.fastfetch}/bin/fastfetch --config none --logo none \
          --structure 'os,host,kernel,packages,shell,term' \
          --color-keys primary \
          --color-title primary \
          --color-separator '#555555'

        # Display uptime
        UPTIME_SEC=$(awk '{print int($1)}' /proc/uptime)
        DAYS=$((UPTIME_SEC / 86400))
        HOURS=$(( (UPTIME_SEC % 86400) / 3600 ))
        MINS=$(( (UPTIME_SEC % 3600) / 60 ))
        echo "Uptime (boot): ''${DAYS}d ''${HOURS}h ''${MINS}m"

        # Disk usage
        echo "" # Add a blank line for spacing
        ${pkgs.coreutils}/bin/df -h / /boot

        # Available updates
        if [ -e /run/motd-updates ]; then
          echo "" # Add a blank line for spacing
          cat /run/motd-updates
        fi

        echo "" # Add a final blank line
        ;;
    esac
  '';
}
