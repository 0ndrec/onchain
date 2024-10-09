#!/bin/bash

# Путь к файлу-флагу для проверки изменения конфигурации Docker
DOCKER_CONFIG_FLAG="$HOME/.docker_config_updated"
NETWORK_NAME="my_custom_network"

# Функция для проверки и установки необходимых пакетов
install_dependencies() {
  # Проверка наличия curl
  if ! [ -x "$(command -v curl)" ]; then
    echo "curl не установлен. Устанавливаем curl..."
    sudo apt-get update -y
    sudo apt-get install curl -y
  else
    echo "curl уже установлен."
  fi

  # Проверка наличия jq
  if ! [ -x "$(command -v jq)" ]; then
    echo "jq не установлен. Устанавливаем jq..."
    sudo apt-get update -y
    sudo apt-get install jq -y
  else
    echo "jq уже установлен."
  fi

  # Проверка наличия yq
  if ! [ -x "$(command -v yq)" ]; then
    echo "yq не установлен. Устанавливаем yq..."
    sudo wget https://github.com/mikefarah/yq/releases/download/v4.34.1/yq_linux_amd64 -O /usr/local/bin/yq
    sudo chmod +x /usr/local/bin/yq
  else
    echo "yq уже установлен."
  fi
}

# Функция для проверки и установки Docker и Docker Compose, если они не установлены
install_docker_if_needed() {
  if ! [ -x "$(command -v docker)" ]; then
    echo "Docker не установлен. Устанавливаем Docker..."
    sudo apt-get update -y
    sudo apt-get install ca-certificates curl gnupg lsb-release -y
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
      sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) \
      signed-by=/etc/apt/keyrings/docker.gpg] \
      https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update -y
    sudo apt-get install docker-ce docker-ce-cli containerd.io -y
  else
    echo "Docker уже установлен."
  fi

  if ! docker compose version > /dev/null 2>&1; then
    echo "Docker Compose не установлен. Устанавливаем Docker Compose..."
    sudo apt-get update -y
    sudo apt-get install docker-compose-plugin -y
  else
    echo "Docker Compose уже установлен."
  fi
}

install_oxker_tui() {
  if ! [ -x "$(command -v oxker)" ]; then
    echo "Oxker TUI не установлен. Устанавливаем Oxker TUI..."
    curl https://raw.githubusercontent.com/mrjackwills/oxker/main/install.sh | bash
  else
    echo "Oxker TUI уже установлен."
  fi
}

# Проверяем, изменялась ли конфигурация Docker, если нет, то добавляем пул IP-адресов
update_docker_config() {
  if [ ! -f "$DOCKER_CONFIG_FLAG" ]; then
    echo "Обновляем конфигурацию Docker с дополнительными пулами адресов..."
    sudo mkdir -p /etc/docker
    if [ -f /etc/docker/daemon.json ]; then
      sudo jq '.default-address-pools += [{"base":"10.10.0.0/16","size":24},{"base":"10.20.0.0/16","size":24}]' \
        /etc/docker/daemon.json > /tmp/daemon.json && \
        sudo mv /tmp/daemon.json /etc/docker/daemon.json
    else
      echo '{
        "default-address-pools": [
          {
            "base": "10.10.0.0/16",
            "size": 24
          },
          {
            "base": "10.20.0.0/16",
            "size": 24
          }
        ]
      }' | sudo tee /etc/docker/daemon.json
    fi
    sudo systemctl restart docker
    touch "$DOCKER_CONFIG_FLAG"
    echo "Конфигурация Docker обновлена и сервис перезапущен."
  else
    echo "Конфигурация Docker уже обновлена. Пропускаем этот шаг."
  fi
}

# Проверяем, существует ли сеть, если нет - создаём её
create_docker_network() {
  if ! docker network ls | grep -q "$NETWORK_NAME"; then
    echo "Создаем Docker сеть $NETWORK_NAME..."
    docker network create "$NETWORK_NAME"
    echo "Сеть $NETWORK_NAME создана."
  else
    echo "Сеть $NETWORK_NAME уже существует. Пропускаем этот шаг."
  fi
}

# Устанавливаем формат для вывода текста
bold=$(tput bold)
normal=$(tput sgr0)

# Путь к директории, где находится сам скрипт
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Путь к файлу wallets.txt
WALLETS="$SCRIPT_DIR/wallets.txt"

# Проверка наличия файла wallets.txt
if [ ! -f "$WALLETS" ]; then
  echo "Файл wallets.txt не найден! Пожалуйста, создайте файл wallets.txt с парами приватный_ключ и публичный_адрес."
  exit 1
