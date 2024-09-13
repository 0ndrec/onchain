#!/bin/bash
set -e

# Default variable values
APT_KEY_URL="https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg"
APT_DOWNLOAD_URL="https://us-central1-apt.pkg.dev/projects/sonaric-platform"
RPM_DOWNLOAD_URL="https://us-central1-yum.pkg.dev/projects/sonaric-platform/sonaric-releases-rpm"

SONARIC_ARGS=""
UNINSTALL=""
VERBOSE=""
DEVNULL="/dev/null"

# Function to display script usage
usage() {
 echo "Usage: $0 [OPTIONS]"
 echo "Options:"
 echo " -h, --help       Display this help message"
 echo " -v, --verbose    Enable verbose mode"
 echo " -u, --uninstall  Uninstall Sonaric"
}

# Function to handle options and arguments
handle_options() {
  while [ $# -gt 0 ]; do
    case $1 in
      -h | --help)
        usage
        exit 0
        ;;
      -v | --verbose)
        VERBOSE=true
        DEVNULL="/dev/stdout"
        ;;
      -u | --uninstall)
        UNINSTALL=true
        ;;
      *)
        echo "Invalid option: $1" >&2
        usage
        exit 1
        ;;
    esac
    shift
  done
}

# Main script execution
handle_options "$@"

print_message() {
  tput bold
  echo ""
	echo "$@"
	echo ""
  tput sgr0
}

command_exists() {
	command -v "$@" > /dev/null 2>&1
}

get_distribution() {
	lsb_dist=""
	# Every system that we officially support has /etc/os-release
	if [ -r /etc/os-release ]; then
		lsb_dist="$(. /etc/os-release && echo "$ID")"
	fi
	# Returning an empty string here should be alright since the
	# case statements don't act unless you provide an actual value
	echo "$lsb_dist"
}

# Check if this is a forked Linux distro
check_forked() {

	# Check for lsb_release command existence, it usually exists in forked distros
	if command_exists lsb_release; then
		# Check if the `-u` option is supported
		set +e
		lsb_release -a -u > /dev/null 2>&1
		lsb_release_exit_code=$?
		set -e

		# Check if the command has exited successfully, it means we're in a forked distro
		if [ "$lsb_release_exit_code" = "0" ]; then
			# Print info about current distro
			cat <<-EOF
			You're using '$lsb_dist' version '$dist_version'.
			EOF

			# Get the upstream release info
			lsb_dist=$(lsb_release -a -u 2>&1 | tr '[:upper:]' '[:lower:]' | grep -E 'id' | cut -d ':' -f 2 | tr -d '[:space:]')
			dist_version=$(lsb_release -a -u 2>&1 | tr '[:upper:]' '[:lower:]' | grep -E 'codename' | cut -d ':' -f 2 | tr -d '[:space:]')

			# Print info about upstream distro
			cat <<-EOF
			Upstream release is '$lsb_dist' version '$dist_version'.
			EOF
		else
			if [ -r /etc/debian_version ] && [ "$lsb_dist" != "ubuntu" ] && [ "$lsb_dist" != "raspbian" ]; then
				if [ "$lsb_dist" = "osmc" ]; then
					# OSMC runs Raspbian
					lsb_dist=raspbian
				else
					lsb_dist=debian
				fi
				dist_version="$(sed 's/\/.*//' /etc/debian_version | sed 's/\..*//')"
				case "$dist_version" in
					12)
						dist_version="bookworm"
					;;
					11)
						dist_version="bullseye"
					;;
					10)
						dist_version="buster"
					;;
					9)
						dist_version="stretch"
					;;
					8)
						dist_version="jessie"
					;;
				esac
			fi
		fi
	fi
}

user="$(id -un 2> /dev/null || true)"
sh_c='sh -c'
if [ "$user" != 'root' ]; then
  if command_exists sudo; then
    sh_c='sudo -E sh -c'
  elif command_exists su; then
    sh_c='su -c'
  else
    cat >&2 <<-'EOF'
Error: this installer needs the ability to run commands as root.
We are unable to find either "sudo" or "su" available to make this happen.
EOF
    exit 1
  fi
fi

exec_cmd() {
  if [ "$VERBOSE" = true ]; then
    echo "$@"
  fi
  $sh_c "$@"
}

confirm_Y() {
  read -p "$1 [Y/n] " reply;
  if [ "$reply" = "${reply#[Nn]}" ]; then
    return 0
  fi
 return 1
}

confirm_N() {
  read -p "$1 [y/N] " reply;
  if [ "$reply" = "${reply#[Yy]}" ]; then
    return 1
  fi
 return 0
}

#confirm_Y "Do you want to install Sonaric?" && echo true || echo false
#
#confirm_N "Do you not want to install Sonaric?" && echo true || echo false

echo '
  /$$$$$$                                          /$$
 /$$__  $$                                        |__/
| $$  \__/  /$$$$$$  /$$$$$$$   /$$$$$$   /$$$$$$  /$$  /$$$$$$$
|  $$$$$$  /$$__  $$| $$__  $$ |____  $$ /$$__  $$| $$ /$$_____/
 \____  $$| $$  \ $$| $$  \ $$  /$$$$$$$| $$  \__/| $$| $$
 /$$  \ $$| $$  | $$| $$  | $$ /$$__  $$| $$      | $$| $$
|  $$$$$$/|  $$$$$$/| $$  | $$|  $$$$$$$| $$      | $$|  $$$$$$$
 \______/  \______/ |__/  |__/ \_______/|__/      |__/ \_______/
'

print_message "Detecting OS..."

# perform some very rudimentary platform detection
lsb_dist=$( get_distribution )
lsb_dist="$(echo "$lsb_dist" | tr '[:upper:]' '[:lower:]')"

case "$lsb_dist" in

  ubuntu)
    if command_exists lsb_release; then
      dist_version="$(lsb_release --codename | cut -f2)"
    fi
    if [ -z "$dist_version" ] && [ -r /etc/lsb-release ]; then
      dist_version="$(. /etc/lsb-release && echo "$DISTRIB_CODENAME")"
    fi
  ;;

  debian|raspbian)
    dist_version="$(sed 's/\/.*//' /etc/debian_version | sed 's/\..*//')"
    case "$dist_version" in
      12)
        dist_version="bookworm"
      ;;
      11)
        dist_version="bullseye"
      ;;
      10)
        dist_version="buster"
      ;;
      9)
        dist_version="stretch"
      ;;
      8)
        dist_version="jessie"
      ;;
    esac
  ;;

  centos|rhel|sles)
    if [ -z "$dist_version" ] && [ -r /etc/os-release ]; then
      dist_version="$(. /etc/os-release && echo "$VERSION_ID")"
    fi
  ;;

  *)
    if command_exists lsb_release; then
      dist_version="$(lsb_release --release | cut -f2)"
    fi
    if [ -z "$dist_version" ] && [ -r /etc/os-release ]; then
      dist_version="$(. /etc/os-release && echo "$VERSION_ID")"
    fi
  ;;

esac

# Check if this is a forked Linux distro
check_forked

echo "OS: $lsb_dist $dist_version"