fi

# Переменные окружения для портов
TYPESENSE_PORT=10006
HTTP_API_PORT=10001
P2P_ipV4BindTcpPort=10002
P2P_ipV4BindWsPort=10003
P2P_ipV6BindTcpPort=10004
P2P_ipV6BindWsPort=10005
P2P_ANNOUNCE_ADDRESS=$(curl -s ipinfo.io/ip)

# Функция для создания docker-compose файла
node_setup(){
    cat <<EOF > docker-compose.yml
services:
  ocean-node:
    image: oceanprotocol/ocean-node:latest
    container_name: ocean-node_$node_count
    restart: always
    ports:
      - "$HTTP_API_PORT:$HTTP_API_PORT"
      - "$P2P_ipV4BindTcpPort:$P2P_ipV4BindTcpPort"
      - "$P2P_ipV4BindWsPort:$P2P_ipV4BindWsPort"
      - "$P2P_ipV6BindTcpPort:$P2P_ipV6BindTcpPort"
      - "$P2P_ipV6BindWsPort:$P2P_ipV6BindWsPort"
    environment:
      PRIVATE_KEY: '$PRIVATE_KEY'
      RPCS: '{
  "1": {
    "rpc": "ТВОЯ rpc alchemy ИЛИ infura",
    "chainId": 1,
    "network": "mainnet",
    "chunkSize": 100
  },
  "10": {
    "rpc": "ТВОЯ rpc alchemy ИЛИ infura",
    "chainId": 10,
    "network": "optimism",
    "chunkSize": 100
  },
  "137": {
    "rpc": "ТВОЯ rpc alchemy ИЛИ infura",
    "chainId": 137,
    "network": "polygon",
    "chunkSize": 100
  },
  "23294": {
    "rpc": "https://sapphire.oasis.io",
    "fallbackRPCs": ["https://1rpc.io/oasis/sapphire"],
    "chainId": 23294,
    "network": "sapphire",
    "chunkSize": 100
  },
  "23295": {
    "rpc": "https://testnet.sapphire.oasis.io",
    "chainId": 23295,
    "network": "sapphire-testnet",
    "chunkSize": 100
  },
  "11155111": {
    "rpc": "ТВОЯ rpc alchemy ИЛИ infura",
    "chainId": 11155111,
    "network": "sepolia",
    "chunkSize": 100
  },
  "11155420": {
    "rpc": "ТВОЯ rpc alchemy ИЛИ infura",
    "chainId": 11155420,
    "network": "optimism-sepolia",
    "chunkSize": 100
  }
}'
      DB_URL: 'http://typesense:8108/?apiKey=xyz'
      IPFS_GATEWAY: 'https://ipfs.io/'
      ARWEAVE_GATEWAY: 'https://arweave.net/'
      INTERFACES: '["HTTP","P2P"]'
      ALLOWED_ADMINS: '["$ALLOWED_ADMINS"]'
      DASHBOARD: 'true'
      HTTP_API_PORT: '$HTTP_API_PORT'
      P2P_ENABLE_IPV4: 'true'
      P2P_ENABLE_IPV6: 'false'
      P2P_ipV4BindAddress: '0.0.0.0'
      P2P_ipV4BindTcpPort: '$P2P_ipV4BindTcpPort'
      P2P_ipV4BindWsPort: '$P2P_ipV4BindWsPort'
      P2P_ipV6BindAddress: '::'
      P2P_ipV6BindTcpPort: '$P2P_ipV6BindTcpPort'
      P2P_ipV6BindWsPort: '$P2P_ipV6BindWsPort'
      P2P_ANNOUNCE_ADDRESSES: '$P2P_ANNOUNCE_ADDRESSES'
    networks:
      - $NETWORK_NAME
    depends_on:
      - typesense

  typesense:
    image: typesense/typesense:26.0
    container_name: typesense_$node_count
    restart: always
    ports:
      - "$TYPESENSE_PORT:$TYPESENSE_PORT"
    networks:
      - $NETWORK_NAME
    volumes:
      - typesense-data:/data
    command: '--data-dir /data --api-key=xyz'

volumes:
  typesense-data:
    driver: local

networks:
  $NETWORK_NAME:
    external: true
EOF
}

# Функция для валидации данных
validate_hex() {
  if [[ ! "$1" =~ ^0x[0-9a-fA-F]{64}$ ]]; then
    echo "Приватный ключ недействителен, выход из программы..."
    exit 1
  fi
}