do_install() {
	# check if systemctl unit is present and if it is active
	if command_exists systemctl && systemctl list-units --full --all sonaricd.service | grep -Fq 'sonaricd.service'; then
    exec_cmd 'systemctl start sonaricd' || echo "Failed to start Sonaric"
  fi

	print_message "Checking Sonaric..."

  if command_exists sonaricd; then
    echo "Sonaric is already installed, checking updates..."
    do_update
    echo "Done"
    exit 0
  else
    echo "Sonaric is not installed."
  fi

  print_message "Installing Sonaric..."

	# Run setup for each distro accordingly
	case "$lsb_dist" in
		ubuntu|debian|raspbian)
      echo "Updating apt..."
      exec_cmd "apt-get update -qq > $DEVNULL"

      # Check if apt satisfies the version requirement
      echo "Checking podman version..."
      exec_cmd "DEBIAN_FRONTEND=noninteractive apt-get satisfy -y -qq --dry-run 'podman (>=3.4.0)' > $DEVNULL" || (
        echo "ERROR: Available podman version is too old, please upgrade to a supported distro"
        exit 1
      )

      echo "Checking prerequisites..."
			pre_reqs="apt-transport-https ca-certificates curl"
			if ! command -v gpg > /dev/null; then
				pre_reqs="$pre_reqs gnupg"
			fi
			apt_repo="deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/sonaric.gpg] $APT_DOWNLOAD_URL sonaric-releases-apt main"
			(
				echo "Updating apt..."
				exec_cmd "apt-get update -qq > $DEVNULL"
				echo "Installing apt dependencies..."
				exec_cmd "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq $pre_reqs > $DEVNULL"
				echo "Installing GPG key..."
				exec_cmd 'install -m 0755 -d /etc/apt/keyrings'
				exec_cmd "curl -fsSL \"$APT_KEY_URL\" | gpg --dearmor --yes -o /etc/apt/keyrings/sonaric.gpg > $DEVNULL 2>&1"
				exec_cmd "chmod a+r /etc/apt/keyrings/sonaric.gpg"
				echo "Configuring apt repository..."
				exec_cmd "echo \"$apt_repo\" > /etc/apt/sources.list.d/sonaric.list"
				echo "Updating apt..."
				exec_cmd "apt-get update -qq > $DEVNULL"
			)
			echo "Installing Sonaric..."

      # Sub-process /usr/bin/dpkg returned an error code (1)

			exec_cmd "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq sonaric"
			;;
		centos|fedora|rhel|rocky)
		  # use dnf for fedora or rocky linux, yum for centos or rhel
			if [ "$lsb_dist" = "fedora" ] || [ "$lsb_dist" = "rocky" ]; then
				pkg_manager="dnf"
				pre_reqs="dnf-plugins-core"
      elif [ "$lsb_dist" = "centos" ]; then
				pkg_manager="yum"
				pre_reqs="yum-utils"
			fi

			(
				echo "Installing dnf dependencies..."
				exec_cmd "$pkg_manager install -y -q $pre_reqs"
				echo "Configuring yum repository..."
				exec_cmd "echo \"[sonaric-releases-rpm]
name=sonaric-releases-rpm
baseurl=$RPM_DOWNLOAD_URL
enabled=1
repo_gpgcheck=0
gpgcheck=0\" > /etc/yum.repos.d/artifact-registry.repo"

        # Enable the repository
				echo "Updating yum..."
				exec_cmd "$pkg_manager makecache"
			)
			(
				pkgs="sonaricd sonaric"
				echo "Installing Sonaric..."
				exec_cmd "$pkg_manager install -y -q $pkgs"
			)
			;;
		*)
			echo
			echo "ERROR: Unsupported distribution '$lsb_dist'"
			echo
			exit 1
			;;
	esac

  echo "Sonaric installation completed"

  print_message "Starting Sonaric..."

  for try in $(seq 1 20); do
    exec_cmd "sonaric version $SONARIC_ARGS > $DEVNULL 2>&1" && break || sleep 2
  done

  print_message "Getting node info..."
  exec_cmd "sonaric node-info $SONARIC_ARGS"

  print_message "Preparing node..."
  confirm_N "Do you want to change your Sonaric node name? You can do it later using 'sonaric node-rename'" && exec_cmd "sonaric node-rename"
  confirm_N "Do you want to save your Sonaric identity? This can be done with 'sonaric identity-export'" && exec_cmd "sonaric identity-export"

  echo "Done"
  exit 0
}