validate_address() {
  if [[ ! "$1" =~ ^0x[0-9a-fA-F]{40}$ ]]; then
    echo "Недействительный адрес кошелька, выход из программы!"
    exit 1
  fi
}

validate_port() {
  if [[ ! "$1" =~ ^[0-9]+$ ]] || [ "$1" -le 1024 ] || [ "$1" -ge 65535 ]; then
    echo "Недействительный номер порта, он должен быть между 1024 и 65535."
    exit 1
  fi
}

validate_ip_or_fqdn() {
  local input=$1

  if [[ "$input" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    IFS='.' read -r -a octets <<< "$input"
    for octet in "${octets[@]}"; do
      if (( octet < 0 || octet > 255 )); then
        echo "Недействительный IPv4 адрес. Каждый октет должен быть между 0 и 255."
        return 1
      fi
    done

    if [[ "$input" =~ ^10\.|^172\.(1[6-9]|2[0-9]|3[0-1])\.|^192\.168\.|^169\.254\.|^100\.64\.|^198\.51\.100\.|^203\.0\.113\.|^224\.|^240\. ]]; then
      echo "Указанный IP адрес принадлежит приватному или не маршрутизируемому диапазону и может быть недоступен для других узлов."
      return 1
    fi
  elif [[ "$input" =~ ^[a-zA-Z0-9.-]+$ ]]; then
    return 0
  else
    echo "Недействительный ввод, должен быть действительным IPv4 адресом или FQDN."
    return 1
  fi

  return 0
}

# Функция для отображения меню
menu() {
  echo "1) Установить Ocean"
  echo "2) Обновить все контейнеры"
  echo "3) Проверить логи контейнера"
  echo "4) Заменить RPC"
  echo "5) Перезагрузить все контейнеры"
  echo "6) Установить OXKER"
  echo -n "Выберите опцию: "
  read choice
  case $choice in
    1) install_ocean ;;
    2) update_containers ;;
    3) view_logs ;;
    4) replace_rpc ;;
    5) restart_containers ;;
    6) install_oxker_tui ;;
    *) echo "Неверный выбор!" ;;
  esac
}