do_update() {
  print_message "Updating Sonaric..."

	case "$lsb_dist" in
		ubuntu|debian|raspbian)
      exec_cmd "apt-get update -qq > $DEVNULL"
      exec_cmd "apt-get install sonaricd sonaric > $DEVNULL"
      exec_cmd "systemctl start sonaricd" || echo 'Failed to start sonaricd'
			;;
		centos|fedora|rhel|rocky)
		  # use dnf for fedora or rocky linux, yum for centos or rhel
			if [ "$lsb_dist" = "fedora" ] || [ "$lsb_dist" = "rocky" ]; then
				pkg_manager="dnf"
				pre_reqs="dnf-plugins-core"
      elif [ "$lsb_dist" = "centos" ]; then
				pkg_manager="yum"
				pre_reqs="yum-utils"
			fi

      exec_cmd "$pkg_manager update --refresh -y -q sonaricd sonaric > $DEVNULL"
      exec_cmd "systemctl start sonaricd" || echo 'Failed to start sonaricd'
      ;;
		*)
			echo
			echo "ERROR: Unsupported distribution '$lsb_dist'"
			echo
			exit 1
			;;
	esac

  for try in $(seq 1 20); do
    exec_cmd "sonaric version $SONARIC_ARGS > $DEVNULL 2>&1" && break || sleep 2
  done
  print_message "Getting node info..."
  exec_cmd "sonaric node-info $SONARIC_ARGS"
  print_message "Updating workloads..."
  exec_cmd "sonaric stop --all $SONARIC_ARGS > $DEVNULL 2>&1"
  exec_cmd "systemctl restart podman > $DEVNULL 2>&1"
  exec_cmd "sonaric update --all $SONARIC_ARGS > $DEVNULL 2>&1"
}

do_uninstall() {
	print_message "Uninstalling Sonaric..."

  # stop and delete all workloads
  if ! command_exists sonaric; then
    echo "Sonaric installation is not found"
    exit 0
  fi

  confirm_Y "Do you really want to uninstall Sonaric?" || exit 0

	# check if systemctl unit is present and if it is active
	if command_exists systemctl && systemctl list-units --full --all sonaricd.service | grep -Fq 'loaded'; then
    exec_cmd "systemctl start sonaricd > $DEVNULL"
  fi

  # stop and delete all workloads
  if command_exists sonaric; then
    exec_cmd "systemctl start sonaricd"
    for try in $(seq 1 20); do
      exec_cmd "sonaric version > $DEVNULL 2>&1" && break || sleep 2
    done
    print_message "Preparing to remove Sonaric..."
    confirm_Y "Do you want to export your Sonaric identity?" && exec_cmd "sonaric identity-export"
    print_message "Removing workloads..."
    exec_cmd "sonaric stop $SONARIC_ARGS -a > $DEVNULL 2>&1"
    exec_cmd "sonaric delete $SONARIC_ARGS -a --force > $DEVNULL 2>&1"
  fi

  print_message "Removing installed packages..."

	# Run setup for each distro accordingly
	case "$lsb_dist" in
		ubuntu|debian|raspbian)
			exec_cmd "DEBIAN_FRONTEND=noninteractive apt-get remove --auto-remove -y -qq sonaricd > $DEVNULL"
			exec_cmd "rm -f /etc/apt/sources.list.d/sonaric.list"
			exec_cmd "rm -f /etc/apt/keyrings/sonaric.gpg"
      echo "Done"
			exit 0
			;;
		centos|fedora|rhel|rocky)
		  # use dnf for fedora or rocky linux, yum for centos or rhel
			if [ "$lsb_dist" = "fedora" ] || [ "$lsb_dist" = "rocky" ]; then
				pkg_manager="dnf"
      elif [ "$lsb_dist" = "centos" ]; then
				pkg_manager="yum"
			fi

      exec_cmd "$pkg_manager remove -y -q sonaricd sonaric > $DEVNULL 2>&1"
      exec_cmd "rm -f /etc/yum.repos.d/artifact-registry.repo"
      echo "Done"
			exit 0
			;;
		*)
			echo
			echo "ERROR: Unsupported distribution '$lsb_dist'"
			echo
			exit 1
			;;
	esac
	exit 1
}

if [ "$UNINSTALL" = true ]; then
  do_uninstall
  exit 0
fi

# wrapped up in a function so that we have some protection against only getting
# half the file during "curl | sh"
do_install