# Функция для установки Ocean (основной процесс установки)
install_ocean() {
  clear
  echo "Устанавливаем необходимые зависимости..."
  install_dependencies
  echo "Устанавливаем Docker и Docker Compose..."
  install_docker_if_needed  # Устанавливаем Docker и Docker Compose, если нужно
  update_docker_config      # Обновляем конфигурацию Docker
  create_docker_network     # Создаем сеть Docker

  echo "Устанавливаем OCEAN узлы"
  node_count=1

  while read priv pub; do
      PRIVATE_KEY=$priv
      ALLOWED_ADMINS=$pub

      mkdir -p "$SCRIPT_DIR/ocean${node_count}" && cd "$SCRIPT_DIR/ocean${node_count}"

      validate_hex "$PRIVATE_KEY"
      validate_address "$ALLOWED_ADMINS"
      validate_port "$HTTP_API_PORT"
      validate_port "$P2P_ipV4BindTcpPort"
      validate_port "$P2P_ipV4BindWsPort"
      validate_port "$P2P_ipV6BindTcpPort"
      validate_port "$P2P_ipV6BindWsPort"

      if [ -n "$P2P_ANNOUNCE_ADDRESS" ]; then
        validate_ip_or_fqdn "$P2P_ANNOUNCE_ADDRESS"
        if [ $? -ne 0 ]; then
          echo "Недействительный адрес. Выход!"
          exit 1
        fi

        if [[ "$P2P_ANNOUNCE_ADDRESS" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            P2P_ANNOUNCE_ADDRESSES='["/ip4/'$P2P_ANNOUNCE_ADDRESS'/tcp/'$P2P_ipV4BindTcpPort'", "/ip4/'$P2P_ANNOUNCE_ADDRESS'/ws/tcp/'$P2P_ipV4BindWsPort'"]'
        elif [[ "$P2P_ANNOUNCE_ADDRESS" =~ ^[a-zA-Z0-9.-]+$ ]]; then
            P2P_ANNOUNCE_ADDRESSES='["/dns4/'$P2P_ANNOUNCE_ADDRESS'/tcp/'$P2P_ipV4BindTcpPort'", "/dns4/'$P2P_ANNOUNCE_ADDRESS'/ws/tcp/'$P2P_ipV4BindWsPort'"]'
        fi
      else
        P2P_ANNOUNCE_ADDRESSES=''
        echo "Адрес не указан, Ocean Node может быть недоступен для других узлов."
      fi

      node_setup
      sleep 3
      docker compose up -d

      echo "Контейнер поднят, подождем перед следующим запуском..."
      sleep 15  # Задержка между запусками контейнеров

      node_count=$(( $node_count + 1 ))
      TYPESENSE_PORT=$(( TYPESENSE_PORT + 10 ))
      HTTP_API_PORT=$(( $HTTP_API_PORT + 10 ))
      P2P_ipV4BindTcpPort=$(( $P2P_ipV4BindTcpPort + 10 ))
      P2P_ipV4BindWsPort=$(( $P2P_ipV4BindWsPort + 10 ))
      P2P_ipV6BindTcpPort=$(( $P2P_ipV6BindTcpPort + 10 ))
      P2P_ipV6BindWsPort=$(( $P2P_ipV6BindWsPort + 10 ))

      # Проверяем, что порты не превышают 65535
      if [ "$HTTP_API_PORT" -ge 65535 ] || [ "$P2P_ipV4BindTcpPort" -ge 65535 ] || [ "$P2P_ipV4BindWsPort" -ge 65535 ]; then
        echo "Порты превышают 65535. Остановка скрипта."
        exit 1
      fi
  done < "$WALLETS"
}

# Функция для замены RPC
replace_rpc() {
  echo "Вставьте новый RPC для сетей:"
  
  echo -n "Введите новый RPC для mainnet (chainId 1): "
  read new_rpc_mainnet

  echo -n "Введите новый RPC для optimism (chainId 10): "
  read new_rpc_optimism

  echo -n "Введите новый RPC для polygon (chainId 137): "
  read new_rpc_polygon

  echo -n "Введите новый RPC для sepolia (chainId 11155111): "
  read new_rpc_sepolia

  echo -n "Введите новый RPC для optimism-sepolia (chainId 11155420): "
  read new_rpc_optimism_sepolia

  echo "Скачиваем последнюю версию образа Docker..."
  docker pull oceanprotocol/ocean-node:latest

  for dir in "$SCRIPT_DIR"/ocean*; do
    if [ -d "$dir" ]; then
      cd "$dir"
      # Останавливаем контейнеры
      docker compose down
      # Обновляем docker-compose.yml
      yq e '.services."ocean-node".environment.RPCS |=
        (. | fromjson |
          .["1"].rpc = "'"$new_rpc_mainnet"'" |
          .["10"].rpc = "'"$new_rpc_optimism"'" |
          .["137"].rpc = "'"$new_rpc_polygon"'" |
          .["11155111"].rpc = "'"$new_rpc_sepolia"'" |
          .["11155420"].rpc = "'"$new_rpc_optimism_sepolia"'" |
          tojson)' -i docker-compose.yml
      # Перезапуск контейнеров
      docker compose up -d
      cd "$SCRIPT_DIR"
    fi
  done
}

# Функция для обновления всех контейнеров
update_containers() {
  clear
  echo "Останавливаем и удаляем все контейнеры..."
  for dir in "$SCRIPT_DIR"/ocean*; do
    if [ -d "$dir" ]; then
      cd "$dir"
      docker compose down
      cd "$SCRIPT_DIR"
    fi
  done
  echo "Скачиваем последнюю версию контейнеров..."
  docker pull oceanprotocol/ocean-node:latest
  echo "Запускаем контейнеры заново..."
  for dir in "$SCRIPT_DIR"/ocean*; do
    if [ -d "$dir" ]; then
      cd "$dir"
      docker compose up -d
      echo "Контейнер в директории $dir запущен. Ждем 10 секунд перед запуском следующего."
      sleep 10
      cd "$SCRIPT_DIR"
    fi
  done
}

# Функция для перезагрузки всех контейнеров с 10-секундной паузой
restart_containers() {
  clear
  echo "Перезагружаем все контейнеры с паузой в 10 секунд..."
  for dir in "$SCRIPT_DIR"/ocean*; do
    if [ -d "$dir" ]; then
      cd "$dir"
      echo "Перезагружаем контейнеры в директории $dir..."
      docker compose down
      docker compose up -d
      echo "Контейнеры в директории $dir перезапущены. Ждем 10 секунд перед следующим."
      sleep 10
      cd "$SCRIPT_DIR"
    fi
  done
  echo "Все контейнеры перезагружены."
}

# Функция для проверки логов контейнера
view_logs() {
  echo -n "Введите номер контейнера: "
  read container_number
  docker logs "ocean-node_$container_number"
}

# Основной запуск
menu  # Запуск основного меню
